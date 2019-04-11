	-- Define Variables
	--DECLARE @ParmDefinition nvarchar(500);  
	--declare @CMPANYID smallint
	--declare @INTERID char(5)
	--declare @SQLCode NVARCHAR(4000)
	--SET @ParmDefinition = N'@CMPANYIDout smallint OUTPUT, @INTERIDout char(5) OUTPUT';  

	declare @SYSDBNAME CHAR(80)
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[SY00100]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
	 select top 1 @SYSDBNAME = DBNAME from SY00100
	else
	 set @SYSDBNAME = 'DYNAMICS'

	--set @SQLCode = N'select @CMPANYIDout = CMPANYID, @INTERIDout = INTERID from ' + rtrim(@SYSDBNAME) + '..SY01500 (nolock) where INTERID = DB_NAME()'
	--exec sp_executesql @SQLCode, @ParmDefinition, @CMPANYIDout = @CMPANYID output, @INTERIDout = @INTERID output
	
	if OBJECT_ID('dbo.synonymGPCompanyMaster') is not null
		DROP SYNONYM dbo.synonymGPCompanyMaster;
		
	EXEC ('create synonym dbo.synonymGPCompanyMaster for ' +  @SYSDBNAME+'..SY01500;');

	IF (@@Error = 0) PRINT 'Creación exitosa del synonym: synonymGPCompanyMaster'
	ELSE PRINT 'Error en la creación del synonym: synonymGPCompanyMaster'

	if OBJECT_ID('dbo.synonymGPCurrencies') is not null
		DROP SYNONYM dbo.synonymGPCurrencies;
	
	EXEC ('create synonym dbo.synonymGPCurrencies for ' +  @SYSDBNAME+'..MC40200;');
	
	IF (@@Error = 0) PRINT 'Creación exitosa del synonym: synonymGPCurrencies'
	ELSE PRINT 'Error en la creación del synonym: synonymGPCurrencies'
	GO


-----------------------------------------------------------------------------
--USE GMSER
--GO
--SELECT OBJECT_ID('dbo.synonymGPCompanyMaster')

--USE GPERU;
--GO
--		create synonym dbo.synonymGPCompanyMaster for DYNAMICS..SY01500;

--		SELECT TOP 100 *
--		FROM dbo.synonymGPCompanyMaster 

--USE GMOPE;
--GO
--		create synonym dbo.synonymGPCompanyMaster for DYNAMICS..SY01600;



--SELECT TOP 10 *
--FROM DYNAMICS..SY01600;


--SELECT *
--FROM DYNAMICS..SY01500;

