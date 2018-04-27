--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiRelacionados') IS NOT NULL
   DROP FUNCTION dbo.fCfdiRelacionados
GO

create function dbo.fCfdiRelacionados(@soptype smallint, @p_sopnumbe varchar(21))
returns table
as
--Prop�sito. Obtiene la relaci�n con otros documentos. 
--		Si la factura relaciona a otra factura o nd, consultar el tracking number
--Requisito. 
--24/10/17 jcf Creaci�n
--
return(
			--ND relaciona a factura
			select 1 orden,	
				cmpr.tipo tipoDocumento,
				da.soptype soptypeTo, left(da.tracking_number, 5) + convert(varchar(10), sg.segmento2) sopnumbeTo,
				da.soptype soptypeFrom, da.sopnumbe sopnumbeFrom
			from sop10107 da	--
				outer apply dbo.fCfdiObtieneSegmento2(rtrim(da.tracking_number), '-') sg
				cross apply dbo.fLcLvComprobanteSunat (da.soptype, left(da.tracking_number, 5) + right('0000000'+convert(varchar(10), sg.segmento2), 8))  cmpr
			where da.sopnumbe = @p_sopnumbe
			and da.soptype = @soptype
			and @soptype = 3

			union all

			--NC o devoluci�n que relaciona a factura o nd
			SELECT 2 orden,
				cmpr.tipo tipoDocumento,
				3 soptypeTo, left(ap.aptodcnm, 5) + convert(varchar(10), sg.segmento2) sopnumbeTo,
				@soptype soptypeFrom, ap.apfrdcnm sopnumbeFrom
			from dbo.vwRmTrxAplicadas  ap
				cross apply dbo.fLcLvComprobanteSunat (3, ap.aptodcnm)  cmpr
				outer apply dbo.fCfdiObtieneSegmento2(rtrim(ap.aptodcnm), '-') sg
			where ap.APFRDCTY = @soptype+4										--tipo nc es 8 en AR
			AND ap.apfrdcnm = @p_sopnumbe
			and @soptype = 4
)	
go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de: fCfdiRelacionados()'
ELSE PRINT 'Error en la creaci�n de: fCfdiRelacionados()'
GO

--------------------------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiRelacionados', 'V') IS NULL)
   exec('create view dbo.vwCfdiRelacionados as SELECT 1 as t');
go

alter view dbo.vwCfdiRelacionados
as

select rel.orden, rel.tipoDocumento, rel.soptypeFrom, rel.sopnumbeFrom, rel.soptypeTo, upper(rel.sopnumbeTo) sopnumbeTo
from sop30200 sop
	cross apply dbo.fCfdiRelacionados(sop.soptype, sop.sopnumbe) rel


go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: vwCfdiRelacionados ()'
ELSE PRINT 'Error en la creaci�n de la funci�n: vwCfdiRelacionados ()'
GO

--------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------

--select *
--from dbo.fCfdiObtieneSegmento2('FF-01', '-')

--			SELECT 2 orden,
--				cmpr.tipo tipoDocumento,
--				3 soptypeTo, ap.aptodcnm, left(ap.aptodcnm, 5)+ convert(varchar(10), sg.segmento2) sopnumbeTo,
--				--@soptype soptypeFrom, 
--				ap.apfrdcnm sopnumbeFrom
--			from dbo.vwRmTrxAplicadas  ap
--				cross apply dbo.fLcLvComprobanteSunat (3, ap.aptodcnm)  cmpr
--				outer apply dbo.fCfdiObtieneSegmento2(rtrim(ap.aptodcnm), '-') sg
