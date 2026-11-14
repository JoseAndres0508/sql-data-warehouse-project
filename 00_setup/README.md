# Configuración y ejecución

## Requisitos

- **SQL Server 2017 o superior** (cualquier edición, incluida Express o Developer) y **SQL Server Management Studio (SSMS)**.
- El proyecto debe estar en `C:\dev\base de datos\sql-data-warehouse-project\`. Las rutas de los CSV están escritas así en `03_scripts/bronze/proc_load_bronze.sql`; si el proyecto se mueve, se actualizan esas 6 rutas.
- SQL Server debe estar instalado en el mismo equipo que los archivos. `BULK INSERT` lee las rutas desde el servidor, no desde SSMS.
- La cuenta del servicio de SQL Server necesita permiso de lectura sobre la carpeta `01_datasets`.

## Instalación (una sola vez)

Ejecutar en SSMS, en este orden. Cada archivo **crea** objetos en la base; ninguno carga datos.

| # | Archivo | Qué crea |
|---|---|---|
| 1 | `03_scripts/init_database.sql` | La base `dw_medallion_sales` y los schemas `bronze`, `silver` y `gold` |
| 2 | `03_scripts/bronze/ddl_bronze.sql` | Las 6 tablas de bronze |
| 3 | `03_scripts/bronze/proc_load_bronze.sql` | El procedimiento `bronze.load_bronze` |
| 4 | `03_scripts/silver/ddl_silver.sql` | Las 6 tablas de silver |
| 5 | `03_scripts/silver/proc_load_silver.sql` | El procedimiento `silver.load_silver` |
| 6 | `03_scripts/gold/ddl_gold.sql` | Las 3 tablas de gold (`dim_customers`, `dim_products`, `fact_sales`) |
| 7 | `03_scripts/gold/proc_load_gold.sql` | El procedimiento `gold.load_gold` |

Se vuelve a ejecutar un archivo solo si cambia la estructura de las tablas o la lógica de un procedimiento. Al modificar un `proc_*.sql`, hay que **ejecutar el archivo** para que el cambio se guarde en la base; guardarlo en disco no basta.

Comprobación: en el Explorador de objetos, en *dw_medallion_sales* → *Programación* → *Procedimientos almacenados*, deben aparecer `bronze.load_bronze`, `silver.load_silver` y `gold.load_gold`.

## Carga de datos

El archivo de ejecución del proyecto es **`03_scripts/run_etl.sql`**. Carga las tres capas en orden y valida el resultado:

```sql
EXEC bronze.load_bronze;
EXEC silver.load_silver;
EXEC gold.load_gold;
```

- El orden es obligatorio: silver lee de bronze y gold lee de silver.
- Cada carga es completa (truncar e insertar), así que se puede ejecutar las veces que se quiera sin duplicar datos.
- Se ejecuta cada vez que lleguen archivos CSV nuevos a `01_datasets`.
- Antes de ejecutarlo, la base seleccionada en SSMS debe ser `dw_medallion_sales`.

## Resultado esperado

En la pestaña *Mensajes*, cada procedimiento muestra las filas cargadas por tabla:

| Capa | Tabla | Filas |
|---|---|---|
| bronze | `crm_cust_info` | 18,494 |
| bronze | `crm_prd_info` | 397 |
| bronze | `crm_sales_details` | 60,398 |
| bronze | `erp_cust_az12` | 18,484 |
| bronze | `erp_loc_a101` | 18,484 |
| bronze | `erp_px_cat_g1v2` | 37 |
| silver | `crm_cust_info` | 18,484 |
| silver | `crm_prd_info` | 397 |
| silver | `crm_sales_details` | 60,398 |
| silver | `erp_cust_az12` | 18,484 |
| silver | `erp_loc_a101` | 18,484 |
| silver | `erp_px_cat_g1v2` | 37 |
| gold | `dim_customers` | 18,484 |
| gold | `dim_products` | 295 |
| gold | `fact_sales` | 60,398 |

La validación final de `run_etl.sql` (ventas sin cliente o sin producto en `gold.fact_sales`) debe dar **0**.

> Mientras bronze no use `FORMAT = 'CSV'`, `crm_cust_info` y `erp_cust_az12` cargan una fila menos (18,493 y 18,483), y silver `erp_cust_az12` queda con 18,483. Ver el README de gold.

## Scripts idempotentes

Todos los scripts se pueden ejecutar varias veces sin error:
- La base y los schemas se crean solo si no existen (`DB_ID`, `SCHEMA_ID`).
- Las tablas se eliminan y se vuelven a crear (`OBJECT_ID` + `DROP TABLE`).
- Los procedimientos usan `CREATE OR ALTER`.
