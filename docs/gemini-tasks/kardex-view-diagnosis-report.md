# Reporte de Diagnóstico: KardexView y Datos de Inventario

## 1. Resumen de Ejecución y Hallazgos (Local)
He ejecutado las consultas de diagnóstico en la base de datos `pos` local (`localhost:5433`). Los resultados son los siguientes:

- **`selemti.mov_inv`**: `0` filas.
- **`selemti.inventory_batch`**: `0` filas.

Al igual que ocurrió en el análisis previo, el esquema local `selemti` se encuentra vacío de datos transaccionales, muy probablemente porque las suites de testing (que utilizan `RefreshDatabase`) limpian rutinariamente este esquema (ya que el archivo `phpunit.xml` tiene configurado correctamente `DB_SCHEMA=selemti` para proteger `public`). 

Como nota adicional, validé que `public.ticket` **sí contiene** sus 109,684 registros originales intactos, lo que confirma que el Invariante Crítico de protección del esquema legacy se está respetando correctamente en los entornos de prueba.

Debido a que no hay datos en `selemti.mov_inv` localmente, las consultas de totales, tipos, inconsistencias y la muestra del Kardex devuelven conjuntos vacíos.

## 2. Inconsistencias de Datos Encontradas
- **Almacenes huérfanos / Batches negativos**: No evaluable localmente. 
- **Totales NULL**: No evaluable localmente.

## 3. Muestra del Kardex
Al no existir un `item_id` con movimientos en el entorno local, la consulta:
```sql
SELECT
    m.id,
    m.ts,
    m.tipo,
    COALESCE(m.cantidad, m.qty) as qty,
    m.ref_tipo,
    m.ref_id,
    m.almacen_id
FROM selemti.mov_inv m
ORDER BY m.ts, m.id
LIMIT 30;
```
Devuelve `0 filas`.

## 4. Opinión Técnica y Siguientes Pasos
Para que la UI del `KardexView` pueda reflejar datos reales y validar la deuda técnica (NULLs, huérfanos, inconsistencias de tipos), es necesario **ejecutar estas consultas directamente en un volcado de producción (o en la réplica)**. 

El servicio `KardexService` en PHP calculará correctamente el balance en base a las filas de `mov_inv`. Si en producción existieran valores NULL en `cantidad` o `qty`, el balance corriente fallaría (matemáticamente sumar NULL propaga el NULL o lo trata como cero dependiendo de la hidratación de Eloquent, pero rompe la lógica de la capa de aplicación). 

**Recomendación:**
Dado que este diagnóstico es de solo lectura y no bloquea directamente el desarrollo de `KardexView`, te sugiero continuar con el *KardexView wiring* usando factorías (seeds) o datos de prueba en tu entorno local. Si me proporcionas un volcado reciente de la tabla `selemti.mov_inv` de producción, puedo realizar el análisis forense de la deuda técnica sin alterar tu base de datos local.
