using System;
using System.Collections.Generic;
using System.Text;
using Comun;

namespace MaquinaDeEstados
{
    public class ReglasME
    {
        public string ultimoMensaje = "";
        public string eBinarioNuevo = "000000";
        public string eBinActualConError = "100000";
        private Parametros _Compania = null;

        public ReglasME( Parametros Param)
        {
            _Compania = Param;
        }

        /// <summary>
        /// Valida el cambio de estado de un documento. 
        /// El parámetro eBinarioActual es una cadena de 6 bits de derecha a izquierda (little endian):
        ///     1           emitido
        ///     2           anulado/eliminado
        ///     3           impreso
        ///     4           publicado
        ///     5           enviado
        ///     6           error
        /// </summary>
        /// <param name="tipoDoc">Tipo de documento</param>
        /// <param name="accion">Proceso que inicia el cambio de estado</param>
        /// <param name="eBinarioActual">Cadena de 6 bits de derecha a izquierda. Indican los estados del documento.</param>
        /// <param name="eBaseNuevo">Estado base al que se requiere cambiar</param>
        /// <param name="compania">Parámetros de la compañía</param>
        /// <returns>True si valida la transición. Cambia el atributo eBinarioNuevo: cadena de 6 bits que indica el nuevo estado del documento</returns>
        public bool ValidaTransicion(string tipoDoc, string accion, string eBinarioActual, string eBaseNuevo)
        {
            ultimoMensaje = "";
            eBinarioNuevo = eBinarioActual;
            eBinActualConError = "1" + Utiles.Derecha(eBinarioActual, 5);
            if (tipoDoc.Equals("FACTURA") && accion.Equals("ENVIA EMAIL"))
            {
                if (eBaseNuevo.Equals("enviado"))
                    if (_Compania.emite == Utiles.Derecha(eBinarioActual, 1).Equals("1")          //emitido
                        && Utiles.Derecha(eBinarioActual, 2)[0].Equals('0')                      //no anulado
                        && _Compania.imprime == Utiles.Derecha(eBinarioActual, 3)[0].Equals('1')  //impreso
                        && _Compania.publica == Utiles.Derecha(eBinarioActual, 4)[0].Equals('1')  //publicado
                        && Utiles.Derecha(eBinarioActual, 5)[0].Equals('0'))                     //no enviado
                    {
                        eBinarioNuevo = "01"+Utiles.Derecha(eBinarioActual, 4);
                        return true;
                        //return Convert.ToString(29, 2).PadLeft(6, '0');        //nuevo estado en binario Enviado=1
                    }
                    else
                        if (Utiles.Derecha(eBinarioActual, 5)[0].Equals('1'))                     //enviado)
                            ultimoMensaje = "Ya fue enviado anteriormente por e-mail. [ValidaTransicion] " + eBinarioActual;
                        else
                            ultimoMensaje = "No está listo para enviarse por e-mail. [ValidaTransicion] "+eBinarioActual;
            }

            if (tipoDoc.Equals("FACTURA") && accion.Equals("EMITE XML Y PDF"))
            {
                if (eBaseNuevo.Equals("emitido/impreso"))
                    if (_Compania.emite && _Compania.imprime && eBinarioActual.Equals("000000"))
                    {
                        eBinarioNuevo = "000101";                                //emitido e impreso
                        eBinActualConError = "100001";                           //emitido, no impreso
                        return true;
                    }
                    else
                        ultimoMensaje = "No está listo para emitir xml o imprimir pdf. [ValidaTransicion]" + eBinarioActual;
            }
            if (tipoDoc.Equals("FACTURA") && (accion.Equals("EMITE XML") || accion.Equals("ANULA VENTA")))
            {
                if (eBaseNuevo.Equals("emitido"))
                    if (_Compania.emite && eBinarioActual.Equals("000000"))
                    {
                        eBinarioNuevo = "000001";                                //emitido
                        return true;
                    }
                    else
                        ultimoMensaje = "No está listo para emitir xml. [ValidaTransicion]" + eBinarioActual;
            }
            if (tipoDoc.Equals("FACTURA") && (accion.Equals("ELIMINA XML")))
            {
                if (eBaseNuevo.Equals("anulado"))
                    if (_Compania.emite == Utiles.Derecha(eBinarioActual, 1).Equals("1") //emitido
                        && _Compania.anula
                        && _Compania.intEstadoCompletado != Convert.ToInt32(eBinarioActual, 2)) //el doc está a medio procesar
                    {
                        eBinarioNuevo = Utiles.Izquierda(eBinarioActual, 4) + "11";     //cambia el bit anulado/eliminado
                        return true;
                    }
                    else
                        ultimoMensaje = "No está listo para anularse. [ValidaTransicion]" + eBinarioActual;
            }

            if (tipoDoc.Equals("FACTURA") && (accion.Equals("IMPRIME PDF")))            // primera impresión
            {
                if (eBaseNuevo.Equals("impreso"))
                    if (_Compania.emite == Utiles.Derecha(eBinarioActual, 1).Equals("1"))//emitido
                    {
                        if (_Compania.imprime)
                        {                                                               //Cambia el bit impreso
                            eBinarioNuevo = Utiles.Izquierda(eBinarioActual, 3)+ "1" + Utiles.Derecha(eBinarioActual, 2);
                            eBinarioNuevo = "0" + Utiles.Derecha(eBinarioNuevo, 5);
                            return true;
                        }
                        else
                        {
                            ultimoMensaje = "La compañía no permite la impresión de facturas. [ValidaTransicion]";
                            return false;
                        }
                    }
                    else
                        ultimoMensaje = "Debe emitir el archivo xml antes de generar el pdf. [ValidaTransicion]" + eBinarioActual;
            }

            return false;
        }

