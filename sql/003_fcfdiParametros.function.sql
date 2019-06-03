IF OBJECT_ID ('dbo.fCfdiParametros') IS NOT NULL
   DROP FUNCTION dbo.fCfdiParametros
GO

create function dbo.fCfdiParametros(@tag1 varchar(17), @tag2 varchar(17), @tag3 varchar(17), @tag4 varchar(17), @tag5 varchar(17), @tag6 varchar(17), @ADRSCODE char(15) = 'MAIN')
returns table
as
--Propósito. Devuelve los parámetros de la compañía
--Requisitos. Los @tagx deben configurarse en la ventana Información de internet del id de dirección @ADRSCODE de la compañía.
--21/11/16 jcf Creación 
--14/09/17 jcf Agrega inet7 y 8
--13/10/17 jcf Agrega datos de dir PREDETERMINADO
--22/11/18 jcf Modifica para multitenant
--
return
(
	select 
		case when charindex(@tag1+'=', ia.inetinfo) > 0 and charindex(char(13), ia.inetinfo) > 0 then
			substring(ia.inetinfo, charindex(@tag1+'=', ia.inetinfo) +len(@tag1)+1, charindex(char(13), ia.inetinfo, charindex(@tag1+'=', ia.inetinfo)) - charindex(@tag1+'=', ia.inetinfo) - len(@tag1)-1) 
		else 'no existe tag: '+@tag1 end param1,
		CASE when charindex(@tag2+'=', ia.inetinfo) > 0 and  charindex(char(13), ia.inetinfo) > 0 then
			substring(ia.inetinfo, charindex(@tag2+'=', ia.inetinfo)+ len(@tag2)+1, charindex(char(13), ia.inetinfo, charindex(@tag2+'=', ia.inetinfo)) - charindex(@tag2+'=', ia.inetinfo) - len(@tag2)-1) 
		else 'no existe tag: '+@tag2 end param2,
		CASE when charindex(@tag3+'=', ia.inetinfo) > 0 and  charindex(char(13), ia.inetinfo) > 0 then
			substring(ia.inetinfo, charindex(@tag3+'=', ia.inetinfo)+ len(@tag3)+1, charindex(char(13), ia.inetinfo, charindex(@tag3+'=', ia.inetinfo)) - charindex(@tag3+'=', ia.inetinfo) - len(@tag3)-1)
		else 'no existe tag: '+@tag3 end param3,
		CASE when charindex(@tag4+'=', ia.inetinfo) > 0 and  charindex(char(13), ia.inetinfo) > 0 then
			substring(ia.inetinfo, charindex(@tag4+'=', ia.inetinfo)+ len(@tag4)+1, charindex(char(13), ia.inetinfo, charindex(@tag4+'=', ia.inetinfo)) - charindex(@tag4+'=', ia.inetinfo) - len(@tag4)-1)
		else 'no existe tag: '+@tag4 end param4,
		CASE when charindex(@tag5+'=', ia.inetinfo) > 0 and  charindex(char(13), ia.inetinfo) > 0 then
			substring(ia.inetinfo, charindex(@tag5+'=', ia.inetinfo)+ len(@tag5)+1, charindex(char(13), ia.inetinfo, charindex(@tag5+'=', ia.inetinfo)) - charindex(@tag5+'=', ia.inetinfo) - len(@tag5)-1)
		else 'no existe tag: '+@tag5 end param5,
		CASE when charindex(@tag6+'=', ia.inetinfo) > 0 and  charindex(char(13), ia.inetinfo) > 0 then
			substring(ia.inetinfo, charindex(@tag6+'=', ia.inetinfo)+ len(@tag6)+1, charindex(char(13), ia.inetinfo, charindex(@tag6+'=', ia.inetinfo)) - charindex(@tag6+'=', ia.inetinfo) - len(@tag6)-1)
		else 'no existe tag: '+@tag6 end param6,
		ia.INET7, ia.INET8
	from SY01200 ia					--coInetAddress Dirección de la compañía
	inner join dbo.synonymGPCompanyMaster ci	--sy_company_mstr 
	--inner join DYNAMICS..SY01500 ci	--sy_company_mstr 
		on ia.Master_Type = 'CMP'
		and ci.INTERID = DB_NAME()
		and ia.Master_ID = ci.INTERID
		and ia.ADRSCODE = case when @ADRSCODE = 'PREDETERMINADO' then ci.LOCATNID else @ADRSCODE end
	inner join sy00600 lm			--sy_location_mstr
		on lm.CMPANYID = ci.CMPANYID
		and lm.LOCATNID = ia.ADRSCODE

)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiParametros()'
ELSE PRINT 'Error en la creación de la función: fCfdiParametros()'
GO

--------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.fCfdiParametrosTipoLeyenda') IS NOT NULL
   DROP FUNCTION dbo.fCfdiParametrosTipoLeyenda
GO

create function dbo.fCfdiParametrosTipoLeyenda(@ADRSCODE char(15), @Master_Type varchar(3))
returns table
as
--Propósito. Devuelve todo el texto de notas de la dirección @ADRSCODE
--Requisitos. -
--02/01/18 jcf Creación 
--
return
(
	select ia.inetinfo, ia.INET7, ia.INET8
	from SY01200 ia								--coInetAddress Dirección de la compañía
	inner join dbo.synonymGPCompanyMaster ci	--sy_company_mstr 
		on ci.INTERID = DB_NAME()
		and ia.Master_ID = ci.INTERID
		and ia.ADRSCODE = case when @ADRSCODE = 'PREDETERMINADO' then ci.LOCATNID else @ADRSCODE end
	where ia.Master_Type = @Master_Type
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiParametrosTipoLeyenda()'
ELSE PRINT 'Error en la creación de la función: fCfdiParametrosTipoLeyenda()'
GO

-----------------------------------------------------------------------------------------------
--select *
--from dbo.fCfdiParametrosTipoLeyenda('LEYENDASFE', 'CMP')



