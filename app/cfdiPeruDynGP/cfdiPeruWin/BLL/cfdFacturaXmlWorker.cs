using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Text;
using System.Xml;
using System.Xml.Xsl;

using Comun;
using cfdiPeru;
//using Encriptador;
using MaquinaDeEstados;
using QRCodeLib;

namespace cfd.FacturaElectronica
{
    class cfdFacturaXmlWorker : BackgroundWorker
    {
        private Parametros _Param;
        private ConexionAFuenteDatos _Conex;
        public string ultimoMensaje = "";

        public cfdFacturaXmlWorker(ConexionAFuenteDatos Conex, Parametros Param)
        {
            WorkerReportsProgress = true;
            WorkerSupportsCancellation = true;
            _Param = Param;
            _Conex = Conex;
        }

        /// <summary>
        /// Ejecuta la generación de archivos xml y pdf en un thread independiente
        /// </summary>
        /// <param name="e">trxVentas</param>
        protected override void OnDoWork(DoWorkEventArgs e)
        {
            ReportProgress(0, "Iniciando proceso...\r\n");
            object[] args = e.Argument as object[];
            vwCfdTransaccionesDeVenta trxVenta = (vwCfdTransaccionesDeVenta)args[0];
            trxVenta.Rewind();                                                          //move to first record

            int errores = 0; int i = 1;
            string antiguoIdCertificado = "";
            XmlDocument sello = new XmlDocument();
            //TecnicaDeEncriptacion criptografo = null;
            XmlDocument comprobante = new XmlDocument();
            XmlDocumentFragment addenda;
            cfdReglasFacturaXml DocVenta = new cfdReglasFacturaXml(_Conex, _Param);     //log de facturas xml emitidas y anuladas
            ReglasME maquina = new ReglasME(_Param);
            ValidadorXML validadorxml = new ValidadorXML(_Param);
            TransformerXML loader = new TransformerXML();
            XslCompiledTransform xslCompilado = loader.Load(_Param.URLArchivoXSLT);
            //PAC representanteSat = new PAC(trxVenta.Ruta_clavePac, trxVenta.Contrasenia_clavePac, _Param);
            String Sello = string.Empty;

            ultimoMensaje = validadorxml.mensajeError;
            //if (validadorxml.numErrores != 0 || DocVenta.numMensajeError != 0 || loader.numErrores != 0 || representanteSat.numErr != 0)
            //{
            //    e.Result = validadorxml.mensajeError + " " + DocVenta.ultimoMensaje + " "+ loader.mensajeError+ " "+ representanteSat.msjError+ "\r\n";
            //    ReportProgress(100, validadorxml.mensajeError + " " + DocVenta.ultimoMensaje + " " + loader.mensajeError + " " + representanteSat.msjError + "\r\n");
            //    return;
            //}
            //do
            //{
            //    if (CancellationPending) { e.Cancel = true; return; }

            //    if (trxVenta.Estado.Equals("no emitido") &&
            //        maquina.ValidaTransicion(_Param.tipoDoc, "EMITE XML Y PDF", trxVenta.EstadoActual, "emitido/impreso"))
            //        if (trxVenta.Voidstts == 0)  //documento no anulado
            //        {
            //            //Cargar los datos del certificado por cada nuevo Id de certificado asociado al documento de venta
            //            if (!trxVenta.ID_Certificado.Equals(antiguoIdCertificado))
            //            {
            //                criptografo = new TecnicaDeEncriptacion(trxVenta.Ruta_clave, trxVenta.Contrasenia_clave, trxVenta.Ruta_certificado.Trim(), trxVenta.Ruta_certificado.Replace(".cer", ".pem").Trim());
            //                antiguoIdCertificado = trxVenta.ID_Certificado;
            //            }

            //            comprobante.LoadXml(trxVenta.ComprobanteXml);
            //            if (criptografo.numErrores == 0 &&
            //                loader.getCadenaOriginal(comprobante, xslCompilado))    //Obtener cadena original del CFD
            //            {                                                           //Crear el archivo xml y sellarlo
            //                Sello = criptografo.obtieneSello(loader.cadenaOriginal);
            //                comprobante.DocumentElement.SetAttribute("Sello", Sello);
            //                comprobante.DocumentElement.SetAttribute("NoCertificado", criptografo.noCertificado);
            //                comprobante.DocumentElement.SetAttribute("Certificado", criptografo.certificadoFormatoPem);

            //                if (!_Conex.IntegratedSecurity)                         //para testeo:
            //                    comprobante.Save(new XmlTextWriter(trxVenta.Sopnumbe + "tst.xml", Encoding.UTF8));
            //            }

            //            if (loader.numErrores == 0 &&
            //                criptografo.numErrores == 0 &&
            //                validadorxml.ValidarXSD(comprobante))                   //Validar el esquema del archivo xml
            //            {
            //                representanteSat.comprobanteFiscal = comprobante;
            //                representanteSat.timbraCFD();                           //agregar sello al comprobante
            //            }
            //            else
            //                errores++;
                        
            //            if (loader.numErrores == 0 && 
            //                validadorxml.numErrores == 0 &&
            //                criptografo.numErrores == 0 &&
            //                representanteSat.numErr == 0)
            //            {
            //                //Agregar el nodo addenda si existe
            //                if (trxVenta.Addenda != null && trxVenta.Addenda.Length > 0)
            //                {
            //                    addenda = comprobante.CreateDocumentFragment();
            //                    addenda.InnerXml = trxVenta.Addenda;
            //                    comprobante.DocumentElement.AppendChild(addenda);
            //                }

            //                //Guarda el archivo xml, genera el cbb y el pdf. 
            //                //Luego anota en la bitácora la factura emitida o el error al generar cbb o pdf.
            //                if (!DocVenta.AlmacenaEnRepositorio(trxVenta, comprobante, maquina, representanteSat.Uuid, Sello))
            //                    errores++;
            //            }
            //            else
            //                errores++;
            //            this.ultimoMensaje = criptografo.ultimoMensaje + " " + validadorxml.mensajeError + " " + DocVenta.ultimoMensaje + " " +
            //                        loader.mensajeError + " " + representanteSat.msjError;
            //        }
            //        else //si el documento está anulado en gp, agregar al log como emitido
            //        {
            //            maquina.ValidaTransicion("FACTURA", "ANULA VENTA", trxVenta.EstadoActual, "emitido");
            //            this.ultimoMensaje = "Anulado en GP y marcado como emitido.";
            //            DocVenta.RegistraLogDeArchivoXML(trxVenta.Soptype, trxVenta.Sopnumbe, "Anulado en GP", "0", _Conex.Usuario, "",
            //                                                     "emitido", maquina.eBinarioNuevo, this.ultimoMensaje.Trim());

            //        }
            //    ReportProgress(i * 100 / trxVenta.RowCount, "Doc:" + trxVenta.Sopnumbe + " " + this.ultimoMensaje.Trim() + "\r\n");
            //    i++;
            //} while (trxVenta.MoveNext() && errores < 10);
            e.Result = "Generación de archivos finalizado! \r\n";
            ReportProgress(100, "");
        }

    }
}
