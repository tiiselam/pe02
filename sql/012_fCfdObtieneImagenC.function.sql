--Prop�sito. dummy para que funcione la vista de impresi�n de factura. Crear el correcto cuando se requiera
--19/10/16 jcf Creaci�n
IF OBJECT_ID (N'dbo.fCfdObtieneImagenC') IS NOT NULL
   DROP FUNCTION dbo.fCfdObtieneImagenC
GO

CREATE FUNCTION dbo.fCfdObtieneImagenC(@Url nvarchar(4000)) RETURNS varbinary(max)
AS 
begin
return (null); 
end
go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de: fCfdObtieneImagenC'
ELSE PRINT 'Error en la creaci�n de: fCfdObtieneImagenC'
GO