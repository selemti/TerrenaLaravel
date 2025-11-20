# Política de Auditoría y Bitácoras
Versión: 2025-10-27  
Estado: ACTIVO / OBLIGATORIO

## Versión 1.1
> Desde Sprint 1.9, el endpoint de carga de evidencias requiere autenticación Sanctum y permiso de rol operacional (`can_manage_purchasing`).

## Principios operativos
- Cada acción que cambie inventario físico, valor inventario, consumo POS histórico, caja chica o autorice desvíos fuera de tolerancia **DEBE** generar un registro en `audit_log` con `user_id`, `timestamp`, `motivo`, `evidencia_url` y `payload_json`.
- A futuro, `evidencia_url` (foto, ticket, remisión) será obligatoria; si no se provee se deberá responder HTTP 422 y rechazar la operación.
- No se permite ajuste silencioso: toda corrección requiere motivo y trazabilidad.

## Acciones que SIEMPRE generan log
- Reprocesar POS.
- Reversar consumo POS.
- Declarar producción y merma.
- Ajustes de inventario.
- Recepciones de compra / devoluciones.
- Transferencias entre almacenes.
- Marcar un ítem como agotado en POS.
- Forzar que un SKU se vaya a cocina.
- Cambios de receta/costos.

## Campos mínimos en bitácoras
- `user_id` (obtenido del guard `auth:sanctum`)
- `timestamp`
- `accion` (enum)
- `referencia` (ticket_id, batch_id, menu_item_id, etc.)
- `motivo`
- `detalles` (JSON con payload contextual)
- `resultado` (`success`, `error`, `reversed`, etc.)

## Alcance obligatorio por permisos
Cada endpoint protegido por los permisos:
- `can_reprocess_sales`
- `can_manage_purchasing`
- `can_edit_production_order`
- `can_manage_cash_register`
- `alerts.view`
debe generar registro de auditoría al ejecutar acciones que cambien inventario, reprocesen ventas, publiquen mermas, alteren disponibilidad operativa o atiendan alertas. El log debe capturar el usuario autenticado vía Sanctum, la carga útil enviada y el resultado final (éxito o error).

## Tablas de log (existentes / planeadas)
- `selemti.inv_consumo_pos_log`
- `selemti.pos_reverse_log`
- `selemti.menu_availability_log`
- `selemti.production_log`
- `selemti.stock_adjustment_log`
- `selemti.corte_cocina_log`

## Regla de cierre de sprint
Ningún sprint puede cerrar endpoints que mueven inventario o disponibilidad sin generar log con los campos mínimos definidos arriba.

## Evidencia obligatoria
- Para ajustes manuales, reprocesos POS, recepciones fuera de tolerancia y transferencias la evidencia (foto, guía o comprobante) es requisito para completar la operación.
- Los archivos se cargan vía `/api/audit/evidence/upload`; el campo `evidencia_url` devuelto debe incluirse en el request de la acción auditada.
- Política de retención: conservar la evidencia por 90 días o hasta el cierre de la auditoría asociada, lo que ocurra primero.

## Dashboard de Auditoría (Sprint 2.0)
- Ruta interna web: GET /audit/logs (Livewire)
- Ruta API backoffice: GET /api/audit/logs (JSON)
- Requiere permiso audit.view
- Uso: Soporte interno puede filtrar por usuario, acción y rango de fechas
  para investigar quién movió inventario, transfirió mercancía, ajustó stock
  o reprocesó ventas POS.
- IMPORTANTE: Sólo lectura. No hay endpoints para borrar ni editar logs.

### Consideraciones de seguridad de acceso al dashboard
- La ruta web `/audit/logs` sólo debe estar disponible para personal interno autenticado.
- La ruta API `/api/audit/logs` requiere permiso `audit.view` y un token Sanctum válido.
- `evidencia_url` puede apuntar a fotos de facturas, guías o tickets con datos sensibles
  (costos, proveedores, cantidades). Estas imágenes son confidenciales.
