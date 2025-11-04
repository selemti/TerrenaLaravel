# ERD · Ventas POS (FloreantPOS) — Núcleo de Reportes

> Esquemas: **public** (POS) y **selemti** (ERP utilitario)
> Motor: PostgreSQL 9.5

```mermaid
erDiagram
  TERMINAL ||--o{ TICKET : "terminal_id"
  TICKET ||--o{ TICKET_ITEM : "ticket_id"
  TICKET ||--o{ TRANSACTIONS : "ticket_id"

  TERMINAL {
    int id PK
    text name
    text location  // sucursal
  }

  TICKET {
    int id PK
    int terminal_id FK -> TERMINAL.id
    date folio_date       // puede ser NULL; usamos COALESCE(closing_date::date, create_date::date)
    timestamp create_date
    timestamp closing_date
    text branch_key
    numeric total_price
    numeric total_discount
    numeric service_charge
    boolean paid
    boolean voided
  }

  TICKET_ITEM {
    int id PK
    int ticket_id FK -> TICKET.id
    int item_id
    text item_name
    numeric item_quantity
    numeric total_price       // línea bruta
    numeric discount          // línea descuento
  }

  TRANSACTIONS {
    int id PK
    int ticket_id FK -> TICKET.id
    numeric amount
    text payment_type
    text payment_sub_type
    text transaction_type     // CREDIT|DEBIT ± variante de Floreant
    text custom_payment_name
    timestamp transaction_time
    boolean voided
  }
```

## Funciones clave
- `public.get_daily_stats(date)` — wrapper de KPIs diarios.
- `public.fn_correct_drawer_report(date)` — corrige neto vs drawer report (cajón).
- `selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name)` — mapea a categorías (`CASH`, `CREDIT_CARD`, `DEBIT_CARD`, `PROPINA`, `CARGO_SERVICIO`, etc.).

## Vistas núcleo (consumidas por API)
- `vw_sales_by_terminal`
- `vw_sales_mix_payment`, `vw_sales_mix_payment_today`, `f_sales_mix_payment_on(date)`
- `vw_sales_by_hour`
- `vw_top_items_today`

## Diagnósticos (auditoría/antifraude)
- `vw_diag_neto_vs_cobros`
- `vw_diag_discount_header_vs_lines`
- `vw_diag_paid_but_no_payments`
- `vw_diag_unnormalized_payments`
- `vw_diag_service_charge_vs_paid`
- `vw_diag_drawer_vs_cash_transactions` (+ `f_diag_drawer_vs_cash_transactions_on(date)`)
- `vw_diag_orphans_tickets`
- `vw_diag_orphans_tx`
- `vw_diag_high_discounts`
- `vw_diag_folio_date_inconsistency`
- `vw_daily_diagnostics_summary` (+ `f_daily_diagnostics_summary_on(date)`)

## Notas de modelado
- En PG 9.5 hay que **forzar casts**: `::numeric`, `::text` para evitar `unknown`.
- `folio_date` puede no estar poblada en todos los tickets; los reportes usan `COALESCE(folio_date, closing_date::date, create_date::date)`.
- Los _split payments_ se manejan por agregación en `transactions` con `transaction_type='CREDIT' AND voided=FALSE`, excluyendo `REFUND|VOID_TRANS`.
- Para “hoy” se usan *wrappers* (vistas) que llaman a funciones `_on(date)` con `CURRENT_DATE`.
