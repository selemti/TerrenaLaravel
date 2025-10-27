
---

### 6. `docs/Replenishment/STATUS_SPRINT_1.8.md`

```md
# 🧭 STATUS SPRINT 1.8 – Reportes y KPIs Operativos

**Objetivo:** Exponer métricas básicas para dirección/operaciones usando los datos ya capturados.  
**Estado general:** 📋 Planificado  
**Fecha:** 2025-10-25  
**Esquema BD:** `selemti`

---

## 1. KPI iniciales
- % de recepción fuera de tolerancia por proveedor
- Tiempo promedio entre PO → Recepción posteada
- Rotación aproximada de inventario por categoría
- Top 10 insumos urgentes (prioridad `URGENTE`)

Estos KPIs alimentan dashboards internos / Livewire.

---

## 2. Trabajo técnico Sprint 1.8

### 2.1 Nuevo controlador:
`app/Http/Controllers/Reports/ReportsController.php`

Acciones READ-ONLY que devuelven JSON, ejemplos:
```php
purchasingLatePO(): JsonResponse
inventoryOverTolerance(): JsonResponse
inventoryTopUrgent(): JsonResponse
Cada método:

arma un query builder (DB::table(...))

return response()->json(['ok' => true, 'data' => $rows])

// TODO caching/report snapshots

2.2 Rutas

Bajo /api/reports/...:

GET /api/reports/purchasing/late-po

GET /api/reports/inventory/over-tolerance

GET /api/reports/inventory/top-urgent

2.3 Permisos

reports.view.purchasing

reports.view.inventory

3. Criterio de cierre Sprint 1.8

ReportsController creado.

Rutas GET creadas.

Cada acción arma el esqueleto de query builder (sin lógica compleja todavía).

Comentado el TODO de cache/snapshots para futuro.