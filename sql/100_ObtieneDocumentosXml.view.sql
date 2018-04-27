--FACTURA ELECTRONICA GP - PERU
--Proyectos:		GETTY
--Prop�sito:		Genera funciones y vistas de FACTURAS para la facturaci�n electr�nica en GP - PERU
--Referencia:		
--		05/12/17 Versi�n CFDI UBL 2.0
--Utilizado por:	Aplicaci�n C# de generaci�n de factura electr�nica PERU
-------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiCertificadoVigente') IS NOT NULL
   DROP FUNCTION dbo.fCfdiCertificadoVigente
GO

create function dbo.fCfdiCertificadoVigente(@fecha datetime)
returns table
as
--Prop�sito. Verifica que la fecha corresponde a un certificado vigente y activo
--			Si existe m�s de uno o ninguno, devuelve el estado: inconsistente
--			Tambi�n devuelve datos del folio y certificado asociado.
--Requisitos. Los estados posibles para generar o no archivos xml son: no emitido, inconsistente
--06/11/17 jcf Creaci�n cfdi Per�
--
return
(  
	--declare @fecha datetime
	--select @fecha = '1/4/12'
	select top 1 --fyc.noAprobacion, fyc.anoAprobacion, 
			fyc.ID_Certificado, fyc.ruta_certificado, fyc.ruta_clave, fyc.contrasenia_clave, fyc.fila, 
			case when fyc.fila > 1 then 'inconsistente' else 'no emitido' end estado
	from (
		SELECT top 2 rtrim(B.ID_Certificado) ID_Certificado, rtrim(B.ruta_certificado) ruta_certificado, rtrim(B.ruta_clave) ruta_clave, 
				rtrim(B.contrasenia_clave) contrasenia_clave, row_number() over (order by B.ID_Certificado) fila
		FROM cfd_CER00100 B
		WHERE B.estado = '1'
			and B.id_certificado <> 'PAC'	--El id PAC est� reservado para el PAC
			and datediff(day, B.fecha_vig_desde, @fecha) >= 0
			and datediff(day, B.fecha_vig_hasta, @fecha) <= 0
		) fyc
	order by fyc.fila desc
)
go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: fCfdiCertificadoVigente()'
ELSE PRINT 'Error en la creaci�n de la funci�n: fCfdiCertificadoVigente()'
GO

--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiCertificadoPAC') IS NOT NULL
   DROP FUNCTION dbo.fCfdiCertificadoPAC
GO

create function dbo.fCfdiCertificadoPAC(@fecha datetime)
returns table
as
--Prop�sito. Obtiene el certificado del PAC. 
--			Verifica que la fecha corresponde a un certificado vigente y activo
--Requisitos. El id PAC est� reservado para registrar el certificado del PAC. 
--06/11/17 jcf Creaci�n 
--
return
(  
	--declare @fecha datetime
	--select @fecha = '5/4/12'
	SELECT rtrim(B.ID_Certificado) ID_Certificado, rtrim(B.ruta_certificado) ruta_certificado, rtrim(B.ruta_clave) ruta_clave, 
			rtrim(B.contrasenia_clave) contrasenia_clave
	FROM cfd_CER00100 B
	WHERE B.estado = '1'
		and B.id_certificado = 'PAC'	--El id PAC est� reservado para el PAC
		and datediff(day, B.fecha_vig_desde, @fecha) >= 0
		and datediff(day, B.fecha_vig_hasta, @fecha) <= 0
)
go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: fCfdiCertificadoPAC()'
ELSE PRINT 'Error en la creaci�n de la funci�n: fCfdiCertificadoPAC()'
GO

--------------------------------------------------------------------------------------------------------

IF (OBJECT_ID ('dbo.vwCfdiSopLineasTrxVentas', 'V') IS NULL)
   exec('create view dbo.vwCfdiSopLineasTrxVentas as SELECT 1 as t');
go

