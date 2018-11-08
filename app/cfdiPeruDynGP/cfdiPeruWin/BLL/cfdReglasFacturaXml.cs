using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Xml;
using System.IO;
using System.Security.AccessControl;

//using Encriptador;
using MyGeneration.dOOdads;
using cfdiPeru;
using Comun;
using Reporteador;
using MaquinaDeEstados;
using QRCodeLib;

namespace cfd.FacturaElectronica
{
    class cfdReglasFacturaXml
    {
        public string ultimoMensaje = "";
        public int numMensajeError = 0;
        private ConexionAFuenteDatos _Conexion = null;
        private Parametros _Param = null;
        //CodigoDeBarras codigobb;
        Documento reporte;
        vwCfdTransaccionesDeVenta cfdiTransacciones;
        vwCfdiDatosDelXml_wrapper cfdiDatosXml;
        private string x_uuid;
        private string x_sello;

        public vwCfdTransaccionesDeVenta CfdiTransacciones
        {
            get
            {
                return cfdiTransacciones;
            }

            set
            {
                cfdiTransacciones = value;
            }
        }

        public cfdReglasFacturaXml(ConexionAFuenteDatos conex, Parametros param)
        {
            _Conexion = conex;
            _Param = param;
            reporte = new Documento(_Conexion, _Param);
            //codigobb = new CodigoDeBarras();

            numMensajeError = reporte.numErr;
            ultimoMensaje = reporte.mensajeErr;
        }

        public void AplicaFiltroADocumentos(bool filtroFecha, DateTime desdeF, DateTime hastaF, DateTime deFDefault, DateTime aFDefault,
                            bool filtroNumDoc, string numDocDe, string numDocA,
                            bool filtroIdDoc, string idDoc,
                            bool filtroEstado, string estado,
                            bool filtroCliente, string cliente, 
                            string nombreVista)
        {
            cfdiTransacciones = new vwCfdTransaccionesDeVenta(_Conexion.ConnStr, nombreVista);
            cfdiTransacciones.Query.AddOrderBy(vwCfdTransaccionesDeVenta.ColumnNames.ID_Certificado, WhereParameter.Dir.ASC);
            cfdiTransacciones.Query.AddOrderBy(vwCfdTransaccionesDeVenta.ColumnNames.Sopnumbe, WhereParameter.Dir.ASC);

            DateTime desdeFecha = new DateTime(deFDefault.Year, deFDefault.Month, deFDefault.Day, 0, 0, 0);
            DateTime hastaFecha = new DateTime(aFDefault.Year, aFDefault.Month, aFDefault.Day, 23, 59, 59);
            if (filtroFecha)
            {
                //Filtro personalizado
                desdeFecha = new DateTime(desdeF.Year, desdeF.Month, desdeF.Day, 0, 0, 0); ;
                hastaFecha = new DateTime(hastaF.Year, hastaF.Month, hastaF.Day, 23, 59, 59);
                //desdeFecha = desdeF;
                //hastaFecha = hastaF;
            }
            if ((!filtroNumDoc && !filtroIdDoc && !filtroEstado && !filtroCliente) || filtroFecha)
            {   //Filtra los documentos por fecha. De forma predeterminada es la fecha de hoy.
                cfdiTransacciones.Where.Fechahora.BetweenBeginValue = desdeFecha;
                cfdiTransacciones.Where.Fechahora.BetweenEndValue = hastaFecha;
                cfdiTransacciones.Where.Fechahora.Operator = WhereParameter.Operand.Between;
            }
            if (filtroNumDoc)
            {
                cfdiTransacciones.Where.Sopnumbe.BetweenBeginValue = numDocDe.Trim();
                cfdiTransacciones.Where.Sopnumbe.BetweenEndValue = numDocA.Trim();
                cfdiTransacciones.Where.Sopnumbe.Operator = WhereParameter.Operand.Between;
            }
            if (filtroIdDoc)
            {
                cfdiTransacciones.Where.Docid.Value = idDoc.Trim();
                cfdiTransacciones.Where.Docid.Operator = WhereParameter.Operand.Equal;
            }
            if (filtroEstado)
            {
                cfdiTransacciones.Where.Estado.Value = estado;
                cfdiTransacciones.Where.Estado.Operator = WhereParameter.Operand.Equal;
            }
            if (filtroCliente)
            {
                cfdiTransacciones.Where.NombreCliente.Value = "%" + cliente + "%";
                cfdiTransacciones.Where.NombreCliente.Operator = WhereParameter.Operand.Like;
            }
            try
            {
                if (!cfdiTransacciones.Query.Load())
                {
                    ultimoMensaje = "No hay datos para el filtro seleccionado.";
                    numMensajeError++;
                }
            }
            catch (Exception eFiltro)
            {
                ultimoMensaje = "[AplicaFiltro] Contacte al administrador. No se pudo consultar la base de datos. " + eFiltro.Message;
                numMensajeError++;
            }

        }


