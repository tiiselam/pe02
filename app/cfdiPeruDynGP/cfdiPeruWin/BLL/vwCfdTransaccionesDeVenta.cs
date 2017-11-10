using System;
using System.Collections.Generic;
using System.Text;
using OpenInvoicePeru.Comun.Dto.Modelos; 

namespace cfdiPeru
{
    class vwCfdTransaccionesDeVenta : vwCfdiTransaccionesDeVenta
    {
        DocumentoElectronico _docElectronico;

        public vwCfdTransaccionesDeVenta(string connstr, string nombreVista)
        {
            this.ConnectionString = connstr;
            this.QuerySource = nombreVista;
            this.MappingName = nombreVista;

            //this.QuerySource = "vwCfdiTransaccionesDeVenta";
            //this.MappingName = "vwCfdiTransaccionesDeVenta";
        }

        public void GenerarDocElectronico()
        {
            _docElectronico = new DocumentoElectronico();
            _docElectronico.TipoDocumento = this.tipoDocumento;
            _docElectronico.IdDocumento = this.Sopnumbe;
            _docElectronico.FechaEmision = this.Fechahora.ToString("dd/MM/yyyy");
            _docElectronico.Moneda = this.Isocurrc;

        }

    }
}
