# Caja · Histórico de Cortes (V4.0)

## 1. Alcance

Fuente de verdad para el flujo de consulta, análisis y aprobación de cortes de caja históricos en `selemti.sesion_cajon`, `selemti.precorte` y `selemti.postcorte`. Esta versión sustituye cualquier documento legacy y se mantiene sincronizada con:

- Controlador web `App\Http\Controllers\Caja\CortesHistoricoController`.
- APIs REST `App\Http\Controllers\Api\Caja\{PostcorteController, PrecorteController, AlertasController}`.
- Servicio `App\Services\Caja\AlertasService`.
- Vista materializada `selemti.vw_sesion_dpr` (datos de Floreant POS).
- **Nuevo**: Servicio `App\Services\Caja\AnalyticsService` (métricas agregadas).

Todo flujo o controlador que no aparezca aquí se considera legacy.

## 2. Tablas y catálogos

| Tabla | Campos relevantes | Comentarios |
|-------|-------------------|-------------|
| `selemti.sesion_cajon` | `id`, `terminal_id`, `terminal_nombre`, `cajero_usuario_id`, `apertura_ts`, `cierre_ts`, `estatus` ('ACTIVA', 'LISTO_PARA_CORTE', 'EN_CORTE', 'CERRADA'), `opening_float`, `closing_float`, `skipped_precorte`, `sucursal` | Sesión de caja por terminal. FK a `public.users(auto_id)` para cajero |
| `selemti.precorte` | `id`, `sesion_id`, `estatus`, `declarado_efectivo`, `declarado_otros`, `notas`, `creado_en`, `creado_por` | Corte preliminar con denominaciones |
| `selemti.postcorte` | `id`, `sesion_id`, `sistema_efectivo_esperado`, `declarado_efectivo`, `diferencia_efectivo`, `veredicto_efectivo` ('CUADRA', 'A_FAVOR', 'EN_CONTRA'), `sistema_tarjetas`, `declarado_tarjetas`, `diferencia_tarjetas`, `veredicto_tarjetas`, `sistema_transferencias`, `declarado_transferencias`, `diferencia_transferencias`, `veredicto_transferencias`, `validado`, `validado_por`, `validado_en`, `requiere_aprobacion`, `aprobado_por`, `aprobado_en`, `rechazado`, `motivo_rechazo`, `rechazado_por`, `rechazado_en`, `motivo_irregular`, `notas`, `creado_en`, `creado_por` | Corte final con conciliación de todos los métodos de pago |
| `selemti.alertas_cortes` | `id`, `postcorte_id`, `sesion_id`, `tipo` ('REQUIERE_APROBACION', 'APROBADO', 'RECHAZADO'), `destinatario_id`, `leida`, `creada_en`, `leida_en` | Sistema de notificaciones para aprobaciones |
| `selemti.vw_sesion_dpr` | `sesion_id`, `terminal_id`, `ticket_count`, `net_sales`, `cash_receipt_amount`, `credit_card_receipt_amount`, `debit_card_receipt_amount`, `total_revenue`, `variance`, `totaldiscountcount`, `totaldiscountamount`, `report_time` | Vista que une sesiones con `drawer_pull_report` de Floreant POS |
| `public.users` | `auto_id`, `first_name`, `last_name`, `user_id` | Usuarios de Floreant POS (cajeros) |

> Nota: `public.ticket` y `public.transactions` son tablas de Floreant POS (READ-ONLY).

## 3. Flujo operativo

### Paso 1 · Consulta de histórico

- **Ruta:** `GET /caja/cortes/historico`
- **Controlador:** `App\Http\Controllers\Caja\CortesHistoricoController::index()`
- **Vista:** `resources/views/caja/historico-cortes.blade.php`
- **Permisos:** `view-cortes-historico` o rol `Super Admin`

