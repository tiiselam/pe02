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
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwSopLineasTrxVentas]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.[vwSopLineasTrxVentas];
GO

create view dbo.vwSopLineasTrxVentas as
--Propósito. Obtiene todas las líneas de facturas de venta SOP y la info aduanera de importación
--			También obtiene la serie/lote del artículo o kits
--			Incluye descuentos
--Requisito. Atención ! DEBE usar unidades de medida listadas en el SAT. 
--23/10/17 JCF Creación
--
select dt.soptype, dt.sopnumbe, dt.LNITMSEQ, dt.ITEMNMBR, ISNULL(sr.serltqty, dt.QUANTITY) cantidad, dt.QUANTITY, sr.serltqty, dt.UOFM, 
	um.UOFMLONGDESC UOFMsat, 
	sr.SERLTNUM, dt.ITEMDESC, dt.ORUNTPRC, dt.OXTNDPRC, dt.CMPNTSEQ, 
	case when isnull(sr.SOPNUMBE, '_nulo')='_nulo' then 
			dt.QUANTITY * dt.ORUNTPRC
		else 
			sr.SERLTQTY * dt.ORUNTPRC
	end importe,
	isnull(ma.ITMTRKOP, 1) ITMTRKOP,		--3 lote, 2 serie, 1 nada
	ma.uscatvls_6, 
	case when isnull(sr.SOPNUMBE, '_nulo')='_nulo' then 
			dt.QUANTITY * dt.ormrkdam
		else 
			sr.SERLTQTY * dt.ormrkdam
	end descuento
from SOP30200 cb
inner join SOP30300 dt
	on cb.SOPNUMBE = dt.SOPNUMBE
	and cb.SOPTYPE = dt.SOPTYPE
INNER join rm00101 cs
	on cs.custnmbr = cb.custnmbr
left join iv00101 ma				--iv_itm_mstr
	on ma.ITEMNMBR = dt.ITEMNMBR
left join sop10201 sr				--SOP_Serial_Lot_WORK_HIST
	on sr.SOPNUMBE = dt.SOPNUMBE
	and sr.SOPTYPE = dt.SOPTYPE
	and sr.CMPNTSEQ = dt.CMPNTSEQ
	and sr.LNITMSEQ = dt.LNITMSEQ
outer apply dbo.fCfdUofMSAT(ma.UOMSCHDL, dt.UOFM ) um
go	

IF (@@Error = 0) PRINT 'Creación exitosa de: vwSopLineasTrxVentas'
ELSE PRINT 'Error en la creación de: vwSopLineasTrxVentas'
GO

-------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiParteXML') IS NOT NULL
   DROP FUNCTION dbo.fCfdiParteXML
GO

create function dbo.fCfdiParteXML(@soptype smallint, @sopnumbe char(21), @LNITMSEQ int)
returns xml 
as
--Propósito. Obtiene info de componentes de kit e info aduanera
--2/5/12 jcf Creación
--
begin
	declare @cncp xml;
	WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
	select @cncp = (
		select dt.uscatvls_6 ClaveProdServ,
				case when dt.ITMTRKOP = 2 then --tracking option: serie
					dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(dt.SERLTNUM))),10) 
					else null
				end NoIdentificacion, 
				dt.cantidad, 
				dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(dt.ITEMDESC))), 10) Descripcion,
				dbo.fCfdiInfoAduaneraXML(dt.ITEMNMBR, dt.SERLTNUM)
		from vwSopLineasTrxVentas dt
		where dt.soptype = @soptype
		and dt.sopnumbe = @sopnumbe
		and dt.LNITMSEQ = @LNITMSEQ
		and dt.CMPNTSEQ <> 0		--a nivel componente de kit
		FOR XML raw('cfdi:Parte') , type
	)
	return @cncp
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiParteXML()'
ELSE PRINT 'Error en la creación de: fCfdiParteXML()'
GO

--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiImpuestosTrasladadosXML') IS NOT NULL
begin
   DROP FUNCTION dbo.fCfdiImpuestosTrasladadosXML
   print 'función fCfdiImpuestosTrasladadosXML eliminada'
end
GO

