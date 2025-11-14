# Finanzas operativas (V4.0)

## 1. Alcance y fuentes

Concentra los módulos financieros activos (caja chica, precortes/postcortes, alertas y cierre diario). Basado en:

- Livewire Caja Chica: `App\Livewire\CashFund\{Index,Open,Movements,Arqueo,Detail,Approvals}` y vistas `resources/views/livewire/cash-fund/*.blade.php`, rutas `routes/web.php:267-272`.
- Modelos `App\Models\{CashFund,CashFundMovement,CashFundArqueo,CashFundMovementAuditLog}` (tablas `selemti.cash_funds`, `cash_fund_movements`, `cash_fund_arqueos`, etc.).
- APIs de caja: `app/Http/Controllers/Api/Caja/*` y `routes/api.php:104-174` (precortes, postcortes, alertas, conciliación, formas de pago, sesiones).
- Servicios operativos: `App\Services\Operations\DailyCloseService` (cierre diario), `App\Services\Operations\PosConsumptionService` (consumo POS, utilizado por DailyClose), `App\Services\Audit\AuditLogService`.
- Documentación vigente `docs/V4.0/Caja/HistoricoCortes.md` (dashboard histórico), legacy `docs/CajaChica/*`.

## 2. Módulos y responsabilidades

### 2.1 Caja chica (Livewire)

| Ruta | Componente | Tablas | Estado actual |
|------|------------|--------|---------------|
| `/cashfund` | `CashFund\Index` | `selemti.cash_funds` | Listado con filtros por estado/búsqueda. Calcula sucursal vía `cat_sucursales` (`getSucursalNombre`). |
| `/cashfund/open` | `CashFund\Open` | `cash_funds` | Alta de fondo (monto inicial, sucursal, responsable). |
| `/cashfund/{id}/movements` | `CashFund\Movements` | `cash_fund_movements`, `cash_fund_movement_audit_logs` | Registro/consulta de egresos, reintegros, depósitos; soporta adjuntos y requiere aprobaciones. |
| `/cashfund/{id}/arqueo` | `CashFund\Arqueo` | `cash_fund_arqueos` | Arqueo y paso a `EN_REVISION`, permite cerrar fondo. |
| `/cashfund/{id}/detail` | `CashFund\Detail` | `cash_funds` + relaciones | Resumen completo del fondo. |
| `/cashfund/approvals` | `CashFund\Approvals` | `cash_fund_movements` | Bandeja de movimientos `POR_APROBAR`, aplica `approve/reject` con bitácora. |

Estados del fondo (`CashFund`): `ABIERTO`, `EN_REVISION`, `CERRADO`. Movimientos (`CashFundMovement`) manejan tipos `EGRESO`, `REINTEGRO`, `DEPOSITO` y estatus `APROBADO/POR_APROBAR/RECHAZADO`. Los cálculos de saldo se exponen como accessors (`total_egresos`, `total_reintegros`, `saldo_disponible`).

Permisos: el menú usa `['active' => 'cajachica']`, pero aún no hay policies explícitas; se recomienda crear `cashfund.view`, `cashfund.manage`, `cashfund.approve`.

### 2.2 API de caja (precortes/postcortes/alertas)

Definido en `routes/api.php:104-174` bajo `Route::prefix('caja')`:

| Grupo | Controlador | Endpoints destacados |
|-------|-------------|----------------------|
| Cajas | `CajasController` | `GET /api/caja/cajas` lista cajas activas. |
| Tickets | `CajaController` | `GET /api/caja/ticket/{id}` detalle. |
| Sesiones | `SesionesController` | `GET /api/caja/sesiones/activa`. |
| Precortes | `PrecorteController` | `POST /precortes` (createLegacy), `GET /{id}` show, `POST /{id}` update, `GET /{id}/totales`, `POST /{id}/enviar`, `GET /sesion/{sesion_id}/totales`. Aún se apoyan en endpoints “legacy” pero están bajo Sanctum. |
| Postcortes | `PostcorteController` | CRUD + aprobación (`/pendientes-aprobacion`, `/aprobar`, `/rechazar`). |
| Alertas | `AlertasController` | `GET /alertas`, `/count`, `PUT /{id}/marcar-leida`, `PUT /marcar-todas-leidas`. Consumidas por `layouts/terrena`. |
| Conciliación | `ConciliacionController` | `GET /conciliacion/{sesion_id}`. |
| Formas de pago | `FormasPagoController` | `GET /formas-pago`. |

Estos endpoints alimentan el dashboard histórico (`docs/V4.0/Caja/HistoricoCortes.md`) y el layout (alertas). Aún existen rutas legacy (`/caja/*.php`) para compatibilidad.

### 2.3 Cierre diario y orquestador

