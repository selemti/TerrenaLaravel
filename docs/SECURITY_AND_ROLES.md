# Seguridad Operativa, Roles y Permisos
Versión: 2025-10-27  
Estado: ACTIVO / OBLIGATORIO

Este documento define las reglas de seguridad operativa del sistema Terrena.  
Estas reglas aplican para inventario, producción, recetas, costos y consumo POS.

Estas políticas SON MANDATORIAS.  
Ningún sprint puede marcarse como "Done" si viola estas reglas.

---

## 1. Separación de dominios (DB Policy)

- El esquema `public` pertenece al POS (Floreant).  
  - Tablas clave: `public.ticket`, `public.ticket_item`, `public.ticket_item_modifier`, `public.menu_item`, etc.
  - Política: **SOLO LECTURA** desde Laravel.
  - Queda estrictamente prohibido agregar columnas, triggers o constraints nuevos sobre tablas de `public` mediante migraciones de Laravel.

- El esquema `selemti` pertenece a Terrena (inventarios, recetas, costos, alertas, reprocesos).
  - Aquí se guarda todo lo operativo:
    - consumo POS expandido y confirmado,
    - control de reproceso,
    - producción y mermas,
    - costos por lote,
    - recepciones de compra,
    - alertas.
  - Política: Todos los cambios estructurales se hacen aquí.

Justificación:
- Protegemos estabilidad del POS.
- Aseguramos trazabilidad de inventario y costo sin tocar la venta original.
- Auditoría puede reconstruir cualquier ajuste.

---

## 2. Principio de Trazabilidad

Para cada acción que afecta inventario, costo o venta histórica:
- debe existir un registro con:
  - quién lo hizo (user_id),
  - cuándo lo hizo (timestamp),
  - por qué lo hizo (motivo / meta JSON),
  - qué afectó (ticket_id, lote_id, etc.).

Esto aplica a:
- reproceso de tickets,
- reversa de consumo,
- ajustes de inventario manuales,
- recepciones de mercancía,
- cierres de conteo físico,
- producción (alta de subrecetas / batches).

Ejemplos de tablas de auditoría:
- `selemti.inv_consumo_pos_log`
- `selemti.pos_reverse_log` (reversa de consumo POS)
- `selemti.mov_inv` (movimientos de inventario con tipo, ref_tipo, ref_id, meta jsonb)

Regla obligatoria:
**No debe existir flujo operativo que cambie stock o costo sin algún log.**

---

## 3. Roles operativos

Estos roles son funcionales (rol en el negocio), no sólo permisos técnicos.

### 3.1 Cajero / Punto de Venta
- Puede vender en POS.
- NO puede ver costos.
- NO puede reprocesar tickets.
- NO puede ajustar inventario.
- Puede ver disponibilidad básica (stock bajo / no disponible).

### 3.2 Cocina / Producción
- Puede reportar producción terminada (ej. "se hicieron 5 L de salsa verde").
- Puede reportar merma (ej. "se desperdiciaron 200g de pechuga").
- NO puede reprocesar tickets pasados.
- NO puede modificar recetas base.
- Puede ver ingredientes y subrecetas que le corresponden.

### 3.3 Compras / Almacén
- Puede capturar recepciones de compra.
- Puede asignar costo unitario por lote recibido (`inventory_batch.unit_cost`).
- Puede registrar inventario inicial / conteos.
- NO puede editar recetas.
- NO puede reprocesar ventas POS.
- Puede ver alertas de stock bajo.

### 3.4 Gerente de Sucursal
- Puede reprocesar tickets atrasados para cuadrar inventario (cuando un producto POS aún no tenía receta asignada).
- Puede reversar consumo de un ticket anulado.
- Puede aprobar ajustes de inventario por diferencia de conteo.
- Puede ver costos de receta y margen.
- Puede generar y aprobar el plan Produmix diario.
- Puede ejecutar intervenciones POS nivel 1 (agotados / forzar KDS) con registro en bitácora.
- NO puede editar recetas maestras.
- NO puede editar precios de proveedores.

### 3.5 Chef Ejecutivo / Control de Receta
- Puede crear/editar recetas base y subrecetas.
- Puede definir mapeo POS → receta (`selemti.pos_map`).
- Puede marcar si un ítem es:
  - `es_producible`
  - `es_empaque_to_go`
  - `es_consumible_operativo`
