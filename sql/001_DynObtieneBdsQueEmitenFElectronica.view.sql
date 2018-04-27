
-----------------------------------------------------------------------------------------
use dynamics
go

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwCfdCompannias]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.vwCfdCompannias;
GO
create view dbo.vwCfdCompannias as
--Propósito. Obtiene la lista de compañías que emiten Factura electrónica
--Utilizado por. Factura electrónica
--14/12/10 jcf Creación
--
select CMPANYID, INTERID, CMPNYNAM, CCode
from DYNAMICS..SY01500 ci			--sy_company_mstr
WHERE upper(UDCOSTR2) = 'EMITE FACTURA ELECTRONICA'

go
IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdCompannias'
ELSE PRINT 'Error en la creación de la vista: vwCfdCompannias'
GO
-----------------------------------------------------------------------------------------

--update DYNAMICS..SY01500 set UDCOSTR2 = 'EMITE FACTURA ELECTRONICA'
--where INTERID in ( 'GPERU')

--SELECT * FROM dynamics..vwCfdCompannias
--select *
--from sop10100
--order by sopnumbe