alter view dbo.vwCfdiSopLineasTrxVentas as
--Prop�sito. Obtiene todas las l�neas de facturas de venta SOP
--			Incluye descuentos
--Requisito. Atenci�n ! DEBE usar unidades de medida listadas en el SERVICIO DE IMPUESTOS. 
--30/11/17 JCF Creaci�n cfdi 3.3
--
select dt.soptype, dt.sopnumbe, dt.LNITMSEQ, dt.ITEMNMBR, dt.ShipToName,
	dt.QUANTITY, dt.UOFM,
	um.UOFMLONGDESC UOFMsat,
	udmfa.descripcion UOFMsat_descripcion,
	um.UOFMLONGDESC, 
	dt.ITEMDESC,
	dt.ORUNTPRC, dt.OXTNDPRC, dt.CMPNTSEQ, 
	dt.QUANTITY * dt.ORUNTPRC cantidadPorPrecioOri, 
	isnull(ma.ITMTRKOP, 1) ITMTRKOP,		--3 lote, 2 serie, 1 nada
	ma.uscatvls_6, 
	dt.ormrkdam,
	dt.QUANTITY * dt.ormrkdam descuento
from SOP30300 dt
left join iv00101 ma				--iv_itm_mstr
	on ma.ITEMNMBR = dt.ITEMNMBR
outer apply dbo.fCfdiUofM(ma.UOMSCHDL, dt.UOFM ) um
outer apply dbo.fCfdiCatalogoGetDescripcion('UDM', um.UOFMLONGDESC) udmfa

go	

IF (@@Error = 0) PRINT 'Creaci�n exitosa de: vwCfdiSopLineasTrxVentas'
ELSE PRINT 'Error en la creaci�n de: vwCfdiSopLineasTrxVentas'
GO
----------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiImpuestosSop') IS NOT NULL
   DROP FUNCTION dbo.fCfdiImpuestosSop
GO

create function dbo.fCfdiImpuestosSop(@SOPNUMBE char(21), @DOCTYPE smallint, @LNITMSEQ int, @prefijo varchar(15), @tipoPrecio varchar(10))
returns table
as
--Prop�sito. Detalle de impuestos en trabajo e hist�ricos de SOP. Filtra los impuestos requeridos por @prefijo
--Requisitos. Los impuestos iva deben ser configurados con un prefijo constante
--27/11/17 jcf Creaci�n 
--
return
(
	select imp.soptype, imp.sopnumbe, imp.taxdtlid, imp.staxamnt, imp.orslstax, imp.tdttxsls, imp.ortxsls,
			tx.NAME, tx.cntcprsn, tx.TXDTLPCT
	from sop10105 imp
		inner join tx00201 tx
		on tx.taxdtlid = imp.taxdtlid
		and tx.cntcprsn like @tipoPrecio
	where imp.sopnumbe = @SOPNUMBE
	and imp.soptype = @DOCTYPE
	and imp.LNITMSEQ = @LNITMSEQ
	and imp.taxdtlid like @prefijo + '%'
)

go


IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: fCfdiImpuestosSop()'
ELSE PRINT 'Error en la creaci�n de la funci�n: fCfdiImpuestosSop()'
GO

----------------------------------------------------------------------------------------------------------
--IF (OBJECT_ID ('dbo.vwCfdiImpuestos', 'V') IS NULL)
--   exec('create view dbo.vwCfdiImpuestos as SELECT 1 as t');
--go

--alter view dbo.vwCfdiImpuestos	--(@p_soptype smallint, @p_sopnumbe varchar(21), @p_LNITMSEQ int)
--as
--		select 	
--			imp.ortxsls,
--			tx.NAME,
--			case when tx.TXDTLPCT=0 then 'Exento' else 'Tasa' end TipoFactor, 
--			tx.TXDTLPCT,
--			imp.orslstax
--		from sop10105 imp	--sop_tax_work_hist
--		inner join tx00201 tx
--			on tx.taxdtlid = imp.taxdtlid

--go

--IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: vwCfdiImpuestos()'
--ELSE PRINT 'Error en la creaci�n de la funci�n: vwCfdiImpuestos()'
--GO

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiConceptos', 'V') IS NULL)
   exec('create view dbo.vwCfdiConceptos as SELECT 1 as t');
go

alter view dbo.vwCfdiConceptos --(@p_soptype smallint, @p_sopnumbe varchar(21), @p_subtotal numeric(19,6))
as
--Prop�sito. Obtiene las l�neas de una factura 
--			Elimina carriage returns, line feeds, tabs, secuencias de espacios y caracteres especiales.
--Requisito. Se asume que una l�nea de factura tiene una l�nea de impuesto
--27/11/17 jcf Creaci�n cfdi 3.3
--03/04/18 jcf Filtra cantidad!=0
--
		select ROW_NUMBER() OVER(ORDER BY Concepto.LNITMSEQ asc) id, 
			Concepto.soptype, Concepto.sopnumbe, Concepto.LNITMSEQ, rtrim(Concepto.ITEMNMBR) ITEMNMBR, '' SERLTNUM, 
			Concepto.ITEMDESC, Concepto.CMPNTSEQ, 
			rtrim(Concepto.UOFMsat) udemSunat,
			'' NoIdentificacion,
			dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(Concepto.ITEMDESC))), 10) Descripcion, 
			(Concepto.OXTNDPRC + isnull(iva.orslstax, 0.00))/Concepto.QUANTITY precioUniConIva,	--precioReferencial
			case when isnull(gra.ortxsls, 0) != 0 then 0.00 else Concepto.ORUNTPRC end valorUni,--valor unitario (precioUnitario)
			Concepto.QUANTITY cantidad, 
			--Concepto.ORUNTPRC * Concepto.cantidad valorVenta,	--valor venta bruto
			Concepto.descuento,
			Concepto.OXTNDPRC importe,							--valor de venta (totalVenta)
			isnull(iva.orslstax, 0.00) orslstax,				--igv

			case when isnull(iva.orslstax, 0) != 0 
				then rtrim(iva.cntcprsn)
				else case when isnull(exe.ortxsls, 0) != 0 
					then rtrim(exe.cntcprsn)
					else case when isnull(xnr.ortxsls, 0) != 0
						then rtrim(xnr.cntcprsn)
						else case when isnull(gra.ortxsls, 0) != 0
							then rtrim(gra.cntcprsn)
							else ''
							end
						end
					end
				end tipoPrecio,
			case when isnull(iva.orslstax, 0) != 0 
				then rtrim(iva.name)
				else case when isnull(exe.ortxsls, 0) != 0 
					then rtrim(exe.name)
					else case when isnull(xnr.ortxsls, 0) != 0
						then rtrim(xnr.name)
						else case when isnull(gra.ortxsls, 0) != 0
							then rtrim(gra.name)
							else ''
							end
						end
					end
				end tipoImpuesto
		from vwCfdiSopLineasTrxVentas Concepto
			outer apply dbo.fLcLvParametros('V_PREFEXONERADO', 'V_PREFEXENTO', 'V_PREFIVA', 'V_GRATIS', 'na', 'na') pr	--Par�metros. prefijo inafectos, prefijo exento, prefijo iva
			outer apply dbo.fCfdiImpuestosSop(Concepto.SOPNUMBE, Concepto.soptype, Concepto.LNITMSEQ, pr.param1, '%') xnr --exonerado
			outer apply dbo.fCfdiImpuestosSop(Concepto.SOPNUMBE, Concepto.soptype, Concepto.LNITMSEQ, pr.param2, '%') exe --inafecto
			outer apply dbo.fCfdiImpuestosSop(Concepto.SOPNUMBE, Concepto.soptype, Concepto.LNITMSEQ, pr.param3, '%') iva --iva
			outer apply dbo.fCfdiImpuestosSop(Concepto.SOPNUMBE, Concepto.soptype, Concepto.LNITMSEQ, pr.param4, '%') gra --gratuito
		where Concepto.CMPNTSEQ = 0					--a nivel kit
		and Concepto.QUANTITY != 0

