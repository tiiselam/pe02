IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'dbo.tblGREM001') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	create table dbo.tblGREM001
	(
	DOCNUMBR		varchar(21),
	GREMReferenciaNumb	varchar(21),
	GREMReferenciaTipo	smallint,
	GREMGuiaIndicador	smallint
	) ;
end
go

------------------------------------------------------------------------------------