create function dbo.fCfdiImpuestosTrasladadosXML(@p_soptype smallint, @p_sopnumbe varchar(21), @p_LNITMSEQ int)
returns xml 
as
begin
	declare @impu xml;
	WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
	select @impu = (
		select 	
			case when @p_LNITMSEQ=0 then null else cast(imp.ortxsls as numeric(19,2)) end Base,
			tx.NAME Impuesto,
			case when tx.TXDTLPCT=0 then 'Exento' else 'Tasa' end TipoFactor, 
			case when tx.TXDTLPCT=0 then null else cast(tx.TXDTLPCT as numeric(19,6)) end TasaOCuota,
			case when tx.TXDTLPCT=0 then null else cast(imp.orslstax as numeric(19,2)) end Importe
		from sop10105 imp	--sop_tax_work_hist
		inner join tx00201 tx
			on tx.taxdtlid = imp.taxdtlid
 		where imp.SOPTYPE = @p_soptype
		  and imp.SOPNUMBE = @p_sopnumbe
		  and imp.LNITMSEQ = @p_LNITMSEQ
		  and tx.TXDTLPCT >= 0
		FOR XML raw('cfdi:Traslado'), type, root('cfdi:Traslados')
		)
	return @impu
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiImpuestosTrasladadosXML()'
ELSE PRINT 'Error en la creación de la función: fCfdiImpuestosTrasladadosXML()'
GO

--------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.fCfdiConceptosXML') IS NOT NULL
   DROP FUNCTION dbo.fCfdiConceptosXML
GO

create function dbo.fCfdiConceptosXML(@p_soptype smallint, @p_sopnumbe varchar(21), @p_subtotal numeric(19,6))
returns xml 
as
--Propósito. Obtiene las líneas de una factura en formato xml para CFDI
--			Elimina carriage returns, line feeds, tabs, secuencias de espacios y caracteres especiales.
--23/10/17 jcf Creación cfdi 3.3
--
begin
	declare @cncp xml;
	if @p_soptype = 4 
	begin
		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
		select @cncp = (
				select top (1) '84111506' '@ClaveProdServ',
					1 '@Cantidad',
					'ACT' '@ClaveUnidad',
					dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(Concepto.ITEMDESC))), 10) '@Descripcion', 
					@p_subtotal				'@ValorUnitario',
					@p_subtotal				'@Importe',
					dbo.fCfdiImpuestosTrasladadosXML(Concepto.soptype, Concepto.sopnumbe, 0) 'cfdi:Impuestos'
				from vwSopLineasTrxVentas Concepto
				where Concepto.CMPNTSEQ = 0					--a nivel kit
				and Concepto.soptype = @p_soptype
				and Concepto.sopnumbe = @p_sopnumbe
				and Concepto.importe != 0          
				order by Concepto.LNITMSEQ
				FOR XML path('cfdi:Concepto'), type, root('cfdi:Conceptos')
				)
	end
	else 
	begin
		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
		select @cncp = (
			select 
				Concepto.uscatvls_6				'@ClaveProdServ',
				case when Concepto.ITMTRKOP = 2 then --tracking option: serie
					dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(Concepto.SERLTNUM))),10) 
					else null
				end '@NoIdentificacion',
				Concepto.cantidad				'@Cantidad', 
				rtrim(Concepto.UOFMsat)			'@ClaveUnidad', 
				dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(Concepto.ITEMDESC))), 10) '@Descripcion', 
				cast(Concepto.ORUNTPRC as numeric(19, 2))				'@ValorUnitario',
				cast(Concepto.importe  as numeric(19, 2))				'@Importe',
				cast(Concepto.descuento as numeric(19, 2))				'@Descuento',

				dbo.fCfdiImpuestosTrasladadosXML(Concepto.soptype, Concepto.sopnumbe, Concepto.LNITMSEQ) 'cfdi:Impuestos',

				dbo.fCfdiInfoAduaneraXML(Concepto.ITEMNMBR, Concepto.SERLTNUM),
			
				dbo.fCfdiParteXML(Concepto.soptype, Concepto.sopnumbe, Concepto.LNITMSEQ) 
			from vwSopLineasTrxVentas Concepto
			where Concepto.CMPNTSEQ = 0					--a nivel kit
			and Concepto.soptype = @p_soptype
			and Concepto.sopnumbe = @p_sopnumbe
			and Concepto.importe != 0          
			FOR XML path('cfdi:Concepto'), type, root('cfdi:Conceptos')
		)
	end
	return @cncp
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiConceptosXML()'
ELSE PRINT 'Error en la creación de: fCfdiConceptosXML()'
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
IF OBJECT_ID ('dbo.fCfdiGeneraDocumentoDeVentaXML') IS NOT NULL
   DROP FUNCTION dbo.fCfdiGeneraDocumentoDeVentaXML
