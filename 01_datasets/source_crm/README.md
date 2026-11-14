# Fuente: CRM

Tres archivos CSV del sistema CRM. Separador `,`, primera fila con encabezados, saltos de línea de Windows (CRLF), sin comillas.

| Archivo | Filas | Contenido | Tabla bronze |
|---|---|---|---|
| `cust_info.csv` | 18,494 | Clientes | `bronze.crm_cust_info` |
| `prd_info.csv` | 397 | Productos e historial de costos | `bronze.crm_prd_info` |
| `sales_details.csv` | 60,398 | Detalle de ventas | `bronze.crm_sales_details` |

## Claves para integrar con el ERP

- `cust_info.cst_key` (`AW00011000`) es la clave del cliente que coincide con el ERP.
- `cust_info.cst_id` (`11000`) es la clave del cliente que usa `sales_details.sls_cust_id`.
- `prd_info.prd_key` (`CO-RF-FR-R92B-58`) contiene dos datos: los primeros 5 caracteres son la categoría (`CO-RF`, que se une con `PX_CAT_G1V2.ID` como `CO_RF`) y el resto es la clave del producto (`FR-R92B-58`, que se une con `sales_details.sls_prd_key`).

## Problemas de calidad conocidos

Se resuelven en silver; ver `03_scripts/silver/README.md`.
- `cust_info`: 4 filas sin `cst_id`, 5 clientes duplicados, espacios en nombres y códigos `M`, `S`, `F`.
- `prd_info`: costos vacíos, códigos de línea con espacio y 200 fechas de fin anteriores a la de inicio.
- `sales_details`: fechas guardadas como número `yyyymmdd`, 19 fechas de orden inválidas, y ventas o precios vacíos, negativos o que no cuadran.

> Los CSV de esta carpeta no se suben al repositorio (`.gitignore`). Este README sí, porque se agregó a Git antes de crear la regla.
