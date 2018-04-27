IF OBJECT_ID ('dbo.fCfdiDatosXmlParaImpresion') IS NOT NULL
   drop function dbo.fCfdiDatosXmlParaImpresion
go

create function dbo.fCfdiDatosXmlParaImpresion(@archivoXml xml)
--Propósito. Obtiene los datos de la factura electrónica
--Usado por. vwCfdTransaccionesDeVenta
--Requisitos. CFDI
--06/11/17 jcf Creación cfdi Perú
--
returns table
return(
	WITH XMLNAMESPACES('http://www.sat.gob.mx/TimbreFiscalDigital' as "tfd")
	select 
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@Version)[1]', 'varchar(5)') [version],
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@UUID)[1]', 'varchar(50)') UUID,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@FechaTimbrado)[1]', 'varchar(20)') FechaTimbrado,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@RfcProvCertif)[1]', 'varchar(20)') RfcPAC,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@Leyenda)[1]', 'varchar(150)') Leyenda,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@SelloCFD)[1]', 'varchar(8000)') selloCFD,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@NoCertificadoSAT)[1]', 'varchar(20)') noCertificadoSAT,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@SelloSAT)[1]', 'varchar(8000)') selloSAT,
	@archivoXml.value('(//@Sello)[1]', 'varchar(8000)') sello,
	@archivoXml.value('(//@NoCertificado)[1]', 'varchar(20)') noCertificado,
	@archivoXml.value('(//@FormaPago)[1]', 'varchar(50)') FormaPago,
	@archivoXml.value('(//@MetodoPago)[1]', 'varchar(21)') MetodoPago
	)
	go
--------------------------------------------------------------------------------------
--PRUEBAS--

--select dx.*
--from vwSopTransaccionesVenta tv
--	cross join dbo.fCfdEmisor() emi
--	outer apply dbo.fCfdCertificadoVigente(tv.fechahora) fv
--	outer apply dbo.fCfdCertificadoPAC(tv.fechahora) pa
--	left join cfdlogfacturaxml lf
--		on lf.soptype = tv.SOPTYPE
--		and lf.sopnumbe = tv.sopnumbe
--		and lf.estado = 'emitido'
--	outer apply dbo.fCfdiDatosXmlParaImpresion(lf.archivoXML) dx
