
---

### 5. `docs/Replenishment/STATUS_SPRINT_1.7.md`

```md
# 🧭 STATUS SPRINT 1.7 – Producción Interna y Consumo

**Objetivo:** Registrar consumo interno de insumos para producir recetas / preparados y reflejarlo en inventario.  
**Estado general:** 📋 Planificado  
**Fecha:** 2025-10-25  
**Esquema BD:** `selemti`

---

## 1. Flujo
1. Cocina planea producir un batch de una receta.
2. Se descuentan insumos (harina, leche, etc.) del inventario de cocina.
3. Se ingresa producto terminado (ej. jarabe base, salsa) al inventario destino (barra / almacén).

Estados:
`PLANIFICADA → EN_PROCESO → COMPLETADA → POSTEADA`

---

## 2. Trabajo técnico Sprint 1.7

### 2.1 Nuevo servicio:
`app/Services/Production/ProductionService.php`

Métodos stub esperados:
```php
planBatch(int $recipeId, float $qtyTarget, int $userId): array
consumeIngredients(int $batchId, array $consumedLines, int $userId): array
completeBatch(int $batchId, array $producedLines, int $userId): array
postBatchToInventory(int $batchId, int $userId): array
// postBatchToInventory genera mov_inv negativo (insumos) y positivo (producto terminado)


2.2 Nuevo controlador:

app/Http/Controllers/Production/ProductionController.php

Acciones REST, respuestas { ok, data, message }, y comentarios // TODO autorización con permisos:

Permisos esperados:

production.batch.plan

production.batch.consume

production.batch.post

2.3 Rutas

Bajo /api/production/...

Ejemplos:

POST /api/production/batch/plan

POST /api/production/batch/{batch_id}/consume

POST /api/production/batch/{batch_id}/complete

POST /api/production/batch/{batch_id}/post

3. Criterio de cierre Sprint 1.7

ProductionService y ProductionController creados con stubs.

Rutas creadas.

Documentado que el sistema genera mov_inv negativo (insumos) y positivo (producto terminado) al postear.