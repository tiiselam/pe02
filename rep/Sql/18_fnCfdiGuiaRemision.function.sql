IF OBJECT_ID ('dbo.fnCfdiGuiaRemision') IS NOT NULL
   DROP FUNCTION dbo.fnCfdiGuiaRemision
GO

create function dbo.fnCfdiGuiaRemision(@SOPTYPE smallint, @SOPNUMBE varchar(21), @indicador smallint)
returns table
as
--Propósito. Obtiene la guía de remisión
--04/06/18 jcf Creación 
--
return
(  
	--select '' DOCNUMBR
	SELECT gr.DOCNUMBR
	from dbo.tblGREM001 gr
	where gr.GREMReferenciaNumb = @SOPNUMBE
	and gr.GREMReferenciaTipo = @SOPTYPE
	and gr.GREMGuiaIndicador = @indicador --GUIA DE REMISION DE FACTURA

)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fnCfdiGuiaRemision()'
ELSE PRINT 'Error en la creación de la función: fnCfdiGuiaRemision()'
GO

