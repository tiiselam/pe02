--Propósito. Objetos sql para factura electrónica de México. Requerimiento de impuestos México.
--Requisitos. 
--02/12/13 jcf Creación
--
SET NOCOUNT ON
GO

PRINT 'Creando objetos para factura electrónica CFDI'
:setvar workpath C:\jcTii\Desarrollo\MEX_Factura_digital_cfdi\mxfe\MxFElctr_SQLScripts

--:r C:\JCTii\GPRelational\rmvwRmTransaccionesTodas.view.sql
--:On Error exit

--:r $(workpath)\00_baseRmTransaccionesTodas.view.sql
--:On Error exit

--:r $(workpath)\01_DynObtieneBdsQueEmitenFElectronica.view.sql
--:On Error exit
--:r $(workpath)\02_DynDaPermisosFacturaElectronica.grant.sql
--:On Error exit
:r $(workpath)\03_fcfdiParametros.function.sql
:On Error exit
:r $(workpath)\10_cfdiCatalogo.table.sql
:On Error exit
:r $(workpath)\12_fCfdObtieneImagenC.function.sql
:On Error exit
:r $(workpath)\35_RegistraHoradeFacturaElectronica.trigger.sql
:On Error exit
:r $(workpath)\40_ObtieneConfiguracionCartasEmail.viewgp2013oAnt.sql
:On Error exit
--:r $(workpath)\40_ObtieneConfiguracionCartasEmail.viewGP2015.sql
--:On Error exit
:r $(workpath)\50_ObtieneDireccionesCorreoClientes.function.sql
:On Error exit
:r $(workpath)\60_OPCIONALCreaMaestroDeCertificadosYFolios.table.sql
:On Error exit
:r $(workpath)\70_CreaLogFacturaElectronica.table.sql
:On Error exit
:r $(workpath)\72_fcfdDatosXmlParaImpresion.function.sql
:On Error exit
:r $(workpath)\80_ABMcfdLogFacturaXML.sprocedure.sql
:On Error exit
:r $(workpath)\83_UtilesYConfiguracion.view.sql
:On Error exit
:r $(workpath)\84_fCfdEmisor.function.sql
:On Error exit
:r $(workpath)\85_fCfdDatosAdicionales.function.sql
:On Error exit
--:r $(workpath)\90_vwSopTransacionesVenta.view.sql
--:On Error exit
:r $(workpath)\90_vwSopTransacionesVenta.GETTYview.sql
:On Error exit
:r $(workpath)\98_Addenda.function.sql
:On Error exit
:r $(workpath)\100_ObtieneDocumentosXml.view.sql
:On Error exit
:r $(workpath)\101_vwRmCfdFacturasConFolioFiscal.view.sql
:On Error exit
:r $(workpath)\110_DaPermisosFacturaElectronicaCia.grant.sql
:On Error exit
--:r $(workpath)\120_DaPermisosReporteFacturaElectrónica.GETTYgrant.sql
--:On Error exit
--:r $(workpath)\130_DaPermisosAUsuariosGETTY.grant.sql
--:On Error exit


PRINT 'Objetos creados satisfactoriamente'
GO
