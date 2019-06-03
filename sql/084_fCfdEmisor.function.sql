
IF OBJECT_ID ('dbo.fCfdiEmisor') IS NOT NULL
   DROP FUNCTION dbo.fCfdiEmisor
GO

create function dbo.fCfdiEmisor()
returns table
as
--Propósito. Devuelve datos del emisor
--Requisitos. 
--Utilizado por. fCfdDatosAdicionales()
--04/12/17 jcf Creación cfdi
--22/11/18 jcf Agrega CTABNACION
--23/05/19 jcf Agrega param5
--
return
( 
select rtrim(replace(ci.TAXREGTN, 'RFC ', '')) TAXREGTN, '6' emisorTipoDoc,
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.LOCATNNM)), 10) LOCATNNM, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.ADRCNTCT)), 10) ADRCNTCT, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(rtrim(ci.ADDRESS1)), 10) ADDRESS1, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(rtrim(ci.ADDRESS2)), 10) ADDRESS2, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.CITY)), 10) CITY, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.COUNTY)), 10) COUNTY, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.[STATE])), 10) [STATE],  
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.CMPCNTRY)), 10) CMPCNTRY, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.ZIPCODE)), 10) ZIPCODE, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.CCODE)), 10) CCODE, 
	left(dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(
			rtrim(ci.ADDRESS1)+' '+rtrim(ci.ADDRESS2)+' '+RTRIM(ci.ZIPCODE)+' '+RTRIM(ci.COUNTY)+' '+RTRIM(ci.CITY)+' '+RTRIM(ci.[STATE])+' '+RTRIM(ci.CMPCNTRY)), 10), 250) LugarExpedicion,
	nt.param1 [version], 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(ISNULL(nt.INET7, '')), 10) INET7,
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(ISNULL(nt.INET8, '')), 10) INET8,
	nt.param2 timeZone,
	nt.param3 ctaBancoNacion,
	nt.param4 incluyeAddendaDflt,	--probablemente no se usa!?
	nt.param5
from DYNAMICS..SY01500 ci			--sy_company_mstr
cross apply dbo.fCfdiParametros('VERSION', 'UTC', 'CTABNACION', 'NA', 'SUCURSAL', 'NA', ci.LOCATNID) nt
where ci.INTERID = DB_NAME()
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiEmisor()'
ELSE PRINT 'Error en la creación de la función: fCfdiEmisor()'
GO

------------------------------------------------------------------------------------
--select *
--from dbo.fCfdiEmisor()


