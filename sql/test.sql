select * 
from SY04200

insert into SY04200(cmtsries, commntid, CMMTTEXT) 
values (3, '03-ERR DESCRIPC', '')

SELECT TOP 100 *
FROM dbo.vwCfdiGeneraDocumentoDeVenta tv
where sopnumbe = 'BNC1-00000009'

select *
from vwCfdiTransaccionesDeVenta
where sopnumbe = 'BNC1-00000009'

select *
from vwCfdiRelacionados
where sopnumbeFrom = 'BNC1-00000009'

SELECT *
from dbo.fCfdiCertificadoVigente('7/30/18') fv

e[] ContenidoArchivoTexto)     at cfdiPeruOperadorServiciosElectronicos.WebServicesOSE.TimbraYEnviaASunat(String ruc, String usuario, String usuarioPassword, String texto)     at cfd.FacturaElectronica.ProcesaCfdi.<GeneraDocumentoXmlAsync>d__21.MoveNext()

select *
--update c set estado='impreso'	-- 	estadoActual='000101'	-- noAprobacion = '1513019407979'
--delete c
from cfdlogfacturaxml c
where c.sopnumbe like 'BNC1-00000009%'
and secuencia = 1187
--and c.soptype = 3
--and estado = 'emitido'

select *
from dbo.fLcLvParametros('V_PREFEXONERADO', 'V_PREFEXENTO', 'V_PREFIVA', 'V_GRATIS', 'na', 'na') pr	--Parámetros. prefijo inafectos, prefijo exento, prefijo iva

select *
from dbo.fCfdiImpuestosSop( 'BNC1-00000009        ', 3, 0, 'V-GRATIS', '02') gra	--gratuito

select *
from vwCfdiConceptos
where sopnumbe = 'BNC1-00000009        '


select *
from vwCfdiSopTransaccionesVenta
where sopnumbe like 'BNC1-00000009'


select *
from vwCfdiGeneraResumenDiario


select *
from dbo.fnCfdGetDireccionesCorreo('HL901436')

	select *
	from rm00106	--rmStmtEmailAddrs 1:To, 2:CC, 3:CCO
	where custnmbr = ''	--'003098841'



select *
from dbo.fCfdiPagoSimultaneoMayor(3, 'FV 00000247', 1) pg


select *
from dbo.sop10106
where sopnumbe LIKE 'B%0000001'

tx00201

sp_columns tx00201

select docncorr, *
--update s set docncorr = '10:23:10:060'
from sop10100 s
where s.sopnumbe like 'B%'

--ingresar la causa de la nc
select docncorr, commntid,  *
--update s set commntid = '01ANULA OPER', refrence = 'x'	-- docncorr = '10:23:10:060'
from sop30200 s
where s.soptype = 4
and s.sopnumbe like 'BNC1-000002'

--ingresar la causa de la nc
insert into sop10106 (SOPTYPE,SOPNUMBE,USRDAT01,USRDAT02,USRTAB01,USRTAB09,USRTAB03,USERDEF1,USERDEF2,USRDEF03,USRDEF04,USRDEF05,COMMENT_1,COMMENT_2,COMMENT_3,COMMENT_4,CMMTTEXT)
values (4, 'BNC1-000002', 0, 0, '', '', '', '', '', '', '', '', 'Anulación de la operación', '', '', '', 'Anulación de la operación')

--------------------------------------------------------------------------------
--Para eliminar un número que se pueda reusar seguir el procedimiento: C:\jcTii\SW\SWDynamicsGP\KnowledgeBase\Completely Removing a Posted SOP Invoice From Dynamics GP.html
SELECT * --into _181026_tx30000
--DELETE TX
FROM TX30000 TX
WHERE 
DOCTYPE = 4 AND SERIES = 1 
AND DOCNUMBR in --= 'BNC1-0000005'
(
'BNC1-00000009',
'BNC1-00000007',
'BNC1-00000008',
'BNC1-00000009'
)

select *
from sop30200
where sopnumbe in
(
'BNC1-00000009',
'BNC1-00000007',
'BNC1-00000008',
'BNC1-00000009'
)

select *
from rm20101
where docnumbr in
(
'BNC1-00000009',
'BNC1-00000007',
'BNC1-00000008',
'BNC1-00000009'
)

