--FACTURA ELECTRONICA GP - PERU
--Proyectos:		GETTY
--Propósito:		Genera funciones y vistas de FACTURAS para la facturación electrónica en GP - PERU
--Referencia:		
--		05/12/17 Versión CFDI UBL 2.0
--Utilizado por:	Aplicación C# de generación de factura electrónica PERU
-------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiGeneraDocumentoDeVentaAgrupado', 'V') IS NULL)
   exec('create view dbo.vwCfdiGeneraDocumentoDeVentaAgrupado as SELECT 1 as t');
go

alter view dbo.vwCfdiGeneraDocumentoDeVentaAgrupado
as
--Propósito. Agrupa los documentos de venta
--Requisitos.  
--07/12/17 jcf Creación cfdi Perú
--
		select tx.serie, tx.docdate, tx.estadoContabilizado, 55 tipoResumenDiario, 
			'RESUMEN' idResumenDiario, 'RC-'+convert(varchar(10), tx.docdate, 112)+'-001' numResumenDiario, tx.tipoDocumento, tx.moneda,
			tx.emisorTipoDoc,
			tx.emisorNroDoc,
			tx.emisorNombre,
			tx.emisorUbigeo,
			tx.emisorDireccion,
			tx.emisorUrbanizacion,
			tx.emisorDepartamento,
			tx.emisorProvincia,
			tx.emisorDistrito,
			tx.receptorTipoDoc,
			tx.receptorNroDoc, 
			tx.receptorNombre, 
			min(tx.sopnumbe) iniRango, 
			max(tx.sopnumbe) finRango, 
			sum(tx.gratuito) totalGratuito,
			sum(tx.ORTDISAM) totalDescuento,
			sum(tx.ivaImponible) totalIvaImponible,
			sum(tx.exonerado) totalExonerado,
			sum(tx.inafecta) totalInafecta,
			sum(tx.iva) totalIva,
			sum(tx.total)	total,

			COUNT(tx.sopnumbe)	cantidad
		from vwCfdiGeneraDocumentoDeVenta tx
		group by tx.serie, tx.docdate, tx.estadoContabilizado, tx.tipoDocumento, tx.moneda,
			tx.emisorTipoDoc,
			tx.emisorNroDoc,
			tx.emisorNombre,
			tx.emisorUbigeo,
			tx.emisorDireccion,
			tx.emisorUrbanizacion,
			tx.emisorDepartamento,
			tx.emisorProvincia,
			tx.emisorDistrito,
			tx.receptorTipoDoc,
			tx.receptorNroDoc, 
			tx.receptorNombre

go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: vwCfdiGeneraDocumentoDeVentaAgrupado ()'
ELSE PRINT 'Error en la creación de la función: vwCfdiGeneraDocumentoDeVentaAgrupado ()'
GO

-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiGeneraResumenDiario', 'V') IS NULL)
   exec('create view dbo.vwCfdiGeneraResumenDiario as SELECT 1 as t');
go

alter view dbo.vwCfdiGeneraResumenDiario
as
--Propósito. Datos del resumen diario de boletas
--Requisitos.  
--07/12/17 jcf Creación cfdi Perú
--
	select 
		tv.tipoResumenDiario,
		tv.numResumenDiario,
		tv.docdate,
		tv.tipoDocumento, 
		tv.emisorTipoDoc,
		tv.emisorNroDoc,
		tv.emisorNombre,
		tv.emisorUbigeo,
		tv.emisorDireccion,
		tv.emisorUrbanizacion,
		tv.emisorDepartamento,
		tv.emisorProvincia,
		tv.emisorDistrito,

		tv.receptorTipoDoc,
		tv.receptorNroDoc,
		--tv.nombreCliente							receptorNombre,
		tv.serie,
		ir.segmento2 iniRango,
		fr.segmento2 finRango,
		tv.moneda,
		tv.totalIvaImponible,
		tv.totalIva,
		tv.totalInafecta,
		tv.totalExonerado,
		tv.totalGratuito,
		tv.totalDescuento,
		tv.total,
		tv.cantidad
	from dbo.vwCfdiGeneraDocumentoDeVentaAgrupado tv
		outer apply dbo.fCfdiObtieneSegmento2(tv.iniRango, '-') ir
		outer apply dbo.fCfdiObtieneSegmento2(tv.finRango, '-') fr
	where tv.serie like 'B%'	--BOLETAS, NC Y ND APLICADAS A BOLETAS
	and tv.estadoContabilizado = 'contabilizado' 
	--and tv.serie = 'BB11'
	--and tv.tipoDocumento = '03'

