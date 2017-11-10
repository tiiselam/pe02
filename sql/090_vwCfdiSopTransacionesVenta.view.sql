IF OBJECT_ID ('dbo.vwCfdiSopTransaccionesVenta') IS NOT NULL
   DROP view vwCfdiSopTransaccionesVenta
GO

create view dbo.vwCfdiSopTransaccionesVenta
--Propósito. Obtiene las transacciones de venta SOP. 
--Utiliza:	vwRmTransaccionesTodas
--Requisitos. No muestra facturas registradas en cuentas por cobrar. 
--24/10/17 jcf Creación cfdi 3.3 
--
AS

SELECT	'contabilizado' estadoContabilizado,
		case when cn.TXRGNNUM = '' 
			then rtrim(dbo.fCfdReemplazaCaracteresNI(replace(cab.custnmbr, '-', '')))
			else rtrim(dbo.fCfdReemplazaCaracteresNI(rtrim(left(replace(cn.TXRGNNUM, '-', ''), 23))))	--loc argentina usa los 23 caracteres de la izquierda
		end idImpuestoCliente,
		cab.CUSTNMBR,
		dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(cab.CUSTNAME))), 10)	nombreCliente,
		rtrim(cab.docid) docid, cab.SOPTYPE, 
		rtrim(cab.sopnumbe) sopnumbe, 
		cab.docdate, 
		CONVERT(datetime, 
				replace(convert(varchar(20), cab.DOCDATE, 102), '.', '-')+'T'+
				case when substring(cab.DOCNCORR, 3, 1) = ':' then rtrim(LEFT(cab.docncorr, 8)) --+'.'+ right(rtrim(cab.docncorr), 3) 
				else '00:00:00' end,
				126) fechaHora,
		cab.ORDOCAMT total,														--se requieren 6 decimales fijos para generar el código de barras
		cab.ORSUBTOT + cab.ORMRKDAM subtotal, 
		cab.ORTAXAMT impuesto, cab.ORMRKDAM, cab.ORTDISAM, cab.ORMRKDAM + cab.ORTDISAM descuento, 
--		cab.docamnt total, cab.SUBTOTAL subtotal, cab.TAXAMNT impuesto, cab.trdisamt descuento,
		cab.orpmtrvd, rtrim(mo.isocurrc) curncyid, 
		case when cab.xchgrate <= 0 then 1 else cab.xchgrate end xchgrate, 
		cab.voidStts + isnull(rmx.voidstts, 0) voidstts, rmx.montoActualOriginal,
		dbo.fCfdEsVacio(dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(cab.address1), 10)) address1, 
		dbo.fCfdEsVacio(dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(cab.address2), 10)) address2, 
		dbo.fCfdEsVacio(dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(cab.address3), 10)) address3, 
		dbo.fCfdEsVacio(dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(cab.city), 10)) city, 
		dbo.fCfdEsVacio(dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(cab.[STATE]), 10)) [state], 
		dbo.fCfdEsVacio(dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(cab.country), 10)) country, 
		right('00000'+dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(cab.zipcode), 10), 5) zipcode, 
		cab.duedate, cab.pymtrmid, cab.glpostdt, 
		dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(cab.cstponbr), 10) cstponbr,
		da.USRDEF05
  from	sop30200 cab							--sop_hdr_hist
		inner join vwCfdIdDocumentos id
			on id.docid = cab.DOCID
        left outer join RM00101 cn				--rm_customer_mstr
			on cn.CUSTNMBR = cab.CUSTNMBR
		left outer join vwRmTransaccionesTodas rmx
             ON rmx.RMDTYPAL in (1, 8)			-- 1 invoice, 8 return
            and rmx.bchsourc = 'Sales Entry'	-- incluye sop
            and (cab.sopType-2 = rmx.rmdTypAl or cab.sopType+4 = rmx.rmdTypAl) --elimina la posibilidad de repetidos
            and cab.sopnumbe = rmx.DOCNUMBR
		OUTER APPLY dbo.fCfdiDatosAdicionales(cab.soptype, cab.sopnumbe) da
		left outer join dynamics..mc40200 mo
			on mo.CURNCYID = cab.curncyid
 where cab.soptype in (3, 4)					--3 invoice, 4 return
 union all
 select 'en lote' estadoContabilizado, cab.custnmbr idImpuestoCliente, cab.CUSTNMBR, cab.CUSTNAME nombreCliente,
		rtrim(cab.docid) docid, cab.SOPTYPE, rtrim(cab.sopnumbe) sopnumbe, 
		cab.docdate, cab.docdate fechaHora,
		cab.ORDOCAMT total, cab.ORSUBTOT subtotal, cab.ORTAXAMT impuesto, 0, cab.ORTDISAM, cab.ORTDISAM descuento, 
		cab.orpmtrvd, rtrim(cab.curncyid) curncyid, 
		cab.xchgrate, 
		cab.voidStts, cab.ORDOCAMT, 
		cab.address1, cab.address2, cab.address3, cab.city, cab.[STATE], cab.country, cab.zipcode, 
		cab.duedate, cab.pymtrmid, cab.glpostdt, 
		cab.cstponbr,
		ctrl.USRDEF05
 from  SOP10100 cab								--sop_hdr_work
		inner join vwCfdIdDocumentos id
			on id.docid = cab.DOCID
        left outer join SOP10106 ctrl			--campos def. por el usuario.
            on ctrl.SOPTYPE = cab.SOPTYPE
            and ctrl.SOPNUMBE = cab.SOPNUMBE
 where cab.SOPTYPE in (3, 4)					--3 invoice, 4 return
go

IF (@@Error = 0) PRINT 'Creación exitosa de: vwCfdiSopTransaccionesVenta'
ELSE PRINT 'Error en la creación de: vwCfdiSopTransaccionesVenta'
GO

-------------------------------------------------------------------------------------------------------
--select isocurrc, curncyid, *
--from dynamics..mc40200
--use dynamics;
