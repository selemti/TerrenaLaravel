# 🧠 PROMPT v8 (FIXED) — Sistema Integral de Reportes de Ventas ERP
*(FloreantPOS + Laravel + PostgreSQL 9.5 | Enterprise + Auditoría + Antifraude)*

## Rol y Alcance
- **Rol:** Desarrollador Laravel + PostgreSQL con **acceso solo lectura** sobre `public` (POS) y `selemti` (ERP).
- **No inventes** tablas/columnas/funciones; **descúbrelas por introspección**.
- **Objetivo:** Implementar reportes de ventas, descuentos y auditorías multi‑sucursal con calidad Odoo / MyMicros / NCR.

---

## 0) Entorno y Pre‑requisitos (obligatorio)
- **PostgreSQL** 9.5 (importante por funciones de redondeo y tipos).
- **Laravel** con Redis, `maatwebsite/excel >= 3.1`, `barryvdh/laravel-dompdf >= 2.0`.
- Forzar TZ y `search_path` *en cada conexión*:
  ```php
  DB::statement("SET TIME ZONE 'America/Mexico_City'");
  DB::statement("SET search_path TO public, selemti");
  ```

---

## 1) Reglas de negocio (sin suposiciones)
- **Ticket válido:** `paid = TRUE AND voided = FALSE`.
- **Neto ticket:** `COALESCE(total_price,0) - COALESCE(total_discount,0)`.
- **Cobros válidos:** `UPPER(transaction_type)='CREDIT' AND voided=FALSE`
  excluyendo `payment_type IN ('REFUND','VOID_TRANS')`.
- **Egresos (no ventas):** `payment_type IN ('REFUND','PAY_OUT','CASH_DROP')`.
- **JOIN principal:** `ticket LEFT JOIN transactions` (conserva tickets válidos sin cobro).
- **NULL‑safe + redondeo:** castear a `numeric` y `ROUND(...,2)` en todos los montos.
- **Normalización de pagos:** `selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name)`.
- **Fecha de corte (`folio_date`)**: usar
  `COALESCE(t.folio_date, t.closing_date::date, t.create_date::date)`
  (compat con tu BD).

> Nota: El prompt original hablaba de `created_at/closed_at/settled_at/paid_at`; en **tu BD real** existen `create_date` y `closing_date` y **sí** hay `folio_date`. Todo aquí está ya **ajustado**.

---

## 2) Orden de implementación (estricto)
1) **Introspección** (`pg_proc`, `pg_constraints`, `information_schema.columns`).
   - Verificar funciones: `get_daily_stats(date)`, `fn_daily_reconciliation(date)`, `fn_reconciliation_detail(date)`, `public.fn_correct_drawer_report(date)`, `selemti.fn_normalizar_forma_pago(...)`.
2) **Vistas CORE** (no parametrizadas).
3) **Diagnósticos CORE** con `error_code`/`severity` **tipados** (`::text`) y montos `::numeric`.
4) **Funciones parametrizadas** `..._on(date)` para operar “por día” (evitar depender de `CURRENT_DATE` en pruebas).
5) **Wrappers “hoy”** (`CURRENT_DATE`) que delegan en las funciones parametrizadas.
6) **(Opcional)** Materialized Views (ventana 7 días) + índices concurrentes.
7) **API Laravel** (solo lectura) + export (XLSX/PDF).
8) **Auditoría y gobernanza** (ver §7).

---

## 3) Vistas CORE (ajustadas a tu BD y PG 9.5)

**3.1** `vw_sales_daily_branch` *(wrapper a función existente)*  
```sql
CREATE OR REPLACE VIEW vw_sales_daily_branch AS
SELECT * FROM public.get_daily_stats(CURRENT_DATE);
```

**3.2** `vw_sales_daily_branch_range` *(rango multi‑día)*  
```sql
CREATE OR REPLACE VIEW vw_sales_daily_branch_range AS
SELECT c.d::date AS folio_date, x.*
FROM generate_series(CURRENT_DATE - INTERVAL '365 days', CURRENT_DATE, INTERVAL '1 day') AS c(d)
CROSS JOIN LATERAL public.get_daily_stats(c.d::date) AS x;
```

