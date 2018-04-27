/****** Object:  StoredProcedure [proc_cfdLogFacturaXMLLoadByPrimaryKey]    Script Date: 25/01/2011 06:17:43 p.m. ******/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[proc_cfdLogFacturaXMLLoadByPrimaryKey]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
    DROP PROCEDURE dbo.[proc_cfdLogFacturaXMLLoadByPrimaryKey];
GO

create PROCEDURE dbo.[proc_cfdLogFacturaXMLLoadByPrimaryKey]
(
	@soptype smallint,
	@sopnumbe varchar(21),
	@secuencia int
)
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @Err int

	SELECT
		[soptype],
		[sopnumbe],
		[secuencia],
		[mensaje],
		[estado],
		[noAprobacion],
		[fechaEmision],
		[idUsuario],
		[fechaAnulacion],
		[idUsuarioAnulacion],
		[archivoXML],
		[estadoActual],
		[mensajeEA]
	FROM [cfdLogFacturaXML]
	WHERE
		([soptype] = @soptype) AND
		([sopnumbe] = @sopnumbe) AND
		([secuencia] = @secuencia)

	SET @Err = @@Error

	RETURN @Err
END
GO


-- Display the status of Proc creation
IF (@@Error = 0) PRINT 'Procedure Creation: proc_cfdLogFacturaXMLLoadByPrimaryKey Succeeded'
ELSE PRINT 'Procedure Creation: proc_cfdLogFacturaXMLLoadByPrimaryKey Error on Creation'
GO

/****** Object:  StoredProcedure [proc_cfdLogFacturaXMLLoadAll]    Script Date: 25/01/2011 06:17:43 p.m. ******/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[proc_cfdLogFacturaXMLLoadAll]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
    DROP PROCEDURE dbo.[proc_cfdLogFacturaXMLLoadAll];
GO

create PROCEDURE dbo.[proc_cfdLogFacturaXMLLoadAll]
AS
BEGIN

	SET NOCOUNT ON
	DECLARE @Err int

	SELECT
		[soptype],
		[sopnumbe],
		[secuencia],
		[mensaje],
		[estado],
		[noAprobacion],
		[fechaEmision],
		[idUsuario],
		[fechaAnulacion],
		[idUsuarioAnulacion],
		[archivoXML],
		[estadoActual],
		[mensajeEA]
	FROM [cfdLogFacturaXML]

	SET @Err = @@Error

	RETURN @Err
END
GO


-- Display the status of Proc creation
IF (@@Error = 0) PRINT 'Procedure Creation: proc_cfdLogFacturaXMLLoadAll Succeeded'
ELSE PRINT 'Procedure Creation: proc_cfdLogFacturaXMLLoadAll Error on Creation'
GO

/****** Object:  StoredProcedure [proc_cfdLogFacturaXMLUpdate]    Script Date: 25/01/2011 06:17:43 p.m. ******/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[proc_cfdLogFacturaXMLUpdate]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
    DROP PROCEDURE dbo.[proc_cfdLogFacturaXMLUpdate];
GO

create PROCEDURE dbo.[proc_cfdLogFacturaXMLUpdate]
(
	@soptype smallint,
	@sopnumbe varchar(21),
	@secuencia int,
	@mensaje varchar(255),
	@estado varchar(20),
	@noAprobacion varchar(21),
	@fechaEmision datetime,
	@idUsuario varchar(10),
	@fechaAnulacion datetime,
	@idUsuarioAnulacion varchar(10),
	@archivoXML xml = NULL,
	@estadoActual varchar(20) = NULL,
	@mensajeEA varchar(255) = NULL
)
AS
BEGIN

	SET NOCOUNT OFF
	DECLARE @Err int

	UPDATE [cfdLogFacturaXML]
	SET
		[mensaje] = @mensaje,
		[estado] = @estado,
		[noAprobacion] = @noAprobacion,
		[fechaEmision] = @fechaEmision,
		[idUsuario] = @idUsuario,
		[fechaAnulacion] = @fechaAnulacion,
		[idUsuarioAnulacion] = @idUsuarioAnulacion,
		[archivoXML] = @archivoXML,
		[estadoActual] = @estadoActual,
		[mensajeEA] = @mensajeEA
	WHERE
		[soptype] = @soptype
	AND	[sopnumbe] = @sopnumbe
	AND	[secuencia] = @secuencia


	SET @Err = @@Error


	RETURN @Err
