# Playbook · Especialista en Caja

**Modelos clave (`App\Models\Caja`)**
- `SesionCajon` → `selemti.sesion_cajon`: columnas v3 (`terminal_id`, `cajero_usuario_id`, `apertura_ts`, `cierre_ts`, `estatus` ∈ {ACTIVA, LISTO_PARA_CORTE, CERRADA}, `opening_float`, `closing_float`, `skipped_precorte`). Relaciona con `Terminal`, `Precorte`, `Postcorte` y `User` POS.
- `Precorte` → `selemti.precorte`: controla `declarado_efectivo`, `declarado_otros`, `estatus` (PENDIENTE|ENVIADO|APROBADO|RECHAZADO), `ip_cliente`, `notas`. Tablas hijas `precorte_efectivo` (denominación, cantidad, subtotal) y `precorte_otros` (tipo, monto, notas) se gestionan manualmente.
- `Postcorte` → `selemti.postcorte`: totales comparativos (`sistema_*`, `declarado_*`, `diferencia_*`, `veredicto_*` con checks), `notas`, banderas `validado`, `validado_por`, `validado_en`.
- `FormasPago` y `Terminal` completan catálogos; todas las definiciones están en `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148-safe.sql`.

**Flujo wizard (routes/api.php)**
1. `GET|POST /api/caja/precortes/preflight/{sesion?}` (`PrecorteController@preflight`) verifica tickets abiertos en `public.ticket`.
2. `POST /api/caja/precortes` (`createLegacy`) busca/crea precorte idempotente por sesión.
3. `POST /api/caja/precortes/{id}` (`updateLegacy`) reemplaza denominaciones (`precorte_efectivo`) y métodos no efectivos (`precorte_otros`) dentro de una transacción.
4. `GET /api/caja/conciliacion/{sesion}` expone `vw_conciliacion_sesion` (poblada por funciones v3 `fn_precorte_after_insert`, `fn_generar_postcorte`).
5. `POST /api/caja/postcortes` y `POST /api/caja/postcortes/{id}` consolidan totales y permiten marcar `validado=true`.
6. `GET /api/caja/sesiones/activa` y `/cajas` sirven para localizar el cajón correcto; rutas `/api/legacy/*` replican endpoints Slim.

**Consideraciones con PostgreSQL legacy**
- Asegura `DB_SCHEMA=selemti,public` y ejecuta parches de `BD/patches/selemti` (funciones, vistas, triggers). Sin `fn_precorte_efectivo_bi` los subtotales no se recalculan.
- Validar que vistas `vw_drawer_resume`, `vw_precorte_*` existan; están documentadas en `docs/DOC_WIZARD_CORTE_CAJA-20251017-0126.md` y `docs/V2/03_Backend/routes_api.md`.

**Buenas prácticas operativas**
- Controla concurrencia: `createLegacy` y `updateLegacy` no bloquean doble submit; si se habilitan múltiples cajeros por terminal, envolver en locks o validar `estatus` antes de continuar.
- Montos siempre en DECIMAL (`decimal:2` en modelos); evita floats al formatear en front (`public/assets/js/caja/wizard.js`).
- Mantén compatibilidad con `/api/legacy/caja/*.php` hasta retirar el frontend antiguo; documenta cambios funcionales en `.claude/context/02_caja_module.md` y en `docs/V2`.
