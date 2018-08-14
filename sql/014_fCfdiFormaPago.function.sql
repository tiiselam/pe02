IF OBJECT_ID ('dbo.fCfdiFormaPagoSimultaneo') IS NOT NULL
   DROP FUNCTION dbo.fCfdiFormaPagoSimultaneo
GO

create function dbo.fCfdiFormaPagoSimultaneo(@chekbkid varchar(15), @pymttype smallint, @cardname varchar(15), @longCodigoFormaPago int)
returns table
--Propósito. Obtiene la forma de pago de un cobro simultáneo con la factura.
--24/10/17 jcf Creación
--09/05/18 jcf Corrige medio de pago vía tarjeta de crédito
--13/08/18 jcf Ajusta códigos de forma de pago de acuerdo a sunat
--
as
return(
	select cm.chekbkid, 
		case when left(UPPER(cm.locatnid), 2) = 'CB' then	--CB representa una cuenta bancaria
 			case @pymttype 
 				when 4 then '1'				--efectivo
 				when 5 then '3'				--cheque
 				when 6 then left(@cardname, @longCodigoFormaPago)	--tarjeta
				else null 
			end
			else									--representa un medio de pago
 				left(Rtrim(cm.locatnid), @longCodigoFormaPago)
		end	FormaPago
	from CM00100 cm
	where cm.chekbkid = @chekbkid
	union all
	select top(1) @chekbkid,  
			case @pymttype 
 				when 6 then left(@cardname, @longCodigoFormaPago)	--tarjeta
				else null 
			end
	from CM00100 cm
	where @chekbkid = ''
	)
go
IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiFormaPagoSimultaneo()'
ELSE PRINT 'Error en la creación de: fCfdiFormaPagoSimultaneo()'
GO
--------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.fCfdiFormaPagoManual') IS NOT NULL
   DROP FUNCTION dbo.fCfdiFormaPagoManual
GO

create function dbo.fCfdiFormaPagoManual(@chekbkid varchar(15), @CSHRCTYP smallint, @FRTSCHID varchar(15), @longCodigoFormaPago int)
returns table
--Propósito. Obtiene la forma de pago de un recibo de cobro
--24/10/17 jcf Creación
--09/05/18 jcf Corrige medio de pago vía tarjeta de crédito
--13/08/18 jcf Ajusta códigos de forma de pago de acuerdo a sunat
--
as
return(
	select cm.chekbkid, 
			case when left(UPPER(cm.locatnid), 2) = 'CB' then	--ch representa una cuenta bancaria
 				case @CSHRCTYP  
 					when 0 then '3'					--cheque
 					when 1 then '1'					--efectivo
 					when 2 then left(@FRTSCHID, @longCodigoFormaPago)
					else null 
				end
				else									--representa un medio de pago
 					left(Rtrim(cm.locatnid), @longCodigoFormaPago)
			end	FormaPago	
	from CM00100 cm
	where cm.chekbkid = @chekbkid
	union all
	select top(1) @chekbkid,  
			case @CSHRCTYP 
 				when 2 then left(@FRTSCHID, @longCodigoFormaPago)	--tarjeta
				else null 
			end
	from CM00100 cm
	where @chekbkid = ''
)
go
IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiFormaPagoManual()'
ELSE PRINT 'Error en la creación de: fCfdiFormaPagoManual()'
GO
--------------------------------------------------------------------------------------------------------

