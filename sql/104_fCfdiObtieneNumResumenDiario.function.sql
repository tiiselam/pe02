--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiObtieneNumResumenDiario') IS NOT NULL
   DROP FUNCTION dbo.fCfdiObtieneNumResumenDiario
GO

create function dbo.fCfdiObtieneNumResumenDiario(@tipoResumenDiario smallint, @numResumenDiario varchar(21))
returns table
as
--Propósito. Obtiene el último resumen diario aceptado o el próximo correlativo en caso de ser rechazado
--Requisito. 
--28/05/18 jcf Creación
--
return(

	select case when estadoActual like '1_1_01'  --resumen publicado y rechazado 
		then left(@numResumenDiario, 12) + right('00'+convert(varchar(5), convert(int, right(maxRD.numResumenDiario, 3))+1), 3)
		else r.sopnumbe				
		end numResumen
	from dbo.cfdLogFacturaXml r
	cross apply (
		select max(lf.sopnumbe) numResumenDiario
		from dbo.cfdlogfacturaxml lf
		where lf.soptype = @tipoResumenDiario
			and left(lf.sopnumbe, 11) = left(@numResumenDiario, 11)
			and lf.estado = 'emitido'
		) maxRD
	where r.soptype = @tipoResumenDiario
	and r.sopnumbe = maxRD.numResumenDiario
	and r.estado = 'emitido'

)	
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiObtieneNumResumenDiario()'
ELSE PRINT 'Error en la creación de: fCfdiObtieneNumResumenDiario()'
GO