**Filtros disponibles:**
- Fecha rápida: Hoy, Última Semana, Mes Actual, Mes Anterior, Últimos 30 días, Personalizado
- Terminal (dropdown)
- Estatus de sesión
- Cajero (dropdown) **[NUEVO FASE 1]**
- Búsqueda global (ID sesión, terminal, cajero)
- Exclusión de domingos sin ventas
- **Más filtros** (colapsable): **[NUEVO FASE 1]**
  - Rango de diferencias (min/max)
  - Solo alertas (requiere_aprobacion = true)
  - Sin validar (validado = false)
  - Por veredicto

**Ordenamiento:**
- 10 columnas ordenables: sesion_id, apertura_ts, terminal_id, cajero_nombre, estatus, cantidad_tickets, total_ventas, sistema_efectivo, declarado_efectivo, diferencia_efectivo

**Paginación:**
- Opciones: 10, 20, 50, 100, Todos
- Bootstrap 5 pagination

**Dashboard KPIs** (superior): **[NUEVO FASE 1]**
- 💰 Ventas totales del período (con % variación vs período anterior)
- 💵 Diferencia total (efectivo + tarjetas + transferencias)
- 📋 Cantidad de cortes (por estatus)
- 🔴 Alertas críticas (sin aprobar y diferencias > $500)

### Paso 2 · Detalle de sesión

- **Ruta:** `GET /caja/cortes/historico/{id}`
- **Controlador:** `App\Http\Controllers\Caja\CortesHistoricoController::show()`
- **Vista:** `resources/views/caja/detalle-corte.blade.php`

**Información mostrada:**
- Datos de sesión (terminal, cajero, fechas, estatus, fondos)
- Precorte con cálculo de diferencia en tiempo real desde `vw_sesion_dpr`
- Postcorte con veredictos por método de pago
- Listado de tickets de la sesión (limitado a 100)

### Servicios auxiliares

**AnalyticsService** **[NUEVO FASE 1]**:
- `getDashboardMetrics(string $fechaInicio, string $fechaFin): array` - Métricas para KPIs
  - Total ventas del período
  - Total diferencias
  - Conteo de cortes por estatus
  - Alertas críticas pendientes
  - Comparación con período anterior (% variación)

**AlertasService** (existente):
- `crearAlertaAprobacion()`, `crearAlertaAprobado()`, `crearAlertaRechazado()`
- `obtenerAlertasPendientes()`, `contarAlertasPendientes()`
- `marcarLeida()`, `marcarLeidasPorPostcorte()`

## 4. Datos y reglas

1. **Cajero**: Vinculado a `public.users` (Floreant POS) mediante `sesion_cajon.cajero_usuario_id = users.auto_id`. Se muestra `first_name + last_name`.
2. **Veredictos**: Calculados automáticamente en `PostcorteController`:
   - `CUADRA`: diferencia < $0.01
   - `A_FAVOR`: diferencia > 0 (cajero tiene más)
   - `EN_CONTRA`: diferencia < 0 (cajero tiene menos)
3. **Exclusión domingos**: Usa `EXTRACT(DOW FROM apertura_ts)` donde 0 = domingo. Solo excluye si `net_sales IS NULL`.
4. **Vista agrupada por día**: **[PLANIFICADO FASE 2]** - Acordeón con totales diarios.
5. **Métricas de vw_sesion_dpr**: Proviene del `drawer_pull_report` de Floreant, se actualiza al hacer corte POS.

## 5. Rutas y endpoints activos

### Web (Vistas)
| Ruta | Propósito | Fuente |
|------|-----------|--------|
| `GET /caja/cortes/historico` | Listado histórico con filtros y KPIs | `routes/web.php` (alias `caja.historico`) |
| `GET /caja/cortes/historico/{id}` | Detalle de sesión individual | `routes/web.php` (alias `caja.historico.detalle`) |
| `GET /caja/cortes/aprobaciones` | Vista de aprobaciones pendientes | `routes/web.php` |