**3.3** `vw_sales_by_terminal`  
Agrega montos `::numeric` + `ROUND`:
```sql
CREATE OR REPLACE VIEW vw_sales_by_terminal AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  term.id        AS terminal_id,
  term.name      AS terminal_name,
  term.location  AS sucursal,
  COUNT(*)       AS tickets,
  ROUND(SUM(COALESCE(t.total_price,0))::numeric,2)                        AS bruto,
  ROUND(SUM(COALESCE(t.total_discount,0))::numeric,2)                     AS descuento,
  ROUND(SUM((COALESCE(t.total_price,0)-COALESCE(t.total_discount,0))::numeric),2) AS neto
FROM public.ticket t
JOIN public.terminal term ON term.id = t.terminal_id
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3,4,5;
```

**3.4** `vw_sales_mix_payment`  
Wrapper “hoy”: `vw_sales_mix_payment_today` delega a `f_sales_mix_payment_on(CURRENT_DATE)` (ver §4.4).

**3.5** `vw_sales_by_hour`  
`create_date` en vez de `created_at`:
```sql
CREATE OR REPLACE VIEW vw_sales_by_hour AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  EXTRACT(HOUR FROM (t.create_date AT TIME ZONE 'America/Mexico_City'))::int AS hour_local,
  ROUND(SUM((COALESCE(t.total_price,0)-COALESCE(t.total_discount,0))::numeric),2) AS neto
FROM public.ticket t
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2,3;
```

**3.6** `vw_top_items_today`  
Evita nombres inciertos de cantidad; usa neto por ítem:
```sql
CREATE OR REPLACE VIEW vw_top_items_today AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  ti.item_id,
  ti.item_name,
  COUNT(*) AS lines,
  ROUND(SUM((COALESCE(ti.total_price,0)-COALESCE(ti.discount,0))::numeric),2) AS neto
FROM public.ticket_item ti
JOIN public.ticket t ON t.id = ti.ticket_id
WHERE COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) = CURRENT_DATE
GROUP BY 1,2,3,4
ORDER BY neto DESC;
```

---

## 4) Diagnósticos CORE (auditoría monetaria)
Todos devuelven `error_code` y `severity` como `text` y aplican tolerancia `ABS(diff) > 0.01`.

**4.1** `vw_diag_neto_vs_cobros`  
(CTE + casts explícitos) — *ya probado*.

**4.2** `vw_diag_discount_header_vs_lines`  
Usa `ticket_item.discount` y `ticket.total_discount` — *ya probado*.

**4.3** `vw_diag_pagos_egresos`  
Suma de `REFUND|PAY_OUT|CASH_DROP` por `terminal_id` — *ya probado*.

**4.4** Funciones parametrizadas y wrappers “hoy” (nuevas)
- `f_sales_mix_payment_on(date)` + `vw_sales_mix_payment_today` — *creadas*.
- `f_diag_drawer_vs_cash_transactions_on(date)` + `vw_diag_drawer_vs_cash_transactions` — *creadas*.
- `f_daily_diagnostics_summary_on(date)` + `vw_daily_diagnostics_summary` — *creadas*.  
Permite consultar cualquier fecha con datos (p. ej., `'2025-10-24'`).

---

## 5) Materialized Views (opcional)
Ventana 7 días + índices `CONCURRENTLY`. **No** incluidas por defecto en SQL para evitar locks; añade si las necesitas.

---

## 6) Módulo de Descuentos y Excepciones
- `vw_discounts_daily`, `vw_discounts_detail_line`, `vw_diag_discount_header_vs_lines` y `vw_sales_exceptions_today` — *incluidas y compatibles con PG 9.5*.
- Si en tu BD no existen `discount_name`/`item_quantity`, ya están **omisas** o reemplazadas por campos reales (`discount`, `total_price`).

---

