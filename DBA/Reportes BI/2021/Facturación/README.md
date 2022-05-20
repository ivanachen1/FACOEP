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

4.

## Evolución Efector

Muestra lo mismo que en la solapa de Monitoreo de Objetivos a diferencia que esta ultima permite evaluar la evolucion de la facturacion
por mes del efector elegido y muestra además, el top ten de las obras sociales que poseen mayor facturación.