### API REST
| Ruta | Propósito | Fuente |
|------|-----------|--------|
| `POST /api/caja/postcorte/create` | Crear postcorte desde precorte | `routes/api.php` |
| `PUT /api/caja/postcorte/{id}` | Actualizar/validar postcorte | `routes/api.php` |
| `GET /api/caja/postcorte/{id}` | Obtener postcorte por ID | `routes/api.php` |
| `GET /api/caja/postcorte/pendientes` | Postcortes que requieren aprobación | `routes/api.php` |
| `POST /api/caja/postcorte/{id}/aprobar` | Aprobar postcorte irregular | `routes/api.php` |
| `POST /api/caja/postcorte/{id}/rechazar` | Rechazar postcorte irregular | `routes/api.php` |
| `GET /api/caja/alertas` | Alertas del usuario autenticado | `routes/api.php` |
| `GET /api/caja/alertas/count` | Contador de alertas sin leer | `routes/api.php` |
| `POST /api/caja/alertas/{id}/marcar-leida` | Marcar alerta como leída | `routes/api.php` |
| `POST /api/caja/alertas/marcar-todas-leidas` | Marcar todas como leídas | `routes/api.php` |

## 6. Componentes UI (V4.0)

### Layout
- **Base**: `layouts.terrena` (Bootstrap 5 + Alpine.js + FontAwesome 6)
- **Componentes reutilizables**:
  - Cards KPI: `x-ui.card` con badges y tooltips **[NUEVO FASE 1]**
  - Filtros: `x-ui.select`, `x-ui.date-picker`
  - Badges de estado: `x-ui.status-badge` para veredictos
  - Tablas: Bootstrap 5 responsive con `table-hover`

### JavaScript
- Alpine.js para interactividad de filtros
- Vanilla JS para auto-submit en cambios de fecha
- Chart.js para gráficos **[PLANIFICADO FASE 3]**

### Paleta de Colores (Veredictos)
- 🟢 Verde `#10B981`: CUADRA
- 🟡 Amarillo `#F59E0B`: Diferencias menores (<$100) o A_FAVOR
- 🔴 Rojo `#EF4444`: EN_CONTRA o diferencias críticas (>$500)
- 🔵 Azul `#3B82F6`: Acciones/CTAs

## 7. Riesgos y tareas abiertas

### Fase 1 (en progreso)
1. ✅ **Crear `AnalyticsService`**: Servicio para métricas agregadas de dashboard KPIs.
2. ✅ **Dashboard KPIs**: 4 cards superiores con totales del período.
3. ✅ **Filtro por Cajero**: Dropdown con query a `public.users`.
4. ✅ **Botón "Ayer"**: Agregar a filtros rápidos de fecha.
5. ✅ **Panel "Más filtros"**: Colapsable con filtros avanzados.

### Fase 2 (planificada)
6. ⏳ **Vista agrupada por día**: Query `GROUP BY DATE(apertura_ts)` con acordeón.
7. ⏳ **Reporte productividad cajeros**: Ranking con velocidad de cierre y accuracy.

### Fase 3 (planificada)
8. ⏳ **Panel Insights lateral**: Sidebar con tendencias y anomalías.
9. ⏳ **Heat map diferencias**: Visualización día/hora con Chart.js.
10. ⏳ **Monitor tiempo real**: Polling cada 30s de sesiones activas.

### Riesgos conocidos
- **Performance con grandes volúmenes**: Paginación obligatoria, índices en `sesion_cajon(terminal_id, apertura_ts)` y `postcorte(sesion_id)`.
- **Domingos sin ventas**: Lógica de exclusión depende de que `vw_sesion_dpr` tenga datos; si el corte POS no se hizo, no aparecerá.
- **Datos históricos de cajeros**: `public.users` puede tener cajeros inactivos; el filtro debe mostrar todos los que tienen sesiones.

---

**Última actualización**: 2025-11-13
**Responsable**: Claude (Frontend UI/UX)
**Estado**: Fase 1 en progreso

Todo cambio al flujo de histórico debe actualizar este archivo **antes** de mergear código relacionado.
