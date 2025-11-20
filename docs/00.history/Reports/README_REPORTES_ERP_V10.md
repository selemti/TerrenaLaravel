## Reportes ERP Terrena – versión V10

Este documento resume los cuatro reportes operativos habilitados en el módulo de **📊 Reportes → Ventas**. Cada sección incluye la descripción funcional, el origen SQL, el endpoint API de apoyo y la ruta web asociada.

---

### 1. 📈 Mix de Ventas

- **Objetivo:** comparar la participación de cada forma de pago (efectivo, tarjetas, vales, transferencias, etc.) y consolidar la facturación por sucursal dentro de un rango de fechas.
- **Dato origen:** `SELECT * FROM public.f_sales_mix_payment_on(:date)` (se invoca una vez por día dentro del rango)
- **Endpoint API:** `GET /api/reports/sales/mix?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&branch=BRANCH_KEY`
- **Ruta web:** `GET /reports/sales/mix`

```json
{
  "success": true,
  "range": {
    "start": "2025-10-01",
    "end": "2025-10-07"
  },
  "branch": null,
  "summary": {
    "total_general": 185430.55,
    "payments": [
      { "key": "CASH", "label": "Efectivo", "amount": 74320.00, "percentage": 40.08 },
      { "key": "CREDIT_CARD", "label": "Tarjeta crédito", "amount": 61580.75, "percentage": 33.22 }
    ],
    "branches": [
      { "key": "MTY_01", "label": "Monterrey Centro", "amount": 90540.12, "percentage": 48.83 }
    ],
    "metrics": { "total_methods": 4, "total_branches": 3 },
    "days": ["2025-10-01", "2025-10-02", "2025-10-03", "2025-10-04", "2025-10-05", "2025-10-06", "2025-10-07"]
  },
  "data": [
    {
      "report_date": "2025-10-01",
      "branch_key": "MTY_01",
      "normalized_payment": "CASH",
      "total": "18210.00"
    },
    {
      "report_date": "2025-10-01",
      "branch_key": "MTY_02",
      "normalized_payment": "CREDIT_CARD",
      "total": "15250.50"
    }
  ],
  "generated_at": "2025-10-07T23:32:11-06:00"
}
```

---

### 2. 💵 Cajón vs Efectivo

- **Objetivo:** detectar diferencias entre el efectivo esperado por transacciones POS y el efectivo reportado en corte de caja, destacando la severidad de cada terminal.
- **Dato origen:** `SELECT * FROM public.f_diag_drawer_vs_cash_transactions_on(:date)` (se ejecuta por día dentro del rango)
- **Endpoint API:** `GET /api/reports/sales/drawer?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&branch=BRANCH_KEY&severity=CRITICAL`
- **Ruta web:** `GET /reports/sales/drawer`

```json
{
  "success": true,
  "range": {
    "start": "2025-10-20",
    "end": "2025-10-24"
  },
  "branch": "MTY_01",
  "severity": "CRITICAL",
  "summary": {
    "total_terminals": 26,
    "discrepancies_count": 4,
    "total_expected": 215230.75,
    "total_registered": 213010.60,
    "total_difference": -2220.15,
    "critical_count": 4,
    "warning_count": 3,
    "info_count": 19,
    "branches": [
      { "key": "MTY_01", "label": "Monterrey Centro", "expected": 215230.75, "registered": 213010.60, "difference": -2220.15 }
    ],
    "days": ["2025-10-20", "2025-10-21", "2025-10-22", "2025-10-23", "2025-10-24"]
  },
  "data": [
    {
      "report_date": "2025-10-24",
      "terminal": "POS-03",
      "branch_key": "MTY_01",
      "efectivo_esperado": "15890.50",
      "efectivo_registrado": "14970.35",
      "diferencia": "-920.15",
      "severidad": "CRITICAL"
    }
  ],
  "generated_at": "2025-10-24T08:15:03-06:00"
}
```

---

### 3. ⚙️ Diagnósticos diarios

- **Objetivo:** monitorear vistas operativas (auditorías, balances, procesos automáticos) y priorizar incidencias por severidad INFO/WARN/CRITICAL.
- **Dato origen:** `SELECT * FROM public.f_daily_diagnostics_summary_on(:date)`
- **Endpoint API:** `GET /api/reports/sales/diagnostics?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&severity=WARN`
- **Ruta web:** `GET /reports/sales/diagnostics`

```json
{
  "success": true,
  "range": {
    "start": "2025-11-01",
    "end": "2025-11-03"
  },
  "severity": "WARN",
  "summary": {
    "total_checks": 48,
    "filtered_count": 17,
    "critical_count": 6,
    "warning_count": 17,
    "info_count": 25,
    "total_rows_affected": 17,
    "severity_filter": "WARN",
    "views": [
      { "view": "Neto vs cobros", "raw_view": "vw_diag_neto_vs_cobros", "severity": "WARN", "count": 8, "report_date": "2025-11-03" }
    ]
  },
  "data": [
    {
      "report_date": "2025-11-03",
      "source_view": "vw_diag_neto_vs_cobros",
      "severity": "WARN",
      "rows": 8
    }
  ],
  "generated_at": "2025-11-03T07:58:41-06:00"
}
```

---

### 4. 🍱 Ítems + Modificadores

- **Objetivo:** visualizar los modificadores más vendidos por ítem, identificar ingresos adicionales y detectar patrones de consumo dentro de un rango de fechas.
- **Dato origen:** `SELECT * FROM public.f_item_mods_on(:date)`
- **Endpoint API:** `GET /api/reports/sales/mods?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD&branch=BRANCH_KEY`
- **Ruta web:** `GET /reports/sales/mods`

```json
{
  "success": true,
  "range": {
    "start": "2025-10-01",
    "end": "2025-10-08"
  },
  "branch": null,
  "summary": {
    "total_items": 22,
    "total_modifiers": 18,
    "total_combinations": 47,
    "total_amount": 9280.40,
    "total_selections": 312,
    "avg_amount_per_selection": 29.74,
    "top_modifiers": [
      { "modifier": "Extra queso", "times_selected": 86, "amount": 2140.00 },
      { "modifier": "Aderezo chipotle", "times_selected": 54, "amount": 1485.80 }
    ],
    "days": ["2025-10-01", "2025-10-02", "2025-10-03", "2025-10-04", "2025-10-05", "2025-10-06", "2025-10-07", "2025-10-08"]
  },
  "data": [
    {
      "report_date": "2025-10-08",
      "item_name": "Hamburguesa Clásica",
      "modifier_name": "Extra queso",
      "qty_item": "86.00",
      "mods_count": 86,
      "mods_total_amount": "2140.00",
      "branch_key": "MTY_01"
    }
  ],
  "generated_at": "2025-10-08T09:40:22-06:00"
}
```

---

### Navegación rápida

| Reporte | Ruta web | Exportes |
| --- | --- | --- |
| Centro de ventas (índice) | `/reports/sales` | — |
| Mix de Ventas | `/reports/sales/mix` | PDF y Excel |
| Cajón vs Efectivo | `/reports/sales/drawer` | PDF y Excel |
| Diagnósticos diarios | `/reports/sales/diagnostics` | PDF y Excel |
| Ítems + Modificadores | `/reports/sales/mods` | PDF y Excel |

> **Nota:** todos los controladores aplican `SET TIME ZONE 'America/Mexico_City'` y `SET search_path TO public, selemti` antes de invocar las funciones `ERP_REPORTS_V9`. Para consumo programático usar tokens Sanctum con el permiso `reports.view`.