GO

create function dbo.fCfdiGeneraDocumentoDeVentaXML (@soptype smallint, @sopnumbe varchar(21))
returns xml 
as
--Propósito. Elabora un comprobante xml para factura electrónica cfdi
--Requisitos. El total de impuestos de la factura debe corresponder a la suma del detalle de impuestos. 
--			Se asume que No incluye retenciones
--23/10/17 jcf Creación cfdi 3.3
--
begin
	declare @cfd xml;
	WITH XMLNAMESPACES
	(
				'http://www.w3.org/2001/XMLSchema-instance' as "xsi",
				'http://www.sat.gob.mx/cfd/3' as "cfdi"
	)
	select @cfd = 
	(
	select 
		'http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv33.xsd'	'@xsi:schemaLocation',
		emi.[version]										'@Version',
		rtrim(tv.docid)										'@Serie',
		rtrim(tv.sopnumbe)									'@Folio',
		convert(datetime, tv.fechahora, 126)				'@Fecha',
		''													'@Sello', 

		case when tv.soptype = 3 
			then case when tv.orpmtrvd = tv.total 
					then pg.FormaPago
					else '99'
				end
			else tr.FormaPago
		end													'@FormaPago',
		''													'@NoCertificado', 
		''													'@Certificado', 
		--tv.pymtrmid								'@CondicionesDePago',

		cast(tv.subtotal as numeric(19,2))					'@SubTotal',
		cast(tv.descuento as numeric(19,2))					'@Descuento',
		tv.curncyid											'@Moneda',

		case when tv.curncyid in ('MXN', 'XXX')
			then null
			else cast(tv.xchgrate as numeric(19,6))
		end													'@TipoCambio',

		cast(tv.total  as numeric(19, 2))					'@Total',
		case when tv.SOPTYPE = 3 
			then 'I' 
			else 'E' 
		end													'@TipoDeComprobante',

		case when tv.orpmtrvd = tv.total or tv.soptype = 4
			then 'PUE'
			Else 'PPD'
		END													'@MetodoPago',
		emi.codigoPostal									'@LugarExpedicion',

        tr.TipoRelacion										'cfdi:CfdiRelacionados/@TipoRelacion',
		dbo.fCfdiRelacionadosXML(tv.soptype, tv.sopnumbe, tv.docid, tr.TipoRelacion) 'cfdi:CfdiRelacionados',
				
		emi.rfc												'cfdi:Emisor/@Rfc',
		emi.nombre											'cfdi:Emisor/@Nombre', 
		emi.regimen											'cfdi:Emisor/@RegimenFiscal',

		tv.idImpuestoCliente								'cfdi:Receptor/@Rfc',
		tv.nombreCliente									'cfdi:Receptor/@Nombre', 
		case when tv.idImpuestoCliente != 'XEXX010101000'
			then pc.param1
			else 'P01'
		END													'cfdi:Receptor/@UsoCFDI',

		dbo.fCfdiConceptosXML(tv.soptype, tv.sopnumbe, tv.subtotal),
		
		cast(tv.impuesto as numeric(19,2))					'cfdi:Impuestos/@TotalImpuestosTrasladados',		
		isnull(dbo.fCfdiImpuestosTrasladadosXML(tv.soptype, tv.sopnumbe, 0), ' ')	'cfdi:Impuestos',

		''													'cfdi:Complemento'
	from dbo.vwSopTransaccionesVenta tv
		cross join dbo.fCfdEmisor() emi
		outer apply dbo.fCfdiPagoSimultaneoMayor(tv.soptype, tv.sopnumbe) pg
		outer apply dbo.fCfdiDatosDeUnaRelacion(tv.soptype, tv.sopnumbe, tv.docid) tr
		outer apply dbo.fCfdiParametrosCliente(tv.CUSTNMBR, 'UsoCFDI', 'na', 'na', 'na', 'na', 'na', 'PREDETERMINADO') pc
	where tv.sopnumbe =	@sopnumbe		
	and tv.soptype = @soptype
	FOR XML path('cfdi:Comprobante'), type
	)
	return @cfd;
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiGeneraDocumentoDeVentaXML ()'
ELSE PRINT 'Error en la creación de la función: fCfdiGeneraDocumentoDeVentaXML ()'
GO
-----------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwCfdiTransaccionesDeVenta]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.[vwCfdiTransaccionesDeVenta];
GO