- NO puede hacer ajustes contables/inventario.
- NO puede reprocesar tickets.

### 3.6 Dirección / Administración Central
- Puede ver todo.
- Puede desbloquear producto caducado (recall lifting).
- Puede generar reportes históricos de costo real por lote.
- Puede supervisar Produmix y disponibilidad en vivo del POS.

---

## 4. Niveles de intervención sobre el POS

- **Nivel 0 (solo lectura histórica)**  
  Consultar tickets/ventas para conciliación de inventario y costo. Sin capacidad de modificar disponibilidad ni rutas POS.
- **Nivel 1 (intervención operativa autorizada – PERMITIDO)**  
  Marcar SKU como agotado o redirigirlo a cocina/KDS. Requiere permiso `can_manage_menu_availability`, genera registro en `selemti.menu_availability_log` con `user_id`, `timestamp`, `motivo`. No altera tickets ya vendidos ni sus totales.
- **Nivel 2 (PROHIBIDO)**  
  Cambiar tickets históricos, tocar impuestos totales, meter triggers que impidan vender si Terrena está caído o descontar inventario dentro del POS.

## 5. Permisos técnicos (ACL / Laravel Permission)

Estos son los permisos que deben existir vía seeder y usarse como middleware en controladores y rutas API.

### `can_view_recipe_dashboard`
- Quién lo tiene: Gerente de Sucursal, Chef Ejecutivo, Dirección.
- Puede:
  - ver `/pos/dashboard/missing-recipes`
  - ver diagnóstico de ticket
  - ver si un ticket requiere reproceso
  - ver discrepancias inventario/venta.

### `can_reprocess_sales`
- Quién lo tiene: Gerente de Sucursal, Dirección.
- Puede:
  - lanzar reproceso histórico de ventas (descargar inventario de tickets viejos),
  - confirmar consumo atrasado,
  - ejecutar reversa de consumo en caso de ticket anulado.
- Debe loguearse en `selemti.pos_reverse_log` / `selemti.inv_consumo_pos_log`.

### `can_edit_production_order`
- Quién lo tiene: Cocina/Producción Líder, Chef Ejecutivo.
- Puede:
  - declarar producción terminada,
  - cerrar órdenes de producción,
  - registrar merma en etapas (limpieza, cocción, etc.).

### `can_manage_purchasing`
- Quién lo tiene: Compras / Almacén / Dirección.
- Puede:
  - capturar recepciones,
  - asignar costo por lote en `inventory_batch.unit_cost`,
  - ajustar existencias iniciales.
- Cubre TODOS los endpoints bajo `/api/inventory/*`, `/api/purchasing/*`, `/api/unidades/*`, `/api/catalogs/*` (cuando afectan abastecimiento) y los reportes críticos de inventario (`/api/reports/purchasing/late-po`, `/api/reports/inventory/over-tolerance`, `/api/reports/inventory/top-urgent`).

### `can_modify_recipe`
- Quién lo tiene: Chef Ejecutivo, Dirección.
- Puede:
  - modificar receta base,
  - crear subrecetas,
  - actualizar `pos_map`.

### `can_manage_produmix`
- Quién lo tiene: Gerente de Sucursal, Dirección.
- Puede:
  - generar, editar y aprobar el plan Produmix (ver `docs/Produccion/PRODUMIX.md`),
  - emitir órdenes de producción hacia cocina,
  - marcar el plan como “listo para producción” o “requerir ajuste”.
- Cocina no posee este permiso; únicamente ejecuta producción confirmada.

### `can_manage_menu_availability`
- Quién lo tiene: Gerente de Sucursal, Dirección.
- Puede:
  - marcar SKUs agotados en POS,
  - forzar routing/KDS de un SKU a cocina,
  - restablecer disponibilidad.
- Cada acción exige motivo y se registra en `selemti.menu_availability_log`.

### `alerts.view`
- Quién lo tiene: Dirección, Operaciones, inventario manager.
- Permite consultar y acuse de alertas operativas expuestas en `/api/alerts/*`.
- Cualquier acción (acknowledge) debe generar log en la tabla de auditoría que corresponda.

