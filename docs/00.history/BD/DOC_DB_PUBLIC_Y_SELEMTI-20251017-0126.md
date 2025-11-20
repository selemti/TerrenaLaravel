DB — Schemas public y selemti (Sólo lectura)

Fecha: 2025-10-17 01:26

Conexión y configuración
- Driver: PostgreSQL (pgsql).
- search_path (sesión actual):
  - BEFORE: selemti, public
  - AFTER:  selemti, public
  - Método: script temporal `scripts/db_search_path.php` que ejecuta `SET search_path TO selemti, public;` y luego `SHOW search_path;` (solo sesión; no persiste).
- Nota: No se modificó `.env`; cambio fue por sesión.

Objetos referenciados por el módulo Caja
- Esquema public: `terminal`, `users`, `ticket`.
- Esquema selemti: `sesion_cajon`, `precorte`, `precorte_efectivo`, `precorte_otros`, `postcorte`, `formas_pago`, vista `vw_conciliacion_sesion`.

Consultas sugeridas (no ejecutadas aún, requieren aprobación)
- Enumerar tablas en ambos esquemas:
  - `SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema IN ('public','selemti') ORDER BY 1,2;`
- Describir columnas de tablas clave (ejemplo):
  - `SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema='selemti' AND table_name='precorte' ORDER BY ordinal_position;`
- Confirmar versión de PostgreSQL (si apruebas):
  - `SELECT version();`

Notas de seguridad y operación
- No escribir en tablas del POS. Todas las operaciones de corte/conciliación en backend son mutaciones, por lo que pruebas deben ser en staging.
- Mantener `search_path` controlado por sesión en tareas de auditoría.

