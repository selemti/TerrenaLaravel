# UI · Recetas

Componentes principales: `App\Livewire\Recipes\RecipesIndex` y `RecipeEditor`.

## 1. Estado Actual

- **RecipesIndex**: muestra listado con búsqueda y paginación. Si la tabla `recipes` no existe, carga datos de demostración (colección en memoria). Permite eliminar registros (demo o reales).
- **RecipeEditor**: placeholder; actualmente sólo renderiza la vista base (`resources/views/livewire/recipes/recipe-editor.blade.php`).

## 2. Funcionalidades Planeadas

| Área | Requerimientos | Fuente original |
|------|----------------|-----------------|
| Recetas base | Campos: código, nombre, rendimiento, unidad, costo, categoría, notas. | `D:\Tavo\2025\UX\00. Recetas\ESPECIFICACIÓN...docx` |
| Componentes / Ingredientes | Múltiples ingredientes con cantidades y UOM. | `Query Recetas\03_modulo_recetas.sql` |
| Pasos | Instrucciones, tiempos, responsables. | `Documentación V1\Acta_Diseno_Tecnico...` |
| Costos | Cálculo automático desde inventario (costo promedio). | Requiere integración con `items` y políticas de stock. |
| Versionado | Historial de cambios, aprobaciones. | Pendiente definir. |

## 3. Base de Datos Necesaria

- Tablas sugeridas:
  - `recipes` (id, codigo, nombre, rendimiento, unidad, categoria, costo, activo, notas, timestamps).
  - `recipe_items` (recipe_id, item_id, cantidad, unidad, merma, costo_unit, costo_total).
  - `recipe_steps` (recipe_id, secuencia, descripcion, tiempo).
- Verificar scripts en `D:\Tavo\2025\UX\00. Recetas\Query Recetas\Full_Recetas*.sql`.

## 4. UX / Assets

- Mockups en `D:\Tavo\2025\UX\00. Recetas\Documentación V1\` y carpeta `ia`, `v2`.
- Recetario Excel (`RECETARIO YESI.xlsx`) como fuente para datos iniciales.

## 5. Pendientes

- [ ] Diseñar esquema definitivo y crear migraciones.  
- [ ] Reemplazar datos demo por consultas reales.  
- [ ] Definir roles/permisos (quién edita o aprueba recetas).  
- [ ] Integrar cálculo de costo en tiempo real.  
- [ ] Documentar API REST correspondiente (si aplica).  
- [ ] Escribir pruebas (validaciones, flujos de guardado).  

Actualiza este documento conforme avance el módulo de recetas.