        public bool AplicaFiltroParaInformeMes(DateTime deFecha, DateTime aFecha,
                                            out vwCfdInformeMensualVentas infMes)
        {
            infMes = new vwCfdInformeMensualVentas(_Conexion.ConnStr);
            infMes.Query.AddOrderBy(vwCfdInformeMensualVentas.ColumnNames.Sopnumbe, WhereParameter.Dir.ASC);

            //Filtra los documentos por fecha. De forma predeterminada es la fecha de hoy.
            infMes.Where.Fechahora.BetweenBeginValue = string.Format("{0:yyyy-MM-dd}", deFecha) + " 00:00:00.0"; //"2010-08-01 00:00:00.0";
            infMes.Where.Fechahora.BetweenEndValue = string.Format("{0:yyyy-MM-dd}", aFecha) + " 23:59:59.9";
            infMes.Where.Fechahora.Operator = WhereParameter.Operand.Between;

            try
            {
                if (infMes.Query.Load())
                    return true;
                else
                    ultimoMensaje = "No hay datos para el filtro seleccionado.";
            }
            catch (Exception eFiltroMes)
            {
                ultimoMensaje = "[AplicaFiltroInformeMes] No se pudo consultar la base de datos. " + eFiltroMes.Message;
            }
            return false;
        }

        /// <summary>
        /// si la factura est� simult�neamente pagada, ingresa el cobro en el log en estado emitido
        /// </summary>
        public void RegistraLogDePagosSimultaneos(short Soptype, string Sopnumbe, string eBinarioNuevo, string eBinarioNuevoExplicado, string eBinActualConError, string eBinActualConErrorExplicado)
        {
            ultimoMensaje = "";
            numMensajeError = 0;
            vwCfdiPagosSimultaneos_wrapper pgSiml = new vwCfdiPagosSimultaneos_wrapper(_Conexion.ConnStr);
            pgSiml.Where.APTODCTY.Value = Soptype;
            pgSiml.Where.APTODCTY.Operator = WhereParameter.Operand.Equal;
            pgSiml.Where.APTODCNM.Conjuction = WhereParameter.Conj.And;
            pgSiml.Where.APTODCNM.Value = Sopnumbe;
            pgSiml.Where.APTODCNM.Operator = WhereParameter.Operand.Equal;
            try
            {
                if (pgSiml.Query.Load())
                {
                    pgSiml.Rewind();
                    for (int i = 1; i <= pgSiml.RowCount; i++)
                    {
                        RegistraLogDeArchivoXML(pgSiml.Apfrdcty, pgSiml.Apfrdcnm, pgSiml.APTODCNM, "0", _Conexion.Usuario, "", "emitido", eBinarioNuevo, eBinarioNuevoExplicado);
                    }
                }
            }
            catch (Exception eGen)
            {
                ultimoMensaje = "Excepci�n al ingresar los pagos simult�neos en el log. [RegistraLogDePagosSimultaneos] " + eGen.Message + " " + eGen.Source;
                ActualizaFacturaEmitida(Soptype, Sopnumbe, _Conexion.Usuario, "emitido", "emitido", eBinActualConError, eBinActualConErrorExplicado + ultimoMensaje.Trim(), String.Empty);
                numMensajeError++;
                throw;
            }
        }

