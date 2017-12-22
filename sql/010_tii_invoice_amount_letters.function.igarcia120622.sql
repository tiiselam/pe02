/****** Object:  UserDefinedFunction [dbo].[TII_INVOICE_AMOUNT_LETTERS]    Script Date: 06/22/2012 09:08:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID ('dbo.TII_INVOICE_AMOUNT_LETTERS') IS NOT NULL
   DROP FUNCTION dbo.TII_INVOICE_AMOUNT_LETTERS
GO

--14/9/15 jcf Agrega parámetros moneda
--
create FUNCTION [dbo].[TII_INVOICE_AMOUNT_LETTERS] 
(
@Numero NUMERIC(20,2),
@moneda varchar(20) = ''
)
RETURNS varchar(2000)
AS
BEGIN
DECLARE @lnEntero INT,
@lcRetorno VARCHAR(512),
@lnTerna INT,
@lcMiles VARCHAR(512),
@lcCadena VARCHAR(512),
@lnUnidades INT,
@lnDecenas INT,
@lnCentenas INT,
@lnFraccion INT
SELECT @lnEntero = CAST(@Numero AS INT),
@lnFraccion = (@Numero - @lnEntero) * 100,
@lcRetorno = '',
@lnTerna = 1
WHILE @lnEntero > 0
BEGIN 
SELECT @lcCadena = ''
SELECT @lnUnidades = @lnEntero % 10
SELECT @lnEntero = CAST(@lnEntero/10 AS INT)
SELECT @lnDecenas = @lnEntero % 10
SELECT @lnEntero = CAST(@lnEntero/10 AS INT)
SELECT @lnCentenas = @lnEntero % 10
SELECT @lnEntero = CAST(@lnEntero/10 AS INT)
-- Unidades
SELECT @lcCadena =
CASE
WHEN @lnUnidades = 1 AND @lnTerna = 1 THEN 'Uno ' + @lcCadena
WHEN @lnUnidades = 1 AND @lnTerna <> 1 THEN 'Un ' + @lcCadena
WHEN @lnUnidades = 2 THEN 'Dos ' + @lcCadena
WHEN @lnUnidades = 3 THEN 'Tres ' + @lcCadena
WHEN @lnUnidades = 4 THEN 'Cuatro ' + @lcCadena
WHEN @lnUnidades = 5 THEN 'Cinco ' + @lcCadena
WHEN @lnUnidades = 6 THEN 'Seis ' + @lcCadena
WHEN @lnUnidades = 7 THEN 'Siete ' + @lcCadena
WHEN @lnUnidades = 8 THEN 'Ocho ' + @lcCadena
WHEN @lnUnidades = 9 THEN 'Nueve ' + @lcCadena
ELSE @lcCadena
END
-- decenas
SELECT @lcCadena =
CASE
WHEN @lnDecenas = 1 THEN
CASE @lnUnidades
WHEN 0 THEN 'Diez '
WHEN 1 THEN 'Once '
WHEN 2 THEN 'Doce '
WHEN 3 THEN 'Trece '
WHEN 4 THEN 'Catorce '
WHEN 5 THEN 'Quince '
ELSE 'Dieci' + @lcCadena
END
WHEN @lnDecenas = 2 AND @lnUnidades = 0 THEN 'Veinte ' + @lcCadena
WHEN @lnDecenas = 2 AND @lnUnidades <> 0 THEN 'Veinti' + @lcCadena
WHEN @lnDecenas = 3 AND @lnUnidades = 0 THEN 'Treinta ' + @lcCadena
WHEN @lnDecenas = 3 AND @lnUnidades <> 0 THEN 'Treinta y ' + @lcCadena
WHEN @lnDecenas = 4 AND @lnUnidades = 0 THEN 'Cuarenta ' + @lcCadena
WHEN @lnDecenas = 4 AND @lnUnidades <> 0 THEN 'Cuarenta y ' + @lcCadena
WHEN @lnDecenas = 5 AND @lnUnidades = 0 THEN 'Cincuenta ' + @lcCadena
WHEN @lnDecenas = 5 AND @lnUnidades <> 0 THEN 'Cincuenta y ' + @lcCadena
WHEN @lnDecenas = 6 AND @lnUnidades = 0 THEN 'Sesenta ' + @lcCadena
WHEN @lnDecenas = 6 AND @lnUnidades <> 0 THEN 'Sesenta y ' + @lcCadena
WHEN @lnDecenas = 7 AND @lnUnidades = 0 THEN 'Setenta ' + @lcCadena
WHEN @lnDecenas = 7 AND @lnUnidades <> 0 THEN 'Setenta Y ' + @lcCadena
WHEN @lnDecenas = 8 AND @lnUnidades = 0 THEN 'Ochenta ' + @lcCadena
WHEN @lnDecenas = 8 AND @lnUnidades <> 0 THEN 'Ochenta y ' + @lcCadena
WHEN @lnDecenas = 9 AND @lnUnidades = 0 THEN 'Noventa ' + @lcCadena
WHEN @lnDecenas = 9 AND @lnUnidades <> 0 THEN 'Noventa y ' + @lcCadena
ELSE @lcCadena
END
-- centenas
SELECT @lcCadena =
CASE
WHEN @lnCentenas = 1 AND @lnUnidades = 0 AND @lnDecenas = 0 THEN 'Cien ' + @lcCadena
WHEN @lnCentenas = 1 AND NOT(@lnUnidades = 0 AND @lnDecenas = 0) THEN 'Ciento ' + @lcCadena
WHEN @lnCentenas = 2 THEN 'Doscientos ' + @lcCadena
WHEN @lnCentenas = 3 THEN 'Trescientos ' + @lcCadena
WHEN @lnCentenas = 4 THEN 'Cuatrocientos ' + @lcCadena
WHEN @lnCentenas = 5 THEN 'Quinientos ' + @lcCadena
WHEN @lnCentenas = 6 THEN 'Seiscientos ' + @lcCadena
WHEN @lnCentenas = 7 THEN 'Setecientos ' + @lcCadena
WHEN @lnCentenas = 8 THEN 'Ochocientos ' + @lcCadena
WHEN @lnCentenas = 9 THEN 'Novecientos ' + @lcCadena
ELSE @lcCadena
END
--Terna
SELECT @lcCadena =
CASE
WHEN @lnTerna = 1 THEN @lcCadena
WHEN @lnTerna = 2 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) THEN @lcCadena + ' Mil '
WHEN @lnTerna = 3 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) AND
@lnUnidades = 1 AND @lnDecenas = 0 AND @lnCentenas = 0 THEN @lcCadena + ' Millon '
WHEN @lnTerna = 3 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) AND
NOT (@lnUnidades = 1 AND @lnDecenas = 0 AND @lnCentenas = 0) THEN @lcCadena + ' Millones '
WHEN @lnTerna = 4 AND (@lnUnidades + @lnDecenas + @lnCentenas <> 0) THEN @lcCadena + ' Mil Millones '
ELSE ''
END
--Armo el retorno terna a terna
SELECT @lcRetorno = @lcCadena + @lcRetorno
SELECT @lnTerna = @lnTerna + 1
END
IF @lnTerna = 1
SELECT @lcRetorno = 'Cero'
--RETURN RTRIM(@lcRetorno) + ' Con ' + LTRIM(STR(@lnFraccion,2)) + '/100'
RETURN RTRIM(@lcRetorno) + ' ' + @moneda + RIGHT(RTRIM(('0' + LTRIM(STR(@lnFraccion,2)))),2) + '/100'
END


GO


