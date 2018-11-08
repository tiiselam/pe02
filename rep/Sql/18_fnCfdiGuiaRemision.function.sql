IF OBJECT_ID ('dbo.fnCfdiGuiaRemision') IS NOT NULL
   DROP FUNCTION dbo.fnCfdiGuiaRemision
GO

create function dbo.fnCfdiGuiaRemision(@SOPTYPE smallint, @SOPNUMBE varchar(21), @indicador smallint)
returns table
as
--Prop�sito. Obtiene la gu�a de remisi�n
--04/06/18 jcf Creaci�n 
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

IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: fnCfdiGuiaRemision()'
ELSE PRINT 'Error en la creaci�n de la funci�n: fnCfdiGuiaRemision()'
GO

