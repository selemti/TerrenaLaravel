Plan de Ataque — Roadmap y Tickets

Fecha: 2025-10-17 01:32

Prioridad Alta
- Autenticación y Autorización API Caja
  - Proteger `/api/caja/*` con `auth:sanctum` o JWT ya instalado (tymon), y roles/permisos (spatie/permission).
  - Revisar Kernel para asegurar `app/Http/Kernel.php` activo con grupo `api` y CORS.
- Estabilización Wizard Cortes
  - Unificar IDs del modal (`#wizardPrecorte`) y selectores en `wizard.js`/`state.js`.
  - Restaurar `puedeWizard()` con reglas de negocio.
  - Quitar `store_id` hardcode → obtener de backend (respuesta de cajas/sesión).
  - Manejo robusto de doble-submit, bloqueo de botones, y estados intermedios.
- Seguridad de endpoints de escritura
  - Validaciones con FormRequests para Precorte/Postcorte (tipos monetarios, rangos, requireds).
  - Logs de auditoría con contexto (usuario, IP, payload saneado).

Prioridad Media
- CRUDs de catálogos clave
  - Proveedores, Artículos, UoM/Conversiones, Almacenes, Sucursales, Políticas de stock.
  - Agregar pruebas Feature básicas (index/create/update/delete) y validaciones.
- UX/Accesibilidad
  - Mensajes de error/toasts consistentes, estados vacíos, focus management en modal, etiquetas ARIA.
- Normalización y encoding
  - Corregir mojibake en blades/JS (UTF‑8), i18n de textos y formateo moneda/fecha.

Prioridad Baja
- Pipeline de assets
  - Unificar uso de Vite y/o documentar excepción de `public/assets` (versión, cache busting).
- Observabilidad
  - Métricas simples (tiempos de respuesta en endpoints críticos), trazas mínimas.

Tickets sugeridos
1) Proteger API Caja con auth y roles
   - Archivos: routes/api.php, app/Http/Kernel.php, config/auth.php, middleware de permisos.
   - Descripción: Agrupar `/api/caja/*` bajo `auth` + autorización por rol; tests Feature.
   - Estimado: 2–3 días; Riesgos: impacto en clientes front.

2) Armonizar Wizard (IDs, guardias, store_id)
   - Archivos: resources/views/caja/_wizard_modals.php, public/assets/js/caja/{wizard.js,state.js,mainTable.js}.
   - Descripción: Unificar `#wizardPrecorte`, restaurar `puedeWizard()`, fuente de `store_id`; QA con estados.
   - Estimado: 1–2 días; Riesgos: regresiones UI.

3) FormRequests Precorte/Postcorte
   - Archivos: app/Http/Requests/Caja/{PrecorteUpdateRequest,PostcorteUpdateRequest}.php, controladores Caja.
   - Descripción: Validaciones de tipos monetarios/negativos, requireds, límites; pruebas Feature.
   - Estimado: 1–2 días; Riesgos: cambios en payload del front.

4) Índices DB (FKs y filtros)
   - Archivos: SQL (migraciones si se maneja esquema), revisión con DBA.
   - Descripción: Índices en FKs y filtros (`ticket(terminal_id, closing_date)`, `precorte_*`, `postcorte(sesion_id)`).
   - Estimado: 0.5–1 día; Riesgos: tamaño/index bloat.

5) Seguridad CORS y Kernel
   - Archivos: app/Http/Kernel.php, config/cors.php (si se agrega), ApiResponseMiddleware.
   - Descripción: Asegurar CORS correcto y middleware activo, entorno local vs prod.
   - Estimado: 0.5 día; Riesgos: bloqueos cross-origin.

Comandos propuestos (no ejecutar todavía)
- Rutas y entorno
  - php artisan route:list
  - php artisan about
- Seguridad/paquetes
  - composer audit
  - npm audit
- Tests
  - php artisan test
- Migraciones (solo en ambientes controlados)
  - php artisan migrate
  - php artisan db:seed

