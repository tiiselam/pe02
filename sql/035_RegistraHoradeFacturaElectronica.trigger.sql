--Factura electrónica 
--Propósito. Crea vista de los id de documentos que se incluyen en factura electrónica.
--			Registrar hora de la factura. Si por algún caso la hora se elimina, se registra una suspensión que no permite contabilizar.
--

--use [compañía];
--go
-----------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwCfdIdDocumentos]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.[vwCfdIdDocumentos];
GO
create view dbo.vwCfdIdDocumentos as
--Propósito. Obtiene id de documentos de venta gp
--Utilizado por. Factura electrónica
--04/11/10 jcf Creación
--23/11/10 jcf Filtra ids predeterminados
--17/06/11 JCF Filtra por tipo de venta
--
select ds.soptype, ds.docid, ds.SOPNUMBE
from sop40200 ds			--sop_id_setp
where soptype in (3, 4)
--where exists (
--	select invdocid 
--	from SOP40100			--sop_setp
--	where (INVDOCID = ds.DOCID
--		or RETDOCID = ds.DOCID)
--	)
go
IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdIdDocumentos'
ELSE PRINT 'Error en la creación de la vista: vwCfdIdDocumentos'
GO

----------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('trgins_sop10100_registraHora','TR') IS NOT NULL
   DROP TRIGGER dbo.trgins_sop10100_registraHora
GO

create TRIGGER dbo.trgins_sop10100_registraHora ON dbo.sop10100
AFTER INSERT
AS
--MEXICO, COLOMBIA, ESPAÑA, PERU, USA
--Propósito. Registra la hora de la transacción. Usar la hora adecuada en cada país.
--24/11/10 JCF Creación. 
--27/08/13 JCF Getty ejecuta una integración en la madrugada desde Argentina. 
--		Si ingresan facturas a hrs > 22 de México, debe generar factura electrónica al día siguiente.
--20/12/13 jcf Todas las facturas ingresan con diferencia -3
--25/08/16 jcf Si la factura se genera a hrs. 03:01 o superior se disminuye 3 horas. Esto para evitar tener la fecha de hoy con hora adelantada.
--			Considerar que en México hay una diferencia de 2 o 3 horas dependiendo de la estación.
--			Esto implica que si un usuario ingresa una factura entre hrs 24 y hrs 3 del día siguiente de Argentina, la hora será siempre menor a 3.
--21/11/16 jcf Parametriza la diferencia horaria en CFDIDIFHORA
--31/07/17 JCF El parámetro está en la dirección PRINCIPAL
--
begin try

	DECLARE @horaMex int;
    set @horaMex = 0;
	select @horaMex = case when isnumeric(PARAM1) = 1 then convert(int, param1) else 0 end
	from dbo.fCfdiParametros('CFDIDIFHORA', '-', '-', '-', '-', '-', 'PREDETERMINADO');

	UPDATE dbo.SOP10100 set DOCNCORR = 
				case when datepart(hh, getdate()) <= @horaMex then
					convert(varchar(12), getdate(), 114)	--hora local del servidor
				else
					convert(varchar(12), dateadd(hh,-@horaMex, getdate()), 114)
				end
	 FROM dbo.SOP10100, inserted 
	 WHERE SOP10100.SOPTYPE = inserted.SOPTYPE 
	 AND SOP10100.SOPNUMBE = inserted.SOPNUMBE;

end try
BEGIN catch
	declare @l_error nvarchar(2048)
	select @l_error = 'Error al registrar la hora de la factura. [trg_sop10100_registraHora] ' + error_message()
	RAISERROR (@l_error , 16, 1)
end catch
go

-------------------------------------------------------------------------------------------------
IF OBJECT_ID ('trgupd_sop10100_registraHora','TR') IS NOT NULL
   DROP TRIGGER dbo.trgupd_sop10100_registraHora
GO

CREATE TRIGGER dbo.trgupd_sop10100_registraHora ON dbo.sop10100
AFTER UPDATE
AS
--SOLO MEXICO
--Propósito. Revisa la hora de la transacción en los documentos de venta habilitados en vwCfdIdDocumentos
--Requisito. Debe existir la suspensión: SIN HORA
--Utiliza. vwCfdIdDocumentos
--25/11/10 JCF Creación. 
--01/12/10 jcf Agrega control por id de documento. Sólo procesa documentos listados en la vista vwCfdIdDocumentos
--
begin TRY
	if (select top 1 SUBSTRING(i.DOCNCORR, 3, 1)
		from vwCfdIdDocumentos id
		inner join inserted i 
			on i.soptype = id.soptype
			and i.docid = id.docid
		) <> ':'
		begin	--agregar suspensión
			if (select count(sop10104.soptype)
				FROM dbo.sop10104
					inner join inserted 
					on sop10104.SOPTYPE = inserted.SOPTYPE 
					AND sop10104.SOPNUMBE = inserted.SOPNUMBE
					and sop10104.prchldid = 'SIN HORA' ) > 0
	
				UPDATE dbo.sop10104 set DELETE1 = 0
				 FROM dbo.sop10104, inserted 
				 WHERE sop10104.SOPTYPE = inserted.SOPTYPE 
				 AND sop10104.SOPNUMBE = inserted.SOPNUMBE
				 and sop10104.prchldid = 'SIN HORA' 
			else
				insert into sop10104 (soptype, sopnumbe, prchldid, delete1 )
				select soptype, sopnumbe, 'SIN HORA', 0
				from inserted
		end
end TRY
BEGIN catch
	RAISERROR ('Error al registrar la hora de la factura. [trgupd_sop10100_registraHora]', 16, 1)
end catch
go

-------------------------------------------------------------------------------------------------
if not exists(select * from SOP00100 where PRCHLDID = 'SIN HORA') 
	insert into SOP00100 (PRCHLDID, DSCRIPTN,[PASSWORD],XFERPHOL,POSTPHOL,FUFIPHOL,PRINPHOL,WORKFLOWHOLD,USER2ENT,CREATDDT,MODIFDT)
	values('SIN HORA', 'Fac. electrónica requiere hora', 'sin hora', 1, 1, 0, 0, 0, '', 0, 0)
go
-------------------------------------------------------------------------------------------------
--delete from sop00100
--where prchldid = 'SIN HORA'
