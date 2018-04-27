
-----------------------------------------------------------------------------------------
use dynamics
go

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwCfdCompannias]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.vwCfdCompannias;
GO
create view dbo.vwCfdCompannias as
--Prop�sito. Obtiene la lista de compa��as que emiten Factura electr�nica
--Utilizado por. Factura electr�nica
--14/12/10 jcf Creaci�n
--
select CMPANYID, INTERID, CMPNYNAM, CCode
from DYNAMICS..SY01500 ci			--sy_company_mstr
WHERE upper(UDCOSTR2) = 'EMITE FACTURA ELECTRONICA'

go
IF (@@Error = 0) PRINT 'Creaci�n exitosa de la vista: vwCfdCompannias'
ELSE PRINT 'Error en la creaci�n de la vista: vwCfdCompannias'
GO
-----------------------------------------------------------------------------------------

--update DYNAMICS..SY01500 set UDCOSTR2 = 'EMITE FACTURA ELECTRONICA'
--where INTERID in ( 'GPERU')

--SELECT * FROM dynamics..vwCfdCompannias
--select *
--from sop10100
--order by sopnumbe
