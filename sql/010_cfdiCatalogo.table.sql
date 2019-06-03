IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'dbo.cfdiCatalogo') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	create table dbo.cfdiCatalogo
	(
	tipo		varchar(5) NOT NULL default 'NA',
	clave		varchar(10) NOT NULL default '',
	descripcion varchar(150) NOT NULL default '',
	CONSTRAINT pkCfdiCatalogo primary key nonclustered
	(tipo, clave) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) on [PRIMARY];
end
else
begin
	ALTER TABLE dbo.cfdiCatalogo DROP CONSTRAINT pkCfdiCatalogo;
	alter table dbo.cfdiCatalogo alter column clave varchar(10) not null;
	ALTER TABLE dbo.cfdiCatalogo ADD CONSTRAINT pkCfdiCatalogo PRIMARY KEY (tipo, clave);
end
go

------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.fCfdiCatalogoGetDescripcion') IS NOT NULL
   DROP FUNCTION dbo.fCfdiCatalogoGetDescripcion
GO

create function dbo.fCfdiCatalogoGetDescripcion(@tipo varchar(5), @clave varchar(10))
returns table 
as
--Prop�sito. Obtiene la descripci�n de los c�digos del cat�logo
--21/11/17 jcf Creaci�n cfdi 3.3
--
return(
	select descripcion
	from dbo.cfdiCatalogo ct
    where ct.tipo = @tipo
	and ct.clave = @clave
)

go

IF (@@Error = 0) PRINT 'Creaci�n exitosa de: fCfdiCatalogoGetDescripcion()'
ELSE PRINT 'Error en la creaci�n de: fCfdiCatalogoGetDescripcion()'
GO
-----------------------------------------------------------------------------------------

--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='01ANULA OPER') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '01ANULA OPER','Anulaci�n de la operaci�n');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='02ANULA ERR RUC') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '02ANULA ERR RUC','Anulaci�n por error en el RUC');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='03CORR ERR DES') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '03CORR ERR DES','Correcci�n por error en la descripci�n');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='04DESCU GLOBAL') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '04DESCU GLOBAL','Descuento global');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='05DESCU ITEM') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '05DESCU ITEM','Descuento por �tem');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='06DEVOL TOTAL') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '06DEVOL TOTAL','Devoluci�n total');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='07DEVOL ITEM') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '07DEVOL ITEM','Devoluci�n por �tem');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='08BONIFICACION') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '08BONIFICACION','Bonificaci�n');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='09DISMINU VALOR') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '09DISMINU VALOR','Disminuci�n en el valor');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='10OTROS') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '10OTROS','Otros Conceptos');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='01INTERES MORA') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '01INTERES MORA','Intereses por mora');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='02AUMENTO VALOR') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '02AUMENTO VALOR','Aumento en el valor');
--if not exists(select 1 from sy04200 where cmtsries=3 and commntid='03PENALIDADES') insert into sy04200(cmtsries, commntid, CMMTTEXT)  values(3, '03PENALIDADES','Penalidades/otros conceptos');
--GO