- Está prohibido compartir capturas de pantalla de este dashboard fuera de la organización
  sin autorización expresa de Dirección de Operaciones.

## Cobertura actual de auditoría operacional

Las siguientes acciones generan una entrada en `audit_log`:

- RECEPTION_APPROVE / RECEPTION_POST
- TRANSFER_SHIP / TRANSFER_RECEIVE / TRANSFER_POST
- INVENTORY_ADJUST
- PRODUCTION_POST_BATCH
- POS_REPROCESS / POS_REVERSE
- INSUMO_CREATE

Cada entrada incluye:
- timestamp
- user_id (quién hizo la acción)
- accion (evento normalizado)
- entidad + entidad_id (ej. 'transfer' + transfer_id)
- motivo (explicación humana de por qué se hizo)
- evidencia_url (foto/remisión/ticket)
- payload_json (snapshot del request)

A futuro `motivo` y `evidencia_url` serán obligatorios en las acciones críticas de inventario, caja chica y POS para cumplir controles operativos.
No se permiten movimientos silenciosos.
Super Admin y soporte también quedan auditados.

## Auditoría de Cambios de Acceso a Usuarios
- Cualquier creación o edición de usuario, asignación de roles o permisos directos ejecutada por personal con privilegios administrativos genera `USER_PERMISSIONS_UPDATE` en `selemti.audit_log`.
- Se registra quién hizo el cambio (`admin_id`), sobre qué usuario se aplicó (`target_user_id`), los roles asignados y los permisos directos resultantes.
- Si la auditoría falla no se bloquea la operación, pero el incidente debe revisarse manualmente en soporte/seguridad.
- Implementado en `app/Livewire/People/UsersIndex.php` a través de `auditAccessChange()`.

## Suspensión y Reactivación de Cuentas
- Activar o desactivar el acceso de un usuario también genera un evento forense.
- Cada acción de suspensión o reactivación registra:
  - admin_id (quién ejecutó la acción),
  - target_user_id (a quién se le aplicó),
  - nuevo estado (ENABLED / DISABLED),
  - acción estandarizada (`USER_ENABLE` / `USER_DISABLE`).
- Este log es obligatorio incluso si la persona sigue en nómina pero se le revocó acceso operativo.
- Implementado en `UsersIndex::toggleActive()`.
El usuario 'soporte' debe conservar permanentemente el rol Super Admin. Este rol garantiza acceso de emergencia a todos los módulos (incluyendo auditoría). Remover Super Admin del usuario 'soporte' requiere aprobación explícita de Dirección de Operaciones.

## Dashboard interno /audit/logs
- El dashboard interno de auditoría está disponible en la ruta interna /audit/logs.
- Sólo personal con permiso audit.view puede acceder.
- Muestra eventos como TRANSFER_SHIP, TRANSFER_RECEIVE, INVENTORY_ADJUST, RECEPTION_POST, PRODUCTION_POST_BATCH, POS_REPROCESS, INSUMO_CREATE, USER_DISABLE y USER_ENABLE.
- Las filas se resaltan así:
  - Rojo (table-danger): tolerancia_fuera = true.
  - Amarillo (table-warning): requires_investigation = true.
  - Azul (table-info): USER_DISABLE / USER_ENABLE (seguridad de acceso).
- Cada fila incluye motivo y evidencia_url (si se aportó).
- motivo es obligatorio para movimientos críticos.
- evidencia_url será obligatoria en producción.
Quitar estos logs requiere aprobación escrita de Dirección de Operaciones.

## Endpoints legacy (deprecated)
- `/api/audit-log/list`
- `/api/audit-log/users`
- `/api/audit-log/modules`

Estos endpoints históricos siguen disponibles para compatibilidad, pero no reciben mejoras específicas. La ruta oficial vigente es `/api/audit/logs` con filtros avanzados y protección `audit.view`.
