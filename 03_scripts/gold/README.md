# Capa gold

Datos preparados para el negocio y el análisis. Integra CRM y ERP en un **modelo estrella**: una tabla de hechos de ventas y dos dimensiones, clientes y productos. Es la capa que consumen las herramientas de BI, las consultas SQL y el aprendizaje automático.

```
          dim_customers
                │
                │ customer_key
                │
          fact_sales ──── product_key ──── dim_products
```

## Archivos

| Archivo | Contenido |
|---|---|
| `ddl_gold.sql` | Crea las 3 tablas. Si existen, las elimina y las vuelve a crear. |
| `proc_load_gold.sql` | Crea el procedimiento `gold.load_gold`. |

Uso: `EXEC gold.load_gold;`, siempre después de `EXEC bronze.load_bronze;` y `EXEC silver.load_silver;`.

## Decisiones generales

- **Tipo de objeto: tablas.** La presentación propone vistas para gold; en este proyecto se usan tablas físicas de hechos y dimensiones, cargadas con un procedimiento igual que bronze y silver. Las consultas analíticas leen datos ya materializados y no recalculan las uniones en cada consulta.
- **Modelo estrella:** una tabla de hechos (`fact_sales`) y dimensiones desnormalizadas (`dim_customers`, `dim_products`). No se crean tablas `report_`.
- **Solo lee de silver**, nunca de bronze. La tabla de hechos obtiene sus claves de las dimensiones de gold.
- **Nombres del negocio en inglés**, con prefijo de categoría (`dim_`, `fact_`). Las columnas usan nombres claros para el negocio, no los del sistema de origen (`first_name` en lugar de `cst_firstname`).
- **Claves subrogadas:** cada dimensión tiene su propia clave `<entity>_key`, de tipo `INT IDENTITY(1,1) PRIMARY KEY`, generada por SQL Server en cada carga. La tabla de hechos guarda estas claves y no los IDs de origen.
- **La tabla de hechos no tiene clave propia.** Su grano es una línea de venta y se identifica por `order_number` junto con el producto.
- **Sin llaves foráneas** (`FOREIGN KEY`) entre `fact_sales` y las dimensiones. SQL Server no permite hacer `TRUNCATE` de una tabla referenciada por una llave foránea, lo que impediría la carga completa. La integridad se asegura con el orden de carga y se verifica con la consulta de validación.
- **Columna técnica** `dwh_create_date DATETIME2 DEFAULT GETDATE()` en las 3 tablas.
- **Carga completa (truncar e insertar):** se vacían las 3 tablas, primero los hechos y luego las dimensiones. El `TRUNCATE` reinicia las claves `IDENTITY` a 1. Después se cargan las dimensiones y al final los hechos, que buscan sus claves en las dimensiones ya cargadas.
- **El procedimiento** muestra con `PRINT` las filas y el tiempo de cada tabla, y captura errores con `TRY...CATCH` y `THROW`, igual que en las otras capas.

## `gold.dim_customers` (18,484 filas)

Un registro por cliente.

| Columna | Origen | Regla |
|---|---|---|
| `customer_key` | Generada | `IDENTITY`, asignada en orden de `cst_id`. |
| `customer_id` | `crm_cust_info.cst_id` | Se usa para unir con las ventas. |
| `customer_number` | `crm_cust_info.cst_key` | Se usa para unir con el ERP. |
| `first_name`, `last_name` | `crm_cust_info` | Tal como quedan en silver. |
| `country` | `erp_loc_a101.cntry` | `n/a` si el cliente no existe en el ERP. |
| `marital_status` | `crm_cust_info.cst_marital_status` | Tal como queda en silver. |
| `gender` | CRM y ERP | El CRM es la fuente principal. Si el CRM tiene `n/a`, se toma el género del ERP; si tampoco existe, `n/a`. |
| `birthdate` | `erp_cust_az12.bdate` | `NULL` si no existe o era inválida. |
| `create_date` | `crm_cust_info.cst_create_date` | Tal como queda en silver. |

- El CRM es la fuente principal de clientes y el ERP los enriquece. Se usa `LEFT JOIN` desde el CRM para no perder ningún cliente.
- Uniones: `crm_cust_info.cst_key = erp_cust_az12.cid` y `crm_cust_info.cst_key = erp_loc_a101.cid`, con los IDs del ERP ya corregidos en silver.

## `gold.dim_products` (295 filas)

Un registro por producto vigente.

| Columna | Origen | Regla |
|---|---|---|
| `product_key` | Generada | `IDENTITY`, asignada en orden de `prd_start_dt` y `prd_key`. |
| `product_id` | `crm_prd_info.prd_id` | |
| `product_number` | `crm_prd_info.prd_key` | Se usa para unir con las ventas. |
| `product_name` | `crm_prd_info.prd_nm` | |
| `category_id` | `crm_prd_info.cat_id` | Columna derivada en silver. |
| `category`, `subcategory`, `maintenance` | `erp_px_cat_g1v2` | `n/a` si la categoría no existe en el ERP. |
| `cost` | `crm_prd_info.prd_cost` | |
| `product_line` | `crm_prd_info.prd_line` | |
| `start_date` | `crm_prd_info.prd_start_dt` | |

- **Solo productos vigentes** (`prd_end_dt IS NULL`), porque el alcance del proyecto es el dato más reciente y no se mantiene historial. Hay exactamente una versión vigente por `prd_key`, así que cada venta encuentra un único producto.
- Unión: `crm_prd_info.cat_id = erp_px_cat_g1v2.id`, con `LEFT JOIN`. Los productos de la categoría `CO_PE`, que no existe en el ERP, quedan con categoría, subcategoría y mantenimiento en `n/a`.
- No se incluye `prd_end_dt`: en esta tabla siempre sería `NULL`.

## `gold.fact_sales` (60,398 filas)

Un registro por línea de venta.

| Columna | Origen |
|---|---|
| `order_number` | `crm_sales_details.sls_ord_num` |
| `product_key` | `dim_products.product_key`, buscado con `sls_prd_key = product_number` |
| `customer_key` | `dim_customers.customer_key`, buscado con `sls_cust_id = customer_id` |
| `order_date`, `shipping_date`, `due_date` | `sls_order_dt`, `sls_ship_dt`, `sls_due_dt`, ya convertidas a `DATE` en silver |
| `sales_amount` | `sls_sales` |
| `quantity` | `sls_quantity` |
| `price` | `sls_price` |

- Solo contiene claves de dimensión y métricas.
- Se usa `LEFT JOIN` hacia las dimensiones para no perder ventas. Toda venta debe encontrar su cliente y su producto.

## Validación

Las tres tablas deben dar 18,484, 295 y 60,398 filas. Además, ninguna venta debe quedar sin cliente o sin producto:

```sql
SELECT COUNT(*)
FROM gold.fact_sales
WHERE customer_key IS NULL OR product_key IS NULL;   -- debe dar 0
```

## Pendiente conocido

Bronze descarta la última fila de `CUST_AZ12.csv`, porque el archivo no termina con salto de línea y su último campo está vacío. Por eso el cliente `AW00029483` queda sin `birthdate` en `dim_customers` hasta que se agregue `FORMAT = 'CSV'` a la carga de bronze.
