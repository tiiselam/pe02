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

--MTDPG Médoto de pago
------------------------------------------------------------------------------------
if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = '01')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', '01', 'Efectivo');

if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = '02')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', '02', 'Cheque nominativo');

if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = '03')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', '03', 'Transferencia electrónica de fondos');

if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = '04')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', '04', 'Tarjeta de Crédito');

if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = '05')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', '05', 'Monedero Electrónico');

if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = '06')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', '06', 'Dinero electrónico');

if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = '08')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', '08', 'Vales de despensa');

if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = '28')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', '28', 'Tarjeta de Débito');

if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = '29')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', '29', 'Tarjeta de Servicio');

if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = '99')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', '99', 'Otros');

if not exists(select 1 from dbo.cfdiCatalogo where tipo = 'MTDPG' and clave = 'NA')
	insert into cfdiCatalogo(tipo, clave, descripcion)
	values('MTDPG', 'NA', 'NA');

--select * from cfdiCatalogo

