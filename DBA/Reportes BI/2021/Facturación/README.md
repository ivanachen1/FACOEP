# Reporte de Facturacion Facoep

Este reporte muestra lo facturado en FACOEP y tiene 5 solapas que son:

## Facturas Emitidas 

Muestra lo facturado Neto utilizando la tabla comprobantes de la
Base de datos del SIF. Utiliza el archivo tipo_comprobante para filtrar los tipos de factura, notas de credito y
notas de debito que se quieren tomar en cuenta al momento de confeccionar el reporte. El Script que tiene el codigo fuente
es el **Script Solapa Facturas Emitidas**

## PAMI 

Muestra lo facturado según el archivo ***Detalles PAMI Capita*** que es nutrido por el area comercial.

## Monitoreo de Objetivos

Esta solapa compara lo que se **Facturó Neto(Facturas + Notas Debito - Notas Credito)** contra lo definido en el excel suministrado año
a año de los objetivos. Es importante controlar que al cargar los nuevos objetivos al excel consolidado de los mismos, los efectores tengan
exactamente el mismo nombre. Si un efector tiene un nombre distinto de un año para otro, hay que corregirlo ya que dejará de funcionar la 
tabla de mapeo del Excel ***EfectoresObjetivos:*** que permite matchear los datos de los objetivos y del SIF por el ID de Efector.

## CRG SIF / SIGEHOS

Esta solapa compara los CRGs que posee Sigehos con los que están en el SIF con el objetivos de analizar cuales no están ingresados en el SIF para que la gerencia de sistemas y estadisticas controlen que los hospitales les facturen a las obras sociales, disminuyendo pérdidas economicas.

Una problematica que posee este reporte es que, ya sea por cambios realizados en FACOEP o por como vienen los datos de SIGEHOS, el nombre de los efectores pueden ser distintos en ambos sistemas, generando que muchos CRGs figuren como no ingresados cuando en realidad si ingresaron.

Para resolver este problema se confecciono el excel ***EfectoresObjetivos***, siendo esta una tabla de mapeo entre ambas bases de datos. En caso de que el nombre del efector venga incorrectamente de SIGEHOS, se debe hacer el mapeo manualmente de la siguiente manera:

1. Revisar la columna **EfectorSigehos** del Excel ***Control-Sigehos.xlsx***. 
2. En caso de que posea valores, significa que hay Efectores que están mal nombrados en Sigehos y se debe hacer el mapeo manualmente en el Excel ***EfectoresObjetivos.xlsx***.
3. Para hacer el mapeo, se debe abrir el archivo, buscar el efector que se desea mapear, crear una linea nueva y copiar y pegar los valores de los campos **ID,sif,EfectorObjetivos y MostrarGrafico** y colocar el valor del excel de control en la columna ***EfectorSigehos***
4. Se comparte el siguente ejemplo: Si en el excel de control me figura como efector **Zubizzarette**, en realidad es el hospital **Zubizarreta** y debe ser mapeado en el excel de objetivos. Para esto se debe colocar una nueva linea de la tabla con los siguientes datos:
    1. ID = 22
    2. sif = HOSPITAL ZUBIZARRETA
    3. EfectorObjetivos = Zubizarreta
    4. MostrarGrafico = 2
    5. **EfectorSigehos** = **Zubizzarette**   

## Evolución Efector

Muestra lo mismo que en la solapa de Monitoreo de Objetivos a diferencia que esta ultima permite evaluar la evolucion de la facturacion
por mes del efector elegido y muestra además, el top ten de las obras sociales que poseen mayor facturación.