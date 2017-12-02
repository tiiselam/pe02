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
        List<DetalleDocumento> lDetalleDocumento;

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
                _docElectronico.TotalVenta = docGP.DocVenta.total;
                _docElectronico.MontoEnLetras = "mil";

                lDetalleDocumento = new List<DetalleDocumento>();
                foreach (vwCfdiConceptos d in docGP.LDocVentaConceptos)
                {
                    lDetalleDocumento.Add(new DetalleDocumento()
                    {
                        CodigoItem = d.ITEMNMBR
                        , Id = Convert.ToInt16(d.id)
                        , Descripcion = d.Descripcion
                        , Cantidad = d.cantidad
                        , UnidadMedida = d.udemSunat
                        , PrecioUnitario = d.valorUni
                        , PrecioReferencial = Convert.ToDecimal(d.precioUniConIva)
                        , TipoPrecio = d.tipoPrecio
                        , Impuesto = d.orslstax
                    });
                }
                _docElectronico.Items = new List<DetalleDocumento>();
                _docElectronico.Items = lDetalleDocumento;

            }
            catch (Exception)
            {

                throw;
            }
        }

    }
}
