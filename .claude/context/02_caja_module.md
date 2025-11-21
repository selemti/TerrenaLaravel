# Módulo Caja · Detalle Técnico

**Modelos y tablas (`app/Models/Caja`)**
- `SesionCajon` apunta a `selemti.sesion_cajon`: columnas v3 (`terminal_id`, `cajero_usuario_id`, `apertura_ts`, `cierre_ts`, `estatus` con check ACTIVA/LISTO_PARA_CORTE/CERRADA, `opening_float`, `closing_float`, `dah_evento_id`, `skipped_precorte`). Relaciones `terminal()`, `precorte()`, `postcorte()`, `cajero()`.
- `Precorte` → `selemti.precorte`: `declarado_efectivo`, `declarado_otros`, `estatus` (PENDIENTE/ENVIADO/APROBADO/RECHAZADO), `creado_en`, `creado_por`, `ip_cliente`, `notas`. Tablas hijas `precorte_efectivo` (denominación, cantidad, subtotal) y `precorte_otros` (tipo, monto, notas) definidas en `DEPLOY v3`.
- `Postcorte` → `selemti.postcorte`: totales comparativos `sistema_*`, `declarado_*`, `diferencia_*`, `veredicto_*` (check CUADRA/A_FAVOR/EN_CONTRA), `validado`, `validado_por`, `validado_en`, `notas`.
- `FormasPago` (`selemti.formas_pago`) y `Terminal` (`public.terminal`) alimentan catálogos auxiliares.

**Controladores API (`app/Http/Controllers/Api/Caja`)**
- `PrecorteController`: `preflight` consulta `public.ticket`; `createLegacy` y `updateLegacy` reproducen lógica Slim (selecciona sesión por terminal/fecha, maneja transacciones `DB::connection('pgsql')` para limpiar/insertar en `precorte_efectivo` y `precorte_otros`, calcula `totalEfectivo`); `statusLegacy`, `resumenLegacy`, `totalesPorSesion` exponen consultas agregadas; `enviar` marca estatus.
- `PostcorteController`: `create/update` normaliza payload, recalcula diferencias y actualiza `postcorte`; `detalle` consulta vistas de conciliación v3 (`vw_conciliacion_sesion`, `vw_drawer_resume`).
- `ConciliacionController@getBySesion` agrega datos contables desde vistas PL/pgSQL.
- `SesionesController@getActiva` devuelve la sesión abierta de un terminal; `CajasController` y `CajaController` listan terminales y detalle de tickets.
- Rutas definidas en `routes/api.php` y duplicadas bajo `/api/legacy/*` para compatibilidad.

**Dependencias SQL**
- Requiere funciones `fn_precorte_after_insert`, `fn_precorte_efectivo_bi`, `fn_generar_postcorte` y vistas `vw_conciliacion_sesion`, `vw_precorte_*` incluidas en `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148-safe.sql` y documentadas en `docs/DOC_WIZARD_CORTE_CAJA-20251017-0126.md`.
- `public.ticket` se usa como fuente de verdad para bloquear precortes; validar que esté sincronizada con POS.

**Riesgos y tareas**
- Falta middleware de autenticación/roles; aplicar (`auth:sanctum` o JWT) antes de exponer en producción.
- Concurrencia: `createLegacy`/`updateLegacy` carecen de locks; considerar `SELECT ... FOR UPDATE` sobre `sesion_cajon` y validación de `estatus`.
- Garantizar que triggers monetarios de v3 estén instalados; sin ellos, los totales mostrados en conciliación quedan desfasados.
