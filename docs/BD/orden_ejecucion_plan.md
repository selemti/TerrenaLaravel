# Plan de Ejecución para Normalización y Optimización de Base de Datos
Fecha: jueves, 30 de octubre de 2025

## Objetivo
Implementar los cambios de normalización y optimización de forma segura y compatible con el ecosistema Terrena.

## Orden de Ejecución Recomendado (Idempotente y Seguro)

### Paso 1: Respaldo
```sql
-- CREAR BACKUP COMPLETO DE LA BASE DE DATOS ANTES DE PROCEDER
-- IMPORTANTE: No omitir este paso
```

### Paso 2: Actualización de cat_unidades
```sql
-- Ejecutar: BD/cat_unidades_optimizacion.sql
-- Incluye:
-- - Creación de registros base (PZ, KG, L, etc.)
-- - Índices para mejor rendimiento
-- - Constraints de formato
```

### Paso 3: Eliminación de campos redundantes en items
```sql
-- Ejecutar: BD/campos_redundantes_eliminacion.sql
-- Incluye:
-- - Creación de tabla items_optimized
-- - Copia de datos
-- - Renombramiento de tablas
-- - Creación de vistas de compatibilidad v_items_legacy
```

### Paso 4: Corrección de tipos de datos
```sql
-- Ejecutar: BD/pos_map_tipo_correccion.sql
-- Asegura compatibilidad con valores MENU/MODIFIER en lugar de PLATO/MODIFICADOR

-- Ejecutar: BD/tipos_datos_correccion.sql (parcial)
-- Incluye cambios de pos_map.receta_id, pero no recipe_cost_history aún
```

### Paso 5: Conversión de recipe_cost_history con FK asegurada
```sql
-- Ejecutar: BD/recipe_cost_history_fk.sql
-- Incluye:
-- - Conversión de recipe_id a varchar(20)
-- - Aplicación de FK inmediatamente después
```

### Paso 6: Manejo de inventory_snapshot
```sql
-- Ejecutar: BD/inventory_snapshot_migracion.sql
-- Opción 1: Usando vistas de compatibilidad (recomendado para tablas grandes)
-- Opción 2: Si tabla no es muy grande, aplicar conversión directa con FK
```

### Paso 7: Aplicación de constraints e índices
```sql
-- Ejecutar: BD/mejora_constraints.sql
-- Aplica todas las FKs, checks y validaciones pendientes

-- Ejecutar: BD/indices_alto_trafico.sql
-- Crea índices específicos para joins de alto tráfico
```

### Paso 8: Implementación de triggers de validación
```sql
-- Ejecutar: BD/trigger_pos_map_solapes.sql
-- Implementa trigger para evitar solapes de vigencia en pos_map
```

## Validaciones Críticas Post-Implementación

1. **Validación de integridad referencial**:
   - Confirmar que todas las FKs se aplicaron correctamente
   - Verificar que no hay registros huérfanos

2. **Validación de funcionalidad crítica**:
   - Cálculo de costos de recetas
   - Mapeo POS-Receta
   - Generación de snapshots
   - Consultas de auditoría

3. **Rendimiento**:
   - Verificar que los índices mejoren el rendimiento esperado
   - Validar tiempos de respuesta en consultas críticas

## Consideraciones de Seguridad

1. **Ejecutar en ventana de mantenimiento** para evitar conflictos concurrentes
2. **Validar con la UI existente** que todas las funcionalidades continúen operativas
3. **Revisar logs de aplicaciones** después de la implementación
4. **Tener plan de rollback** preparado en caso de problemas críticos

## Aplicaciones Afectadas a Validar

- **Módulo de Mapeos POS**: `/pos/mapping`
- **Cálculo de Costos**: `RecalcularCostosRecetasService`
- **Cierre Diario**: `DailyCloseService` 
- **Generación de Snapshots**: `inventory_snapshot` queries
- **Consultas de Auditoría**: `verification_queries_psql_v6.sql`

## Resultados Esperados

- Mayor integridad referencial
- Mejor rendimiento en consultas frecuentes
- Estructura más coherente y mantenible
- Compatibilidad mantenida con aplicaciones existentes
- Preparación para futuras optimizaciones

## Notas Adicionales

- El sistema mantiene compatibilidad con vistas legado durante la transición
- Valores antiguos como 'PLATO'/'MODIFICADOR' se convierten gradualmente a 'MENU'/'MODIFIER'
- Los índices están optimizados para los patrones de consulta comunes del sistema
- Los triggers previenen errores de datos en tiempo real