go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: vwCfdiGeneraResumenDiario ()'
ELSE PRINT 'Error en la creación de la función: vwCfdiGeneraResumenDiario ()'
GO
-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiListaResumenDiario', 'V') IS NULL)
   exec('create view dbo.vwCfdiListaResumenDiario as SELECT 1 as t');
go

alter view dbo.vwCfdiListaResumenDiario as
--Propósito. Lista de Resumen de boletas y docs relacionados agrupados por día
--Usado por. App Factura digital (doodads)
--Requisitos. El estado "no emitido" indica que no se ha emitido el archivo xml pero que está listo para ser generado.
--			El estado "inconsistente" indica que existe un problema en el folio o certificado, por tanto no puede ser generado.
--			El estado "emitido" indica que el archivo xml ha sido generado y sellado por el PAC y está listo para ser impreso.
--06/11/17 jcf Creación cfdi Perú
--

select rd.estadoContabilizado, cast(rd.tipoResumenDiario as smallint) Soptype, rd.idResumenDiario docid, rd.numResumenDiario sopnumbe, rd.docdate fechahora,
	'' CUSTNMBR, '' nombreCliente, '' idImpuestoCliente, 0.00 total, 0.00 montoActualOriginal, cast(0 as smallint) Voidstts, 

	isnull(lf.estado, isnull(fv.estado, 'inconsistente')) estado,
	case when isnull(lf.estado, isnull(fv.estado, 'inconsistente')) = 'inconsistente' 
		then 'folio o certificado inconsistente'
		else ISNULL(lf.mensaje, rd.estadoContabilizado)
	end mensaje,
	cast('' as xml) comprobanteXml,

	fv.ID_Certificado, fv.ruta_certificado, fv.ruta_clave, fv.contrasenia_clave, 
	isnull(pa.ruta_certificado, '_noexiste') ruta_certificadoPac, isnull(pa.ruta_clave, '_noexiste') ruta_clavePac, isnull(pa.contrasenia_clave, '') contrasenia_clavePac, 
	emi.TAXREGTN rfc, 
	isnull(lf.noAprobacion, '') regimen, 
	emi.INET7 rutaXml, 
	emi.ZIPCODE codigoPostal,
	isnull(lf.estadoActual, '000000') estadoActual, 
	isnull(lf.mensajeEA, rd.estadoContabilizado) mensajeEA,
	'' isocurrc,
	cast('' as xml) addenda
from 
	(select docdate, estadoContabilizado, tipoResumenDiario, idResumenDiario, numResumenDiario
		from dbo.vwCfdiGeneraDocumentoDeVentaAgrupado 
		where serie like 'B%'	--BOLETAS, NC Y ND APLICADAS A BOLETAS
		and estadoContabilizado = 'contabilizado' 
		group by docdate, estadoContabilizado, tipoResumenDiario, idResumenDiario, numResumenDiario) rd
	cross join dbo.fCfdiEmisor() emi
	outer apply dbo.fCfdiCertificadoVigente(rd.docdate) fv
	outer apply dbo.fCfdiCertificadoPAC(rd.docdate) pa
	left join cfdlogfacturaxml lf
		on lf.soptype = rd.tipoResumenDiario
		and lf.sopnumbe = rd.numResumenDiario
		and lf.estado = 'emitido'

go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiListaResumenDiario'
ELSE PRINT 'Error en la creación de la vista: vwCfdiListaResumenDiario'
GO

-----------------------------------------------------------------------------------------

-- FIN DE SCRIPT ***********************************************

