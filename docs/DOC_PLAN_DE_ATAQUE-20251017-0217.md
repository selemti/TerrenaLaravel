Plan de Ataque — CRUDs faltantes + ERD

Fecha: 20251017-0217

Altas
- Auth/roles en /api/caja (Sanctum/JWT + spatie/permission) y Kernel estándar.
- Wizard: IDs consistentes, guardias reactivados, store_id desde backend.
- Índices DB: precorte_efectivo(precorte_id), eliminar duplicado precorte(sesion_id), evaluar índice parcial en ticket.
- PostgreSQL upgrade (9.5 → versión soportada).

Medias
- CRUD admin Formas de Pago (selemti.formas_pago) — endpoints REST + UI (opcional).
- CRUD Proveedores (selemti.proveedor) — si no está cubierto por Livewire actual.
- API Recepciones (list/show/create) — hoy solo UI Livewire.
- Recetas: versionado/publicación/borrador; validación costos; endpoints REST opcionales.
- Stock Policy: CRUD y aplicación en flujos afectados.
- Validaciones con FormRequests en Precorte/Postcorte y catálogos.

Bajas
- Observabilidad (logs/metrics caja), Swagger con esquemas y ejemplos; pipeline de assets (Vite/public).

Tickets sugeridos (nuevos)
1) CRUD Formas de Pago
   - Rutas: /api/caja/formas-pago [GET, POST, PUT, DELETE], vistas opcionales.
   - Archivos: controlador + FormRequest + model (ya existe) + tests.
   - Riesgos: coordinación con POS si se sincroniza.
2) CRUD Proveedores
   - Rutas: /api/catalogos/proveedores [CRUD].
   - Archivos: controlador + requests + vistas/Livewire.
3) API Recepciones Inventario
   - Rutas: /api/inventory/receptions [index, show, store].
   - Archivos: controlador + requests; Livewire ya existente.
4) Recetas — versionado y publicación
   - Rutas: /api/recipes/...; lógica de costos; validación insumos.
5) Tests Feature para Caja (precorte/postcorte/conciliación)
   - Cubrir estados: tickets abiertos, DPR pendiente, validación postcorte.
6) Kernel y Middlewares
   - Crear app/Http/Kernel.php; registrar ApiResponseMiddleware; CORS adecuado.

Comandos (propuestos, no ejecutar)
- php artisan make:request, make:controller, make:policy; php artisan test; composer audit; npm audit.
