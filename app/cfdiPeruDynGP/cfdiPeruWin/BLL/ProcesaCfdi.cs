using cfdiPeru;
using Comun;
using MaquinaDeEstados;
using OpenInvoicePeru.Comun.Dto.Intercambio;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Xml;

namespace cfd.FacturaElectronica
{
    public class ProcesaCfdi
    {
        private Parametros _Param;
        private ConexionAFuenteDatos _Conex;
        private String tramaXmlFirmado;
        private String tramaZipCdr;
        private String nroTicket=String.Empty;
        private bool _rbRetenciones = false;
        private bool _rbResumen = false;
        private readonly HttpClient _client;

        public string ultimoMensaje = "";
        vwCfdTransaccionesDeVenta trxVenta;

        internal vwCfdTransaccionesDeVenta TrxVenta
        {
            get
            {
                return trxVenta;
            }

            set
            {
                trxVenta = value;
            }
        }
        public delegate void LogHandler(int iAvance, string sMsj);
        public event LogHandler Progreso;

        /// <summary>
        /// Dispara el evento para actualizar la barra de progreso
        /// </summary>
        /// <param name="iProgreso"></param>
        public void OnProgreso(int iAvance, string sMsj)
        {
            if (Progreso != null)
                Progreso(iAvance, sMsj);
        }

        public ProcesaCfdi(ConexionAFuenteDatos Conex, Parametros Param)
        {
            _Param = Param;
            _Conex = Conex;
            _client = new HttpClient { BaseAddress = new Uri(ConfigurationManager.AppSettings["UrlOpenInvoicePeruApi"]) };

        }

        /// <summary>
        /// Ejecuta la generación de archivos xml en un thread independiente
        /// </summary>
        /// <param name="e">trxVentas</param>
        public async Task GeneraXmlAsync()
        {
            try
            {
                String msj = String.Empty;
                trxVenta.Rewind();                                                          //move to first record

                int errores = 0; int i = 1;
                cfdReglasFacturaXml DocVenta = new cfdReglasFacturaXml(_Conex, _Param);     //log de facturas xml emitidas y anuladas
                ReglasME maquina = new ReglasME(_Param);
                ValidadorXML validadorxml = new ValidadorXML(_Param);
                TransformerXML loader = new TransformerXML();
                //String Sello = string.Empty;

                OnProgreso(1, "INICIANDO...");              //Notifica al suscriptor
                do
                {
                    msj = String.Empty;
                    try
                    {
                        if (trxVenta.Estado.Equals("no emitido") &&
                            maquina.ValidaTransicion(_Param.tipoDoc, "EMITE XML Y PDF", trxVenta.EstadoActual, "emitido/impreso"))
                            if (trxVenta.Voidstts == 0)  //documento no anulado
                            {
                                trxVenta.ArmarDocElectronico();

                                var proxy = new HttpClient { BaseAddress = new Uri(ConfigurationManager.AppSettings["UrlOpenInvoicePeruApi"]) };

                                string metodoApi;
                                switch (trxVenta.DocElectronico.TipoDocumento)
                                {
                                    case "07":
                                        metodoApi = "api/GenerarNotaCredito";
                                        break;
                                    case "08":
                                        metodoApi = "api/GenerarNotaDebito";
                                        break;
                                    default:
                                        metodoApi = "api/GenerarFactura";
                                        break;
                                }

                                var response = await proxy.PostAsJsonAsync(metodoApi, trxVenta.DocElectronico);
                                //response.EnsureSuccessStatusCode();
                                var respuesta = await response.Content.ReadAsAsync<DocumentoResponse>();
                                if (!respuesta.Exito)
                                    throw new ApplicationException(respuesta.MensajeError);

                                if (!_Param.seguridadIntegrada)
                                {
                                    String RutaArchivo = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, $"{trxVenta.DocElectronico.IdDocumento}.xml");
                                    byte[] bTramaXmlSinFirma = Convert.FromBase64String(respuesta.TramaXmlSinFirma);
                                    File.WriteAllBytes(RutaArchivo, bTramaXmlSinFirma);
                                }

                                await EnviaSunat(respuesta.TramaXmlSinFirma);

                                //Guarda el archivo xml, genera el cbb y el pdf. 
                                //Luego anota en la bitácora la factura emitida o el error al generar cbb o pdf.
                                DocVenta.AlmacenaEnRepositorio(trxVenta, Encoding.UTF8.GetString(Convert.FromBase64String(tramaXmlFirmado)), maquina, tramaXmlFirmado, tramaZipCdr);

                            }
                            else //si el documento está anulado en gp, agregar al log como emitido
                            {
                                maquina.ValidaTransicion("FACTURA", "ANULA VENTA", trxVenta.EstadoActual, "emitido");
                                msj = "Anulado en GP y marcado como emitido.";
                                DocVenta.RegistraLogDeArchivoXML(trxVenta.Soptype, trxVenta.Sopnumbe, "Anulado en GP", "0", _Conex.Usuario, "", "emitido", maquina.eBinarioNuevo, msj.Trim());
                            }
                    }
                    catch (ApplicationException ae)
                    {
                        msj = ae.Message + Environment.NewLine + ae.StackTrace;
                        errores++;
                    }
                    catch (IOException io)
                    {
                        msj = "Excepción al revisar la carpeta/archivo: "+ trxVenta.Ruta_clave + " Verifique su existencia y privilegios." + Environment.NewLine + io.Message + Environment.NewLine;
                        errores++;
                    }
                    catch (Exception lo)
                    {
                        string imsj = lo.InnerException == null ? "" : lo.InnerException.ToString();
                        msj = lo.Message + " " + imsj + Environment.NewLine + lo.StackTrace;
                        errores++;
                    }
                    finally
                    {
                        OnProgreso(i * 100 / trxVenta.RowCount, "Doc:" + trxVenta.Sopnumbe + " " + msj.Trim() + Environment.NewLine);              //Notifica al suscriptor
                        i++;
                    }
                } while (trxVenta.MoveNext() && errores < 10);
            }
            catch (Exception xw)
            {
                string imsj = xw.InnerException == null ? "" : xw.InnerException.ToString();
                this.ultimoMensaje = xw.Message + " " + imsj + Environment.NewLine + xw.StackTrace;
            }
            finally
            {
                OnProgreso(100, ultimoMensaje);
            }
            OnProgreso(100, "Proceso finalizado!");
        }

