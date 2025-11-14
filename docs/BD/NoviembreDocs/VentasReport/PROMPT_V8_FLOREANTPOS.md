# PROMPT V8 · Reportes de Ventas/Descuentos/Auditoría para FloreantPOS (PostgreSQL 9.5 + Laravel)

**Rol:** Desarrollador Laravel + PostgreSQL con acceso **solo lectura**.
**No inventes tablas/columnas/funciones.** Descubre todo por **introspección** y **usa los nombres reales** de esta BD.

## Entorno y Realidades Confirmadas
- **PostgreSQL:** 9.5 (importante: `ROUND(numeric,2)` requiere castear a `numeric` cuando partes vienen como `double precision`).
- **Schemas:** `public` (FloreantPOS), `selemti` (normalizaciones/utilidades).
- **Tablas principales (public):** `ticket`, `transactions`, `terminal`, `ticket_item`.
- **Columnas clave reales:**
  - `ticket`: `id`, `create_date`, `closing_date`, `folio_date`, `total_price`, `total_discount`, `service_charge`, `paid`, `voided`, `branch_key`, `terminal_id`, `settled` (boolean).
  - `transactions`: `id`, `ticket_id`, `payment_type`, `transaction_type`, `payment_sub_type`, `custom_payment_name`, `transaction_time`, `amount`, `voided`.
  - `ticket_item`: `id`, `ticket_id`, `item_id`, `item_name`, `item_quantity`, `total_price`, `discount`.
  - `terminal`: `id`, `name`, `location`.
- **Funciones existentes:**
  - `public.get_daily_stats(date)`
  - `public.fn_daily_reconciliation(date)`
  - `public.fn_reconciliation_detail(date)`
  - `public.fn_correct_drawer_report(date)` → devuelve: `(terminal_id, original_total_revenue, corrected_neto_tickets, adjustment)`
  - `selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name)`
- **Zona horaria (obligatoria en cada conexión):**
  ```sql
  SET TIME ZONE 'America/Mexico_City';
  SET search_path TO public, selemti;
  ```

## Reglas de Negocio (aplicables a esta BD real)
- **Tickets válidos:** `paid = TRUE AND voided = FALSE`.
- **Neto ticket:** `(COALESCE(total_price,0) - COALESCE(total_discount,0))`.
- **Folio de corte (folio_date):** usar el campo real `folio_date`; cuando falte, usar `COALESCE(folio_date, closing_date::date, create_date::date)`.
- **Cobros válidos:** en `transactions` cuando `UPPER(transaction_type)='CREDIT' AND voided=FALSE` y `payment_type NOT IN ('REFUND','VOID_TRANS')`.
- **Pagos normalizados:** `selemti.fn_normalizar_forma_pago(...)`.
- **NULL-safe + redondeo:** aplicar `COALESCE(...,0)` y castear a `numeric` antes de `ROUND(...,2)` por compatibilidad 9.5.
- **JOIN principal para reportes de cobros:** `LEFT JOIN ticket → transactions` para conservar tickets válidos sin pago.

## Orden de Implementación
1) **Vistas CORE:**  
   - `vw_sales_daily_branch`, `vw_sales_daily_branch_range` (usar `get_daily_stats(date)` con `::date`),  
   - `vw_sales_by_terminal`, `vw_sales_mix_payment`, `vw_sales_by_hour`, `vw_top_items_today` (todas usando columnas reales).

2) **Diagnósticos CORE:**  
   - `vw_diag_neto_vs_cobros`, `vw_diag_discount_header_vs_lines`,  
   - `vw_diag_orphans_tx`, `vw_diag_orphans_tickets`, `vw_diag_pagos_egresos`.

3) **Módulo Descuentos y Excepciones:**  
   - `vw_discounts_daily`, `vw_discounts_detail_line`, `vw_sales_exceptions_today`.

4) **Auditoría Avanzada:**  
   - `vw_diag_high_discounts`, `vw_diag_folio_date_inconsistency`,  
   - `vw_diag_paid_but_no_payments`, `vw_diag_unnormalized_payments`, `vw_diag_service_charge_vs_paid`.

