# sql-data-warehouse-project

Almacén de datos de ventas construido en **SQL Server** con **arquitectura Medallion** (bronze → silver → gold). Consolida dos sistemas de origen, un **CRM** y un **ERP**, entregados como archivos CSV, en un modelo listo para reportes y análisis.

## Arquitectura

| Capa | Contenido | Tipo de objeto | Carga | Transformación |
|---|---|---|---|---|
| **bronze** | Datos originales, tal como llegan | Tablas | Completa: truncar e insertar (`BULK INSERT`) | Ninguna |
| **silver** | Datos limpios y estandarizados | Tablas | Completa: truncar e insertar (`INSERT ... SELECT`) | Limpieza, estandarización, normalización, columnas derivadas |
| **gold** | Datos listos para el negocio | Vistas | No aplica | Integración, reglas de negocio, modelo estrella |

## Decisiones generales

- **Una sola base de datos con tres schemas** (`bronze`, `silver`, `gold`). La presentación ofrece dos alternativas; se eligió esta en lugar de tres bases de datos (`DW_Bronze`, `DW_Silver`, `DW_Gold`) porque es más simple de administrar y permite consultas entre capas sin referencias entre bases.
- **Base de datos:** `dw_medallion_sales`, en `snake_case` y en inglés, según las convenciones de nombres.
- **Alcance:** solo se trabaja con el conjunto de datos más reciente. No se guarda historial; cada carga reemplaza los datos anteriores.
- **Pruebas:** la carpeta `04_tests` de la guía no se implementa en esta entrega por tiempo. La validación se hizo con conteos de filas y consultas puntuales, documentadas en el README de cada capa.
- **Datos de origen fuera de Git:** las carpetas `source_crm/` y `source_erp/` están en `.gitignore`.

## Estructura

```
sql-data-warehouse-project/
├── 00_setup/           Guía de configuración y orden de ejecución
├── 01_datasets/
│   ├── source_crm/     3 archivos CSV del CRM
│   └── source_erp/     3 archivos CSV del ERP
├── 02_docs/            Convenciones de nombres y criterios de calidad de datos
└── 03_scripts/
    ├── init_database.sql
    ├── bronze/
    ├── silver/
    └── gold/
```
