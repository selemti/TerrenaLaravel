# Plan de Normalización y Optimización de Base de Datos
Fecha: jueves, 30 de octubre de 2025

## Objetivo
Normalizar y optimizar la base de datos de Terrena Laravel para mejorar su funcionalidad, rendimiento e integridad referencial.

## Análisis Actual
- La base de datos tiene 140 tablas con ciertas inconsistencias en tipos de datos
- Existen campos redundantes y relaciones no siempre bien definidas
- Algunas tablas usan tipos de datos inconsistentes para la misma entidad

## Cambios Propuestos

### 1. Inconsistencias de Tipos de Datos
- `inventory_snapshot.item_id` usa UUID cuando debería ser VARCHAR(20) para coincidir con `items.id`
- `mov_inv`, `receta_det` y otras tablas usan VARCHAR(20) consistentemente

### 2. Campos Redundantes en Items
- `items.unidad_medida` (VARCHAR) y `items.unidad_medida_id` (INTEGER) representan lo mismo
- `items.categoria_id` (VARCHAR) y `items.category_id` (BIGINT) posiblemente duplicados

### 3. Referencias de Unidades de Medida
- Falta una tabla central para unidades de medida con referencias adecuadas

## Estrategia de Implementación
1. Crear vistas para mantener compatibilidad durante la transición
2. Actualizar tipos de datos inconsistentes
3. Eliminar campos redundantes
4. Implementar referencias adecuadas
5. Asegurar integridad referencial con constraints apropiados