
🧠 **PROMPT V9 — Replicar Reportes Jasper (FloreantPOS) en Terrena (Laravel + PostgreSQL)**

**Rol:** Desarrollador Laravel 12 + PostgreSQL 9.5 con acceso *solo lectura*.  
**Entrada:** Usa el dump real que ya está en la BD (esquemas `public`, `selemti`). **No inventes** tablas/columnas.  
**Objetivo:** Implementar *reportes adicionales* equivalentes a los PDFs dentro de `Octubre.zip`:

- `sales_report_*` (detalle)
- `sales_summary_report*` (resumen)
- `sales_summary_balance_detail*` (resumen por forma de pago)
- `sales_summary_exception*` (excepciones)
- `menu_usage_report*` (uso de menú)
- `journal_report*` (libro)

Además del filtro por **rango de fechas**, agrega filtro por **Sucursal (branch_key)** y opcional **Terminal**.

---

### 0) Conexión y entorno (obligatorio)
```php
DB::statement("SET TIME ZONE 'America/Mexico_City'");
DB::statement("SET search_path TO public, selemti");
```

### 1) Reglas de negocio
- Ticket válido: `paid=TRUE AND voided=FALSE` (tabla `public.ticket`).
- `folio_date = COALESCE(t.folio_date, t.closing_date::date, t.create_date::date)`.
- Normalización de pagos: `selemti.fn_normalizar_forma_pago(payment_type, transaction_type, payment_sub_type, custom_payment_name)`.
- Neto de línea: `total_price - discount_amount`.
- Pagos válidos: `transaction_type='CREDIT' AND voided=FALSE` excluyendo `payment_type IN ('REFUND','VOID_TRANS')`.

### 2) SQL (crear con migración tipo `DB::unprepared`)
Carga y ejecuta el archivo `database/sql/reportes/script_sql_reportes_adicionales.sql`.  
El archivo incluye vistas:

- `vw_ticket_base` (helper)
- `vw_report_sales_detail`
- `vw_report_sales_summary`
- `vw_report_balance_detail`
- `vw_report_sales_exceptions`  (usa las vistas de diagnóstico existentes)
- `vw_report_menu_usage`
- `vw_report_journal_lines`, `vw_report_journal_payments`

### 3) Endpoints (solo lectura)

Rutas (`routes/web.php` para las vistas, `routes/api.php` para JSON):

```
GET /reports/sales/detail
GET /reports/sales/summary
GET /reports/sales/balance
GET /reports/sales/exceptions
GET /reports/menu/usage
GET /reports/journal
GET /api/reports/sales/detail
GET /api/reports/sales/summary
GET /api/reports/sales/balance
GET /api/reports/sales/exceptions
GET /api/reports/menu/usage
GET /api/reports/journal
```

Parámetros comunes: `?start=YYYY-MM-DD&end=YYYY-MM-DD&branch=SELEMTI[,VARADERO]&terminal=101[,102]`  
Si no se envían, default = todo el rango + todas las sucursales.

### 4) Controladores (pseudo)

- `Reports\Sales\SalesDetailController@index` → `vw_report_sales_detail`
- `Reports\Sales\SalesSummaryController@index` → `vw_report_sales_summary`
- `Reports\Sales\BalanceController@index` → `vw_report_balance_detail`
- `Reports\Sales\ExceptionsController@index` → `vw_report_sales_exceptions`
- `Reports\Menu\UsageController@index` → `vw_report_menu_usage`
- `Reports\Sales\JournalController@index` → join de `vw_report_journal_lines` + `vw_report_journal_payments`

Cada controlador debe aceptar filtros, construir el `where` (folio_date between, IN branch, IN terminal) y devolver **JSON** y **Blade**. Para exportes, reusa los helpers que ya existen en el proyecto (CSV/PDF) y respeta redondeo a 2 decimales.

### 5) Blade (ubicación en menú)

En el **Sidebar → Reportes** añade:
- `Dashboard` (ya existe)
- `Mix de Ventas` (ya existe)
- `Resumen de Ventas` → `/reports/sales/summary`
- `Detalle de Ventas` → `/reports/sales/detail`
- `Balance por Forma de Pago` → `/reports/sales/balance`
- `Excepciones` → `/reports/sales/exceptions`
- `Uso de Menú` → `/reports/menu/usage`
- `Journal` → `/reports/journal`

### 6) Validaciones y pruebas
- Verifica que para fechas como `2025-10-24` los totales en `summary` y `balance` sean consistentes con `mix`.
- Cruza `exceptions` con tus vistas `vw_diag_*` existentes.
- Confirma que `menu_usage` y `journal` listan correctamente items y modificadores (usa las tablas: `ticket_item_modifier` + `ticket_item_modifier_relation`).

### 7) Entregables
- **SQL**: `database/sql/reportes/script_sql_reportes_adicionales.sql` (usa el que te doy).
- **Controladores**: en `app/Http/Controllers/Reports/...`
- **Rutas**: `routes/web.php` y `routes/api.php`.
- **Vistas**: `resources/views/reports/...` con filtros (rango de fechas, sucursal, terminal) y botones Exportar/Imprimir.
- **Docs**: `docs/Reports/JASPER_EQUIVALENTS.md` explicando cada vista y endpoint.

### 8) Consideraciones de performance
- Indexar `ticket(folio_date, branch_key)`, `transactions(ticket_id)`, `ticket_item(ticket_id)` si no existen.
- Para rangos largos, pagina `detail` y `journal` (server-side).
- Cachear `summary` y `balance` por día y sucursal (Redis) cuando sea necesario.

**Acción:** Implementa lo anterior exactamente. Si algún nombre de columna no existe en la BD, lista la columna faltante y usa la alternativa de la misma vista sin romper el endpoint.
