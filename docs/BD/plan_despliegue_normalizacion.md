# Plan de Despliegue para Normalización de Base de Datos
Fecha: jueves, 30 de octubre de 2025

## Objetivo
Implementar los cambios de normalización de base de datos con validaciones rápidas para confirmar que todo quedó correctamente.

## Fase 1: Preparación
1. Crear backup completo de la base de datos
2. Realizar cambios en entorno de desarrollo/pruebas
3. Validar funcionalidad crítica antes de implementar en producción

## Fase 2: Implementación
Sigue el orden de ejecución recomendado:
1. BD/cat_unidades_optimizacion.sql
2. BD/campos_redundantes_eliminacion.sql
3. BD/pos_map_tipo_correccion.sql
4. BD/tipos_datos_correccion.sql
5. BD/recipe_cost_history_fk.sql
6. BD/inventory_snapshot_migracion.sql
7. BD/mejora_constraints.sql
8. BD/indices_alto_trafico.sql
9. BD/trigger_pos_map_solapes.sql

## Checks Rápidos para Validar "Ya Quedó"

Copia estos comandos tal cual en psql (ajusta selemti si usas otro esquema):

### 1) Tablas potencialmente duplicadas por "shape" (mismo set de columnas)
```sql
WITH cols AS (
  SELECT table_schema, table_name,
         array_agg(column_name ORDER BY ordinal_position) AS colnames
  FROM information_schema.columns
  WHERE table_schema IN ('public','selemti')
  GROUP BY 1,2
),
shapes AS (
  SELECT c1.table_schema, c1.table_name,
         c2.table_schema AS other_schema, c2.table_name AS other_table,
         c1.colnames
  FROM cols c1
  JOIN cols c2
    ON c1.colnames = c2.colnames
   AND (c1.table_schema, c1.table_name) < (c2.table_schema, c2.table_name)
)
SELECT * FROM shapes
ORDER BY colnames, table_schema, table_name;
```

**Qué buscar**: pares table_name/other_table con columnas idénticas. Si aparecen, revisamos caso por caso (migrar datos → consolidar → crear vista con el nombre que "desaparece" para no romper UI).

### 2) Tablas "huérfanas" (sin FKs que las referencien)
```sql
SELECT n.nspname AS schema, c.relname AS table
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind='r'
  AND n.nspname IN ('public','selemti')
  AND NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints tc
    WHERE tc.constraint_type='FOREIGN KEY'
      AND (tc.table_schema, tc.table_name) = (n.nspname, c.relname)
  )
  AND NOT EXISTS (
    SELECT 1
    FROM information_schema.referential_constraints rc
    JOIN information_schema.key_column_usage kcu
      ON rc.unique_constraint_name = kcu.constraint_name
     AND rc.unique_constraint_schema = kcu.constraint_schema
    WHERE kcu.table_schema = n.nspname
      AND kcu.table_name   = c.relname
  )
ORDER BY 1,2;
```

**Qué buscar**: tablas sin FKs "entrando" ni "saliendo". Algunas pueden ser catálogos legítimos; las demás, candidatas a limpieza o a documentar su relación.

### 3) Consistencia de Unidades base (solo KG, L, EA)
```sql
-- ¿Existen unidades "raras"?
SELECT DISTINCT u.codigo, u.nombre
FROM selemti.cat_unidades u
WHERE u.codigo NOT IN ('KG','L','EA');

-- ¿Items con unidad no mapeada?
SELECT i.id, i.nombre, i.unidad_medida_id
FROM selemti.items i
LEFT JOIN selemti.cat_unidades u ON u.id = i.unidad_medida_id
WHERE u.codigo NOT IN ('KG','L','EA');
```

**Objetivo**: que la primera devuelva 0 filas (catálogo limpio) y la segunda también (todo item se ciñe a KG/L/EA).

Extra (recomendado): un CHECK en cat_unidades.codigo para limitar a ('KG','L','EA') y que cualquier "presentación" se modele con factor de conversión en otra entidad (proveedor–presentación), no como unidad base.

### 4) UI estable tras el cambio en inventory_snapshot.item_id
```sql
-- ¿Existen item_id en snapshot que no estén en items?
SELECT s.item_id
FROM selemti.inventory_snapshot s
LEFT JOIN selemti.items i ON i.id::text = s.item_id::text
WHERE i.id IS NULL
GROUP BY s.item_id;

-- ¿Y a la inversa, items sin snapshot del día X?
-- \set bdate 2025-10-29
SELECT i.id
FROM selemti.items i
LEFT JOIN selemti.inventory_snapshot s
  ON s.item_id::text = i.id::text
 AND s.snapshot_date = :'bdate'::date
WHERE s.item_id IS NULL
LIMIT 50;
```

**Esperado**: primeras 0 filas (nada "huérfano" en snapshot).

Si hay faltantes, se cubren con generateDailySnapshot (ya orquestado) o corrigiendo mapeos.

## Fase 3: Validación Post-Implementación
1. Validar funcionalidad crítica: cálculo de costos, mapeo POS, cierre diario
2. Verificar rendimiento de consultas comunes
3. Confirmar que vistas de compatibilidad funcionan correctamente
4. Revisar logs del sistema en busca de errores

## Fase 4: Documentación y Seguimiento
1. Actualizar documentación técnica con nuevos esquemas
2. Documentar cambios en componentes del sistema
3. Planificar actualización de código backend/frontend según el documento: docs/BD/ajustes_codigo_post_migracion.md
4. Programar reunión de conocimiento para equipo de desarrollo

## Checklist Final
- [ ] Backup de base de datos realizado
- [ ] Scripts ejecutados en orden correcto
- [ ] Checks rápidos validados
- [ ] Funcionalidad crítica confirmada
- [ ] Documentación actualizada
- [ ] Plan de ajustes de código distribuido al equipo