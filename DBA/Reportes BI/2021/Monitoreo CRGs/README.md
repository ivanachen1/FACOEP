#Manual Tecnico Reporte

## Scripts Componen

### Script CRGs Facturados

Este Script crea el DataFrame utilizado en la solapa de CRGs Facturados del Reporte. El mismo contiene una consulta SQL
que tiene un SubSelect para obtener todos los CRGs - Efectores - Numeros DPH que contienen al menos un código de 
prestacion definido en el excel "Prestaciones Nancy". Al colocar codigos en el archivo lo que se genera es que se amplie
la busqueda, mientras que quitar codigos de prestación se achica el resultado.

La consulta SQL hace un FROM con la tabla CRGDET, que permite obtener el número del CRG y el número de DPH del mismo.
Luego hace un LEFT JOIN con la tabla de proveedorprestador para obtener el nombre del Efector. Además hace un SUB - SELECT
con la tabla de COMPROBANTECRGDET para obtener las facturas asociadas al crg, las prestaciones involucradas.

Es importante recalcar que la Primary Key que hace funcionar los joins es la combinatoria CRG - EFECTOR ya que el mismo
CRG puede estar presente en varios efectores