        /// <summary>
        /// Inserta datos de una factura en el log de facturas. 
        /// </summary>
        /// <returns></returns>
        public void RegistraLogDeArchivoXML(short soptype, string sopnumbe, string mensaje, string noAprobacion, string idusuario, string innerxml, 
                                            string eBaseNuevo, string eBinarioActual, string mensajeBinActual)
        {
            try
            {
                //log de facturas xml emitido y xml anulado
                cfdLogFacturaXML logVenta = new cfdLogFacturaXML(_Conexion.ConnStr);
                
                logVenta.AddNew();
                logVenta.Soptype = soptype;
                logVenta.Sopnumbe = sopnumbe;
                logVenta.Mensaje = Utiles.Derecha(mensaje, 255);
                logVenta.Estado = eBaseNuevo;
                logVenta.NoAprobacion = noAprobacion;
                logVenta.FechaEmision = DateTime.Now;
                logVenta.IdUsuario = Utiles.Derecha(idusuario, 10);
                logVenta.IdUsuarioAnulacion = "-";
                logVenta.FechaAnulacion = new DateTime(1900, 1, 1);
                if (!innerxml.Equals("")) 
                    logVenta.ArchivoXML = innerxml;
                logVenta.EstadoActual = eBinarioActual;
                logVenta.MensajeEA = Utiles.Derecha(mensajeBinActual, 255);
                logVenta.Save();
           }
           catch (Exception)
           {
                throw;
           }
        }

        /// <summary>
        /// Actualiza la fecha, estado y observaciones de una factura emitida en el log de facturas. 
        /// </summary>
        /// <returns></returns>
        public void ActualizaFacturaEmitida(short Soptype, string Sopnumbe, string idusuario, string eBaseAnterior, string eBaseNuevo, string eBinarioActual, string mensajeEA, string noAprobacion)
        {
            cfdLogFacturaXML xmlEmitido = new cfdLogFacturaXML(_Conexion.ConnStr);
            xmlEmitido.Where.Soptype.Value = Soptype;
            xmlEmitido.Where.Soptype.Operator = WhereParameter.Operand.Equal;
            xmlEmitido.Where.Sopnumbe.Conjuction = WhereParameter.Conj.And;
            xmlEmitido.Where.Sopnumbe.Value = Sopnumbe;
            xmlEmitido.Where.Sopnumbe.Operator = WhereParameter.Operand.Equal;
            xmlEmitido.Where.Estado.Conjuction = WhereParameter.Conj.And;
            xmlEmitido.Where.Estado.Value = eBaseAnterior;      // "emitido";
            xmlEmitido.Where.Estado.Operator = WhereParameter.Operand.Equal;
            try
            {
                if (xmlEmitido.Query.Load())
                {
                    if (!eBaseAnterior.Equals(eBaseNuevo))
                        xmlEmitido.Estado = eBaseNuevo;         // "anulado";
                    xmlEmitido.FechaAnulacion = DateTime.Now;
                    xmlEmitido.IdUsuarioAnulacion = Utiles.Derecha(idusuario, 10);
                    xmlEmitido.EstadoActual = eBinarioActual;
                    xmlEmitido.MensajeEA = Utiles.Derecha(mensajeEA, 255);
                    xmlEmitido.NoAprobacion = noAprobacion;
                    xmlEmitido.Save();
                    //ultimoMensaje = "Completado.";
                }
                else
                {
                    throw new ArgumentException(Sopnumbe+" No est� en la bit�cora en estado 'emitido'.");
                }
            }
            catch (Exception)
            {
                throw;
            }
        }

