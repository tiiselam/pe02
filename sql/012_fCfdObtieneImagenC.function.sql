--Propósito. dummy para que funcione la vista de impresión de factura. Crear el correcto cuando se requiera
--19/10/16 jcf Creación
IF OBJECT_ID (N'dbo.fCfdObtieneImagenC') IS NOT NULL
   DROP FUNCTION dbo.fCfdObtieneImagenC
GO

CREATE FUNCTION dbo.fCfdObtieneImagenC(@Url nvarchar(4000)) RETURNS varbinary(max)
AS 
begin
return (null); 
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdObtieneImagenC'
ELSE PRINT 'Error en la creación de: fCfdObtieneImagenC'
GO