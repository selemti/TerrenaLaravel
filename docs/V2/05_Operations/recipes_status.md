# Estado del Módulo de Recetas (2025-10-21)

## Datos existentes
- `selemti.receta_cab`: 123 recetas generadas automáticamente desde `public.menu_item`.
- `selemti.receta_version`: 123 versiones iniciales (versión 1, en borrador).
- Aún no hay registros en `receta_det`, `hist_cost_receta`, `merma_proceso`, `rendimiento_receta`.

## Integraciones activas
- Script `scripts/sync_menu_recipes.php` que recorre el catálogo POS y crea recetas/versión inicial.
- Listado `/recipes` actualizado: consume `receta_cab` y muestra estado de versión.

## Faltantes principales
1. **Editor de recetas** (cabecera, ingredientes, merma, publicación de versión).
2. **Servicio de costeo** (AP→EP, WAC, snapshot en `hist_cost_receta`) y botón de recalculo.
3. **Sincronización automática POS↔Recetas**: trigger/job + mapeo PLU→versión publicada (`menu_item.recepie`).
4. **Subrecetas/modificadores**: árbol PLU → subrecetas → ingredientes, alta automática para `menu_modifier`.
5. **Producción y mermas**: endpoints `/produccion/op`, registrar `rendimiento_receta`, `merma_proceso`.
6. **Documentación**: terminar flujos de costeo, checklist, parámetros en `/recetas`.

## Próximos pasos inmediatos
- Añadir filtros por categoría (ya implementado) y continuar con el editor real.
- Diseñar command/trigger que sincronicen automáticamente nuevas altas POS.
- Escribir servicio de costeo con unidad base e integración con inventario.
