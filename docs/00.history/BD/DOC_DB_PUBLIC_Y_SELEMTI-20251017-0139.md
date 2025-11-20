DB — Inventario real (public, selemti) [Solo lectura]

Fecha: 2025-10-17 01:39

Método
- Sesión PHP con Laravel DB; SET search_path TO selemti, public (solo sesión).
- Consultas: information_schema (tablas/columnas), pg_catalog (PK/FK/índices), pg_class.reltuples (estimación filas).
- Scripts: `scripts/db_inventory.php` (inventario global JSON), `scripts/db_indexes_core.php` (índices clave).

Resumen por esquema
- public (POS/Floreant): muchas tablas (tickets, cajones, menús, etc.). Relevantes para Caja:
  - `public.ticket` — índices detectados: `ticketclosingdate` (closing_date), `idx_ticket_close_term_owner (closing_date, terminal_id, owner_id)`, `ticket_pkey`, `ux_ticket_dailyfolio`, otros.
- selemti (control backoffice):
  - `selemti.sesion_cajon` — PK, índices por terminal/apertura y cajero/apertura, único por (terminal_id, cajero_usuario_id, apertura_ts).
  - `selemti.precorte` — PK y 2 índices sobre `sesion_id` (posible duplicidad).
  - `selemti.precorte_efectivo` — solo PK (no índice en `precorte_id`).
  - `selemti.precorte_otros` — PK e índice en `precorte_id`.
  - `selemti.postcorte` — PK y UNIQUE en `sesion_id`.

Estimación de filas (pg_class.reltuples)
- selemti.postcorte ≈ 4, selemti.precorte ≈ 4, selemti.precorte_efectivo ≈ 26, selemti.precorte_otros ≈ 8, selemti.sesion_cajon ≈ 8.
- Resto de tablas (selemti.* y public.*) con valores pequeños o no críticos para el flujo de Caja en esta muestra.

Hallazgos críticos
- `selemti.precorte_efectivo` SIN índice por `precorte_id` → consultas y deletes/joins por precorte serán más costosos. Sugerido: `CREATE INDEX idx_precorte_efectivo_precorte ON selemti.precorte_efectivo(precorte_id);`
- `selemti.precorte` con dos índices equivalentes en `sesion_id` (`idx_precorte_sesion_id` y `precorte_sesion_id_idx`) → redundancia. Sugerido: dejar uno.
- `public.ticket` consulta de preflight: `WHERE terminal_id=? AND closing_date IS NULL`. Índices útiles detectados:
  - `ticketclosingdate` (closing_date) y compuesto `idx_ticket_close_term_owner (closing_date, terminal_id, owner_id)`.
  - Aunque no hay índice simple en `terminal_id`, el compuesto puede ayudar si el plan usa `closing_date` primero (IS NULL) y filtra por `terminal_id`. Validar plan de ejecución; opcional: índice `(terminal_id, closing_date)` si fuera cuello de botella.

Columnas y tipos (muestra clave)
- `selemti.precorte`: totales declarados parecen numéricos; validar tipo NUMERIC/DECIMAL (evitar float). Notas y estatus presentes.
- `selemti.postcorte`: columnas de diferencias/veredictos; confirmar NUMERIC/DECIMAL y marcas `validado`, `validado_por`, `validado_en`.
- `selemti.sesion_cajon`: `apertura_ts/cierre_ts`, `estatus`, `opening_float/closing_float`.

Índices (extracto de scripts/db_indexes_core.php)
- sesion_cajon: `ix_sesion_cajon_terminal (terminal_id, apertura_ts)`, `ix_sesion_cajon_cajero (cajero_usuario_id, apertura_ts)`, `pkey`, `unique(terminal_id, cajero_usuario_id, apertura_ts)`.
- precorte: `pkey`, `idx_precorte_sesion_id`, `precorte_sesion_id_idx` (duplicidad).
- precorte_efectivo: `pkey` (falta índice FK `precorte_id`).
- precorte_otros: `pkey`, `ix_precorte_otros_precorte (precorte_id)`.
- postcorte: `pkey`, `uq_postcorte_sesion_id (sesion_id UNIQUE)`.
- public.ticket: múltiples índices; relevantes `closing_date`, `(closing_date, terminal_id, owner_id)`, `pkey`, `ux_ticket_dailyfolio`.

Sugerencias de optimización
- Añadir índice en `selemti.precorte_efectivo(precorte_id)`.
- Eliminar índice duplicado de `selemti.precorte(sesion_id)` dejando uno consistente.
- Evaluar plan de `preflight` (terminal_id + closing_date IS NULL). Si hay latencia, crear `public.ticket(terminal_id, closing_date)` (parcial `WHERE closing_date IS NULL`).
- Revisar DECIMAL/NUMERIC para montos y consolidar reglas de redondeo.

Apéndice: Cómo se obtuvo
- Inventario JSON (recortado en CLI por tamaño): `php scripts/db_inventory.php`.
- Índices clave: `php scripts/db_indexes_core.php`.

