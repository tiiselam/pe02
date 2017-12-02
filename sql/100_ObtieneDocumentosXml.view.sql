--FACTURA ELECTRONICA GP - MEXICO
--Proyectos:		GETTY
--Propósito:		Genera funciones y vistas de FACTURAS para la facturación electrónica en GP - MEXICO
--Referencia:		
--		01/11/11 Versión CFD 1 -	100823 Normativa formal Anexo 20.pdf, 
--		10/02/12 Versión CFD 2.2 - 111230 Normativa Anexo20.doc
--		25/04/12 Versión CFDI 3.2 - 111230 Normativa Anexo20.doc
--		23/10/17 Versión CFDI 3.3 - cfdv33.pdf
--Utilizado por:	Aplicación C# de generación de factura electrónica México
-----------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiInfoAduaneraXML') IS NOT NULL
   DROP FUNCTION dbo.fCfdiInfoAduaneraXML
GO

create function dbo.fCfdiInfoAduaneraXML(@ITEMNMBR char(31), @SERLTNUM char(21))
returns xml 
as
--Propósito. Obtiene info aduanera para conceptos de importación
--Requisito. Se asume que todos los artículos importados usan número de serie o lote. De otro modo se consideran nacionales.
--			También se asume que no hay números de serie repetidos por artículo
--24/10/17 jcf Creación cfdi 3.3
--
begin
	declare @cncp xml;
	select @cncp = null;

	IF isnull(@SERLTNUM, '_NULO') <> '_NULO'	
	begin
		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
		select @cncp = (
		   select ad.NumeroPedimento	--, ad.fecha
		   from (
				--En caso de usar número de lote, la info aduanera viene en el número de lote y los atributos del lote
				select top 1 stuff(stuff(stuff(dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(@SERLTNUM)),10) , 3, 0, '  '), 7, 0, '  '), 13, 0, '  ') NumeroPedimento
						--dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(la.LOTATRB1 +' '+ la.LOTATRB2))),10) numero, 
				  from iv00301 la				--iv_lot_attributes [ITEMNMBR LOTNUMBR]
				  inner join IV00101 ma			--iv_itm_mstr
					on ma.ITEMNMBR = la.ITEMNMBR
				 where ma.ITMTRKOP = 3			--lote
					and la.ITEMNMBR = @ITEMNMBR
					and la.LOTNUMBR = @SERLTNUM
				union all
				--En caso de usar número de serie, la info aduanera viene de los campos def por el usuario de la recepción de compra
				select top 1 stuff(stuff(stuff(dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(ud.user_defined_text01))),10) , 3, 0, '  '), 7, 0, '  '), 13, 0, '  ') NumeroPedimento
				  from POP30330	rs				--POP_SerialLotHist [POPRCTNM RCPTLNNM QTYTYPE SLTSQNUM]
					inner JOIN POP10306 ud		--POP_ReceiptUserDefined 			
					on ud.POPRCTNM = rs.POPRCTNM
					inner join IV00101 ma		--iv_itm_mstr
					on ma.ITEMNMBR = rs.ITEMNMBR
				where ma.ITMTRKOP = 2			--serie
					and rs.ITEMNMBR = @ITEMNMBR
					and rs.SERLTNUM = @SERLTNUM
				) ad
			FOR XML raw('cfdi:InformacionAduanera') , type
		)
	end
	return @cncp
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiInfoAduaneraXML()'
ELSE PRINT 'Error en la creación de: fCfdiInfoAduaneraXML()'
GO

-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiSopLineasTrxVentas', 'V') IS NULL)
   exec('create view dbo.vwCfdiSopLineasTrxVentas as SELECT 1 as t');
go

alter view dbo.vwCfdiSopLineasTrxVentas as
--Propósito. Obtiene todas las líneas de facturas de venta SOP
--			Incluye descuentos
--Requisito. Atención ! DEBE usar unidades de medida listadas en el SAT. 
--30/11/17 JCF Creación cfdi 3.3
--
select dt.soptype, dt.sopnumbe, dt.LNITMSEQ, dt.ITEMNMBR, dt.ShipToName,
	dt.QUANTITY, dt.UOFM,
	um.UOFMLONGDESC UOFMsat,
	udmfa.descripcion UOFMsat_descripcion,
	um.UOFMLONGDESC, 
	dt.ITEMDESC,
	dt.ORUNTPRC, dt.OXTNDPRC, dt.CMPNTSEQ, 
	dt.QUANTITY * dt.ORUNTPRC importe, 
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

