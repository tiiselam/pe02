--Factura Electrónica
--Propósito. Accesos a objetos de factura electrónica
--Requisitos. Para usuario de dominio: Crear login y accesos a bds: Dynamics, [GCOL], INTDB2
--			Ejecutar en Dynamics
--24/05/11 jcf Creación

use dynamics;
IF DATABASE_PRINCIPAL_ID('rol_cfdigital') IS NULL
	create role rol_cfdigital;
	
--Objetos que usa factura electrónica
grant select on dbo.sy01500 to rol_cfdigital, dyngrp;
grant select on dbo.vwCfdCompannias  to rol_cfdigital, dyngrp;
grant select on dbo.MC40200  to rol_cfdigital, dyngrp;

--use dynamics
--EXEC sp_addrolemember 'rol_cfdigital', 'ARGTII-DIR-02\Invitado' ;
--create user [GILA\nurys.sanchezmartine] for login [GILA\nurys.sanchezmartine];
--create user [GILA\contador.mexico] for login [GILA\contador.mexico];
--EXEC sp_addrolemember 'rol_cfdigital', 'GILA\nurys.sanchezmartine';
--EXEC sp_addrolemember 'rol_cfdigital', 'GILA\daniel.montes' ;
--EXEC sp_addrolemember 'rol_cfdigital', 'GILA\laura.gonzalez' ;
--EXEC sp_addrolemember 'rol_cfdigital', 'GILA\tiiselam' ;
--EXEC sp_addrolemember 'rol_cfdigital', 'ARGTII-DIR-02\juan.fernandez' 
--EXEC sp_addrolemember 'rol_cfdigital', 'GILA\contador.mexico';

