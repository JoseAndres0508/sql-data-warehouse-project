# Fuente: ERP

Tres archivos CSV del sistema ERP. Separador `,`, primera fila con encabezados, saltos de línea de Windows (CRLF), sin comillas. Los encabezados vienen en mayúsculas; en las tablas se usan en minúsculas por la convención `snake_case`.

| Archivo | Filas | Contenido | Tabla bronze |
|---|---|---|---|
| `CUST_AZ12.csv` | 18,484 | Datos demográficos del cliente (nacimiento, género) | `bronze.erp_cust_az12` |
| `LOC_A101.csv` | 18,484 | País del cliente | `bronze.erp_loc_a101` |
| `PX_CAT_G1V2.csv` | 37 | Categorías y subcategorías de producto | `bronze.erp_px_cat_g1v2` |

## Claves para integrar con el CRM

- `CUST_AZ12.CID` se une con `cust_info.cst_key` después de quitar el prefijo `NAS` (`NASAW00011000` → `AW00011000`).
- `LOC_A101.CID` se une con `cust_info.cst_key` después de quitar el guion (`AW-00011000` → `AW00011000`).
- `PX_CAT_G1V2.ID` se une con los primeros 5 caracteres de `prd_info.prd_key`, cambiando `-` por `_`.

## Problemas de calidad conocidos

Se resuelven en silver; ver `03_scripts/silver/README.md`.
- `CUST_AZ12`: prefijo `NAS` en 11,042 IDs, 16 fechas de nacimiento en el futuro y género inconsistente (`Male`, `M`, `F `, vacíos).
- `LOC_A101`: guion en los IDs y países inconsistentes (`US`, `USA`, `United States`, `DE`, vacíos).
- `PX_CAT_G1V2`: sin problemas.
- La categoría `CO_PE`, que usan algunos productos del CRM, no existe en este archivo.

> Los CSV de esta carpeta no se suben al repositorio (`.gitignore`). Este README sí, porque se agregó a Git antes de crear la regla.