## 7) Auditoría y Gobernanza (incluido)
> Esta sección **sí** está en este prompt y en el SQL. Lo que **escribe** (triggers) va **comentado** para entornos de sólo‑lectura; puedes habilitarlo cuando decidas.

- **A1) Inmutabilidad de `folio_date`:**  
  - Vista `vw_diag_folio_date_inconsistency` *(creada)* compara `folio_date` con `closing_date` y `create_date`.
  - Trigger `prevent_folio_date_change()` **comentado** en el SQL (actívalo solo si puedes escribir).

- **A2) CDC (Change Data Capture):**  
  - Se provee **plantilla comentada** de tabla `audit.ticket_changes` + triggers para `ticket` y `ticket_item` en campos críticos (precio/descuento/paid/voided).

- **A3) Propina declarada vs cobrada:**  
  - **Opcional**: depende de que exista `ticket.tip_amount`. En tu BD **no está**; queda **comentado** en el SQL.

- **A4) Reconciliación efectivo (cajón vs transacciones):**  
  - Implementado vía `fn_correct_drawer_report(date)` + función `f_diag_drawer_vs_cash_transactions_on(date)` y wrapper `vw_diag_drawer_vs_cash_transactions` — *probado*.

- **A5) `paid=TRUE` sin transacciones:**  
  - Vista `vw_diag_paid_but_no_payments` — *creada*.

- **A6) Cobertura de normalización de pagos:**  
  - Vista `vw_diag_unnormalized_payments` — *creada*.

- **A7) Integridad referencial de ítems:**  
  - `vw_diag_orphan_ticket_items` queda **comentada** porque tu catálogo se llama `menu_item` (ajusta si quieres habilitarla).

- **A8) Service charge vs cobrado:**  
  - `vw_diag_service_charge_vs_paid` — *creada*, usa `ticket.service_charge` (campo confirmado en tu BD).

---

## 8) API Laravel (solo lectura)
- **Rutas:** `GET /api/reports/sales/*`.
- **Middleware:** `auth:sanctum` + `ScopeBranches`.
- **Policies:** `'reports.view'`, `'sales.analytics'`.
- **Arquitectura:** `BaseReportController` (filtros `?date|start_date|end_date|branch|terminal|limit|page`, export, logging).  
  API Resources **sin NULL**, redondeo a 2 decimales.  
- **Export:** `?export=xlsx|pdf` (mismo dataset de las vistas/funciones).

---

## 9) KPIs y Métricas (base)
```sql
CREATE OR REPLACE VIEW vw_sales_kpis AS
SELECT
  COALESCE(t.folio_date, t.closing_date::date, t.create_date::date) AS folio_date,
  t.branch_key,
  ROUND(SUM((COALESCE(t.total_price,0)-COALESCE(t.total_discount,0))::numeric)
        / NULLIF(COUNT(*),0), 2) AS avg_ticket,
  COUNT(*)::numeric(12,2) / NULLIF(COUNT(DISTINCT t.id),0) AS tickets_per_unique_ticket -- ejemplo base
FROM public.ticket t
WHERE t.paid=TRUE AND t.voided=FALSE
GROUP BY 1,2;
```

---

## 10) Documentación mínima (incluida en este paquete)
- Este **PROMPT_v8 (FIXED)**.
- `script_sql_corregido_v8.sql` listo para aplicar (crea vistas/funciones).  
- (Opcional) Puedes generar `docs/Reports/*.md` más detallados; incluimos *templates* básicos aparte si los requieres.

---

## 11) Checklists de validación
- **Introspección:** funciones/columnas confirmadas.
- **Vistas/funciones:** compilan en PG 9.5; `ROUND(...,2)` con `::numeric`.
- **Diagnósticos:** devuelven `error_code` y `severity` tipados.
- **Wrappers “hoy”:** operativos (si el día no tiene datos, devolverán 0 filas).
- **API/Export:** <2s con índices adecuados; XLSX/PDF levantan del mismo dataset.
- **Gobernanza:** vistas activas; triggers/CDC **comentados** hasta que decidas habilitarlos.