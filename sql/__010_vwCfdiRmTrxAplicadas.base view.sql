IF (OBJECT_ID ('dbo.vwCfdiRmTrxAplicadas', 'V') IS NULL)
   exec('create view dbo.vwCfdiRmTrxAplicadas as SELECT 1 as t');
go

alter view dbo.vwCfdiRmTrxAplicadas 
--Propósito. Documentos aplicados de Receivables Management abiertos e históricos
--Usado por. 
--11/10/17 JCF Creación
--
as
--
select 'A' rmTipoTrx, APFRDCTY, APFRDCNM, APFRDCDT, APTODCTY, APTODCNM, CUSTNMBR, APTODCDT, CPRCSTNM, TRXSORCE, GLPOSTDT, POSTED, TAXDTLID, 
	APPLYTOGLPOSTDATE, CURNCYID, APPTOAMT, ORAPTOAM, APTOEXRATE, APPLYFROMGLPOSTDATE, FROMCURR, APFRMAPLYAMT, ACTUALAPPLYTOAMOUNT, 
	RLGANLOS, APFRMWROFAMT, ActualWriteOffAmount, convert(varchar(12), APFRDCDT, 112) + rtrim(APFRDCNM) idPago
from rm20201			--rm_applied_open [APTODCNM, APTODCTY, APFRDCNM, APFRDCTY]
union all
select 'H' rmTipoTrx, ah.APFRDCTY, ah.APFRDCNM, ah.APFRDCDT, ah.APTODCTY, ah.APTODCNM, ah.CUSTNMBR, ah.APTODCDT, ah.CPRCSTNM, ah.TRXSORCE, ah.GLPOSTDT, ah.POSTED, 
	ah.TAXDTLID, ah.APPLYTOGLPOSTDATE, ah.CURNCYID, ah.APPTOAMT, ah.ORAPTOAM, ah.APTOEXRATE, ah.APPLYFROMGLPOSTDATE, ah.FROMCURR, ah.APFRMAPLYAMT, ah.ACTUALAPPLYTOAMOUNT, 
	ah.RLGANLOS, ah.APFRMWROFAMT, ActualWriteOffAmount, convert(varchar(12), ah.APFRDCDT, 112) + rtrim(ah.APFRDCNM) idPago
from rm30201 ah			--rm_Applied_history [APTODCNM, APTODCTY, APFRDCNM, APFRDCTY]
inner join rm30101 pg	--rm_history [CUSTNMBR, DOCNUMBR, RMDTYPAL]
	on pg.RMDTYPAL = ah.APFRDCTY
	and pg.DOCNUMBR = ah.APFRDCNM
inner join rm30101 ft	--rm_history [CUSTNMBR, DOCNUMBR, RMDTYPAL]
	on ft.RMDTYPAL = ah.APTODCTY
	and ft.DOCNUMBR = ah.APTODCNM

go
IF (@@Error = 0) PRINT 'Creación exitosa de: vwCfdiRmTrxAplicadas'
ELSE PRINT 'Error en la creación de: vwCfdiRmTrxAplicadas'
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------
