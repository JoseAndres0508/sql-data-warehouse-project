# Capa silver

Datos limpios y estandarizados, listos para integrarse en gold. Lee de bronze, aplica las reglas de calidad y escribe en tablas con la misma estructura más los ajustes necesarios.

## Archivos

| Archivo | Contenido |
|---|---|
| `ddl_silver.sql` | Crea las 6 tablas. Si existen, las elimina y las vuelve a crear. |
| `proc_load_silver.sql` | Carga de las 6 tablas, que se agrupa en el procedimiento `silver.load_silver`. |

Uso: `EXEC silver.load_silver;`, siempre después de `EXEC bronze.load_bronze;`.

## Decisiones generales

- **Mismas tablas y columnas que bronze**, en el schema `silver`, con estos cambios de estructura:
  - Todas las tablas tienen `dwh_create_date DATETIME2 DEFAULT GETDATE()` como última columna. Se llena sola en cada carga y no se incluye en los `INSERT`.
  - `crm_prd_info` tiene una columna nueva, `cat_id`, después de `prd_id`.
  - Las fechas de `crm_sales_details` cambian de `INT` a `DATE`.
- **Carga completa (truncar e insertar):** `TRUNCATE` y luego `INSERT INTO silver.... SELECT ... FROM bronze....`, con la limpieza dentro del `SELECT`.
- **Criterio de calidad:** se aplica el definido en `02_docs/README.md`.

## Decisiones por tabla

### `silver.crm_cust_info` (18,484 filas)

| Problema | Decisión |
|---|---|
| 4 filas sin `cst_id`, sin ningún otro dato | Se eliminan (`WHERE cst_id IS NOT NULL`). |
| 5 clientes con varias filas (6 filas sobrantes) | Se conserva la más reciente por `cst_create_date` (`ROW_NUMBER() ... ORDER BY cst_create_date DESC`, con `flag_last = 1`). |
| Espacios en `cst_firstname` y `cst_lastname` | `TRIM`. |
| `cst_marital_status` en código | `S` → `Single`, `M` → `Married`, otro o vacío → `n/a`. |
| `cst_gndr` en código | `F` → `Female`, `M` → `Male`, otro o vacío → `n/a`. |

### `silver.crm_prd_info` (397 filas)

| Problema | Decisión |
|---|---|
| `prd_key` combina categoría y producto | `cat_id` = primeros 5 caracteres con `-` cambiado por `_` (`CO-RF` → `CO_RF`), para unir con `erp_px_cat_g1v2.id`. `prd_key` = desde el carácter 7 (`FR-R92B-58`), para unir con `crm_sales_details.sls_prd_key`. |
| 2 costos vacíos | `0`. |
| `prd_line` en código y con espacio | `M` → `Mountain`, `R` → `Road`, `S` → `Other Sales`, `T` → `Touring`, otro o vacío → `n/a`. |
| 200 fechas de fin anteriores a la fecha de inicio | Se recalcula: cada versión de un producto termina el día anterior al inicio de la siguiente (`LEAD(prd_start_dt)` por `prd_key`, menos 1 día). La versión más reciente queda con `prd_end_dt = NULL`, que significa vigente. |

### `silver.crm_sales_details` (60,398 filas)

| Problema | Decisión |
|---|---|
| Fechas como número `yyyymmdd` | Se convierten a `DATE` (`CAST` a `VARCHAR` y luego a `DATE`). |
| 19 `sls_order_dt` inválidas (`0`, o longitud distinta de 8) | `NULL`. La misma regla se aplica a `sls_ship_dt` y `sls_due_dt` como protección, aunque hoy no tienen errores. |
| `sls_sales` vacía, ≤ 0 o distinta de cantidad × precio | Se recalcula como `sls_quantity * ABS(sls_price)`. |
| `sls_price` vacío o ≤ 0 | Se recalcula como `sls_sales / sls_quantity`. `NULLIF` evita la división entre cero. |
| Ninguna fila se elimina | Todas las ventas son válidas una vez corregidas. |

**Regla de negocio:** ventas = cantidad × precio.

### `silver.erp_cust_az12` (18,484 filas)

| Problema | Decisión |
|---|---|
| 11,042 `cid` con prefijo `NAS` | Se quita el prefijo para que coincida con `crm_cust_info.cst_key`. |
| 16 `bdate` en el futuro (hasta el año 9999) | `NULL`. |
| `gen` inconsistente (`Male`, `M`, `F `, vacíos, espacios) | `F` o `Female` → `Female`, `M` o `Male` → `Male`, otro → `n/a`. |

### `silver.erp_loc_a101` (18,484 filas)

| Problema | Decisión |
|---|---|
| `cid` con guion (`AW-00011000`) | Se quita el guion para que coincida con `crm_cust_info.cst_key`. |
| `cntry` inconsistente | `DE` → `Germany`, `US` o `USA` → `United States`, vacío → `n/a`, el resto con `TRIM`. Quedan 7 valores: Australia, Canada, France, Germany, United Kingdom, United States y n/a. |

### `silver.erp_px_cat_g1v2` (37 filas)

| Problema | Decisión |
|---|---|
| Ninguno | Se copia tal cual. Pasa por silver igual que las demás, para que gold solo lea de silver. |

## Resultado de la integración

Después de la limpieza, los 18,484 clientes de `erp_cust_az12` y de `erp_loc_a101` coinciden con `crm_cust_info.cst_key`. Todas las `sls_prd_key` de ventas existen en `crm_prd_info.prd_key`. La única excepción es la categoría `CO_PE`, que no existe en el ERP.
