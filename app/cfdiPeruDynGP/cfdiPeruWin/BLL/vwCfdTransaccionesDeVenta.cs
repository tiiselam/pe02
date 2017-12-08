using System;
using System.Collections.Generic;
using System.Text;
using OpenInvoicePeru.Comun.Dto.Modelos;
using cfdiEntidadesGP;

namespace cfdiPeru
{
    class vwCfdTransaccionesDeVenta : vwCfdiTransaccionesDeVenta
    {
        DocumentoElectronico _docElectronico;
        ResumenDiarioNuevo _resumenElectronico;
        List<DetalleDocumento> lDetalleDocumento;
        private const string FormatoFecha = "yyyy-MM-dd";

        public DocumentoElectronico DocElectronico
        {
            get
            {
                return _docElectronico;
            }

            set
            {
                _docElectronico = value;
            }
        }

        public ResumenDiarioNuevo ResumenElectronico
        {
            get
            {
                return _resumenElectronico;
            }

            set
            {
                _resumenElectronico = value;
            }
        }

        public vwCfdTransaccionesDeVenta(string connstr, string nombreVista)
        {
            this.ConnectionString = connstr;
            this.QuerySource = nombreVista;
            this.MappingName = nombreVista;

            //this.QuerySource = "vwCfdiTransaccionesDeVenta";
            //this.MappingName = "vwCfdiTransaccionesDeVenta";
        }

        public void ArmarDocElectronico()
        {
            try
            {
                DocumentoVentaGP docGP = new DocumentoVentaGP();

                docGP.GetDatosDocumentoVenta(this.Sopnumbe, this.Soptype);

                _docElectronico = new DocumentoElectronico();
                _docElectronico.TipoDocumento = docGP.DocVenta.tipoDocumento;
                _docElectronico.IdDocumento = docGP.DocVenta.idDocumento;
                _docElectronico.FechaEmision = this.Fechahora.ToString();
                _docElectronico.Moneda = docGP.DocVenta.moneda;
                _docElectronico.Emisor.NroDocumento = docGP.DocVenta.emisorNroDoc;
                _docElectronico.Emisor.NombreComercial = docGP.DocVenta.emisorNombre;
                _docElectronico.Emisor.NombreLegal = docGP.DocVenta.emisorNombre;
                _docElectronico.Emisor.Ubigeo = docGP.DocVenta.emisorUbigeo;
                _docElectronico.Emisor.Direccion = docGP.DocVenta.emisorDireccion;
                _docElectronico.Emisor.Urbanizacion = docGP.DocVenta.emisorUrbanizacion;
                _docElectronico.Emisor.Departamento = docGP.DocVenta.emisorDepartamento;
                _docElectronico.Emisor.Provincia = docGP.DocVenta.emisorProvincia;
                _docElectronico.Emisor.Distrito = docGP.DocVenta.emisorDistrito;
                _docElectronico.Receptor.TipoDocumento = docGP.DocVenta.receptorTipoDoc;
                _docElectronico.Receptor.NroDocumento = docGP.DocVenta.receptorNroDoc;
                _docElectronico.Receptor.NombreComercial = docGP.DocVenta.receptorNombre;
                _docElectronico.Receptor.NombreLegal = docGP.DocVenta.receptorNombre;
                _docElectronico.TipoOperacion = docGP.DocVenta.tipoOperacion;
                _docElectronico.DescuentoGlobal = docGP.DocVenta.ORTDISAM;
                _docElectronico.TotalIgv = docGP.DocVenta.iva;
                _docElectronico.Gravadas = docGP.DocVenta.ivaImponible;
                _docElectronico.Inafectas = docGP.DocVenta.inafecta;
                _docElectronico.Exoneradas = docGP.DocVenta.exonerado;
                _docElectronico.Gratuitas = docGP.DocVenta.gratuito;
                _docElectronico.TotalVenta = docGP.DocVenta.total;
                _docElectronico.MontoEnLetras = docGP.DocVenta.montoEnLetras;

                lDetalleDocumento = new List<DetalleDocumento>();
                foreach (vwCfdiConceptos d in docGP.LDocVentaConceptos)
                {
                    lDetalleDocumento.Add(new DetalleDocumento()
                    {
                        CodigoItem = d.ITEMNMBR,
                        Id = Convert.ToInt16(d.id),
                        Descripcion = d.Descripcion,
                        Cantidad = d.cantidad,
                        UnidadMedida = d.udemSunat,
                        PrecioUnitario = d.valorUni,
                        PrecioReferencial = Convert.ToDecimal(d.precioUniConIva),
                        TotalVenta = Convert.ToDecimal(d.importe),
                        TipoPrecio = d.tipoPrecio,
                        Impuesto = d.orslstax,
                        TipoImpuesto = d.tipoImpuesto,
                        
                    });
                }
                _docElectronico.Items = new List<DetalleDocumento>();
                _docElectronico.Items = lDetalleDocumento;

                if (docGP.LDocVentaRelacionados.Count > 0)
                {
                    _docElectronico.Relacionados = new List<DocumentoRelacionado>();
                    _docElectronico.Discrepancias = new List<Discrepancia>();
                    foreach (vwCfdiRelacionados d in docGP.LDocVentaRelacionados)
                    {
                        _docElectronico.Relacionados.Add(new DocumentoRelacionado()
                        {
                            NroDocumento = d.sopnumbeTo,
                            TipoDocumento = d.tipoDocumento
                        });

                        _docElectronico.Discrepancias.Add(new Discrepancia()
                        {
                            Tipo = docGP.DocVenta.discrepanciaTipo,
                            Descripcion = docGP.DocVenta.discrepanciaDesc,
                            NroReferencia = d.sopnumbeTo
                        });
                    }

                }


            }
            catch (Exception)
            {

                throw;
            }
        }

