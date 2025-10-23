# Protocolo · Debug de Incidencias

1. **Reproducir y delimitar**
   - Identifica dominio (Caja, Inventario, Catálogos, Reportes). Repite el request vía `/api/...` antes de tocar UI Livewire.
   - Revisa logs con `php artisan pail --timeout=0` (parte de `composer run dev`) y captura trace inicial.

2. **Verificar entorno**
   - Confirma `.env`: `DB_CONNECTION=pgsql`, `DB_SCHEMA=selemti,public`, credenciales correctas. Si falta el esquema, muchos modelos fallan en runtime.
   - Ejecuta `php artisan catalogs:verify-tables --details` para validar catálogos `public`. Si el error involucra objetos `selemti`, verifica contra `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148-safe.sql` que tablas, vistas y funciones existan.

3. **Inspeccionar datos**
   - Replica consultas crudas en `psql`: extrae SQL desde controladores (`DB::connection('pgsql')->selectOne(...)`) y sustituye parámetros reales.
   - Para caja, revisa `selemti.sesion_cajon`, `precorte`, `precorte_efectivo`, `postcorte`, `vw_conciliacion_sesion`.
   - Para inventario, revisa `selemti.items`, `inventory_batch`, `mov_inv`, vistas `vw_stock_*`. Confirmar restricciones (cantidad ≥ 0) definidas en deploy v3.

4. **Depuración modular**
   - **Caja**: sigue flujo `preflight → createLegacy/updateLegacy → conciliación → postcorte`. Verifica triggers (`fn_precorte_efectivo_bi`) y que `public.ticket` refleje tickets abiertos.
   - **Inventario**: usa `/api/inventory/items/{id}/kardex` y `/batches` para validar lotes; si fallan, revisar conversiones (`conversiones_unidad`) y triggers de recepción.
   - **Unidades/Catálogos**: compara `public.cat_*` con `selemti.*` y corrige divergencias.

5. **Frontend**
   - Analiza `public/assets/js/caja/*.js` o componentes Livewire según el módulo; confirma que IDs y payloads coincidan con lo que espera el backend.
   - Usa DevTools para revisar requests: verifica `Content-Type`, JSON válido y campos requeridos.

6. **Solución y prevención**
   - Añade pruebas dirigidas (`php artisan test --filter=NombreTest`) cuando aplique.
   - Documenta hallazgos y fixes en `.claude/context` y `docs/V2/03_Backend/` para mantener alineación con la base de conocimiento.
   - Si se requiere un parche SQL, agrega script en `BD/patches` y actualiza `schema_{selemti,public}.md` con el orden de ejecución.
