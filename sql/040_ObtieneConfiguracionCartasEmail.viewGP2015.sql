/****** Object:  Table [dbo].[CN00700]    Script Date: 04/25/2012 11:13:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO

--Si no está instalado Collections, crear la tabla de cartas
IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[CN00700]') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	CREATE TABLE [dbo].[CN00700](
		[Letter_Type] [smallint] NOT NULL,
		[LTRRPTNM] [char](31) NOT NULL,
		[LTRDESC] [char](51) NOT NULL,
		[Hide_in_lookup] [tinyint] NOT NULL,
		[CN_Print_Using_Report] [char](31) NOT NULL,
		[Action_Promised] [char](17) NOT NULL,
		[CN_Email_Subject] [char](81) NOT NULL,
		[CN_Word_Letter] [tinyint] NOT NULL,
		[CN_Word_Document_File] [char](255) NOT NULL,
		[CN_LetterPerAddress] [tinyint] NOT NULL,
		[DEX_ROW_ID] [int] IDENTITY(1,1) NOT NULL,
		[CN_Letter_Text] [text] NOT NULL,
	 CONSTRAINT [PKCN00700] PRIMARY KEY CLUSTERED 
	(
		[Letter_Type] ASC,
		[LTRRPTNM] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
end
GO

SET ANSI_PADDING OFF
GO
----------------------------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwCfdCartasReclamacionDeuda]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.vwCfdCartasReclamacionDeuda;
GO

create view dbo.vwCfdCartasReclamacionDeuda as
--Propósito. Configura el asunto y detalle del email.
--Utilizado por. Factura electrónica
--31/01/11 jcf Creación 
--
select letter_type, ltrrptnm, ltrdesc, 
	CN_Email_Subject, CN_Letter_Text,
	CN_Word_Letter, CN_Word_Document_File
from CN00700	
go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdCartasReclamacionDeuda'
ELSE PRINT 'Error en la creación de la vista: vwCfdCartasReclamacionDeuda'
GO

---------------------------------------------------------------------------------------------------------
	delete from cn00700 where ltrrptnm = 'FACTURA_ELECTRONICA';

	insert into cn00700(Letter_Type,
	LTRRPTNM,
	LTRDESC,
	Hide_in_lookup,
	CN_Print_Using_Report,
	Action_Promised,
	CN_Email_Subject,
	CN_Word_Letter,
	CN_Word_Document_File,
	CN_Letter_Text, 
	CN_LetterPerAddress
	)
	values(3, 'FACTURA_ELECTRONICA', 'Carta para enviar factura electrónica', 0, '', '', 'MTP - ', 0, '', 
	'Estimado cliente,' +  char(10) +  char(10) 
+	'Enviamos la factura correspondiente a los servicios prestados.' +  char(10) +  char(10) 
+	'Atentamente,' +  char(10) 
+	'Mexico Tower Partners'
	, ''
	);

	PRINT 'Creación exitosa del parámetro: FACTURA_ELECTRONICA';


--select * from vwCfdCartasReclamacionDeuda