- **Servicio**: `App\Services\Operations\DailyCloseService` (usa `PosConsumptionService`) coordina cierre por sucursal/fecha:
  1. Verifica lotes POS (`pos_sync_batches`).
  2. Valida consumo teórico (`processTheoreticalConsumption`).
  3. Revisa recepciones/transferencias del día (`selemti.recepcion_cab`, `transferencias`).
  4. Verifica conteos (`inventory_counts`).
  5. Genera snapshot (`selemti.mov_inv`, `items`).
- **API**: `routes/api.php:229-248` expone `/api/orquestador/daily-close`, `/orquestador/recalcular-costos`, `/orquestador/generar-snapshot`, todos con `auth:sanctum`. Cualquier flujo financiero que dependa del cierre debe usar estos endpoints para consolidar POS ↔ inventario ↔ caja.

### 2.4 Dashboards e integraciones complementarias

- **Histórico de cortes**: `docs/V4.0/Caja/HistoricoCortes.md` + `App\Http\Controllers\Caja\CortesHistoricoController` muestran KPIs y filtros avanzados. Es la vista aprobada para gerentes.
- **Alertas globales**: `layouts/terrena.blade.php` consulta `/api/caja/alertas*` y muestra badges en top bar. Las reglas están documentadas en la ficha de Caja y en esta guía (ver riesgos).
- **Auditoría**: `App\Services\Audit\AuditLogService` se invoca desde `PosConsumptionController` (reprocesos/reversas) y el API de producción; cualquier cambio financiero debe registrar acciones aquí.

## 3. Rutas y permisos recomendados

| Recurso | Ruta(s) | Middleware/permiso sugerido |
|---------|---------|-----------------------------|
| Caja Chica (web) | `/cashfund/*` | `auth`, `permission:cashfund.view` / `cashfund.manage` / `cashfund.approve`. |
| API Caja | `/api/caja/*` | `auth:sanctum`, `permission:caja.precorte`, `caja.postcorte.approve`, `alerts.view`. |
| Orquestador | `/api/orquestador/*` | `auth:sanctum`, `permission:operations.daily_close`. |
| Dashboards | `/caja/cortes/historico`, `/caja/cortes/aprobaciones` | `permission:view-cortes-historico`, `ver-alertas-cortes`. |

Revisa `config/permissions.php` y `docs/UI-UX/v6/PERMISSIONS_MATRIX_V6.md` para alinear nombres. Varias rutas hoy tienen middleware “temporalmente deshabilitado”; restáuralo al mover a producción.

## 4. Reglas y pendientes

1. **Middleware consistente**: algunos endpoints (`alertas`, `postcortes`) mencionan que el middleware está deshabilitado “temporariamente”. Deben protegerse con `auth:sanctum` + permisos específicos antes de exponerlos fuera de QA.
2. **Convergencia legacy**: las rutas `/api/caja/*.php` siguen existiendo para compatibilidad. Define un plan de retiro (migrar clientes al nuevo prefijo y mover la especificación a `docs/_archive`).
3. **Caja chica permisos**: el módulo Livewire no aplica policies; usuarios autenticados pueden abrir fondos. Crear gates para apertura, movimientos y aprobaciones.
4. **Adjuntos y evidencia**: `CashFundMovement` soporta `adjunto_path`, pero no se valida tamaño/formato. Define reglas y almacenamiento (`storage/app/public/cashfund`) antes de habilitar cargas masivas.
5. **DailyClose lock**: `DailyCloseService` usa `Cache::lock`. Configura Redis en producción para evitar cierres simultáneos; en ambientes sin Redis el lock no funcionará.
6. **Alerting & KPIs**: mantén sincronizados `docs/V4.0/Caja/HistoricoCortes.md` y esta guía cuando se agreguen KPIs adicionales o nuevos servicios (por ejemplo, analytics sobre `vw_sesion_dpr`).

## 5. Checklist antes de tocar finanzas

- [ ] Confirmaste en la BD real (`172.24.240.1`) las tablas `cash_funds`, `cash_fund_movements`, `cash_fund_arqueos`, `cash_fund_movement_audit_logs`, `cash_fund_movements_audit_logs`, `precorte/postcorte`, `pos_sync_batches`.
- [ ] Rutas web/API (`routes/web.php:267-272`, `routes/api.php:104-174`, `229-248`) actualizadas con middleware/permisos apropiados.
- [ ] Cualquier ajuste de caja chica usa los componentes Livewire existentes y registra cambios en esta guía y en `docs/V4.0/Caja/HistoricoCortes.md` si aplica.
- [ ] Reprocesos o cierres diarios registran auditoría (`AuditLogService`) y, si operan vía CLI (`pos:reprocess`, `recetas:recalcular-costos`), se ejecutan con `--force` sólo en producción monitorizada.
- [ ] Adjuntos o archivos sensibles se almacenan vía `storage` seguro; no publiques rutas absolutas.
- [ ] Documentaste aquí cualquier nuevo endpoint/servicio financiero antes de solicitar QA.

Siguiendo estas pautas mantenemos los flujos financieros (caja chica, corte, alertas y cierres diarios) alineados con el código real y aseguramos trazabilidad completa en Terrena V4.0.