        /// <summary>
        /// Traducción en palabras del estado binario 
        /// </summary>
        /// <param name="eBinario">Cadena de 6 bits de derecha a izquierda que indica los estados del documento.</param>
        /// <param name="compania">Parámetros de la compañía</param>
        /// <returns>Traducción del estado binario.</returns>
        public string EnLetras(string eBinario)
        {
            string eBase = "";

            if (_Compania.emite)
                if (emitido(eBinario))
                    eBase += "Xml emitido. ";
                else
                    eBase += "Xml no emitido. ";

            if (anulado(eBinario))
                    eBase += "Xml eliminado. ";

            if (_Compania.imprime)
                if (impreso(eBinario))
                    eBase += "Pdf impreso. ";
                else
                    eBase += "Pdf no impreso. ";

            if (_Compania.publica)
                if (publicado(eBinario))
                    eBase += "Docs. publicados. ";
                else
                    eBase += "Docs. no publicados. ";

            if (_Compania.envia)
                if (enviado(eBinario))
                    eBase += "E-mail enviado.";
                else
                    eBase += "E-mail no enviado. ";

            if (error(eBinario))
                eBase += " ";

            return eBase;
        }

        public bool emitido(string eBinario)
        {
            return Utiles.Derecha(eBinario, 1).Equals("1");
        }
        public bool anulado(string eBinario)
        {
            return Utiles.Derecha(eBinario, 2)[0].Equals('1');
        }
        public bool impreso(string eBinario)
        {
            //Console.WriteLine(Utiles.Derecha(eBinario, 3)[0].Equals('1') + " - " + Utiles.Derecha(eBinario, 3)[0].Equals('1'));
            return Utiles.Derecha(eBinario, 3)[0].Equals('1');
        }
        public bool publicado(string eBinario)
        {
            return Utiles.Derecha(eBinario, 4)[0].Equals('1');
        }
        public bool enviado(string eBinario)
        {
            return Utiles.Derecha(eBinario, 5)[0].Equals('1');
        }
        public bool error(string eBinario)
        {
            return Utiles.Derecha(eBinario, 6)[0].Equals('1');
        }

    }
}