        /// <summary>
        /// Guarda el archivo xml, lo comprime en zip y anota en la bit�cora la factura emitida y el nuevo estado binario.
        /// Luego genera y guarda el c�digo de barras bidimensional y pdf. En caso de error, anota en la bit�cora. 
        /// </summary>
        /// <param name="trxVenta">Lista de facturas cuyo �ndice apunta a la factura que se va procesar.</param>
        /// <param name="comprobante">Documento xml firmado por la sunat</param>
        /// <param name="mEstados">Nuevo set de estados</param>
        /// <param name="tramaXmlFirmado">trama del xml firmado por la sunat en base 64</param>
        /// <param name="tramaZipCdr">trama zipeada del cdr enviado por la sunat</param>
        public void AlmacenaEnRepositorio(vwCfdTransaccionesDeVenta trxVenta, String comprobante, ReglasME mEstados, String tramaXmlFirmado, String tramaZipCdr, String ticket, String nomArchivoCDR, 
                                        String tipoDoc, String accion, bool eBinarioOK)
        {
            try
            {   //arma el nombre del archivo xml
                string nomArchivo = Utiles.FormatoNombreArchivo(trxVenta.Docid + trxVenta.Sopnumbe + "_" + trxVenta.s_CUSTNMBR, trxVenta.s_NombreCliente, 20);
                string rutaYNomArchivoCfdi = string.Concat(trxVenta.RutaXml.Trim() , nomArchivo ,"_", accion.Substring(0,2), ".xml");
                string rutaYNomArchivoCdr = trxVenta.RutaXml.Trim() + @"CDR\"+ nomArchivoCDR;

                //Guarda el archivo xml
                if ((tipoDoc.Equals("FACTURA") && accion.Equals("EMITE XML Y PDF")) ||
                    (tipoDoc.Equals("RESUMEN") && accion.Equals("ENVIA RESUMEN")) ||
                    (tipoDoc.Equals("FACTURA") && accion.Equals("DAR DE BAJA"))
                    )
                {
                    if (!string.IsNullOrEmpty(tramaXmlFirmado))
                        File.WriteAllBytes($"{rutaYNomArchivoCfdi}", Convert.FromBase64String(tramaXmlFirmado));
                    else
                        throw new ArgumentException("No se puede guardar el archivo xml " + nomArchivo + " porque est� vac�o.");
                }

                //Guarda el CDR
                if (tipoDoc.Equals("FACTURA") && accion.Equals("EMITE XML Y PDF") ||
                    accion.Equals("CONSULTA CDR")
                    )
                {
                    if (!string.IsNullOrEmpty(tramaZipCdr))
                        File.WriteAllBytes($"{rutaYNomArchivoCdr}", Convert.FromBase64String(tramaZipCdr));
                    else
                        throw new ArgumentException("No se puede guardar el archivo cdr de la SUNAT porque est� vac�o.");
                }

                String status;
                String msjBinActual;
                String eBinario = !eBinarioOK ? mEstados.eBinActualConError : mEstados.eBinarioNuevo;
                switch (accion){
                    case "DAR DE BAJA":
                        status = "publicado";
                        msjBinActual = "Baja solicitada el " + DateTime.Today.ToString();
                        break;
                    case "CONSULTA CDR":
                        if (tipoDoc.Equals("FACTURA")) 
                            status = !eBinarioOK ? "rechazo_sunat" : "anulado";
                        else 
                            status = !eBinarioOK ? "rechazo_sunat" : "acepta_sunat";

                        msjBinActual = comprobante;
                        rutaYNomArchivoCfdi = rutaYNomArchivoCdr;
                        break;
                    default:
                        status = "emitido";
                        msjBinActual = mEstados.EnLetras(eBinario, tipoDoc);
                        break;
                }
                
                //Registra log de la emisi�n del xml antes de imprimir el pdf, sino habr� error al imprimir
                RegistraLogDeArchivoXML(trxVenta.Soptype, trxVenta.Sopnumbe, rutaYNomArchivoCfdi, ticket, _Conexion.Usuario, comprobante.Replace("encoding=\"utf-8\"", ""),
                                        status, eBinario, msjBinActual);

                //Genera pdf
                if (tipoDoc.Equals("FACTURA") && accion.Equals("EMITE XML Y PDF"))
                   reporte.generaEnFormatoPDF(rutaYNomArchivoCfdi, trxVenta.Soptype, trxVenta.Sopnumbe, trxVenta.EstadoContabilizado);

            }
            catch (DirectoryNotFoundException)
            {
                string smsj = "Verifique en GP la existencia de la carpeta indicada en la configuraci�n de Ruta de archivos Xml. La ruta de la carpeta no pudo ser encontrada: " + trxVenta.RutaXml;
                throw new DirectoryNotFoundException(smsj);
            }
            catch (IOException)
            {
                string smsj = "Verifique permisos de escritura en la carpeta: " + trxVenta.RutaXml + ". No se pudo guardar el archivo xml ni registrar el documento en la bit�cora. ";
                throw new IOException(smsj);
            }
            catch (Exception eAFE)
            {
                string smsj;
                if (eAFE.Message.Contains("denied"))
                    smsj = "Elimine el archivo xml antes de volver a generar uno nuevo. Luego vuelva a intentar. " + eAFE.Message;
                else
                    smsj = "Contacte a su administrador. No se pudo guardar el archivo XML ni registrar la Bit�cora. " + eAFE.Message + Environment.NewLine + eAFE.StackTrace;
                throw new Exception(smsj);
            }
        }