IF (@@Error = 0) PRINT 'Creación exitosa de: vwCfdiSopLineasTrxVentas'
ELSE PRINT 'Error en la creación de: vwCfdiSopLineasTrxVentas'
GO
-------------------------------------------------------------------------------------------------------
--IF OBJECT_ID ('dbo.fCfdiParteXML') IS NOT NULL
--   DROP FUNCTION dbo.fCfdiParteXML
--GO

--create function dbo.fCfdiParteXML(@soptype smallint, @sopnumbe char(21), @LNITMSEQ int)
--returns xml 
--as
----Propósito. Obtiene info de componentes de kit e info aduanera
----2/5/12 jcf Creación
----
--begin
--	declare @cncp xml;
--	WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
--	select @cncp = (
--		select dt.uscatvls_6 ClaveProdServ,
--				case when dt.ITMTRKOP = 2 then --tracking option: serie
--					dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(dt.SERLTNUM))),10) 
--					else null
--				end NoIdentificacion, 
--				dt.cantidad, 
--				dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(dt.ITEMDESC))), 10) Descripcion,
--				dbo.fCfdiInfoAduaneraXML(dt.ITEMNMBR, dt.SERLTNUM)
--		from vwCfdiSopLineasTrxVentas dt
--		where dt.soptype = @soptype
--		and dt.sopnumbe = @sopnumbe
--		and dt.LNITMSEQ = @LNITMSEQ
--		and dt.CMPNTSEQ <> 0		--a nivel componente de kit
--		FOR XML raw('cfdi:Parte') , type
--	)
--	return @cncp
--end
--go

--IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiParteXML()'
--ELSE PRINT 'Error en la creación de: fCfdiParteXML()'
--GO
----------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiImpuestosSop') IS NOT NULL
   DROP FUNCTION dbo.fCfdiImpuestosSop
GO

create function dbo.fCfdiImpuestosSop(@SOPNUMBE char(21), @DOCTYPE smallint, @LNITMSEQ int, @prefijo varchar(15))
returns table
as
--Propósito. Detalle de impuestos en trabajo e históricos de SOP. Filtra los impuestos requeridos por @prefijo
--Requisitos. Los impuestos iva deben ser configurados con un prefijo constante
--27/11/17 jcf Creación 
--
return
(
	select imp.soptype, imp.sopnumbe, imp.taxdtlid, imp.staxamnt, imp.orslstax, imp.tdttxsls, imp.ortxsls,
			tx.NAME, tx.TXDTLPCT
	from sop10105 imp
		inner join tx00201 tx
		on tx.taxdtlid = imp.taxdtlid
	where imp.sopnumbe = @SOPNUMBE
	and imp.soptype = @DOCTYPE
	and imp.LNITMSEQ = @LNITMSEQ
	and imp.taxdtlid like @prefijo + '%'
)

go


IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiImpuestosSop()'
ELSE PRINT 'Error en la creación de la función: fCfdiImpuestosSop()'
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

--IF (@@Error = 0) PRINT 'Creación exitosa de la función: vwCfdiImpuestos()'
--ELSE PRINT 'Error en la creación de la función: vwCfdiImpuestos()'
--GO

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiConceptos', 'V') IS NULL)
   exec('create view dbo.vwCfdiConceptos as SELECT 1 as t');
go

