﻿using System;
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
        vwCfdiGeneraResumenDiario _resumenCab;
        List<vwCfdiGeneraResumenDiario> _lDocResumenLineas;
        List <vwCfdiConceptos> _LDocVentaConceptos;
        List<vwCfdiRelacionados> _LDocVentaRelacionados;

        public DocumentoVentaGP()
        {
            _LDocVentaConceptos = new List<vwCfdiConceptos>();
            _DocVenta = new vwCfdiGeneraDocumentoDeVenta();
            _LDocVentaRelacionados = new List<vwCfdiRelacionados>();
            _resumenCab = new vwCfdiGeneraResumenDiario();
            _lDocResumenLineas = new List<vwCfdiGeneraResumenDiario>();
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

        public vwCfdiGeneraResumenDiario ResumenCab
        {
            get
            {
                return _resumenCab;
            }

            set
            {
                _resumenCab = value;
            }
        }

        public List<vwCfdiGeneraResumenDiario> LDocResumenLineas
        {
            get
            {
                return _lDocResumenLineas;
            }

            set
            {
                _lDocResumenLineas = value;
            }
        }

        public void GetDatosDocumentoVenta(String Sopnumbe, short Soptype)
        {
            using (PERUEntities dv = new PERUEntities())
            {
                _DocVenta = dv.vwCfdiGeneraDocumentoDeVenta
                                    .Where(v => v.sopnumbe == Sopnumbe && v.soptype == Soptype)
                                    .First();
                _LDocVentaConceptos = dv.vwCfdiConceptos
                                    .Where(v => v.sopnumbe == Sopnumbe && v.soptype == Soptype)
                                    .ToList();
                _LDocVentaRelacionados = dv.vwCfdiRelacionados
                                    .Where(v => v.sopnumbeFrom == Sopnumbe && v.soptypeFrom == Soptype)
                                    .ToList();

                //var resDoc = dv.vwCfdiGeneraDocumentoDeVenta.Where(v => v.sopnumbe == Sopnumbe && v.soptype == Soptype);
                //foreach (vwCfdiGeneraDocumentoDeVenta doc in resDoc)
                //{
                //    _DocVenta = doc;
                //    break;
                //}
                //var resCon = dv.vwCfdiConceptos.Where(v => v.sopnumbe == Sopnumbe && v.soptype == Soptype);
                //foreach (vwCfdiConceptos c in resCon)
                //{
                //    _LDocVentaConceptos.Add(c);
                //}

                //var resRelacionados = dv.vwCfdiRelacionados.Where(v => v.sopnumbeFrom == Sopnumbe && v.soptypeFrom == Soptype);
                //foreach (vwCfdiRelacionados c in resRelacionados)
                //{
                //    _LDocVentaRelacionados.Add(c);
                //}

            }

        }
        public void GetDatosResumenBoletas(String Sopnumbe, short Soptype)
        {
            using (PERUEntities dv = new PERUEntities())
            {
                _lDocResumenLineas = dv.vwCfdiGeneraResumenDiario
                                                        .Where(v => v.numResumenDiario == Sopnumbe && v.tipoResumenDiario == Soptype)
                                                        .ToList();

                _resumenCab = _lDocResumenLineas.First();

                //var resDoc = dv.vwCfdiGeneraResumenDiario.Where(v => v.numResumenDiario == Sopnumbe && v.tipoResumenDiario == Soptype);
                //foreach (vwCfdiGeneraResumenDiario re in resDoc)
                //{
                //    _resumenCab = re;
                //    break;
                //}

            }

        }
    }
}