        private void getDatosDelXml(short soptype, string sopnumbe)
        {
            try
            {
                x_uuid = string.Empty;
                x_sello = string.Empty;
                cfdiDatosXml.Where.Sopnumbe.Value = sopnumbe;
                cfdiDatosXml.Where.Sopnumbe.Operator = WhereParameter.Operand.Equal;
                cfdiDatosXml.Where.Soptype.Conjuction = WhereParameter.Conj.And;
                cfdiDatosXml.Where.Soptype.Value = soptype;
                cfdiDatosXml.Where.Soptype.Operator = WhereParameter.Operand.Equal;
                cfdiDatosXml.Where.Estado.Conjuction = WhereParameter.Conj.And;
                cfdiDatosXml.Where.Estado.Value = "emitido";
                cfdiDatosXml.Where.Estado.Operator = WhereParameter.Operand.Equal;

                if (cfdiDatosXml.Query.Load())
                {
                    x_uuid = cfdiDatosXml.UUID;
                    x_sello = cfdiDatosXml.Sello;
                }

            }
            catch (Exception eIddoc)
            {
                ultimoMensaje = "Contacte al administrador. No se puede acceder a la base de datos." + eIddoc.Message;
            }
        }

        /// <summary>
        /// Genera y guarda el archivo pdf. 
        /// Luego anota en la bit�cora la factura impresa y el nuevo estado binario
        /// </summary>
        /// <param name="trxVenta"></param>
        /// <param name="eBase"></param>
        /// <param name="eBinario"></param>
        /// <param name="enLetras"></param>
        /// <returns></returns>
        public bool AlmacenaEnRepositorio(vwCfdTransaccionesDeVenta trxVenta, string eBase, string eBinario, string enLetras)
        {
            ultimoMensaje = "";
            numMensajeError = 0;

            try
            {
                string nomArchivo = Utiles.FormatoNombreArchivo(trxVenta.Docid + trxVenta.Sopnumbe + "_" + trxVenta.s_CUSTNMBR, trxVenta.s_NombreCliente, 20);
                string rutaYNomArchivo = trxVenta.RutaXml.Trim() + nomArchivo;

                reporte.generaEnFormatoPDF(rutaYNomArchivo, trxVenta.Soptype, trxVenta.Sopnumbe, trxVenta.EstadoContabilizado);

                numMensajeError = reporte.numErr; // + codigobb.iErr;
                ultimoMensaje = reporte.mensajeErr; // + codigobb.strMensajeErr;

                if (reporte.numErr==0)  // && codigobb.iErr==0)
                    RegistraLogDeArchivoXML(trxVenta.Soptype, trxVenta.Sopnumbe, "Almacenado en " + rutaYNomArchivo, "0", _Conexion.Usuario, "", eBase, eBinario, enLetras);

                return ultimoMensaje.Equals(string.Empty);
            }
            catch (Exception eAFE)
            {
                ultimoMensaje = "Contacte a su administrador. No se pudo guardar el archivo PDF ni registrar la Bit�cora. [AlmacenaEnRepositorio()] " + eAFE.Message;
                numMensajeError++;
                return false;
            }
        }
    }
}