END
GO


-- Display the status of Proc creation
IF (@@Error = 0) PRINT 'Procedure Creation: proc_cfdLogFacturaXMLUpdate Succeeded'
ELSE PRINT 'Procedure Creation: proc_cfdLogFacturaXMLUpdate Error on Creation'
GO




/****** Object:  StoredProcedure [proc_cfdLogFacturaXMLInsert]    Script Date: 25/01/2011 06:17:43 p.m. ******/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[proc_cfdLogFacturaXMLInsert]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
    DROP PROCEDURE dbo.[proc_cfdLogFacturaXMLInsert];
GO

create PROCEDURE dbo.[proc_cfdLogFacturaXMLInsert]
(
	@soptype smallint,
	@sopnumbe varchar(21),
	@secuencia int = NULL output,
	@mensaje varchar(255),
	@estado varchar(20),
	@noAprobacion varchar(21),
	@fechaEmision datetime,
	@idUsuario varchar(10),
	@fechaAnulacion datetime,
	@idUsuarioAnulacion varchar(10),
	@archivoXML xml = NULL,
	@estadoActual varchar(20) = NULL,
	@mensajeEA varchar(255) = NULL
)
AS
BEGIN

	SET NOCOUNT OFF
	DECLARE @Err int

	INSERT
	INTO [cfdLogFacturaXML]
	(
		[soptype],
		[sopnumbe],
		[mensaje],
		[estado],
		[noAprobacion],
		[fechaEmision],
		[idUsuario],
		[fechaAnulacion],
		[idUsuarioAnulacion],
		[archivoXML],
		[estadoActual],
		[mensajeEA]
	)
	VALUES
	(
		@soptype,
		@sopnumbe,
		@mensaje,
		@estado,
		@noAprobacion,
		@fechaEmision,
		@idUsuario,
		@fechaAnulacion,
		@idUsuarioAnulacion,
		@archivoXML,
		@estadoActual,
		@mensajeEA
	)

	SET @Err = @@Error

	SELECT @secuencia = SCOPE_IDENTITY()

	RETURN @Err
END
GO


-- Display the status of Proc creation
IF (@@Error = 0) PRINT 'Procedure Creation: proc_cfdLogFacturaXMLInsert Succeeded'
ELSE PRINT 'Procedure Creation: proc_cfdLogFacturaXMLInsert Error on Creation'
GO

/****** Object:  StoredProcedure [proc_cfdLogFacturaXMLDelete]    Script Date: 25/01/2011 06:17:43 p.m. ******/
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[proc_cfdLogFacturaXMLDelete]') AND OBJECTPROPERTY(id,N'IsProcedure') = 1)
    DROP PROCEDURE dbo.[proc_cfdLogFacturaXMLDelete];
GO

create PROCEDURE dbo.[proc_cfdLogFacturaXMLDelete]
(
	@soptype smallint,
	@sopnumbe varchar(21),
	@secuencia int
)
AS
BEGIN

	SET NOCOUNT OFF
	DECLARE @Err int

	DELETE
	FROM [cfdLogFacturaXML]
	WHERE
		[soptype] = @soptype AND
		[sopnumbe] = @sopnumbe AND
		[secuencia] = @secuencia
	SET @Err = @@Error

	RETURN @Err
END
GO


-- Display the status of Proc creation
IF (@@Error = 0) PRINT 'Procedure Creation: proc_cfdLogFacturaXMLDelete Succeeded'
ELSE PRINT 'Procedure Creation: proc_cfdLogFacturaXMLDelete Error on Creation'
GO
