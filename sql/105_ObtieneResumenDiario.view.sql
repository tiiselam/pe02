--FACTURA ELECTRONICA GP - PERU
--Proyectos:		GETTY
--Propósito:		Genera funciones y vistas de FACTURAS para la facturación electrónica en GP - PERU
--Referencia:		
--05/12/17 Versión CFDI UBL 2.0
--03/01/19 v ubl 2.1. Los resúmenes no son necesarios. Sólo están para compatilidad de la app.
--Utilizado por:	Aplicación C# de generación de factura electrónica PERU
-------------------------------------------------------------------------------------------------------

IF (OBJECT_ID ('dbo.vwCfdiGeneraDocumentoDeVentaAgrupado', 'V') IS NULL)
   exec('create view dbo.vwCfdiGeneraDocumentoDeVentaAgrupado as SELECT 1 as t');
go

alter view dbo.vwCfdiGeneraDocumentoDeVentaAgrupado
as
--Propósito. Agrupa los documentos de venta
--Requisitos.  
--07/12/17 jcf Creación cfdi Perú
--28/05/18 jcf Agrega consecutivo correcto para resumen en caso de rechazo
--04/06/18 jcf Cambios para versión 2 de resumen. Los docs ya no se agrupan y deben ser en moneda PEN
--13/08/18 jcf Cambio montos en moneda original, formapago, xchgrate, ORTDISAM
--03/01/19 jcf Ajusta nuevos campos de ubl 21. Actualmente no es necesario para Sunat.
--
		select tx.serie, tx.docdate, tx.estadoContabilizado, 55 tipoResumenDiario, 
			'RESUMEN' idResumenDiario, isnull(onr.numResumen, 'RC-'+convert(varchar(10), tx.docdate, 112)+'-001') numResumenDiario, 
			tx.tipoDocumento, tx.moneda, tx.xchgrate,
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
			tx.sopnumbe iniRango, 
			tx.sopnumbe finRango, 
			tx.sopnumbe,
			tx.soptype,

			tx.montoSubtotalGratuito totalGratuito,
			tx.montoTotalDescuentosPorItem totalDescuento,
			tx.descuentoGlobalMonto ORTDISAM,
			tx.montoSubtotalIvaImponible totalIvaImponible,
			tx.montoSubtotalExonerado totalExonerado,
			tx.montoSubtotalInafecto totalInafecta,
			tx.montoTotalIgv totalIva,
			tx.montoTotalVenta total,
			1	cantidad,
			'' formaPago
		from dbo.vwCfdiGeneraDocumentoDeVenta tx
			outer apply dbo.fCfdiObtieneNumResumenDiario(55, 'RC-'+convert(varchar(10), tx.docdate, 112)+'-001') onr

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
--04/06/18 jcf Cambios para versión 2 de resumen
--13/08/18 jcf Agrega xchgrate, ORTDISAM
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
		tv.serie,
		tv.sopnumbe,
		0 iniRango,
		0 finRango,
		tv.moneda,
		tv.xchgrate,
		tv.totalIvaImponible,
		tv.totalIva,
		tv.totalInafecta,
		tv.totalExonerado,
		tv.totalGratuito,
		tv.totalDescuento,
		tv.ORTDISAM,
		tv.total,
		tv.cantidad,
		tv.formaPago,
		rel.tipoDocumento tipoDocumentoTo, rel.sopnumbeTo
	from dbo.vwCfdiGeneraDocumentoDeVentaAgrupado tv
		outer apply dbo.fCfdiRelacionados(tv.soptype, tv.sopnumbe) rel
		--outer apply dbo.fCfdiObtieneSegmento2(tv.iniRango, '-') ir
		--outer apply dbo.fCfdiObtieneSegmento2(tv.finRango, '-') fr
	where tv.serie like 'B%'	--BOLETAS, NC Y ND APLICADAS A BOLETAS
	and tv.estadoContabilizado = 'contabilizado' 

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

