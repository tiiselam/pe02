--use mtp1

IF OBJECT_ID ('dbo.fCfdEmisor') IS NOT NULL
   DROP FUNCTION dbo.fCfdEmisor
GO

create function dbo.fCfdEmisor()
returns table
as
--Propósito. Devuelve datos del emisor
--Requisitos. Los impuestos están configurados en el campo texto de la compañía. 
--			Debe indicar el parámetros IMPUESTOS=[idImpuesto1],[idImpuesto2],etc.
--			Debe indicar el parámetros OTROS=[01] ó [02]
--			[01] El método de pago es fijo. Si la factura viene de la interface pagada indica tarjeta de crédito, sino depósito
--				El número de cuenta bancaria viene del campo 1 def por el usuario de la dirección de facturación del cliente
--			[02] El método de pago viene del campo 1 tipo lista def por el usuario de la factura
--				El número de cuenta bancaria viene del campo 2 tipo texto def por el usuario de la factura
--Utilizado por. fCfdDatosAdicionales()
--24/04/12 jcf Creación cfdi
--02/07/12 jcf Agrega parámetro OTROS. 
--08/02/17 jcf Elimina estado de lugarExpedicion
--14/09/17 jcf Usa fCfdiParametros y agrega estado a lugarExpedicion
--
return
( 
select rtrim(replace(ci.TAXREGTN, 'RFC ', '')) rfc, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.ADRCNTCT)), 10) nombre, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(rtrim(ci.ADDRESS1)), 10) calle, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(rtrim(ci.ADDRESS2)), 10) colonia, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.CITY)), 10) ciudad, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.COUNTY)), 10) municipio, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.[STATE])), 10) estado,  
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.CMPCNTRY)), 10) pais, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.ZIPCODE)), 10) codigoPostal, 
	left(dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(
			rtrim(ci.ADDRESS1)+' '+rtrim(ci.ADDRESS2)+' '+RTRIM(ci.ZIPCODE)+' '+RTRIM(ci.COUNTY)+' '+RTRIM(ci.CITY)+' '+RTRIM(ci.[STATE])+' '+RTRIM(ci.CMPCNTRY)), 10), 250) LugarExpedicion,
	nt.param1 [version], 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(ISNULL(nt.INET7, '')), 10) rutaXml,
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(ISNULL(nt.INET8, '')), 10) regimen,
	nt.param2 impuestos,
	nt.param3 otrosDatos,
	nt.param4 incluyeAddendaDflt
from DYNAMICS..SY01500 ci			--sy_company_mstr
cross apply dbo.fCfdiParametros('VERSION', 'IMPUESTOS', 'OTROS', 'ADDENDADFLT', 'NA', 'NA', ci.LOCATNID) nt
where ci.INTERID = DB_NAME()
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdEmisor()'
ELSE PRINT 'Error en la creación de la función: fCfdEmisor()'
GO

------------------------------------------------------------------------------------
--select *
--from dbo.fCfdEmisor()

