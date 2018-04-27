IF OBJECT_ID ('dbo.fCfdiObtieneUUID') IS NOT NULL
   DROP FUNCTION dbo.fCfdiObtieneUUID
GO

create function dbo.fCfdiObtieneUUID(@soptype smallint, @sopnumbe varchar(21))
returns table
as
--Prop�sito. Devuelve el UUID de un cfdi
--Requisitos. 
--13/10/17 jcf Creaci�n 
--
return
(
	select tv.docid, dx.uuid, tv.voidstts, dx.FormaPago
	from vwCfdiSopTransaccionesVenta tv
		left join cfdlogfacturaxml lf
			on lf.soptype = tv.SOPTYPE
			and lf.sopnumbe = tv.sopnumbe
			and lf.estado = 'emitido'
		outer apply dbo.fCfdiDatosXmlParaImpresion(lf.archivoXML) dx
	where tv.soptype = @soptype
	and tv.sopnumbe = @sopnumbe
)
go


IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: fCfdiObtieneUUID()'
ELSE PRINT 'Error en la creaci�n de la funci�n: fCfdiObtieneUUID()'
GO

-------------------------------------------------------------------------------------------------------------
--select *
--from dbo.fCfdiObtieneUUID(3, '00000002')

