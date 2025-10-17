Wizard de Corte de Caja — Detalle

Fecha: 2025-10-17 01:26

Ubicación
- Vista: resources/views/caja/cortes.blade.php
- Parcial modal: resources/views/caja/_wizard_modals.php
- JS: public/assets/js/caja/{main.js, wizard.js, mainTable.js, helpers.js, state.js, config.js}
- Controladores: app/Http/Controllers/Api/Caja/{PrecorteController,PostcorteController,ConciliacionController,SesionesController,CajasController}

Flujo (Mermaid)
```mermaid
flowchart TD
  A[Lista Cajas día] -->|click Wizard| B[Preflight sesión]
  B -->|GET/POST /api/caja/precortes/preflight/{sesion}| C{Tickets abiertos?}
  C -- Sí --> C1[Mostrar banner Falta corte POS]
  C -- No --> D[Crear/recuperar Precorte]
  D -->|POST /api/caja/precortes| E[Precorte ID]
  E --> F[Guardar Declaración]
  F -->|POST /api/caja/precortes/{id}| G[Conciliación]
  G -->|GET /api/caja/conciliacion/{sesion}| H{DPR ok?}
  H -- No --> C1
  H -- Sí --> I[Postcorte]
  I -->|POST /api/caja/postcortes| J[Resumen y veredictos]
  J -->|POST /api/caja/postcortes/{id} validado=true| K[Cerrar sesión cajón]
```

Validación por paso
- Preflight: bloquea precorte si hay tickets abiertos (`public.ticket` con `closing_date IS NULL`).
- Precorte: requiere denoms > 0 y campos no-efectivo; guarda en `selemti.precorte_*`.
- Conciliación: lee `selemti.vw_conciliacion_sesion` y muestra diferencias; habilita paso 3 tras DPR.
- Postcorte: calcula diferencias Declarado vs Sistema y permite validación/cierre.

Persistencia
- Precorte: `selemti.precorte`, `selemti.precorte_efectivo`, `selemti.precorte_otros`.
- Postcorte: `selemti.postcorte` (upsert por `sesion_id`). Cierra `selemti.sesion_cajon` si validado.

Riesgos
- Idempotencia/doble-submit: Wizard usa Map inflight y reemplazo de listeners (`bindOnce`), pero falta bloqueo en botones en todas rutas; validar backend con llaves/constraints.
- Concurrencia multiusuario: Precorte idempotente por sesión, Postcorte upsert por `sesion_id`; riesgo de carreras si varios validan simultáneo.
- Precisión monetaria: Calcular con DECIMAL en DB y formatear en front; asegurar no depender de float. El front usa parseo robusto y toFixed(2), pero backend debe usar DECIMAL/NUMERIC.
- Zonas horarias: Consulta de sesiones usa rango por fechas; revisar TZ del servidor/app.

Bugs hallados y reproducibilidad
- Mismatch ID modal: `wizard.js` inicializa `#czModalPrecorte`; el modal real es `#wizardPrecorte` (resources/views/caja/_wizard_modals.php:1). Resultado: el modal puede no inicializar y caer en `fallbackModal`. Repro: abrir Wizard desde botón; revisar consola.
- Guard de acciones deshabilitado: `public/assets/js/caja/mainTable.js:1` `puedeWizard()` retorna `true` siempre. Repro: estados sin requisitos aún muestran botón.
- store_id hardcodeado: `mainTable.js` define `const store=1`. Repro: inspeccionar data-* del botón.
- Encoding mojibake en UI: acentos mal codificados. Repro: visualizar títulos/labels.

Mejoras propuestas
- Unificar IDs del modal y selectores (`wizard.js`/`state.js`).
- Restaurar lógica real en `puedeWizard()`.
- Obtener `store_id` desde backend o contexto.
- Añadir auth/roles a rutas `/api/caja/*`.

