# DEVLOG Sprint 1 · REC-001 (UI Versionado)

## Cambios realizados
- Nuevo componente Livewire `VersionComparator` con vista interactiva para cargar receta, seleccionar dos versiones y mostrar diff (ingredientes agregados/removidos/modificados) usando `RecipeVersionService::compareVersions`.
- Componente `VersionActivator` embebido para publicar versiones desde la misma pantalla, reutilizando `RecipeVersionService::publishVersion` y refrescando el comparador.
- Ruta web `/recipes/{id}/versions` registrada y accesos directos desde el listado de recetas.
- Prueba de integración `tests/Feature/RecipeVersioningTest.php` con mocks de servicio que valida carga de historial, mapeo de diff y publicación de versión.

## Notas
- Las vistas usan layout Terrena y mantienen badges para identificar versión publicada.
- Se optó por claves dinámicas para remount del activador cuando cambia `recipeId`, evitando estado inconsistente.
