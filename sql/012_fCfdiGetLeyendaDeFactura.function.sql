IF OBJECT_ID ('dbo.fCfdiGetLeyendaDeFactura') IS NOT NULL
   DROP FUNCTION dbo.fCfdiGetLeyendaDeFactura
GO

create function dbo.fCfdiGetLeyendaDeFactura(@SOPNUMBE char(21), @DOCTYPE smallint, @tipo varchar(2))
returns table
as
--Prop�sito. Obtiene la leyenda de una factura
--Requisitos. -
--03/05/19 jcf Creaci�n
--
return
(
	select memo 
	from [INT_SOPHDR]
	where sopnumbe = @SOPNUMBE
	and soptype = @DOCTYPE
)

go


IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: fCfdiGetLeyendaDeFactura()'
ELSE PRINT 'Error en la creaci�n de la funci�n: fCfdiGetLeyendaDeFactura()'
GO
