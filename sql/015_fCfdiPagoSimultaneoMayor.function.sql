IF OBJECT_ID ('dbo.fCfdiPagoSimultaneoMayor') IS NOT NULL
   DROP FUNCTION dbo.fCfdiPagoSimultaneoMayor
GO

create function dbo.fCfdiPagoSimultaneoMayor(@soptype smallint, @sopnumbe varchar(21), @longCodigoFormaPago int)
returns table
--Prop�sito. Obtiene la forma de pago del pago m�s grande. Este pago ha sido ingresado simult�neamente con la factura.
--24/10/17 jcf Creaci�n
--13/08/18 jcf Agrega @longCodigoFormaPago
--
as
return(
	select top (1) cm.FormaPago
	from sop10103 py
	outer apply dbo.fCfdiFormaPagoSimultaneo(py.chekbkid, py.pymttype, py.cardname, @longCodigoFormaPago) cm
	where py.soptype = @soptype
	and py.sopnumbe = @sopnumbe
	order by py.oamtpaid desc
)

go
IF (@@Error = 0) PRINT 'Creaci�n exitosa de: fCfdiPagoSimultaneoMayor()'
ELSE PRINT 'Error en la creaci�n de: fCfdiPagoSimultaneoMayor()'
GO
--------------------------------------------------------------------------------------------------------

