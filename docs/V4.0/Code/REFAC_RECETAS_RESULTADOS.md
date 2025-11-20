# Refactor Recetas – Alineación BD ↔ Código

## 1. Resumen
- MISMATCH corregidos (confirmados contra BD): 1
- FANTASMA atendidos (comentados / TODO): 0
- Total conflictos mapa ↔ BD (ERROR_MAPA detectados): 2

## 2. Análisis de conflictos en el mapa
Durante la validación, se detectaron 2 casos donde el archivo de mapeo tenía errores:
- Recetas.pos_map.meta: marcado como 'FANTASMA' pero SI existe en BD
- Recetas.pos_map.vigente_desde: marcado como 'FANTASMA' pero SI existe en BD

Esto indica que el archivo de mapeo marcaba estas columnas como inexistentes cuando en realidad sí existen en la base de datos.

## 3. Cambios por tabla/columna
| Tabla | Columna | Tipo (MISMATCH/FANTASMA) | Archivos afectados | Acción |
|-------|---------|---------------------------|-------------------|---------|
| pos_map | receta_version_id | MISMATCH | app/Models/PosMap.php | cambié recipe_version_id → receta_version_id en $fillable |
| pos_map | receta_version_id | MISMATCH | app/Livewire/Pos/PosMappingForm.php | cambié property recipe_version_id → receta_version_id |
| pos_map | receta_version_id | MISMATCH | resources/views/livewire/pos/pos-mapping-form.blade.php | cambié wire:model y @error de recipe_version_id a receta_version_id |
| pos_map | receta_version_id | MISMATCH | app/Services/Pos/Repositories/RecetaRepository.php | cambié el campo consultado en la base de datos |

## 4. Archivos modificados
- `app/Models/PosMap.php` - Corrección del nombre de columna en $fillable de recipe_version_id a receta_version_id
- `app/Livewire/Pos/PosMappingForm.php` - Actualización de propiedad, regla de validación y referencia en el método create
- `resources/views/livewire/pos/pos-mapping-form.blade.php` - Actualización de wire:model y directiva @error
- `app/Services/Pos/Repositories/RecetaRepository.php` - Corrección en consulta de base de datos para usar nombre correcto de columna

## 5. Notas importantes
- Se encontraron discrepancias en el archivo de mapeo que marcaba como FANTASMA columnas que sí existen en la base de datos (meta y vigente_desde).
- El campo `receta_version_id` en la tabla `pos_map` es el que debe usarse en lugar de `recipe_version_id`.
- La tabla `recipe_version_items` (diferente a `pos_map`) sí usa el nombre en inglés `recipe_version_id`, lo cual es correcto y no se modificó.
- El modelo PosMap ya usaba el campo `meta` correctamente, lo que contradice el archivo de mapeo que lo marcaba como FANTASMA.

## 6. TODOs importantes
No se requieren TODOs en este caso ya que se logró alinear el código con la estructura real de la base de datos.