        async Task EnviaSunat(String xmlSinFirma)
        {
                string codigoTipoDoc = trxVenta.DocElectronico.TipoDocumento;

                if (string.IsNullOrEmpty(trxVenta.DocElectronico.IdDocumento))
                    throw new InvalidOperationException("La Serie y el Correlativo no pueden estar vacíos");

                var tramaXmlSinFirma = xmlSinFirma;

                var firmadoRequest = new FirmadoRequest
                {
                    TramaXmlSinFirma = tramaXmlSinFirma,
                    //CertificadoDigital = Convert.ToBase64String(File.ReadAllBytes(_txtRutaCertificado)),
                    CertificadoDigital = Convert.ToBase64String(File.ReadAllBytes(trxVenta.Ruta_clave)),
                    PasswordCertificado = trxVenta.Contrasenia_clave,   // txtPassCertificado.Text,
                    UnSoloNodoExtension = _rbRetenciones || _rbResumen
                };

                var jsonFirmado = await _client.PostAsJsonAsync("api/Firmar", firmadoRequest);
                var respuestaFirmado = await jsonFirmado.Content.ReadAsAsync<FirmadoResponse>();
                if (!respuestaFirmado.Exito)
                    throw new ApplicationException(respuestaFirmado.MensajeError);

                var enviarDocumentoRequest = new EnviarDocumentoRequest
                {
                    Ruc = trxVenta.DocElectronico.Emisor.NroDocumento,  // txtNroRuc.Text,
                    UsuarioSol = trxVenta.Ruta_certificadoPac,    //txtUsuarioSol.Text,
                    ClaveSol = trxVenta.Contrasenia_clavePac,
                    EndPointUrl = _Param.URLwebServPAC,
                    IdDocumento = trxVenta.DocElectronico.IdDocumento,
                    TipoDocumento = codigoTipoDoc,
                    TramaXmlFirmado = respuestaFirmado.TramaXmlFirmado
                };

                var apiMetodo = _rbResumen && codigoTipoDoc != "09" ? "api/EnviarResumen" : "api/EnviarDocumento";

                var jsonEnvioDocumento = await _client.PostAsJsonAsync(apiMetodo, enviarDocumentoRequest);

                RespuestaComunConArchivo respuestaEnvio;
                if (!_rbResumen)
                {
                    respuestaEnvio = await jsonEnvioDocumento.Content.ReadAsAsync<EnviarDocumentoResponse>();
                    var rpta = (EnviarDocumentoResponse)respuestaEnvio;
                    
                    //txtResult.Text = $@"{Resources.procesoCorrecto}{Environment.NewLine}{rpta.MensajeRespuesta} siendo las {DateTime.Now}";
                    try
                    {
                        if (rpta.Exito)
                        {
                            if (!string.IsNullOrEmpty(rpta.TramaZipCdr))
                            {
                                tramaXmlFirmado = respuestaFirmado.TramaXmlFirmado;
                                tramaZipCdr = rpta.TramaZipCdr;
                                //File.WriteAllBytes($"{_carpetaXml}\\{respuestaEnvio.NombreArchivo}", Convert.FromBase64String(respuestaFirmado.TramaXmlFirmado));
                                //File.WriteAllBytes($"{_carpetaCdr}\\R-{respuestaEnvio.NombreArchivo}", Convert.FromBase64String(rpta.TramaZipCdr));
                            }
                            else
                            {
                                throw new ApplicationException("La respuesta de la Sunat es positiva, pero la trama zipCdr está vacía.");
                            }
                        }
                        else
                        {
                            throw new ApplicationException(rpta.MensajeError + Environment.NewLine + rpta.MensajeRespuesta);
                        }
                    }
                    catch (Exception)
                    {
                        throw;
                        //MessageBox.Show(ex.Message, Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
                else
                {
                    respuestaEnvio = await jsonEnvioDocumento.Content.ReadAsAsync<EnviarResumenResponse>();
                    var rpta = (EnviarResumenResponse)respuestaEnvio;
                    nroTicket = rpta.NroTicket;
                    //txtResult.Text = $@"{Resources.procesoCorrecto}{Environment.NewLine}{rpta.NroTicket}";
                }

                if (!respuestaEnvio.Exito)
                    throw new ApplicationException(respuestaEnvio.MensajeError);

        }

    }
}

