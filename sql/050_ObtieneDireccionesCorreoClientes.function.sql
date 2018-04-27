--=========================================================
-- Propósito. Obtiene las direcciones de correo del cliente
-- 25/01/11 jcf Creación
--=========================================================
IF OBJECT_ID (N'dbo.fnCfdGetDireccionesCorreo') IS NOT NULL
   DROP FUNCTION dbo.fnCfdGetDireccionesCorreo
GO

CREATE FUNCTION dbo.fnCfdGetDireccionesCorreo(@custnmbr char(15))
RETURNS @DireccionesCorreo TABLE 
(
    emailTo nvarchar(max) NOT NULL,
    emailCC nvarchar(max) NOT NULL,
    emailCCO nvarchar(max) NOT NULL
)
AS
-- Propósito. Obtiene las direcciones de correo del cliente
-- 25/01/11 jcf Creación
BEGIN

	declare @emailTo nvarchar(max), @emailCC nvarchar(max), @emailCCO nvarchar(max);
	select @emailTo = '', @emailCC = '', @emailCCO = '';

	select @emailTo = @emailTo + case when Email_Type = 1 then ',' + rtrim(Email_Recipient) else '' end,
			@emailCC = @emailCC + case when Email_Type = 2 then ',' + rtrim(Email_Recipient) else '' end,
			@emailCCO = @emailCCO + case when Email_Type = 3 then ',' + rtrim(Email_Recipient) else '' end
	from rm00106	--rmStmtEmailAddrs 1:To, 2:CC, 3:CCO
	where custnmbr = @custnmbr	--'003098841'
	order by Email_Type;

   INSERT @DireccionesCorreo (emailTo, emailCC, emailCCO) values(@emailTo, @emailCC, @emailCCO);
   RETURN
END
GO

IF (@@Error = 0) PRINT 'Creación exitosa de: fnCfdGetDireccionesCorreo'
ELSE PRINT 'Error en la creación de: fnCfdGetDireccionesCorreo'
GO
-----------------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwCfdClienteDireccionesCorreo]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.[vwCfdClienteDireccionesCorreo];
GO

create view dbo.vwCfdClienteDireccionesCorreo as
select ms.CUSTNMBR, dc.emailTo, dc.emailCC, dc.emailCCO
from rm00101 ms
cross apply (select emailTo, emailCC, emailCCO 
			from dbo.fnCfdGetDireccionesCorreo(ms.CUSTNMBR)) dc
go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdClienteDireccionesCorreo'
ELSE PRINT 'Error en la creación de la vista: vwCfdClienteDireccionesCorreo'
GO
-----------------------------------------------------------------------------------------------------

