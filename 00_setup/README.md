# Configuración y ejecución

## Requisitos

- **SQL Server** (cualquier edición, incluida Express o Developer) y **SQL Server Management Studio (SSMS)**.
- El proyecto debe estar en `C:\dev\base de datos\sql-data-warehouse-project\`. Las rutas de los CSV están escritas así en `proc_load_bronze.sql`; si el proyecto se mueve, se actualizan esas 6 rutas.
- SQL Server debe estar instalado en el mismo equipo que los archivos. `BULK INSERT` lee las rutas desde el servidor, no desde SSMS.
- La cuenta del servicio de SQL Server necesita permiso de lectura sobre la carpeta `01_datasets`.

## Orden de ejecución

| # | Archivo | Qué hace | Frecuencia |
|---|---|---|---|
| 1 | `03_scripts/init_database.sql` | Crea la base `dw_medallion_sales` y los schemas `bronze`, `silver` y `gold` | Una vez |
| 2 | `03_scripts/bronze/ddl_bronze.sql` | Crea las 6 tablas de bronze | Una vez, o si cambia la estructura |
| 3 | `03_scripts/bronze/proc_load_bronze.sql` | Crea el procedimiento `bronze.load_bronze` | Una vez, o si cambia la carga |
| 4 | `03_scripts/silver/ddl_silver.sql` | Crea las 6 tablas de silver | Una vez, o si cambia la estructura |
| 5 | `03_scripts/silver/proc_load_silver.sql` | Crea el procedimiento `silver.load_silver` | Una vez, o si cambia la carga |
| 6 | Scripts de `03_scripts/gold/` | Crean las vistas del modelo estrella | Una vez, o si cambia el modelo |

## Carga de datos

Cada vez que lleguen datos nuevos:

```sql
EXEC bronze.load_bronze;
EXEC silver.load_silver;
```

Gold no se carga, porque son vistas que leen de silver en el momento de la consulta.

## Scripts idempotentes

Todos los scripts se pueden ejecutar varias veces sin error:
- La base y los schemas se crean solo si no existen (`DB_ID`, `SCHEMA_ID`).
- Las tablas se eliminan y se vuelven a crear (`OBJECT_ID` + `DROP TABLE`).
- Los procedimientos usan `CREATE OR ALTER`.
