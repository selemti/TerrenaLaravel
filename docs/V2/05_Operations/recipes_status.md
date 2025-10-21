# Estado del Módulo de Recetas (2025-10-21)

## Datos existentes
- `selemti.receta_cab`: 123 recetas generadas automáticamente desde `public.menu_item`.
- `selemti.receta_version`: 123 versiones iniciales (versión 1, en borrador).
- Aún no hay registros en `receta_det`, `hist_cost_receta`, `merma_proceso`, `rendimiento_receta`.

## Integraciones activas
- Script `scripts/sync_menu_recipes.php` que recorre el catálogo POS y crea recetas/versión inicial.
- **Comando `php artisan recipes:sync-pos`**: sincroniza PLU desde Floreant (actualiza nombre/categoría/precio, crea versión 1 si falta). Opción `--modifiers` genera placeholders `REC-MOD-xxxxx` en `receta_cab` y los registra en `selemti.modificadores_pos`.
- **Editor Livewire básico**: `/recipes/editor/{id?}` permite editar cabecera y capturar ingredientes. IDs se generan secuencialmente (`REC-xxxxx` para platos, `SUB-xxxxx` para sub-recetas) y se puede convertir placeholders de modificadores (`REC-MOD-xxxxx`).
- Listado `/recipes` actualizado: consume `receta_cab` y muestra estado de versión.
  * Oculta placeholders `REC-MOD-xxxxx`; sólo se muestran platos y sub-recetas reales.
  * Columna principal muestra `Receta · categoria`; el PLU se despliega en una columna secundaria para mayor claridad.

## Faltantes principales
1. **Editor de recetas** (cabecera, ingredientes, merma, publicación de versión).
   - [ ] Agregar buscador de insumos, validación contra catálogo, edición inline de merma/sub-recetas y resumen de costo.
   - [ ] Flujo de publicación/clonado de versiones.
2. **Servicio de costeo** (AP→EP, WAC, snapshot en `hist_cost_receta`) y botón de recalculo.
3. **Sincronización automática POS↔Recetas**: trigger/evento en POS o job programado que ejecute `recipes:sync-pos` al detectar nuevos PLU/modificadores; escribir `menu_item.recepie` con la versión publicada.
4. **Subrecetas/modificadores**: árbol PLU → subrecetas → ingredientes, completar ingredientes reales y enlace automáticos (placeholders listos en `modificadores_pos`).
5. **Producción y mermas**: endpoints `/produccion/op`, registrar `rendimiento_receta`, `merma_proceso`.
6. **Documentación**: terminar flujos de costeo, checklist, parámetros en `/recetas` y actualizar este documento en cada iteración.

## Próximos pasos inmediatos
- Añadir filtros por categoría (ya implementado) y continuar con el editor real.
- Diseñar command/trigger que sincronicen automáticamente nuevas altas POS.
- Escribir servicio de costeo con unidad base e integración con inventario.