alter view dbo.vwCfdiConceptos --(@p_soptype smallint, @p_sopnumbe varchar(21), @p_subtotal numeric(19,6))
as
--Propósito. Obtiene las líneas de una factura 
--			Elimina carriage returns, line feeds, tabs, secuencias de espacios y caracteres especiales.
--Requisito. Se asume que una línea de factura tiene una línea de impuesto
--27/11/17 jcf Creación cfdi 3.3
--
		select ROW_NUMBER() OVER(ORDER BY Concepto.LNITMSEQ DESC) id, 
			Concepto.soptype, Concepto.sopnumbe, Concepto.LNITMSEQ, Concepto.ITEMNMBR, null SERLTNUM, 
			Concepto.ITEMDESC, Concepto.CMPNTSEQ, 
			Concepto.UOFMsat udemSunat,
			null NoIdentificacion,
			dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(Concepto.ITEMDESC))), 10) Descripcion, 
			Concepto.ORUNTPRC * (1 + iva.TXDTLPCT/100)	precioUniConIva,	--precioReferencial
			Concepto.ORUNTPRC valorUni,							--valor unitario (precioUnitario)
			Concepto.QUANTITY cantidad, 
			--Concepto.ORUNTPRC * Concepto.cantidad valorVenta,	--valor venta bruto
			Concepto.descuento,
			Concepto.importe,									--valor de venta (totalVenta)
			isnull(iva.orslstax, 0.00) orslstax,				--igv

			'01' tipoPrecio,	-- 01 incluye igv, 02 no oneroso
			case when isnull(iva.orslstax, 0) != 0 
				then rtrim(iva.name)
				else case when isnull(exe.ortxsls, 0) != 0 
					then rtrim(exe.name)
					else case when isnull(rtrim(xnr.ortxsls), 0) != 0
						then rtrim(xnr.name)
						else ''
						end
					end
				end tipoImpuesto
		from vwCfdiSopLineasTrxVentas Concepto
			outer apply dbo.fLcLvParametros('V_PREFEXONERADO', 'V_PREFEXENTO', 'V_PREFIVA', 'na', 'na', 'na') pr	--Parámetros. prefijo inafectos, prefijo exento, prefijo iva
			outer apply dbo.fCfdiImpuestosSop(Concepto.SOPNUMBE, Concepto.soptype, Concepto.LNITMSEQ, pr.param1) xnr --exonerado
			outer apply dbo.fCfdiImpuestosSop(Concepto.SOPNUMBE, Concepto.soptype, Concepto.LNITMSEQ, pr.param2) exe --inafecto
			outer apply dbo.fCfdiImpuestosSop(Concepto.SOPNUMBE, Concepto.soptype, Concepto.LNITMSEQ, pr.param3) iva --iva
		where Concepto.CMPNTSEQ = 0					--a nivel kit

go

IF (@@Error = 0) PRINT 'Creación exitosa de: vwCfdiConceptos()'
ELSE PRINT 'Error en la creación de: vwCfdiConceptos()'
GO

--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiCertificadoVigente') IS NOT NULL
   DROP FUNCTION dbo.fCfdiCertificadoVigente
GO

create function dbo.fCfdiCertificadoVigente(@fecha datetime)
returns table
as
--Propósito. Verifica que la fecha corresponde a un certificado vigente y activo
--			Si existe más de uno o ninguno, devuelve el estado: inconsistente
--			También devuelve datos del folio y certificado asociado.
--Requisitos. Los estados posibles para generar o no archivos xml son: no emitido, inconsistente
--06/11/17 jcf Creación cfdi Perú
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
			and B.id_certificado <> 'PAC'	--El id PAC está reservado para el PAC
			and datediff(day, B.fecha_vig_desde, @fecha) >= 0
			and datediff(day, B.fecha_vig_hasta, @fecha) <= 0
		) fyc
	order by fyc.fila desc
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiCertificadoVigente()'
ELSE PRINT 'Error en la creación de la función: fCfdiCertificadoVigente()'
GO

--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiCertificadoPAC') IS NOT NULL
   DROP FUNCTION dbo.fCfdiCertificadoPAC
GO

