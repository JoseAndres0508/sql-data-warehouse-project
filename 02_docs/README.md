# Documentación del proyecto

## Requisitos (de la presentación de la clase)

- **Objetivo:** almacén de datos moderno en SQL Server que consolida información de ventas para reportes analíticos y toma de decisiones.
- **Fuentes:** dos sistemas, ERP y CRM, entregados como CSV.
- **Calidad:** los problemas de calidad se limpian y resuelven antes del análisis.
- **Integración:** ambas fuentes se combinan en un único modelo fácil de usar para consultas analíticas.
- **Alcance:** solo el conjunto de datos más reciente, sin historial.
- **Documentación:** el modelo se documenta para usuarios de negocio y equipos de análisis.

## Convenciones de nombres

### Principios generales
- Formato `snake_case`: minúsculas y palabras separadas por `_`.
- Todos los nombres en inglés.
- No se usan palabras reservadas de SQL como nombres.

### Tablas

| Capa | Patrón | Ejemplo |
|---|---|---|
| bronze | `<sourcesystem>_<entity>`, con la entidad igual al nombre de origen | `crm_cust_info` |
| silver | `<sourcesystem>_<entity>`, con la entidad igual al nombre de origen | `crm_cust_info` |
| gold | `<category>_<entity>`, con nombres del negocio | `dim_customers`, `fact_sales` |

Prefijos de categoría en gold: `dim_` para dimensiones, `fact_` para hechos y `report_` para reportes.

### Columnas
- **Claves subrogadas:** `<entity>_key`, por ejemplo `customer_key` en `dim_customers`.
- **Columnas técnicas:** prefijo `dwh_`, por ejemplo `dwh_create_date`.
- En bronze y silver, los nombres de columna son los del sistema de origen, en minúsculas.

### Procedimientos almacenados
- Patrón `load_<layer>`, dentro del schema de su capa: `bronze.load_bronze`, `silver.load_silver`.

## Criterio de calidad de datos

La presentación pide resolver los problemas de calidad, pero no define cómo. Este es el criterio aplicado en todo el proyecto:

| Situación | Decisión |
|---|---|
| Fila sin clave primaria | Se elimina: no se puede relacionar con nada. |
| Fila duplicada por clave | Se conserva la versión más reciente y se eliminan las anteriores. |
| Texto descriptivo vacío o código desconocido | Se reemplaza por `n/a`. |
| Código abreviado (`M`, `S`, `F`, `R`…) | Se traduce al nombre completo (`Married`, `Single`, `Female`, `Road`…). |
| Espacios al inicio o al final | Se eliminan con `TRIM`. |
| Mismo valor escrito de varias formas (`US`, `USA`) | Se estandariza a un único valor (`United States`). |
| Valor numérico vacío que se va a sumar (costo) | Se reemplaza por `0`. |
| Valor que se puede calcular a partir de otros (ventas, precio) | Se recalcula con la regla de negocio. |
| Fecha inválida o imposible (futuro, formato incorrecto) | Se deja en `NULL`: nunca se inventa una fecha. |
| Fecha de fin de un registro vigente | `NULL`, que significa "vigente". |

**Principio general:** se elimina solo lo que no se puede usar; lo que se puede deducir se calcula, y lo que falta se marca (`n/a` en texto, `NULL` en fechas).

El detalle por tabla está en `03_scripts/silver/README.md`.
