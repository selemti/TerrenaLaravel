Wizard de Corte de Caja — Flujo, Validaciones y Riesgos

Fecha: 2025-10-17 02:58

Ubicación (controladores, requests, vistas, JS)
- Controladores (API Caja):
  - app/Http/Controllers/Api/Caja/CajasController.php
  - app/Http/Controllers/Api/Caja/PrecorteController.php
  - app/Http/Controllers/Api/Caja/PostcorteController.php
  - app/Http/Controllers/Api/Caja/SesionesController.php
  - app/Http/Controllers/Api/Caja/ConciliacionController.php
  - app/Http/Controllers/Api/Caja/FormasPagoController.php
- Requests relacionados:
  - app/Http/Requests/StorePrecorteRequest.php:12 (authorize(): false) — no está en uso
  - app/Http/Requests/Auth/LoginRequest.php:17 (authorize(): true)
- Vistas y parciales:
  - resources/views/caja/cortes.blade.php:2 (@include('caja._wizard_modals'))
  - resources/views/caja/_wizard_modals.php:17 (id="wizardPrecorte")
  - resources/views/layouts/terrena.blade.php (carga assets y layout)
- JavaScript (helpers/state/wizard):
  - public/assets/js/caja/main.js
  - public/assets/js/caja/mainTable.js:32 (const store = 1)
  - public/assets/js/caja/wizard.js:61 (document.getElementById('czModalPrecorte'))
  - public/assets/js/caja/state.js:14 (modal: getElementById('czModalPrecorte')) y 50 (modalElement: 'wizardPrecorte')
  - public/assets/js/caja/helpers.js, config.js

Flujo (Mermaid)
```mermaid
flowchart TD
  A[Inicio en Cajas del día] --> B[Preflight sesión]
  B -->|GET/POST /api/caja/precortes/preflight/{sesion}| C{Tickets abiertos?}
  C -- Sí --> C1[Banner: Falta corte POS]
  C -- No --> D[Crear/recuperar Precorte]
  D -->|POST /api/caja/precortes| E[Precorte ID]
  E --> F[Declaración: denoms + no efectivo]
  F -->|POST /api/caja/precortes/{id}| G[Conciliación]
  G -->|GET /api/caja/conciliacion/{sesion}| H{DPR ok?}
  H -- No --> C1
  H -- Sí --> I[Postcorte]
  I -->|POST /api/caja/postcortes| J[Veredictos/notas]
  J -->|POST /api/caja/postcortes/{id} (validado=true)| K[Cerrar sesión cajón]
```

Validación por paso
- Cliente (JS):
  - Paso 1: requiere total de efectivo (denominaciones) > 0 y campos no efectivo con números válidos; botón Guardar habilitado cuando ok.
  - Paso 2: muestra conciliación; “Ir a Postcorte” bloqueado hasta DPR; “Sincronizar POS” para refrescar.
  - Paso 3: veredictos/notas/validar (parte UI presente; revisar completitud).
- Servidor (API):
  - Preflight: rechaza si hay tickets abiertos (public.ticket.closing_date IS NULL).
  - Precorte: updateLegacy borra/reescribe denoms y no-efectivo en transacción; totales recalculados server-side.
  - Postcorte: create/update calcula diferencias DECIMAL y puede cerrar sesión; valida ‘validado’ y marca timestamps.

Persistencia
- Precorte: selemti.precorte (cabecera), selemti.precorte_efectivo (denominaciones), selemti.precorte_otros (no-efectivo).
- Conciliación: vista selemti.vw_conciliacion_sesion (lectura).
- Postcorte: selemti.postcorte (upsert por sesion_id); al validar, cierra selemti.sesion_cajon.

Navegación
- Paso a paso gestionado en public/assets/js/caja/wizard.js/state.js: setStep(1→2→3), con visibilidad de botones por paso y barra de progreso.
- “Next/Back”: el avance bloquea hasta cumplir validaciones; regreso permitido para editar.
- Confirmación final: validar=true en update postcorte y cierre de sesión.

Riesgos y mitigación
- Idempotencia
  - Mitigar con token/nonce por formulario y validación server-side de estado (no re-crear precorte si existe para la sesión; ya implementado en createLegacy).
- Concurrencia
  - Riesgo: dos usuarios intentando cerrar la misma sesión.
  - Mitigar con transacciones y SELECT ... FOR UPDATE en postcorte/estado de sesión; verificar ‘validado’ y estatus antes de actualizar; unique(sesion_id) ya ayuda.
- Doble-submit
  - Mitigar: deshabilitar botones al enviar; en servidor, verificar estado actual (p. ej., no repetir INSERT ni validar dos veces); ya hay lógica idempotente parcial.
- Precisión monetaria / TZ
  - Usar DECIMAL/NUMERIC en totales; evitar float en cálculos. Confirmar TZ para fechas de corte y rangos de sesión.

Bugs concretos (archivo:línea)
- Parcial del modal con extensión inconsistente
  - resources/views/caja/cortes.blade.php:2 (@include('caja._wizard_modals')) — espera .blade.php, pero existe resources/views/caja/_wizard_modals.php
- ID del modal inconsistente
  - resources/views/caja/_wizard_modals.php:17 (id="wizardPrecorte")
  - public/assets/js/caja/wizard.js:61 (busca 'czModalPrecorte'); public/assets/js/caja/state.js:14/50 (mezcla 'czModalPrecorte' y 'wizardPrecorte')
- Botón de Wizard habilitado sin reglas
  - public/assets/js/caja/mainTable.js:23 (puedeWizard) y 32 (const store = 1)
- Request con authorize()=false (no usado, pero confuso)
  - app/Http/Requests/StorePrecorteRequest.php:12 (authorize(): false)

Checklist de pruebas manuales
- Preflight
  - [ ] Con tickets abiertos, bloquea avance y muestra banner.
  - [ ] Sin tickets abiertos, permite crear/recuperar precorte.
- Precorte
  - [ ] Suma de denoms correcta y validación de no-efectivo (>=0, 2 decimales).
  - [ ] Guarda denoms/otros; re-ingreso no duplica; totales en DB correctos.
- Conciliación
  - [ ] Vista concilia con DPR; “Ir a Postcorte” habilitado solo tras DPR.
  - [ ] “Sincronizar POS” refresca conciliación.
- Postcorte
  - [ ] Cálculo de diferencias consistente; permite notas y veredictos.
  - [ ] Validado=true cierra sesión; segundo submit no reprocesa.
- Concurrencia
  - [ ] Dos usuarios no pueden validar la misma sesión simultáneamente.
- Seguridad
  - [ ] Endpoints /api/caja/* protegidos con auth/roles (una vez aplicado).
- UI/Accesibilidad
  - [ ] Botones deshabilitan durante submit; errores claros; layout responde.

