# 🧭 STATUS SPRINT 1.7 – Producción Interna y Consumo

Estado general: 🟨 En progreso  
Fecha: 2025-10-26

## 1. Rutas expuestas (Laravel)
- POST /api/production/batch/plan -> Production\ProductionController@plan
- POST /api/production/batch/{batch_id}/consume -> Production\ProductionController@consume
- POST /api/production/batch/{batch_id}/complete -> Production\ProductionController@complete
- POST /api/production/batch/{batch_id}/post -> Production\ProductionController@post

## 2. Backend
- `ProductionService` contiene stubs para planificar, consumir insumos, completar y postear batches; valida IDs/cantidades y deja TODOs para mov_inv negativos/positivos.
- `ProductionController` inyecta el servicio, normaliza arreglos `lines`, responde `{ok, data, message}` y mantiene `TODO` de permisos `production.batch.*`.
- El módulo está aislado bajo `/api/production`, listo para conectar con recetas y menús POS.

## 3. Pendiente para cerrar sprint
- Calcular insumos con base en recipe_versions y validar inventario antes de consumir.
- Persistir producción real (cabecera/detalle) y métricas de rendimiento.
- Generar movimientos `mov_inv` negativos (insumos) y positivos (producto terminado) en el posteo.

## 4. Riesgos / Bloqueantes
- Dependencia de catálogos de recetas y equivalencias UOM; sin ellos no se puede calcular consumo.
- Falta de policies permitiría planear batches sin autorización del área de producción.
- Riesgo contable si se postea producción dos veces sin bloqueo transaccional.

## 5. Siguiente paso inmediato
Integrar recipe BOMs en `ProductionService::consumeIngredients()` para descontar insumos reales.
