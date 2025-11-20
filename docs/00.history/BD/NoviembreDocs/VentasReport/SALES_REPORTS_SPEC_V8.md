# 🧠 PROMPT v8 — Sistema Integral de Reportes de Ventas ERP
*(FloreantPOS + Laravel + PostgreSQL 9.5 | Enterprise + Auditoría + Antifraude)*

**Rol:** Desarrollador Laravel + PostgreSQL con **acceso solo lectura**.  
**No inventes** tablas/columnas/funciones → **descúbrelas por introspección**.  
**Objetivo:** Reportes de ventas, descuentos, auditorías y *mix de modificadores* multi‑sucursal sobre `public` (POS) y `selemti` (ERP), con calidad Odoo / MyMicros / NCR.

---

## 0) Entorno y Pre‑requisitos (obligatorio)

- PostgreSQL **9.5** (confirmado)  
- Laravel con:
  - Redis (cache)
  - `maatwebsite/excel >= 3.1`
  - `barryvdh/laravel-dompdf >= 2.0`

En **cada conexión**:
```php
DB::statement("SET TIME ZONE 'America/Mexico_City'");
DB::statement("SET search_path TO public, selemti");
```

---

## 1) Reglas de negocio (sin suposiciones)

- **Tickets válidos**: `paid=TRUE AND voided=FALSE`
- **Neto ticket**: `COALESCE(total_price,0) - COALESCE(total_discount,0)`  
  *(propina/servicio separados)*
- **Cobros válidos**: `UPPER(transaction_type)='CREDIT' AND voided=FALSE`
  excluyendo `payment_type IN ('REFUND','VOID_TRANS')`
- **Egresos (no ventas)**: `payment_type IN ('REFUND','PAY_OUT','CASH_DROP')`
- **JOIN** principal: `LEFT JOIN ticket → transactions` (conserva tickets sin cobro)
- **Redondeo**: usar `::numeric` + `ROUND(...,2)` en PG 9.5
- **Normalización de pagos**: `selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name)`
- **Fecha de corte (folio_date)**: usar `COALESCE(folio_date, closing_date::date, create_date::date)` (según lo observado en BD real)

---

## 2) Orden de implementación (estricto)

- **Introspección completa**: `pg_proc`, `pg_constraint`, `information_schema.columns`
- **Funciones confirmadas**:
  - `public.get_daily_stats(date)`
  - `public.fn_daily_reconciliation(date)`
  - `public.fn_reconciliation_detail(date)`
  - `public.fn_correct_drawer_report(date)`
  - `selemti.fn_normalizar_forma_pago(...)`
- **Timestamps reales** en `ticket`:
  - `create_date`, `closing_date`, `folio_date` (sin `paid_at/settled_at`)
- **Catálogos**: `menu_item`, `menu_modifier`, `menu_modifier_group` …
- **Auditoría**: buscar tablas/funciones `selemti.*audit*|*log*`
- **Guardar introspección** en `docs/Reports/sales_schema.txt` (plantilla incluida)

---

## 3) Vistas CORE (confirmadas en tu BD)

> **Ya compiladas y probadas** en PG 9.5 (usando casts explícitos).  
> Ubica sus definiciones en tu folder `database/sql/views/*.sql` si deseas separarlas.

- `vw_sales_daily_branch` *(wrapper de `get_daily_stats(CURRENT_DATE)`)*  
- `vw_sales_daily_branch_range` *(serie de 365 días → `get_daily_stats(d)`)*  
- `vw_sales_by_terminal`
- `vw_sales_mix_payment`
- `vw_sales_by_hour`
- `vw_top_items_today`

**KPIs:**  
- `vw_sales_kpis` (avg ticket, items por ticket)

---

## 4) Diagnósticos CORE (auditoría monetaria)

- `vw_diag_neto_vs_cobros`
- `vw_diag_discount_header_vs_lines`
- `vw_diag_pagos_egresos`
- `vw_diag_paid_but_no_payments`
- `vw_diag_high_discounts`
- `vw_diag_folio_date_inconsistency`
- `vw_diag_unnormalized_payments`
- `vw_diag_service_charge_vs_paid`
- `vw_diag_orphans_tx`
- `vw_diag_orphans_tickets`

**Reconciliación de cajón (CRÍTICO):**  
- `fn_correct_drawer_report(date)` (firma confirmada)  
- `f_diag_drawer_vs_cash_transactions_on(date)` *(parametrizada)*  
- `vw_diag_drawer_vs_cash_transactions` *(wrapper a CURRENT_DATE)*

**Resumen Operativo:**  
- `f_daily_diagnostics_summary_on(date)`  
- `vw_daily_diagnostics_summary` *(wrapper a CURRENT_DATE)*

---

## 5) Materialized Views (ventana corta + índices)

> *(Opcional; cuando quieras optimizar lecturas)*

- `mv_sales_by_terminal`, `mv_sales_mix_payment`, `mv_sales_by_hour` con ventana `>= CURRENT_DATE - INTERVAL '7 days'`
- Índices `CONCURRENTLY`:
  - `(folio_date, branch_key, terminal_id)`
  - `(folio_date, branch_key, normalized_payment)`
  - `(folio_date, branch_key)`

**Refresh/Recovery**
- `REFRESH MATERIALIZED VIEW CONCURRENTLY ...`
- Si hay locks: `DROP INDEX` → `REFRESH` → `RECREATE INDEX CONCURRENTLY`
- Invalidar cache Redis (`reports:*`) tras refresh

---

## 6) **Módulo de Modificadores (agrupados por Item)**

