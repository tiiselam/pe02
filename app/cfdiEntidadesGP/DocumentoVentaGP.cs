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

        public DocumentoVentaGP()
        {
            LDocVentaConceptos = new List<vwCfdiConceptos>();
            DocVenta = new vwCfdiGeneraDocumentoDeVenta();
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
                    DocVenta = doc;
                    break;
                }
                var resCon = dv.vwCfdiConceptos.Where(v => v.sopnumbe == Sopnumbe && v.soptype == Soptype);
                foreach (vwCfdiConceptos c in resCon)
                {
                    LDocVentaConceptos.Add(c);
                }
            }

        }
    }
}