go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de: vwCfdiConceptos()'
ELSE PRINT 'Error en la creaci�n de: vwCfdiConceptos()'
GO
-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiGeneraDocumentoDeVenta', 'V') IS NULL)
   exec('create view dbo.vwCfdiGeneraDocumentoDeVenta as SELECT 1 as t');
go

alter view dbo.vwCfdiGeneraDocumentoDeVenta
as
--Prop�sito. Elabora un comprobante xml para factura electr�nica cfdi Per�
--Requisitos.  
--27/11/17 jcf Creaci�n cfdi Per�
--27/04/18 jcf Ajusta montos exonerado, inafecto, gratuito
--
	select convert(varchar(20), tv.dex_row_id) correlativo, 
		tv.soptype,
		tv.sopnumbe,
		cmpr.serie,
		cmpr.numero,
		cmpr.tipo									tipoDocumento,
		emi.emisorTipoDoc, 
		emi.TAXREGTN								emisorNroDoc,
		emi.LOCATNNM								emisorNombre,
		emi.ZIPCODE									emisorUbigeo,
		emi.ADDRESS1								emisorDireccion,
		emi.ADDRESS2								emisorUrbanizacion,
		emi.[STATE]									emisorDepartamento,
		emi.COUNTY									emisorProvincia,
		emi.CITY									emisorDistrito,

		cmpr.nsaif_type_nit							receptorTipoDoc,
		tv.idImpuestoCliente						receptorNroDoc,
		tv.nombreCliente							receptorNombre,

		rtrim(tv.sopnumbe)							idDocumento,
		convert(datetime, tv.fechahora, 126)		fechaEmision,
		tv.curncyid									moneda,
		cmpr.tipoOperacion,
		tv.descuento,
		tv.ORTDISAM,
		isnull(iva.TXDTLPCT, 0.00)/100				ivaTasa,
		isnull(iva.ortxsls, 0.00)					ivaImponible,
		isnull(iva.orslstax, 0.00)					iva,

		isnull(exe.ortxsls, 0.00)					inafecta,
		isnull(xnr.ortxsls, 0.00)					exonerado,
		isnull(gra.ortxsls, 0.00)					gratuito,

		tv.xchgrate,
		tv.total,
		--Para NC:
		left(tv.commntid, 2)						discrepanciaTipo,
		dbo.fCfdReemplazaSecuenciaDeEspacios(rtrim(dbo.fCfdReemplazaCaracteresNI(tv.comment_1)), 10) discrepanciaDesc,
		UPPER(DBO.TII_INVOICE_AMOUNT_LETTERS(tv.total, default)) montoEnLetras,
		tv.estadoContabilizado, tv.docdate
	from dbo.vwCfdiSopTransaccionesVenta tv
		cross join dbo.fCfdiEmisor() emi
		outer apply dbo.fLcLvComprobanteSunat (tv.soptype, tv.sopnumbe)  cmpr
		outer apply dbo.fLcLvParametros('V_PREFEXONERADO', 'V_PREFEXENTO', 'V_PREFIVA', 'V_GRATIS', 'na', 'na') pr	--Par�metros. prefijo inafectos, prefijo exento, prefijo iva
		outer apply dbo.fCfdiImpuestosSop(tv.sopnumbe, tv.soptype, 0, pr.param1, '01') xnr  --exonerado
		outer apply dbo.fCfdiImpuestosSop(tv.sopnumbe, tv.soptype, 0, pr.param2, '01') exe	--exento/inafecto
		outer apply dbo.fCfdiImpuestosSop(tv.sopnumbe, tv.soptype, 0, pr.param3, '01') iva	--iva
		outer apply dbo.fCfdiImpuestosSop(tv.sopnumbe, tv.soptype, 0, pr.param4, '02') gra	--gratuito
