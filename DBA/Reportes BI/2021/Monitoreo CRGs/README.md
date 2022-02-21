# Manual Tecnico Reporte

## Tablas

### Tabla Universo

Esta tabla identifica el Universo de CRGs, DPHs y Efectores que entran en la medición según el listado de prestaciones
presente en el archivo Prestaciones Nancy. La query es un SELECT DISTINCT de los campos CRGNUM, PPRID de la tabla CRGDET.
En la Query se crea un campo de ID que se utilizará en Power BI para relacionar como tabla de puente las tablas 
CRGPorEstadosSuma y CRGDetalle.

Esto se ejecuta en el Script llamado Monitoreo CRGs_Universo.R

### Tabla CRGPorEstadosSuma

Esta tabla posee todo lo que suma para controlar los importes del CRG, dejando de lado los Efectores,CRGs y Efectores
que no posean en algunos de sus prestaciones los codigos suministrados en el archivo Prestaciones Nancy. 

Esta Query hace un select de campos de las tablas CRG, CRGDET y proveedor prestador y hace un Join con la tabla Universo 
para identificar que registros debo tomar en cuenta en la suma. En el WHERE figura id_test IS NOT NULL debido a que 
son las combinaciones de Efectores, CRGs y DPHs que tengo que dejar de Lado en el análisis. 

Además se alimenta del archivo PrestacionesNoSumar que filtra que prestaciones no debemos tomar en cuenta al momento de sumar
el importe en el reporte.


El Script que contiene esta logica es Monitoreo CRGs_CRGPorEstadosSuma.R

### Tabla CRGDetalle

Esta tabla muestra el detalle de todo el CRG y matchea con la tabla CRGEstadosSuma mediante la tabla Universo.
Esta tabla lo unico que contempla es que el CRG, el DPH y el Efector del detalle del CRG contenga al menos un codigo
de prestacion de los definidos en el archivo Prestaciones Nancy.