create view dbo.vwCfdiTransaccionesDeVenta as
--Propósito. Todos los documentos de venta: facturas y notas de crédito. 
--Usado por. App Factura digital (doodads)
--Requisitos. El estado "no emitido" indica que no se ha emitido el archivo xml pero que está listo para ser generado.
--			El estado "inconsistente" indica que existe un problema en el folio o certificado, por tanto no puede ser generado.
--			El estado "emitido" indica que el archivo xml ha sido generado y sellado por el PAC y está listo para ser impreso.
--06/11/17 jcf Creación cfdi Perú
--
select tv.estadoContabilizado, tv.soptype, tv.docid, 
	tv.sopnumbe,				--id documento
	tv.fechahora, 
	tv.CUSTNMBR, tv.nombreCliente, tv.idImpuestoCliente, cast(tv.total as numeric(19,2)) total, tv.montoActualOriginal, tv.voidstts, 

	su.tipo tipoDocumento,

	isnull(lf.estado, isnull(fv.estado, 'inconsistente')) estado,
	case when isnull(lf.estado, isnull(fv.estado, 'inconsistente')) = 'inconsistente' 
		then 'folio o certificado inconsistente'
		else ISNULL(lf.mensaje, tv.estadoContabilizado)
	end mensaje,
	cast('' as xml) comprobanteXml,
	
	--Datos del xml sellado por el PAC:
	isnull(dx.selloCFD, '') selloCFD, 
	isnull(dx.FechaTimbrado, '') FechaTimbrado, 
	isnull(dx.UUID, '') UUID, 
	isnull(dx.noCertificadoSAT, '') noCertificadoSAT, 
	isnull(dx.[version], '') [version], 
	isnull(dx.selloSAT, '') selloSAT, 
	isnull(dx.FormaPago, '') formaDePago,
	isnull(dx.sello, '') sello, 
	isnull(dx.noCertificado, '') noCertificado, 

	'||'+dx.[version]+'|'+dx.UUID+'|'+dx.FechaTimbrado+'|'+dx.RfcPAC + 
	case when isnull(dx.Leyenda, '') = '' then '' else '|'+dx.Leyenda end
	+'|'+dx.selloCFD+'|'+dx.noCertificadoSAT+'||' cadenaOriginalSAT,
	
	fv.ID_Certificado, fv.ruta_certificado, fv.ruta_clave, fv.contrasenia_clave, 
	isnull(pa.ruta_certificado, '_noexiste') ruta_certificadoPac, isnull(pa.ruta_clave, '_noexiste') ruta_clavePac, isnull(pa.contrasenia_clave, '') contrasenia_clavePac, 
	emi.rfc, emi.regimen, emi.rutaXml, 
	isnull(lf.estadoActual, '000000') estadoActual, 
	isnull(lf.mensajeEA, tv.estadoContabilizado) mensajeEA,
	isnull(dx.MetodoPago, '') metodoDePago,
	tv.curncyid isocurrc,		--moneda
	cast('' as xml) addenda
	--dbo.fCfdAddendaXML(tv.custnmbr,  tv.soptype, tv.sopnumbe, tv.docid, tv.cstponbr, tv.curncyid, tv.docdate, tv.xchgrate, tv.subtotal, tv.total, emi.incluyeAddendaDflt) addenda
from vwCfdiSopTransaccionesVenta tv
	cross join dbo.fCfdEmisor() emi
	outer apply dbo.fCfdiCertificadoVigente(tv.fechahora) fv
	outer apply dbo.fCfdiCertificadoPAC(tv.fechahora) pa
	outer apply dbo.fLcLvComprobanteSunat ( tv.SOPTYPE, tv.SOPNUMBE) su
	left join cfdlogfacturaxml lf
		on lf.soptype = tv.SOPTYPE
		and lf.sopnumbe = tv.sopnumbe
		and lf.estado = 'emitido'
	outer apply dbo.fCfdiDatosXmlParaImpresion(lf.archivoXML) dx
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

