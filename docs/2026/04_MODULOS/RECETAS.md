# Módulo de Recetas y Costeo
> Actualizado: Abril 2026

## Conceptos

- **Receta** — estructura de ingredientes para producir un platillo (BOM)
- **Versión de receta** — historial de cambios con costeo asociado
- **BOM (Bill of Materials)** — lista explodida de ingredientes con cantidades y costos
- **Snapshot de costo** — fotografía del costo en un punto en el tiempo

---

## Flujo de Costeo

```
Receta (ingredientes + cantidades)
        │
        ▼
RecipeCostingService (calcula costo usando WAC actual de cada ítem)
        │
        ├── RecipeCostSnapshotService (guarda snapshot histórico)
        │
        ▼
historial_costos_receta (costo por versión + fecha)
```

---

## Componentes Livewire

| Componente | Ruta | Descripción |
|-----------|------|------------|
| RecipesIndexLW | `/recipes` | Lista de recetas |
| RecipeEditorLW | `/recipes/editor/{id?}` | Editor de receta + BOM |
| VersionComparator | `/recipes/{id}/versions` | Comparar versiones |
| VersionActivator | (integrado) | Activar versión |
| UnidadesIndex | (catálogos) | Unidades de medida |
| PresentacionesIndex | (catálogos) | Presentaciones |
| ConversionesIndex | (catálogos) | Conversiones |

---

## Servicios

| Servicio | Líneas | Estado |
|----------|--------|--------|
| RecalcularCostosRecetasService | 470 | ✅ |
| RecipeCostingService (Costing/) | 331 | ✅ |
| RecipeVersionService | 296 | ✅ |
| RecipeCostService | 116 | ✅ |
| RecipeCostSnapshotService | 164 | ✅ |

---

## API Endpoints

```
GET  /api/recipes/{id}/cost           → Costo actual (WAC)
GET  /api/recipes/{id}/bom/implode    → BOM desplegado (ingredientes + sub-recetas)
POST /api/recipes/{id}/cost/snapshot  → Guardar snapshot de costo
GET  /api/recipes/{id}/cost/history   → Histórico de costos
GET  /api/recipes/{id}/cost/compare   → Comparar dos versiones
```

---

## Tablas

| Tabla | Descripción |
|-------|------------|
| `recetas` | Cabecera: nombre, rendimiento, categoría |
| `receta_detalle` | Ingredientes: item_id, cantidad, unidad_id |
| `receta_version` | Versiones con costo calculado |
| `receta_shadow` | Versión en borrador |
| `historial_costos_receta` | Snapshots WAC por fecha |

---

## Integración con Producción

Las recetas son la base de las `ordenes_produccion`. Cuando se ejecuta una orden:
1. `ProductionService` lee la receta activa
2. Calcula los insumos necesarios según rendimiento
3. Genera movimientos de salida en inventario (`inventory_batch`)
4. Actualiza el costo promedio del producto terminado