### `can_manage_cash_register` *(pendiente de implementación en rutas)*
- Quién lo tendrá: Dirección, auditor interno y responsables de caja.
- Cubrirá endpoints `/api/caja/*` cuando se activen operaciones sensibles (postcorte, conciliaciones, arqueos).
- Mientras se implementa, el módulo caja permanece protegido únicamente por `auth:sanctum`.

### Guard mínimo `auth:sanctum`
- Toda ruta que afecte inventario, costo, disponibilidad POS o reproceso debe incluir `auth:sanctum`.
- Si más adelante se adopta Passport u otro mecanismo, debe mantenerse un guard autenticado equivalente que bloquee usuarios anónimos.
- Está prohibido eliminar middleware de seguridad en rutas API simplemente porque el guard final aún no está implementado; si se requiere un guard temporal, debe delegar en un guard autenticado real.
- Rutas públicas permitidas (sin autenticación): `POST /api/auth/login`, `GET /api/ping`, `GET /api/health`. Ningún otro endpoint puede exponerse sin `auth:sanctum`.

Regla:
Cada endpoint nuevo debe declarar explícitamente qué permiso exige utilizando `auth:sanctum` + `permission:<permiso>`.

```php
Route::middleware(['auth:sanctum', 'permission:can_reprocess_sales'])
    ->post('/pos/tickets/{ticketId}/reprocess', [PosConsumptionController::class, 'reprocess']);
```

## 6. Reglas Mandatorias de Seguridad Operativa

- `public.*` es solo lectura. Ninguna migración puede alterar tablas `public`.
- Ningún ajuste de inventario, reproceso de ticket o reversa puede ejecutarse sin:
  - permiso explícito,
  - registro en log con user_id, timestamp, motivo (ver `docs/AUDIT_LOG_POLICY.md`).
- Toda receta vendible DEBE estar mapeada en `selemti.pos_map`.
  - Si no lo está, debe aparecer en el dashboard `/pos/dashboard/missing-recipes` en rojo.
- Ninguna descarga de inventario puede ocurrir “directo a mano” sin pasar por un tipo de movimiento autorizado en `selemti.mov_inv`.
- Cambios a recetas (`recipe_version`) NO significan revaluar histórico automáticamente.
  - Para eso existe reproceso manual, con permiso `can_reprocess_sales`.
- Producción (fabricar salsa, cocinar pechuga, etc.) siempre crea entrada a inventario terminado y descarga insumos crudos. Nunca se ajusta stock directo.
- Intervenciones POS nivel 1 (agotado / forzar KDS) requieren `can_manage_menu_availability`, motivo y registro en `selemti.menu_availability_log`. No alteran tickets históricos.
- Solo los endpoints `POST /api/auth/login`, `GET /api/ping` y `GET /api/health` pueden operar sin autenticación. Todo el resto de la API exige `auth:sanctum`.

## 7. Cláusula de Cumplimiento para todos los Sprints

Para marcar una historia de usuario / sprint como "Done", se deben cumplir TODAS las siguientes condiciones:

- ¿Este cambio intentó tocar el esquema `public`?
  - Si sí → RECHAZADO (no permitido).
- ¿Este cambio agregó o usó endpoints que afectan stock, costo o ventas históricas?
  - Esos endpoints DEBEN:
    - exigir un permiso de los listados arriba,
    - registrar log (user_id, timestamp, motivo) en la tabla correspondiente.
- ¿El cambio agregó pantallas nuevas (dashboard, producción, compras...)?
  - Esas pantallas deben FILTRAR la visibilidad según rol.
- ¿Se agregó / cambió receta, subreceta, empaques to-go o mapeo POS→receta?
  - Debe ser visible para Chef Ejecutivo y Dirección.
  - No debe estar disponible para Cajero / Cocina básica.

Si cualquiera de estas condiciones falla, la historia NO se puede cerrar.

## 8. Referencias Cruzadas

Estas políticas aplican a:

- `docs/Recetas/POS_CONSUMPTION_SERVICE.md`
- `docs/Produccion/PRODUMIX.md`
- `docs/Produccion/PRODUCTION_FLOW.md`
- `docs/POS/LIVE_AVAILABILITY.md`
- `docs/Replenishment/ROLES_OPERATIVOS_FASE1.md`
- migraciones bajo `database/migrations/`
- seeders de permisos (RecetasPermissionsSeeder)

Toda nueva documentación técnica debe enlazar a este archivo.