go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: vwCfdiGeneraDocumentoDeVenta ()'
ELSE PRINT 'Error en la creaci�n de la funci�n: vwCfdiGeneraDocumentoDeVenta ()'
GO
-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiTransaccionesDeVenta', 'V') IS NULL)
   exec('create view dbo.vwCfdiTransaccionesDeVenta as SELECT 1 as t');
go

alter view dbo.vwCfdiTransaccionesDeVenta as
--Prop�sito. Todos los documentos de venta: facturas y notas de cr�dito. 
--Usado por. App Factura digital (doodads)
--Requisitos. El estado "no emitido" indica que no se ha emitido el archivo xml pero que est� listo para ser generado.
--			El estado "inconsistente" indica que existe un problema en el folio o certificado, por tanto no puede ser generado.
--			El estado "emitido" indica que el archivo xml ha sido generado y sellado por el PAC y est� listo para ser impreso.
--06/11/17 jcf Creaci�n cfdi Per�
--

select tv.estadoContabilizado, tv.soptype, tv.docid, tv.sopnumbe, tv.fechahora, 
	tv.CUSTNMBR, tv.nombreCliente, tv.idImpuestoCliente, cast(tv.total as numeric(19,2)) total, tv.montoActualOriginal, tv.voidstts, 

	isnull(lf.estado, isnull(fv.estado, 'inconsistente')) estado,
	case when isnull(lf.estado, isnull(fv.estado, 'inconsistente')) = 'inconsistente' 
		then 'folio o certificado inconsistente'
		else ISNULL(lf.mensaje, tv.estadoContabilizado)
	end mensaje,
	case when isnull(lf.estado, isnull(fv.estado, 'inconsistente')) = 'no emitido' 
		then null	--dbo.fCfdiGeneraDocumentoDeVentaXML (tv.soptype, tv.sopnumbe) 
		else cast('' as xml) 
	end comprobanteXml,
	
	fv.ID_Certificado, fv.ruta_certificado, fv.ruta_clave, fv.contrasenia_clave, 
	isnull(pa.ruta_certificado, '_noexiste') ruta_certificadoPac, isnull(pa.ruta_clave, '_noexiste') ruta_clavePac, isnull(pa.contrasenia_clave, '') contrasenia_clavePac, 
	emi.TAXREGTN rfc, 
	isnull(lf.noAprobacion, '') regimen, 
	emi.INET7 rutaXml, 
	emi.ZIPCODE codigoPostal,
	isnull(lf.estadoActual, '000000') estadoActual, 
	isnull(lf.mensajeEA, tv.estadoContabilizado) mensajeEA,
	tv.curncyid isocurrc,
	null addenda
from dbo.vwCfdiSopTransaccionesVenta tv
	cross join dbo.fCfdiEmisor() emi
	outer apply dbo.fCfdiCertificadoVigente(tv.fechahora) fv
	outer apply dbo.fCfdiCertificadoPAC(tv.fechahora) pa
	left join cfdlogfacturaxml lf
		on lf.soptype = tv.SOPTYPE
		and lf.sopnumbe = tv.sopnumbe
		and lf.estado = 'emitido'

go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de la vista: vwCfdiTransaccionesDeVenta'
ELSE PRINT 'Error en la creaci�n de la vista: vwCfdiTransaccionesDeVenta'
GO

-----------------------------------------------------------------------------------------
--IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwCfdiDocumentosAImprimir]') AND OBJECTPROPERTY(id,N'IsView') = 1)
--    DROP view dbo.[vwCfdiDocumentosAImprimir];
--GO
IF (OBJECT_ID ('dbo.vwCfdiDocumentosAImprimir', 'V') IS NULL)
   exec('create view dbo.vwCfdiDocumentosAImprimir as SELECT 1 as t');
go

