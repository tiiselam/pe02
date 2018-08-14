select * 
from SY04200

insert into SY04200(cmtsries, commntid, CMMTTEXT) 
values (3, '03-ERR DESCRIPC', '')

SELECT TOP 100 *
FROM vwCfdiRelacionados

select *
from vwCfdiSopTransaccionesVenta
where sopnumbe = 'F001-00000065'


select *
--update c set estadoActual='000101'	-- noAprobacion = '1513019407979'
--delete c
from cfdlogfacturaxml c
where c.sopnumbe = 'FF50-00000001'
and c.soptype = 3
and estado = 'publicado'

select *
from dbo.fLcLvParametros('V_PREFEXONERADO', 'V_PREFEXENTO', 'V_PREFIVA', 'V_GRATIS', 'na', 'na') pr	--Parámetros. prefijo inafectos, prefijo exento, prefijo iva

select *
from dbo.fCfdiImpuestosSop( 'F001-00000065', 3, 0, 'V-GRATIS', '02') gra	--gratuito

select *
from vwCfdiConceptos
where sopnumbe = 'F001-00000065'


select *
from vwCfdiGeneraDocumentoDeVenta
where sopnumbe like 'F001-00000065'


select *
from vwCfdiGeneraResumenDiario

SP_COLUMNS cfdlogfacturaxml

select *
from DYNAMICS..SY01500



select *
from dbo.fCfdiPagoSimultaneoMayor(3, 'FV 00000247', 1) pg


select *
from dbo.sop10103
where sopnumbe = 'FV 00000247'

tx00201

sp_columns tx00201

