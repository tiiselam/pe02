IF OBJECT_ID ('dbo.vwRmCfdFacturasConFolioFiscal') IS NOT NULL
     DROP view dbo.vwRmCfdFacturasConFolioFiscal
GO

create view dbo.vwRmCfdFacturasConFolioFiscal as
--Propósito. Facturas con folio fiscal
--14/10/15 jcf Creación
--
select 
	rm.rmdtypal, rm.tipoDoc, rm.soptype, rm.docdate, rm.docnumbr, rm.voidstts, case when rm.voidstts = 1 then 'sí' else 'no' end anulado, 
	rm.custnmbr, rm.custname, rm.txrgnnum, rm.totalImpuesto, rm.totalDoc, rm.duedate, 
	rm.curncyid, rm.curtrxam, rm.ortrxamt, rm.slsamnt, rm.cashamnt, rm.orctrxam, rm.ororgtrx, rm.xchgrate,
	cfdi.uuid, cfdi.docid, cfdi.mensajeEA
from vwRmTransaccionesTodas rm
left join vwCfdTransaccionesDeVenta cfdi
	on cfdi.soptype = rm.soptype
	and cfdi.sopnumbe = rm.docnumbr
where rmdtypal in (1, 8)	--facturas, devoluciones
--and year(docdate) = 2015
--and rm.custnmbr = '000000206'

go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwRmCfdFacturasConFolioFiscal'
ELSE PRINT 'Error en la creación de la vista: vwRmCfdFacturasConFolioFiscal'
GO

--grant select on vwRmCfdFacturasConFolioFiscal to dyngrp;

--select * from vwRmCfdFacturasConFolioFiscal


