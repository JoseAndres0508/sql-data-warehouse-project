# Capa gold

Datos preparados para el negocio y el análisis. Integra CRM y ERP en un **modelo estrella** que consumen las herramientas de BI, las consultas SQL y el aprendizaje automático.

## Decisiones

- **Tipo de objeto: vistas.** Gold no guarda datos ni tiene procedimiento de carga: sus vistas leen de silver en el momento de la consulta, así que siempre muestran la última carga.
- **Solo lee de silver**, nunca de bronze.
- **Modelo estrella:** una tabla de hechos rodeada de dimensiones desnormalizadas.
- **Nombres del negocio en inglés**, con prefijo de categoría (`dim_`, `fact_`, `report_`). Las columnas también usan nombres claros para el negocio, no los del sistema de origen (por ejemplo, `first_name` en lugar de `cst_firstname`).
- **Claves subrogadas:** cada dimensión tiene su propia clave `<entity>_key`, generada con `ROW_NUMBER()`. La tabla de hechos se relaciona con las dimensiones por esas claves y no por los IDs de origen.

## Modelo

| Vista | Tipo | Granularidad | Fuentes en silver |
|---|---|---|---|
| `gold.dim_customers` | Dimensión | Un cliente | `crm_cust_info` + `erp_cust_az12` (nacimiento, género) + `erp_loc_a101` (país) |
| `gold.dim_products` | Dimensión | Un producto vigente | `crm_prd_info` + `erp_px_cat_g1v2` (categoría, subcategoría, mantenimiento) |
| `gold.fact_sales` | Hechos | Una línea de venta | `crm_sales_details`, unida a `dim_customers` y `dim_products` |

## Reglas de integración

- **Clientes:** `crm_cust_info.cst_key` = `erp_cust_az12.cid` = `erp_loc_a101.cid`. El CRM es la fuente principal; el ERP la enriquece. Se usa `LEFT JOIN` para no perder clientes del CRM.
- **Género:** el CRM es la fuente principal. Si el CRM tiene `n/a`, se toma el género del ERP.
- **Productos:** solo se incluyen las versiones vigentes (`prd_end_dt IS NULL`), porque el alcance es el dato más reciente. Se unen con `erp_px_cat_g1v2` por `cat_id = id` con `LEFT JOIN`: los productos de la categoría `CO_PE`, que no existe en el ERP, quedan sin nombre de categoría.
- **Ventas:** `crm_sales_details.sls_cust_id` se une con el `cst_id` del cliente, y `sls_prd_key` con el `prd_key` del producto, para obtener las claves subrogadas.