**Objetivo**: medir *mix de modificadores* (sabor, proteína, extras, etc.) **agrupados por su `ticket_item` padre** para saber cómo se vendieron/adicionaron.

**Tablas relevantes (existentes):**
- `ticket_item`, `ticket_item_modifier`, `ticket_item_modifier_relation` (si aplica)
- `menu_item`, `menu_modifier`, `menu_modifier_group`

### 6.1 Función robusta (column‑smart, PG 9.5)
Se entrega una función **parametrizada** que *autodescubre* los nombres de columnas típicos (por ejemplo, `item_name` vs `name`; `item_quantity` vs `quantity`) y construye SQL dinámico para **no romper** si la instalación de Floreant varía.

**Archivo:** `database/sql/views/vw_items_modifiers.sql` (incluido)  
Expone:
- `f_item_mods_on(date)` → dataset por día
- `vw_item_mods_today` → wrapper a `CURRENT_DATE`

**Salidas clave:**
- `folio_date, branch_key, terminal_id, ticket_id, ticket_item_id`
- `item_name, modifier_name`
- `qty_item` (cantidad del item), `mods_count` (veces aplicado)
- `mods_total_amount` (suma de importes/recargos del modificador cuando aplique)

> Esta función usa `information_schema` para detectar columnas candidatas y `EXECUTE` el SQL dinámico con *joins* ya preparados a `ticket`, `ticket_item`, `ticket_item_modifier` y la *relation* si existe.

### 6.2 Reportes sugeridos (sobre la función)
- **Top modificadores por ítem** (hoy / rango)  
- **Mix por categoría** (sumarizando por `menu_category` si la necesitas)  
- **Heatmap hora × modificador** (usar `EXTRACT(HOUR FROM create_date)`)  
- **Detección de “modificadores caros”** (mods_total_amount > X)

---

## 7) API Laravel (solo lectura)

**Rutas:** `GET /api/reports/sales/*`  
**Middleware:** `auth:sanctum`, `ScopeBranches`  
**Policies:** `'reports.view'`, `'sales.analytics'`

**Filtros comunes:**
```
?date=YYYY-MM-DD
?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
?branch=...&terminal=...&limit=1000&page=1
?export=xlsx|pdf
```

**Exportes:** mismo dataset que las vistas/funciones; XLSX/PDF via `maatwebsite/excel` y `laravel-dompdf`.  
**Límites/Jobs:** exportes >5s → Queue; cleanup diarios de archivos >24h.

---

## 8) Auditoría y Gobernanza

- **folio_date inmutable** (diagnóstico ya entregado). Trigger opcional si más adelante se permite escritura desde ERP.
- **CDC** (Change Data Capture) recomendado para: `ticket.total_discount`, `ticket.total_price`, `ticket.paid`, `ticket.voided` y *mods* aplicados (en `ticket_item_modifier`).
- **Propina declarada vs cobrada** (vista incluida)
- **Cierre de cajón vs cobros** (vista + función incluidas)
- **Checklist SQL** (`diag_checklist.sql`) con conteos rápidos y *spot checks* por fecha.

---

## 9) Documentación y estructura de archivos

```
docs/Reports/
  SALES_REPORTS_SPEC_V8.md        ← (este archivo)
  ERD_SALES.md                    ← ya generado
  README_API_SALES.md             ← ya generado
  sales_schema.txt                ← ya generado

database/sql/views/
  vw_sales_core.sql               ← vistas CORE (ventas)
  vw_diagnostics.sql              ← vistas diag_* (auditoría)
  vw_items_modifiers.sql          ← (NUEVO) ítems + modificadores (dinámico)

database/sql/diagnostics/
  diag_checklist.sql              ← (NUEVO) validación rápida post‑deploy
```

---

## 10) Checklists de validación

**Despliegue**
- [ ] `SET TIME ZONE` + `SET search_path` activos
- [ ] Vistas CORE compilan
- [ ] Diags compilan y **devuelven filas** en día con datos (usa funciones `_on(date)`)
- [ ] `vw_diag_drawer_vs_cash_transactions` vacía *hoy* si no hay ventas, pero `f_*_on('YYYY-MM-DD')` sí rinde
- [ ] `f_item_mods_on('YYYY-MM-DD')` devuelve data (verificar columnas autodetectadas)

**API**
- [ ] Endpoints responden < **2s**
- [ ] Filtros validan fechas (≤ `CURRENT_DATE`, rango ≤ 365d)
- [ ] Exportes XLSX/PDF correctos

**Gobernanza**
- [ ] Logs de accesos/exportes (usuario, endpoint, filtros, timestamp)
- [ ] `vw_daily_diagnostics_summary` poblado en días con datos
- [ ] CDC planificado (si aplica)

---

## 11) Ejemplos útiles (SQL)

**Resumen operativo de un día con datos:**
```sql
SELECT * FROM public.f_daily_diagnostics_summary_on('2025-10-24');
```

**Drawer vs Efectivo (día con datos):**
```sql
SELECT * FROM public.f_diag_drawer_vs_cash_transactions_on('2025-10-24') LIMIT 10;
```

**Mix de pago (wrapper hoy + función por fecha):**
```sql
SELECT * FROM vw_sales_mix_payment_today;
SELECT * FROM public.f_sales_mix_payment_on('2025-10-24');
```

**Ítems + Modificadores (por fecha):**
```sql
SELECT * FROM public.f_item_mods_on('2025-10-24') ORDER BY item_name, modifier_name;
```

---

> **Nota**: Todo el SQL de este paquete está escrito para PG **9.5** con **casts explícitos** a `numeric(12,2)` y literales `::text` para evitar el tipo `unknown` en vistas.