create function dbo.fCfdiCertificadoPAC(@fecha datetime)
returns table
as
--Propósito. Obtiene el certificado del PAC. 
--			Verifica que la fecha corresponde a un certificado vigente y activo
--Requisitos. El id PAC está reservado para registrar el certificado del PAC. 
--06/11/17 jcf Creación 
--
return
(  
	--declare @fecha datetime
	--select @fecha = '5/4/12'
	SELECT rtrim(B.ID_Certificado) ID_Certificado, rtrim(B.ruta_certificado) ruta_certificado, rtrim(B.ruta_clave) ruta_clave, 
			rtrim(B.contrasenia_clave) contrasenia_clave
	FROM cfd_CER00100 B
	WHERE B.estado = '1'
		and B.id_certificado = 'PAC'	--El id PAC está reservado para el PAC
		and datediff(day, B.fecha_vig_desde, @fecha) >= 0
		and datediff(day, B.fecha_vig_hasta, @fecha) <= 0
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiCertificadoPAC()'
ELSE PRINT 'Error en la creación de la función: fCfdiCertificadoPAC()'
GO

--------------------------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiGeneraDocumentoDeVenta', 'V') IS NULL)
   exec('create view dbo.vwCfdiGeneraDocumentoDeVenta as SELECT 1 as t');
go

alter view dbo.vwCfdiGeneraDocumentoDeVenta
as
--Propósito. Elabora un comprobante xml para factura electrónica cfdi
--Requisitos. El total de impuestos de la factura debe corresponder a la suma del detalle de impuestos. 
--			Se asume que No incluye retenciones
--27/11/17 jcf Creación cfdi 3.3
--
	select 
		tv.soptype,
		tv.sopnumbe,
		cmpr.tipo									tipoDocumento, 
		emi.TAXREGTN								emisorNroDoc,
		emi.ADRCNTCT								emisorNombre,
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

		isnull(exe.tdttxsls, 0.00)					inafecta,
		isnull(xnr.tdttxsls, 0.00)					exonerado,

		tv.xchgrate,

		tv.total

--		dbo.fCfdiRelacionadosXML(tv.soptype, tv.sopnumbe, tv.docid, tr.TipoRelacion) 'cfdi:CfdiRelacionados',
--		dbo.fCfdiConceptosXML(tv.soptype, tv.sopnumbe, tv.subtotal),
	from dbo.vwCfdiSopTransaccionesVenta tv
		cross join dbo.fCfdiEmisor() emi
--		outer apply dbo.fCfdiDatosDeUnaRelacion(tv.soptype, tv.sopnumbe, tv.docid) tr
		outer apply dbo.fLcLvComprobanteSunat (tv.soptype, tv.sopnumbe)  cmpr
		outer apply dbo.fLcLvParametros('V_PREFEXONERADO', 'V_PREFEXENTO', 'V_PREFIVA', 'na', 'na', 'na') pr	--Parámetros. prefijo inafectos, prefijo exento, prefijo iva
		outer apply dbo.fLvSopTaxWorkHist(tv.sopnumbe, tv.soptype, pr.param1) xnr   --exonerado
		outer apply dbo.fLvSopTaxWorkHist(tv.sopnumbe, tv.soptype, pr.param2) exe	--exento/inafecto
		outer apply dbo.fLvSopTaxWorkHist(tv.sopnumbe, tv.soptype, pr.param3) iva	--iva

go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: vwCfdiGeneraDocumentoDeVenta ()'
ELSE PRINT 'Error en la creación de la función: vwCfdiGeneraDocumentoDeVenta ()'
GO
-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiTransaccionesDeVenta', 'V') IS NULL)
   exec('create view dbo.vwCfdiTransaccionesDeVenta as SELECT 1 as t');
go

alter view dbo.vwCfdiTransaccionesDeVenta as
--Propósito. Todos los documentos de venta: facturas y notas de crédito. 
--Usado por. App Factura digital (doodads)
--Requisitos. El estado "no emitido" indica que no se ha emitido el archivo xml pero que está listo para ser generado.
--			El estado "inconsistente" indica que existe un problema en el folio o certificado, por tanto no puede ser generado.
--			El estado "emitido" indica que el archivo xml ha sido generado y sellado por el PAC y está listo para ser impreso.
--06/11/17 jcf Creación cfdi Perú
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
	
	----Datos del xml sellado por el PAC:
	--isnull(dx.selloCFD, '') selloCFD, 
	--isnull(dx.FechaTimbrado, '') FechaTimbrado, 
	--isnull(dx.UUID, '') UUID, 
	--isnull(dx.noCertificadoSAT, '') noCertificadoSAT, 
	--isnull(dx.[version], '') [version], 
	--isnull(dx.selloSAT, '') selloSAT, 
	--isnull(dx.FormaPago, '') formaDePago,
	--isnull(dx.sello, '') sello, 
	--isnull(dx.noCertificado, '') noCertificado, 
	--isnull(dx.MetodoPago, '') metodoDePago,
	--isnull(dx.usoCfdi, '') usoCfdi,
	--isnull(dx.RfcPAC, '') RfcPAC,
	--isnull(dx.Leyenda, '') Leyenda,

	--'||'+dx.[version]+'|'+dx.UUID+'|'+dx.FechaTimbrado+'|'+dx.RfcPAC + 
	--case when isnull(dx.Leyenda, '') = '' then '' else '|'+dx.Leyenda end
	--+'|'+dx.selloCFD+'|'+dx.noCertificadoSAT+'||' cadenaOriginalSAT,
	
	fv.ID_Certificado, fv.ruta_certificado, fv.ruta_clave, fv.contrasenia_clave, 
	isnull(pa.ruta_certificado, '_noexiste') ruta_certificadoPac, isnull(pa.ruta_clave, '_noexiste') ruta_clavePac, isnull(pa.contrasenia_clave, '') contrasenia_clavePac, 
	emi.rfc, emi.regimen, emi.rutaXml, emi.codigoPostal,
	isnull(lf.estadoActual, '000000') estadoActual, 
	isnull(lf.mensajeEA, tv.estadoContabilizado) mensajeEA,
	tv.curncyid isocurrc,
	null addenda
from dbo.vwCfdiSopTransaccionesVenta tv
	cross join dbo.fCfdEmisor() emi
	outer apply dbo.fCfdiCertificadoVigente(tv.fechahora) fv
	outer apply dbo.fCfdiCertificadoPAC(tv.fechahora) pa
	left join cfdlogfacturaxml lf
		on lf.soptype = tv.SOPTYPE
		and lf.sopnumbe = tv.sopnumbe
		and lf.estado = 'emitido'

go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiTransaccionesDeVenta'
ELSE PRINT 'Error en la creación de la vista: vwCfdiTransaccionesDeVenta'
GO

-----------------------------------------------------------------------------------------
--IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwCfdiDocumentosAImprimir]') AND OBJECTPROPERTY(id,N'IsView') = 1)
--    DROP view dbo.[vwCfdiDocumentosAImprimir];
--GO
IF (OBJECT_ID ('dbo.vwCfdiDocumentosAImprimir', 'V') IS NULL)
   exec('create view dbo.vwCfdiDocumentosAImprimir as SELECT 1 as t');
