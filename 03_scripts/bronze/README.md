# Capa bronze

Datos originales, sin procesar, tal como llegan de los CSV. Sirve para trazabilidad y para depurar problemas: si algo sale mal en silver o gold, se puede comparar contra el dato original.

## Archivos

| Archivo | Contenido |
|---|---|
| `ddl_bronze.sql` | Crea las 6 tablas. Si existen, las elimina y las vuelve a crear. |
| `proc_load_bronze.sql` | Crea el procedimiento `bronze.load_bronze`. |

Uso: `EXEC bronze.load_bronze;`

## Decisiones

- **Sin transformaciones.** Los datos se cargan exactamente como vienen, con espacios, duplicados y errores incluidos. Toda la limpieza ocurre en silver.
- **Nombres de tabla:** `<sourcesystem>_<entity>`, con el sistema tomado de la carpeta y la entidad del nombre del archivo, en minúsculas.
- **Nombres de columna:** los del encabezado del CSV, en el mismo orden y en minúsculas.
- **Sin columnas técnicas** (`dwh_`). Las tablas reflejan el CSV exactamente, para que `BULK INSERT` cargue directo sin tabla intermedia.
- **Tipos de datos:**
  - Texto como `NVARCHAR(50)`, con margen de sobra sobre la longitud máxima real.
  - Números como `INT` y fechas `yyyy-mm-dd` como `DATE`, porque todos los valores reales lo permiten.
  - Las fechas de `crm_sales_details` (`sls_order_dt`, `sls_ship_dt`, `sls_due_dt`) quedan como `INT`, porque vienen como `20101229` y algunas son inválidas (`0`, `5489`). Se convierten a fecha en silver.
- **Carga completa (truncar e insertar):** cada ejecución vacía la tabla con `TRUNCATE` y la vuelve a llenar con `BULK INSERT`. Esto cumple el alcance de "solo los datos más recientes" y evita duplicados al recargar.
- **Opciones de `BULK INSERT`:** `FIRSTROW = 2` para saltar los encabezados, `FIELDTERMINATOR = ','` y `TABLOCK` para mayor velocidad.
- **Rutas absolutas** a `C:\dev\base de datos\sql-data-warehouse-project\01_datasets\`.
- **El procedimiento** muestra con `PRINT` las filas y el tiempo de cada tabla y el tiempo total, y captura errores con `TRY...CATCH`, mostrando el mensaje y volviendo a lanzar el error con `THROW`.
- **Las validaciones no están dentro del procedimiento:** el procedimiento solo carga.

## Tablas y filas esperadas

| Tabla | Origen | Filas |
|---|---|---|
| `bronze.crm_cust_info` | `source_crm/cust_info.csv` | 18,494 |
| `bronze.crm_prd_info` | `source_crm/prd_info.csv` | 397 |
| `bronze.crm_sales_details` | `source_crm/sales_details.csv` | 60,398 |
| `bronze.erp_cust_az12` | `source_erp/CUST_AZ12.csv` | 18,484 |
| `bronze.erp_loc_a101` | `source_erp/LOC_A101.csv` | 18,484 |
| `bronze.erp_px_cat_g1v2` | `source_erp/PX_CAT_G1V2.csv` | 37 |
