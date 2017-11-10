/****** Object:  Table [dbo].[cfd_CER00100]    Script Date: 01/07/2011 19:56:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[cfd_CER00100]') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	CREATE TABLE [dbo].[cfd_CER00100](
		[ID_Certificado] [char](21) NOT NULL,
		[ruta_certificado] [char](251) NOT NULL,
		[ruta_clave] [char](251) NOT NULL,
		[contrasenia_clave] [char](31) NOT NULL,
		[fecha_vig_desde] [datetime] NOT NULL,
		[fecha_vig_hasta] [datetime] NOT NULL,
		[estado] [char](1) NOT NULL,
		[fecha_ultima_modificacio] [datetime] NOT NULL,
		[TIME1] [datetime] NOT NULL,
		[usr_ultima_modificacion] [char](21) NOT NULL,
		[DEX_ROW_ID] [int] IDENTITY(1,1) NOT NULL,
	 CONSTRAINT [PKcfd_CER00100] PRIMARY KEY NONCLUSTERED 
	(
		[ID_Certificado] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY];

	ALTER TABLE [dbo].[cfd_CER00100]  WITH CHECK ADD CHECK  ((datepart(hour,[fecha_vig_desde])=(0) AND datepart(minute,[fecha_vig_desde])=(0) AND datepart(second,[fecha_vig_desde])=(0) AND datepart(millisecond,[fecha_vig_desde])=(0)));

	ALTER TABLE [dbo].[cfd_CER00100]  WITH CHECK ADD CHECK  ((datepart(hour,[fecha_vig_hasta])=(0) AND datepart(minute,[fecha_vig_hasta])=(0) AND datepart(second,[fecha_vig_hasta])=(0) AND datepart(millisecond,[fecha_vig_hasta])=(0)));

	ALTER TABLE [dbo].[cfd_CER00100]  WITH CHECK ADD CHECK  ((datepart(hour,[fecha_ultima_modificacio])=(0) AND datepart(minute,[fecha_ultima_modificacio])=(0) AND datepart(second,[fecha_ultima_modificacio])=(0) AND datepart(millisecond,[fecha_ultima_modificacio])=(0)));

	ALTER TABLE [dbo].[cfd_CER00100]  WITH CHECK ADD CHECK  ((datepart(day,[TIME1])=(1) AND datepart(month,[TIME1])=(1) AND datepart(year,[TIME1])=(1900)));
end
go

--------------------------------------------------------------------------------------------------------------------------
IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[cfd_FOL00100]') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	CREATE TABLE [dbo].[cfd_FOL00100](
		[serie] [char](11) NOT NULL,
		[num_folio_desde] [char](21) NOT NULL,
		[num_folio_hasta] [char](21) NOT NULL,
		[numero_aprobacion] [int] NOT NULL,
		[anio_aprobacion] [smallint] NOT NULL,
		[ID_Certificado] [char](21) NOT NULL,
		[fecha_ultima_modificacio] [datetime] NOT NULL,
		[TIME1] [datetime] NOT NULL,
		[usr_ultima_modificacion] [char](21) NOT NULL,
		[DEX_ROW_ID] [int] IDENTITY(1,1) NOT NULL,
	 CONSTRAINT [PKcfd_FOL00100] PRIMARY KEY NONCLUSTERED 
	(
		[serie] ASC,
		[numero_aprobacion] ASC,
		[ID_Certificado] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY];

	ALTER TABLE [dbo].[cfd_FOL00100]  WITH CHECK ADD CHECK  ((datepart(hour,[fecha_ultima_modificacio])=(0) AND datepart(minute,[fecha_ultima_modificacio])=(0) AND datepart(second,[fecha_ultima_modificacio])=(0) AND datepart(millisecond,[fecha_ultima_modificacio])=(0)));

	ALTER TABLE [dbo].[cfd_FOL00100]  WITH CHECK ADD CHECK  ((datepart(day,[TIME1])=(1) AND datepart(month,[TIME1])=(1) AND datepart(year,[TIME1])=(1900)));
end
go

