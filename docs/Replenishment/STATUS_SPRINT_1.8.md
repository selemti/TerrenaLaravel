# 🧭 STATUS SPRINT 1.8 – Reportes y KPIs Operativos

Objetivo: Exponer métricas básicas para dirección/operaciones desde datos que ya capturamos.

Estado general: Planificado  
Fecha: 2025-10-25  
Esquema BD: `selemti`

---

## 1. KPI iniciales
- % de recepción fuera de tolerancia por proveedor
- Tiempo promedio entre PO → Recepción posteada
- Rotación aproximada de inventario por categoría
- Top 10 insumos urgentes (prioridad URGENTE)

---

## 2. Trabajo técnico Sprint 1.8
- `ReportsController` bajo `/api/reports/...`
  Endpoints read-only, sin mutar BD.
  Ejemplo:
  - `/api/reports/purchasing/late-po`
  - `/api/reports/inventory/over-tolerance`
  - `/api/reports/inventory/top-urgent`

- Cada método arma un query builder (DB::table(...)) y regresa JSON consumible por dashboard interno Livewire más tarde.

- No necesitamos cache todavía, pero dejar TODO para caching/report snapshots futuro.

---

## 3. Permisos
- reports.view.purchasing
- reports.view.inventory
