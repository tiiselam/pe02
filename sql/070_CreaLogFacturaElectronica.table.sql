--GETTY - Factura Electr�nica M�xico CFDI
--Prop�sito. Tablas y funciones para monitorear la creaci�n de facturas en formato xml
--
---------------------------------------------------------------------------------------
--Prop�sito. Log de facturas emitidas en formato xml. S�lo debe haber un estado emitido para cada factura.
--23/4/12 jcf Creaci�n cfdi
--
IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[cfdLogFacturaXML]') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	CREATE TABLE dbo.cfdLogFacturaXML (
	  soptype SMALLINT  NOT NULL DEFAULT 0 ,
	  sopnumbe VARCHAR(21)  NOT NULL DEFAULT '' ,
	  secuencia INTEGER  NOT NULL IDENTITY ,
	  estado VARCHAR(20)  NOT NULL DEFAULT 'anulado' , 
	  mensaje VARCHAR(255)  NOT NULL DEFAULT 'xml no emitido' ,
	  estadoActual varchar(20) default '000000', 
	  mensajeEA varchar(255) default '',
	  noAprobacion varchar(21) not null default '',
	  fechaEmision datetime not null default getdate(), 
	  idUsuario varchar(10) not null default '',
	  fechaAnulacion datetime not null default 0,
	  idUsuarioAnulacion varchar(10) not null default '',
	  archivoXML xml default ''
	PRIMARY KEY(soptype, sopnumbe, secuencia));

	alter table dbo.cfdLogFacturaXML add constraint chk_estado check(estado in ('emitido', 'anulado', 'impreso', 'publicado', 'enviado', 'sunat'));
	create index idx1_cfdLogFacturaXML on dbo.cfdLogFacturaXML(soptype, sopnumbe, estado) include (estadoActual, archivoXML);
end;
go

---------------------------------------------------------------------------------------------------------------------------
--Para actualizar Getty:
--drop index idx1_cfdLogFacturaXML on dbo.cfdLogFacturaXML;
--	create index idx1_cfdLogFacturaXML on dbo.cfdLogFacturaXML(soptype, sopnumbe, estado) include (estadoActual, archivoXML);

--alter table dbo.cfdLogFacturaXML drop constraint chk_estado;


