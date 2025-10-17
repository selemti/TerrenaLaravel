Plan de Ataque — Tickets desde VIEW_FIELD_MATRIX y Auditorías

Fecha: 2025-10-17 02:57

Resumen
- Tickets accionables derivados de la matriz de campos, rutas/controladores y ERDs. No implican cambios en BD salvo donde se indique como “coordinar con DBA”.

Alta prioridad
1) Proteger /api/caja/* con auth/roles
   - Archivos: routes/api.php; app/Http/Kernel.php; config/auth.php
   - Acciones: añadir middleware auth (Sanctum/JWT) + permission; tests Feature.
   - Estimado: 2–3 días; Riesgos: impacto en front.

2) Wizard Cortes: añadir name= en inputs y reactivar guardias
   - Archivos: resources/views/caja/_wizard_modals.php; public/assets/js/caja/{mainTable.js,wizard.js,state.js}
   - Acciones: añadir name="decl_credito|decl_debito|decl_transfer" y para denoms; restaurar puedeWizard(); unificar IDs.
   - Estimado: 1–2 días; Riesgos: validaciones cruzadas.

3) FormRequests Precorte/Postcorte
   - Archivos: app/Http/Requests/Caja/{PrecorteUpdateRequest,PostcorteUpdateRequest}.php; controladores Caja
   - Acciones: reglas (denoms >0, montos >=0, max len notas, tipos numéricos); mensajes y tests.
   - Estimado: 1–2 días; Riesgos: cambios en payload.

4) UI Postcorte: veredictos/notas/validado
   - Archivos: resources/views/caja/_wizard_modals.php; public/assets/js/caja/wizard.js
   - Acciones: exponer campos y flujo de validación; reflejar ‘validado’ y notas.
   - Estimado: 1 día; Riesgos: sincronización con backend.

5) Kernel estándar y CORS
   - Archivos: app/Http/Kernel.php; app/Http/Middleware/ApiResponseMiddleware.php
   - Acciones: normalizar Kernel; registrar middlewares; verificar CORS.
   - Estimado: 0.5–1 día; Riesgos: arranque.

Media prioridad
6) Recepciones Inventario — API y alineación BD/UI
   - Archivos: app/Http/Controllers/Api/Inventory/ReceptionController.php (nuevo); Requests; vistas Livewire
   - Acciones: endpoints index/show/store; confirmar columnas (qty_pack, pack_size, lot, exp_date, temp, evidence); mapear a tablas (cab/det/lote); tests.
   - Estimado: 2–3 días; Riesgos: modelado.

7) CRUD Formas de Pago (admin)
   - Archivos: app/Http/Controllers/Api/Caja/FormasPagoController.php; Requests; vistas opcionales
   - Acciones: agregar POST/PUT/DELETE (si procede); policies; tests.
   - Estimado: 1–2 días; Riesgos: coherencia operativo.

8) CRUD Proveedores (si no cubierto)
   - Archivos: Api/Catalogs/ProveedoresController (nuevo) o Livewire; Requests
   - Acciones: endpoints; validaciones; tests.
   - Estimado: 1–2 días; Riesgos: duplicidad con Livewire.

9) Índices DB (coordinar con DBA)
   - Acciones: crear idx en selemti.precorte_efectivo(precorte_id); eliminar índice duplicado en selemti.precorte(sesion_id); evaluar índice parcial en public.ticket (terminal_id, closing_date) WHERE closing_date IS NULL.
   - Estimado: 0.5–1 día; Riesgos: ventana y bloat.

Baja prioridad
10) Limpieza de mojibake e i18n
    - Archivos: blades/JS con acentos rotos
    - Acciones: forzar UTF-8; revisar textos y locale.
    - Estimado: 0.5 día.

11) Tests Feature — Caja
    - Archivos: tests/Feature/*
    - Acciones: cubrir precorte (preflight, create/update), conciliación, postcorte (validado); corregir fallo en PrecorteApiTest (ruta '/').
    - Estimado: 1–2 días.

Matrices → Tickets específicos
- Inputs sin columna equivalente (propuesta):
  - recepciones.lines[].temp, evidence → columnas en detalle/archivo; tipo: numeric(5,2) y text/url.
- Columnas sin UI:
  - postcorte: veredictos, validado, notas → añadir a vista wizard.
- Tipos no alineados:
  - Montos: homogenizar a numeric(12,2) en precorte_efectivo/subtotales y precorte_otros.monto; evitar double precision en POS para cálculos críticos.

Notas
- Todas las acciones de BD requieren coordinación con DBA y ambiente de staging.
- Cambios de seguridad no tocan .env; sólo wiring de middlewares/guards/policies.

