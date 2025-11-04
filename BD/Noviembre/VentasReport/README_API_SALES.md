# API de Reportes de Ventas — Terrena · V8 (FloreantPOS + Laravel + PostgreSQL)

Última actualización: 2025-11-04 05:32:39  
Alcance: Endpoints **solo lectura** para KPIs, ventas, descuentos y auditoría antifraude.
Compatibilidad: **PostgreSQL 9.5**, `public` (POS) + `selemti` (ERP).

---

## 0) Requisitos de conexión (Laravel)
Forzar siempre zona horaria y search_path por request:
```php
DB::statement("SET TIME ZONE 'America/Mexico_City'");
DB::statement("SET search_path TO public, selemti");
```

Autenticación y seguridad:
- `auth:sanctum`
- Policy: `reports.view`
- Scope por sucursal: `ScopeBranches` (filtra `branch_key`)

Límites y exportes:
- `?export=xlsx|pdf` — si el dataset tarda > 5s, mandar a **queue**
- Límite: 5 exportes/usuario/hora
- Limpieza: `php artisan reports:cleanup-old-exports` (borra >24h)

---

## 1) Parámetros comunes
- `date=YYYY-MM-DD`  
- `start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` (máx 365 días)
- `branch={BRANCH_KEY}`
- `terminal={TERMINAL_ID}`
- `limit=1000&page=1`
- `export=xlsx|pdf`

Validación:
- `date` y rangos **≤ CURRENT_DATE**
- `branch` debe existir y estar autorizado por `ScopeBranches`

---

## 2) Endpoints

### 2.1 Ventas por terminal
**GET** `/api/reports/sales/by-terminal`
- Fuente: `vw_sales_by_terminal`
- Respuesta (por fila): `folio_date, branch_key, terminal_id, terminal_name, sucursal, tickets, bruto, descuento, neto`

**Ejemplo**
```bash
curl -H "Authorization: Bearer $TOKEN"   "https://tu-api/api/reports/sales/by-terminal?start_date=2025-10-20&end_date=2025-10-31&branch=PRINCIPAL"
```

---

### 2.2 Mix de pago
**GET** `/api/reports/sales/mix-payment`
- Fuentes:
  - `vw_sales_mix_payment` (histórico)
  - `vw_sales_mix_payment_today` (wrapper a `CURRENT_DATE`)
  - `f_sales_mix_payment_on(date)` (parametrizada)
- Campos: `folio_date, branch_key, normalized_payment, total`

**Ejemplo**
```bash
curl -H "Authorization: Bearer $TOKEN"   "https://tu-api/api/reports/sales/mix-payment?date=2025-10-24&branch=PRINCIPAL"
```

---

### 2.3 Ventas por hora
**GET** `/api/reports/sales/by-hour`
- Fuente: `vw_sales_by_hour`
- Campos: `folio_date, branch_key, hour_local, neto`

---

### 2.4 Top items (hoy)
**GET** `/api/reports/sales/top-items/today`
- Fuente: `vw_top_items_today`
- Campos: `folio_date, branch_key, item_id, item_name, qty, neto`

---

### 2.5 Descuentos
**GET** `/api/reports/sales/discounts/daily`  
**GET** `/api/reports/sales/discounts/detail`
- Fuentes: `vw_discounts_daily`, `vw_discounts_detail_line`
- Campos resumen: `folio_date, branch_key, sucursal, terminal, tickets_con_desc, descuento_total, descuento_prom_ticket`
- Campos detalle: `folio_date, branch_key, sucursal, terminal, ticket_id, ticket_item_id, item_name, line_total_bruto, line_descuento, line_neto, discount_name`

**Ejemplo**
```bash
curl -H "Authorization: Bearer $TOKEN"   "https://tu-api/api/reports/sales/discounts/detail?start_date=2025-10-20&end_date=2025-10-31&branch=PRINCIPAL&export=xlsx"
```

---

### 2.6 Excepciones del día (UI caja/cortes)
**GET** `/api/reports/sales/exceptions/today`
- Fuente: `vw_sales_exceptions_today`
- Campos: `folio_date, branch_key, sucursal, terminal, ticket_id, total_bruto, total_descuento, total_neto, voided, descuento_mayor_30, exception_code, severity`

---

### 2.7 Diagnósticos (antifraude)
**GET** `/api/reports/sales/diagnostics/summary`
- Fuentes: `vw_daily_diagnostics_summary` (wrapper `CURRENT_DATE`) y `f_daily_diagnostics_summary_on(date)`
- Estructura: `source_view, severity, rows`

Vistas diagnósticas consultables:
- `vw_diag_neto_vs_cobros`
- `vw_diag_discount_header_vs_lines`
- `vw_diag_paid_but_no_payments`
- `vw_diag_unnormalized_payments`
- `vw_diag_service_charge_vs_paid`
- `vw_diag_drawer_vs_cash_transactions`
- `vw_diag_orphans_tickets`
- `vw_diag_orphans_tx`
- `vw_diag_high_discounts`
- `vw_diag_folio_date_inconsistency`

**Severidades:** `INFO | WARN | CRITICAL`

---

## 3) Ejemplos de respuestas

### 3.1 /by-terminal (JSON)
```json
[
  {
    "folio_date":"2025-10-31",
    "branch_key":"PRINCIPAL",
    "terminal_id":102,
    "terminal_name":"102",
    "sucursal":"PRINCIPAL",
    "tickets":19,
    "bruto":1413.00,
    "descuento":0.00,
    "neto":1413.00
  }
]
```

### 3.2 /diagnostics/summary (JSON)
```json
[
  {"source_view":"vw_diag_neto_vs_cobros","severity":"CRITICAL","rows":5},
  {"source_view":"vw_diag_high_discounts","severity":"WARN","rows":5}
]
```

---

## 4) Exportes

- XLSX y PDF deben tomar **el mismo dataset** que la vista/función base.
- Para PDF, usa plantillas Blade en `resources/views/reports/`.
- Para XLSX, usa `maatwebsite/excel` con `FromQuery`/`FromView`.
- Post-export: registra en log (endpoint, filtros, user, filas, duración).

---

## 5) Rendimiento

- Considera **Materialized Views** con ventana de 7 días si el tráfico lo amerita.
- Índices recomendados (si habilitas MVs):
  - `(folio_date, branch_key, terminal_id)`
  - `(folio_date, branch_key, normalized_payment)`
  - `(folio_date, branch_key)`
- Invalidar cache Redis por `branch` luego de `REFRESH`.