go

alter view dbo.vwCfdiDocumentosAImprimir as
--Propósito. Lista los documentos de venta que están listos para imprimirse: facturas y notas de crédito. 
--			Incluye los datos del cfdi.
--07/05/12 jcf Creación
--29/05/12 jcf Cambia la ruta para que funcione en SSRS
--10/07/12 jcf Agrega metodoDePago, NumCtaPago
--29/08/13 jcf Agrega USERDEF1 (nroOrden)
--11/09/13 jcf Agrega ruta del archivo en formato de red
--09/07/14 jcf Modifica la obtención del nombre del archivo
--13/07/16 jcf Agrega catálogo de método de pago
--19/10/16 jcf Agrega rutaFileDrive. Util para reportes Crystal
--18/09/17 jcf Agrega isocurrc
--25/10/17 jcf Ajuste para cfdi 3.3
--
select tv.soptype, tv.docid, tv.sopnumbe, tv.fechahora fechaHoraEmision, tv.regimen regimenFiscal, 
	tv.idImpuestoCliente rfcReceptor, tv.nombreCliente, tv.total, formaDePago, tv.isocurrc,
	tv.metodoDePago,
	--tv.NumCtaPago, tv.USERDEF1, 
	UUID folioFiscal, noCertificado noCertificadoCSD, [version], selloCFD, selloSAT, cadenaOriginalSAT, noCertificadoSAT, FechaTimbrado, 
	--tv.rutaxml								+ 'cbb\' + replace(tv.mensaje, 'Almacenado en '+tv.rutaxml, '')+'.jpg' rutaYNomArchivoNet,
	'file://'+replace(tv.rutaxml, '\', '/') + 'cbb/' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaYNomArchivo, 
	tv.rutaxml								+ 'cbb\' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaYNomArchivoNet,
	'file://c:\getty' + substring(tv.rutaxml, charindex('\', tv.rutaxml, 3), 250) 
											+ 'cbb\' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaFileDrive
from dbo.vwCfdiTransaccionesDeVenta tv
left join dbo.cfdiCatalogo ca
	on ca.tipo = 'MTDPG'
	and ca.clave = tv.metodoDePago
where estado = 'emitido'
go
IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiDocumentosAImprimir  '
ELSE PRINT 'Error en la creación de la vista: vwCfdiDocumentosAImprimir '
GO
-----------------------------------------------------------------------------------------

-- FIN DE SCRIPT ***********************************************

