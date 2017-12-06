using System;
using System.Collections.Generic;
using System.Data.Linq;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace cfdiEntidadesGP
{
    public class DocumentoVentaGP
    {
        vwCfdiGeneraDocumentoDeVenta _DocVenta;
        List <vwCfdiConceptos> _LDocVentaConceptos;
        List<vwCfdiRelacionados> _LDocVentaRelacionados;

        public DocumentoVentaGP()
        {
            _LDocVentaConceptos = new List<vwCfdiConceptos>();
            _DocVenta = new vwCfdiGeneraDocumentoDeVenta();
            _LDocVentaRelacionados = new List<vwCfdiRelacionados>();
        }

        public vwCfdiGeneraDocumentoDeVenta DocVenta
        {
            get
            {
                return _DocVenta;
            }

            set
            {
                _DocVenta = value;
            }
        }

        public List<vwCfdiConceptos> LDocVentaConceptos
        {
            get
            {
                return _LDocVentaConceptos;
            }

            set
            {
                _LDocVentaConceptos = value;
            }
        }

        public List<vwCfdiRelacionados> LDocVentaRelacionados
        {
            get
            {
                return _LDocVentaRelacionados;
            }

            set
            {
                _LDocVentaRelacionados = value;
            }
        }

        public void GetDatosDocumentoVenta(String Sopnumbe, short Soptype)
        {
            using (PERUEntities dv = new PERUEntities())
            {
                //var options = new DataLoadOptions();
                //options.LoadWith<PERUEntities>(v => v.vwCfdiConceptos);
                //options.AssociateWith<PERUEntities>(v => v.vwCfdiConceptos.Where(n => n.sopnumbe == Sopnumbe && n.soptype == Soptype));
                
                var resDoc = dv.vwCfdiGeneraDocumentoDeVenta.Where(v => v.sopnumbe == Sopnumbe && v.soptype == Soptype);
                foreach (vwCfdiGeneraDocumentoDeVenta doc in resDoc)
                {
                    _DocVenta = doc;
                    break;
                }
                var resCon = dv.vwCfdiConceptos.Where(v => v.sopnumbe == Sopnumbe && v.soptype == Soptype);
                foreach (vwCfdiConceptos c in resCon)
                {
                    _LDocVentaConceptos.Add(c);
                }

                var resRelacionados = dv.vwCfdiRelacionados.Where(v => v.sopnumbeFrom == Sopnumbe && v.soptypeFrom == Soptype);
                foreach (vwCfdiRelacionados c in resRelacionados)
                {
                    _LDocVentaRelacionados.Add(c);
                }

            }

        }
    }
}