        public void ArmarResumenElectronico()
        {
            try
            {
                DocumentoVentaGP docGP = new DocumentoVentaGP();
                docGP.GetDatosResumenBoletas(this.Sopnumbe, this.Soptype);

                _resumenElectronico = new ResumenDiarioNuevo()
                {
                    IdDocumento = docGP.ResumenCab.numResumenDiario,
                    FechaEmision = docGP.ResumenCab.docdate.ToString(FormatoFecha), //DateTime.Today.ToString(FormatoFecha),
                    FechaReferencia = docGP.ResumenCab.docdate.ToString(FormatoFecha),
                    Emisor = new Contribuyente()
                    {
                        NroDocumento = docGP.ResumenCab.emisorNroDoc,
                        TipoDocumento = docGP.ResumenCab.emisorTipoDoc,
                        Direccion = docGP.ResumenCab.emisorDireccion,
                        Urbanizacion = docGP.ResumenCab.emisorUrbanizacion,
                        Departamento = docGP.ResumenCab.emisorDepartamento,
                        Provincia = docGP.ResumenCab.emisorProvincia,
                        Distrito = docGP.ResumenCab.emisorDistrito,
                        NombreComercial = docGP.ResumenCab.emisorNombre,
                        NombreLegal = docGP.ResumenCab.emisorNombre,
                        Ubigeo = docGP.ResumenCab.emisorUbigeo
                    },
                    Resumenes=new List<GrupoResumenNuevo>()
                };

                int i = 1;
                foreach (vwCfdiGeneraResumenDiario re in docGP.LDocResumenLineas)
                {
                    _resumenElectronico.Resumenes.Add(new GrupoResumenNuevo
                    {
                        Id = i,
                        TipoDocumento=re.tipoDocumento,
                        IdDocumento= re.numResumenDiario,
                        Serie=re.serie,
                        NroDocumentoReceptor=re.receptorNroDoc,
                        TipoDocumentoReceptor=re.receptorTipoDoc,
                        Moneda=re.moneda,
                        Gravadas = Convert.ToDecimal(re.totalIvaImponible),
                        Exoneradas = Convert.ToDecimal(re.totalExonerado),
                        //Gratuitas=re.totalGratuito,
                        Inafectas= Convert.ToDecimal(re.totalInafecta),
                        TotalIgv= Convert.ToDecimal(re.totalIva),
                        TotalVenta = Convert.ToDecimal(re.total),
                        CodigoEstadoItem=1,
                        CorrelativoInicio=Convert.ToInt32(re.iniRango),
                        CorrelativoFin=Convert.ToInt32(re.finRango)
                    });
                    i++;
                }
            }
            catch (Exception)
            { throw;
            }
        }
    }
}