alter view dbo.vwCfdiDocumentosAImprimir as
--Prop�sito. Lista los documentos de venta que est�n listos para imprimirse: facturas y notas de cr�dito. 
--06/11/17 jcf Creaci�n cfdi Per� ubl 2.0
--
select tv.soptype, tv.sopnumbe, tv.fechaEmision fechaHoraEmision, 
	--tv.regimenFiscal, 'NA' rgfs_descripcion, tv.codigoPostal, 
	rtrim(td.dscriptn) tipoDocCliente, 
	tv.receptorNroDoc rfcReceptor, tv.receptorNombre nombreCliente, tv.total, tv.moneda isocurrc, --tv.mensajeEA, 
	tv.tipoDocumento TipoDeComprobante,
	case when tv.tipoDocumento = '01' then 'FACTURA ELECTRONICA'
		WHEN tv.tipoDocumento = '08' then 'NOTA DE DEBITO ELECTRONICA'
		WHEN tv.tipoDocumento = '03' then 'BOLETA ELECTRONICA'
		WHEN tv.tipoDocumento = '08' then 'NOTA DE DEBITO ELECTRONICA'
		WHEN tv.tipoDocumento = '07' then 'NOTA DE CREDITO ELECTRONICA'
		else 'OTRO' 
	end tdcmp_descripcion,

		tv.tipoOperacion,
		tv.descuento,
		tv.ORTDISAM,
		tv.ivaImponible,
		tv.iva,
		tv.inafecta,
		tv.exonerado,
		tv.gratuito,

		--Para NC:
		tv.discrepanciaDesc,
	
	--Datos del xml sellado por el PAC:
	'' SelloCFD, 
	'1/1/1900' FechaTimbrado, 
	'' folioFiscal, 
	'' NoCertificadoSAT, 
	'' [Version], 
	'' selloSAT, 
	'' formaDePago,			'NA' frpg_descripcion,
	'' Sello, 
	'' NoCertificadoCSD, 
	'' metodoDePago,			'NA' mtdpg_descripcion,
	'' RfcPAC,
	'' Leyenda,
	'' cadenaOriginalSAT
	--tv.rutaxml								+ 'cbb\' + replace(tv.mensaje, 'Almacenado en '+tv.rutaxml, '')+'.jpg' rutaYNomArchivoNet,
	--'file:'+replace(tv.rutaxml, '\', '/') + 'cbb/' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaYNomArchivo, 
	--tv.rutaxml								+ 'cbb\' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaYNomArchivoNet,
	--'file://c:\getty' + substring(tv.rutaxml, charindex('\', tv.rutaxml, 3), 250) 
	--										+ 'cbb\' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaFileDrive
from vwCfdiGeneraDocumentoDeVenta tv
	left join cfdlogfacturaxml lf
		on lf.soptype = tv.SOPTYPE
		and lf.sopnumbe = tv.sopnumbe
		and lf.estado = 'emitido'
	--inner join dbo.vwCfdiDatosDelXml dx
	--	on dx.soptype = tv.SOPTYPE
	--	and dx.sopnumbe = tv.sopnumbe
	--	and dx.estado = 'emitido'
	--outer apply dbo.fLcLvComprobanteSunat (tv.soptype, tv.sopnumbe)  cmpr
	left join nsaif_sy00102 td
		on td.nsaif_type = tv.receptorTipoDoc
	--outer apply dbo.fCfdiCatalogoGetDescripcion('MTDPG', dx.MetodoPago) mtdpg
	--outer apply dbo.fCfdiCatalogoGetDescripcion('FRPG', dx.FormaPago) frpg
	--outer apply dbo.fCfdiCatalogoGetDescripcion('RGFS', tv.regimen) rgfs
	--outer apply dbo.fCfdiCatalogoGetDescripcion('USCF', dx.usoCfdi) uscf
	--outer apply dbo.fCfdiCatalogoGetDescripcion('TPRL', dx.TipoRelacion) tprl
go
IF (@@Error = 0) PRINT 'Creaci�n exitosa de la vista: vwCfdiDocumentosAImprimir  '
ELSE PRINT 'Error en la creaci�n de la vista: vwCfdiDocumentosAImprimir '
GO
-----------------------------------------------------------------------------------------

-- FIN DE SCRIPT ***********************************************