5) **Cajón vs Efectivo (Reconciliación):**
   - Crear **función parametrizada** `f_diag_drawer_vs_cash_transactions_on(date)` que combine:
     - `fn_correct_drawer_report(date)` (base esperada por terminal)
     - Transacciones del día `p_date` (`CASH` vs `NON CASH` normalizado)
     - `expected_cash = corrected_neto_tickets - non_cash_in`
   - Luego el wrapper `vw_diag_drawer_vs_cash_transactions` = `SELECT * FROM f_diag_drawer_vs_cash_transactions_on(CURRENT_DATE)`.

6) **Wrappers “por fecha” (para pruebas y API):**
   - `f_sales_mix_payment_on(date)` y vista `vw_sales_mix_payment_today`.
   - `f_daily_diagnostics_summary_on(date)` y vista `vw_daily_diagnostics_summary`.

7) **KPIs:** `vw_sales_kpis` (avg_ticket, items_per_ticket, totales, % descuento).

8) **Materialized Views (opcional, performance):** crear `mv_sales_*` a 7 días y refrescar diario. En PG 9.5 no hay `IF NOT EXISTS` → usar `DROP ... IF EXISTS` seguido de `CREATE` y (opcional) índices `CONCURRENTLY` fuera de transacción.

## Requisitos de Auditoría y Gobernanza
1. `folio_date` debe ser coherente con `closing_date::date` o `create_date::date`. Reportar en `vw_diag_folio_date_inconsistency` cualquier desvío.
2. Diagnósticos con `error_code` (`text`) y `severity` (`INFO|WARN|CRITICAL`).
3. Reporte `paid=TRUE` sin transacciones (`vw_diag_paid_but_no_payments`).
4. Cobertura 100% de normalización de pago (`vw_diag_unnormalized_payments`).
5. Reconciliación cajón vs transacciones (`f_diag_drawer_vs_cash_transactions_on(date)` + `vw_diag_drawer_vs_cash_transactions`).
6. Service charge declarado vs cobrado (`vw_diag_service_charge_vs_paid`).

## API Laravel (solo lectura)
- **Rutas base:** `GET /api/reports/sales/*`  
- **Middleware:** `auth:sanctum`, `ScopeBranches` (multi-sucursal).  
- **Policies:** `reports.view`, `sales.analytics`.  
- **Filtros comunes:**  
  `?date=YYYY-MM-DD` · `?start_date&end_date` · `?branch&terminal&limit&page` · `?export=xlsx|pdf`  
- **Validación:** Fechas ≤ `CURRENT_DATE`, rango ≤ 365 días, `branch_key` autorizado.  
- **Exports:** PDF/XLSX; si >5s, usar queue. Cleanup de archivos >24h.

## Guías de Compatibilidad PG 9.5
- Siempre castear a `numeric` antes de `ROUND(...,2)` si el origen es `double precision`.
- Castear literales de texto en vistas (`'XYZ'::text`) para evitar columnas tipo `unknown`.
- Al recrear vistas que cambiaron tipos, usa `DROP VIEW IF EXISTS ...` antes de `CREATE`.

## Runbook Rápido (QA)
- **Diagnóstico hoy:** `SELECT * FROM vw_daily_diagnostics_summary;`
- **Diagnóstico por día:** `SELECT * FROM public.f_daily_diagnostics_summary_on('YYYY-MM-DD');`
- **Cajón vs efectivo (día):** `SELECT * FROM public.f_diag_drawer_vs_cash_transactions_on('YYYY-MM-DD');`
- **Mix pago hoy:** `SELECT * FROM vw_sales_mix_payment_today;`

## Resultado Esperado
- Vistas y funciones compilan en **PG 9.5**.
- Columnas y funciones **reales** (sin `paid_at`, `settled_at`, etc.).
- Reportes de ventas, descuentos y auditoría **coherentes** y **auditables**.
