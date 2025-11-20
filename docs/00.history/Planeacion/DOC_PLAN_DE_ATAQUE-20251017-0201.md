Plan de Ataque — Ampliado

Fecha: 2025-10-17 02:01

Prioridad Alta
- Autenticación/Autorización API Caja
  - Proteger /api/caja/* con auth (Sanctum o JWT existente) + roles (spatie/permission).
  - Tareas: agrupar rutas bajo middleware, políticas/permissions por endpoint, pruebas Feature.
  - Archivos: routes/api.php, app/Http/Kernel.php, config/auth.php.
- Kernel y middleware
  - Normalizar a app/Http/Kernel.php; mover configuración desde app/Http/Middleware/Kernel.php.
  - Garantizar CORS/throttle/bindings en grupo api.
- Wizard Corte de Caja
  - Unificar IDs (#wizardPrecorte), restaurar puedeWizard(), obtener store_id del backend.
  - Bloqueo doble-submit; estados y toasts coherentes; limpieza mojibake.
- BD (rendimiento e integridad)
  - Agregar índice selemti.precorte_efectivo(precorte_id).
  - Eliminar índice duplicado en selemti.precorte(sesion_id), mantener uno.
  - Evaluar índice parcial en public.ticket (terminal_id, closing_date) WHERE closing_date IS NULL.
- Plataforma
  - Plan de actualización de PostgreSQL (9.5 → soportada LTS), pruebas regresión.

Prioridad Media
- CRUDs Catálogos (proveedores, artículos, UoM, almacenes, sucursales, políticas de stock) con validaciones y tests.
- Validaciones con FormRequests en Precorte/Postcorte.
- UX/Accesibilidad: mensajes, focus, ARIA.
- Pipeline de assets: estrategia entre Vite y public/assets.

Prioridad Baja
- Observabilidad: logs y métricas básicas en endpoints Caja.
- L5-Swagger: definir esquemas y ejemplos de payloads.

Tickets sugeridos
1) Proteger /api/caja con auth/roles
   - Desc: añadir middleware auth y autorización; pruebas Feature.
   - Archivos: routes/api.php, app/Http/Kernel.php.
   - Estimado: 2–3 días; Riesgos: impacto en front.
2) Normalizar Kernel/Middleware
   - Desc: mover Kernel a app/Http/Kernel.php; registrar ApiResponseMiddleware; revisar CORS.
   - Archivos: app/Http/Kernel.php, app/Http/Middleware/ApiResponseMiddleware.php.
   - Estimado: 0.5–1 día; Riesgos: ruptura de entorno si mal aplicado.
3) Wizard: IDs + guardias + store_id
   - Desc: unificar IDs, reactivar puedeWizard, eliminar hardcode; QA.
   - Archivos: resources/views/caja/_wizard_modals.php, public/assets/js/caja/{wizard.js,state.js,mainTable.js}.
   - Estimado: 1–2 días; Riesgos: regresiones UI.
4) Índices DB
   - Desc: añadir idx en precorte_efectivo(precorte_id), eliminar duplicado en precorte(sesion_id), evaluar índice parcial en ticket.
   - Archivos: migraciones SQL (coordinar con DBA).
   - Estimado: 0.5–1 día; Riesgos: bloqueo o bloat si no se planifica ventana.
5) FormRequests Precorte/Postcorte
   - Desc: validar montos/negativos/requireds; sanitizar; pruebas Feature.
   - Archivos: app/Http/Requests/Caja/*.php, controladores Caja.
   - Estimado: 1–2 días; Riesgos: cambios en payload.
6) Corregir test Feature fallido
   - Desc: ajustar ruta '/' o test para responder 200; añadir pruebas de endpoints Caja.
   - Archivos: tests/Feature/*.php, routes/web.php.
   - Estimado: 0.5 día; Riesgos: mínimo.
7) Upgrade PostgreSQL
   - Desc: plan de migración versiones, compatibilidad drivers, pruebas de rendimiento.
   - Estimado: 2–4 días; Riesgos: compatibilidad.

Comandos propuestos (no ejecutar)
- php artisan migrate, db:seed, test, route:cache/config:cache (solo en entornos controlados).

