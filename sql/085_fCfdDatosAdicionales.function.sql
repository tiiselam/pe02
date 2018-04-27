--------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.fCfdiDatosAdicionales') IS NOT NULL
   DROP FUNCTION dbo.fCfdiDatosAdicionales
GO

create function dbo.fCfdiDatosAdicionales(@soptype smallint, @sopnumbe varchar(21))
returns table
as
--Prop�sito. Devuelve datos adicionales de la factura
--Requisitos. -
--24/10/17 jcf Creaci�n cfdi
--
return
( 
	select ctrl.USRDEF05, ctrl.usrtab01, ctrl.comment_1
	from SOP10106 ctrl					--campos def. por el usuario.
	where ctrl.soptype = @soptype
	and ctrl.sopnumbe = @sopnumbe
)
go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: fCfdiDatosAdicionales()'
ELSE PRINT 'Error en la creaci�n de la funci�n: fCfdiDatosAdicionales()'
GO
--------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.fCfdiUofM') IS NOT NULL
   DROP FUNCTION dbo.fCfdiUofM
GO

create function dbo.fCfdiUofM(@UOMSCHDL varchar(11), @UOFM varchar(9))
returns table
as
--Prop�sito. Obtiene la descripci�n larga de la unidad de medida 
--Requisitos. 
--02/08/12 jcf Creaci�n 
--
return
( 
	select UOFMLONGDESC
	from iv40202	--unidades de medida [UOMSCHDL SEQNUMBR]
	WHERE UOMSCHDL = @UOMSCHDL
	and UOFM = @UOFM 
)
go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de la funci�n: fCfdiUofM()'
ELSE PRINT 'Error en la creaci�n de la funci�n: fCfdiUofM()'
GO

------------------------------------------------------------------------------------------
--select *
--from dbo.fCfdiDatosAdicionales(0, 3, 'FV A0001-00000016', 'C0004', 'PRINCIPAL')

