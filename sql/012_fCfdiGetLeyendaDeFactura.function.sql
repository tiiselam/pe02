IF OBJECT_ID ('dbo.fCfdiGetLeyendaDeFactura') IS NOT NULL
   DROP FUNCTION dbo.fCfdiGetLeyendaDeFactura
GO

create function dbo.fCfdiGetLeyendaDeFactura(@SOPNUMBE char(21), @DOCTYPE smallint, @tipo varchar(2))
returns table
as
--Propósito. Obtiene la leyenda de una factura
--Requisitos. -
--03/05/19 jcf Creación
--
return
(
	select memo 
	from [INT_SOPHDR]
	where sopnumbe = @SOPNUMBE
	and soptype = @DOCTYPE
)

go


IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiGetLeyendaDeFactura()'
ELSE PRINT 'Error en la creación de la función: fCfdiGetLeyendaDeFactura()'
GO
