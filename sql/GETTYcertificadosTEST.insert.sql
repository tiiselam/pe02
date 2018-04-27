--Inserta datos de certificados de test
--
use PER10
go

insert into cfd_CER00100 
( ID_Certificado, ruta_certificado, ruta_clave,contrasenia_clave, fecha_vig_desde, fecha_vig_hasta, estado, [fecha_ultima_modificacio], [TIME1], [usr_ultima_modificacion])
values('PAC', 'MODDATOS',  '', 'MODDATOS', '1/1/17', '7/24/20', 1, 0, 0, '')
go
insert into cfd_CER00100 
( ID_Certificado, ruta_certificado, ruta_clave,contrasenia_clave, fecha_vig_desde, fecha_vig_hasta, estado, [fecha_ultima_modificacio], [TIME1], [usr_ultima_modificacion])
values('210510', '', '\\10.1.1.22\GettyPE_FacturaElectronica\certificado\cfdiPeruWin_TemporaryKey.pfx', '', '5/11/17', '5/10/21', 1, 0, 0, '')
go
insert into cfd_CER00100 
( ID_Certificado, ruta_certificado, ruta_clave,contrasenia_clave, fecha_vig_desde, fecha_vig_hasta, estado, [fecha_ultima_modificacio], [TIME1], [usr_ultima_modificacion])
values('210510', '', 'C:\GPUsuario\GPCfdi\feGettyPeru\certificado\cfdiPeruWin_TemporaryKey.pfx', '', '5/11/17', '5/10/21', 1, 0, 0, '')
go

----------------------
select *
from cfd_CER00100 
where id_certificado = '210510               '

SP_COLUMNS CFD_CER00100