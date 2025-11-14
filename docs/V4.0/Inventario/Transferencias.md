# Inventario · Transferencias internas (V4.0)

## 1. Alcance

Documenta el flujo de transferencias entre almacenes (SOLICITADA → APROBADA → EN_TRANSITO → RECIBIDA → POSTEADA) basado en `TransferService`, `transfer_*` y los componentes Livewire `Transfers/*`. Sustituye el README legacy (`resources/views/transfers/README.md`) y referencias dispersas en docs V2. Toda modificación debe reflejarse aquí antes de mergear código.

## 2. Tablas y modelos

| Tabla | Modelo | Campos clave | Comentarios |
|-------|--------|--------------|-------------|
| `selemti.transfer_cab` | `App\Models\Inventory\TransferHeader` | `origen_almacen_id`, `destino_almacen_id`, `estado`, `creada_por`, `aprobada_por`, `despachada_por`, `recibida_por`, `posteada_por`, timestamps (`fecha_*`) | Estados soportados por constantes en el modelo. |
| `selemti.transfer_det` | `App\Models\Inventory\TransferLine` | `transfer_id`, `item_id`, `cantidad_solicitada`, `cantidad_despachada`, `cantidad_recibida`, `unidad_medida`, `observaciones[_recepcion]` | `varianza` y `varianza_porcentaje` calculados como atributos. |
| `selemti.mov_inv` / `inventario.movements` | `App\Models\Inv\Movement` | `tipo_movimiento` (`TRASPASO_OUT/IN`), `cantidad`, `almacen_id`, `item_id`, `referencia_tipo='TRANSFER'`, `referencia_id` | TransferService los genera al postear. |
| Catálogos | `selemti.cat_almacenes`, `selemti.items`, `selemti.unidades_medida` | Usados por los formularios para seleccionar origen/destino e ítems. |

## 3. Servicios y flujo backend

**Servicio principal:** `App\Services\Inventory\TransferService`

1. `createTransfer($fromAlmacenId, $toAlmacenId, $lines, $userId)`  
   - Crea cabecera `transfer_cab` (estado `SOLICITADA`) y líneas con `cantidad_solicitada`.  
   - Valida IDs positivos y que origen ≠ destino.  
   - TODO anotado en código: validar stock al crear.

2. `approveTransfer($transferId, $userId)`  
   - Solo desde `SOLICITADA`. Verifica stock en `selemti.stock` (consulta actual) por item.  
   - Actualiza `estado=APROBADA`, guarda `aprobada_por`, `fecha_aprobada`.

3. `markInTransit($transferId, $userId, $numeroGuia)`  
   - Solo desde `APROBADA`. Copia `cantidad_despachada = cantidad_solicitada`, registra `numero_guia`, `despachada_por`, `fecha_despachada`, estado `EN_TRANSITO`.

4. `receiveTransfer($transferId, $receivedLines, $userId)`  
   - Solo desde `EN_TRANSITO`. Actualiza `cantidad_recibida`, observaciones por línea, `recibida_por`, `fecha_recibida`, estado `RECIBIDA`.  
   - Calcula varianzas por línea (`hasVariance()`).

5. `postTransferToInventory($transferId, $userId)`  
   - Solo desde `RECIBIDA`. Inserta movimientos Kardex:  
     - `TRASPASO_OUT` (cantidad negativa) en almacén origen.  
     - `TRASPASO_IN` (cantidad positiva) en almacén destino.  
   - Actualiza estado `POSTEADA`, `posteada_por`, `fecha_posteada`.  
   - TODO anotado: sellar estado final y generar logs/auditoría.

Cada método opera dentro de transacciones y lanza `RuntimeException` si el estado no corresponde.

## 4. Componentes y rutas

| Ruta | Componente/Vista | Estado actual |
|------|------------------|---------------|
| `/transfers` | `App\Livewire\Transfers\Index` | Listado con datos mock (`mockTransfers()`). Falta conexión a API/DB. |
| `/transfers/create` | `App\Livewire\Transfers\Create` | Formulario funcional (carga catálogos reales). Guarda vía mock `mockCreateTransfer()`, pendiente integrarla con API. |
| `/transfers/{id}/detail` (planeado) | `App\Livewire\Inventory\TransferDetail` (por implementar) | Debe consumir endpoints ship/receive/post. |
| APIs previstas | `POST /api/inventory/transfers/create`, `/{id}/approve`, `/{id}/ship`, `/{id}/receive`, `/{id}/post` | Rutas documentadas en `TransferService` y FRONT blueprint, pero no existen controladores reales aún. |

Los menús se muestran sólo a usuarios con `can_manage_purchasing` (layout Terrena). `FRONT_BLUEPRINT_V2` propone permisos específicos (`inventory.transfers.approve/ship/receive/post`).

## 5. Reglas de negocio

1. **Estados**: sólo se puede avanzar en el orden descrito; se documenta `STATUS_CANCELADA` pero no hay métodos para cancelación aún.  
2. **Stock origen**: aprobación exige validar `selemti.stock`. TransferService ya consulta pero depende de la tabla `stock`.  
3. **Varianzas**: `receiveTransfer` detecta diferencias y las devuelve en la respuesta; faltan políticas para tolerancias, aprobaciones y ajustes automáticos.  
4. **Kardex inmutable**: `postTransferToInventory` genera `TRASPASO_OUT/IN`. Debe ejecutarse una sola vez; repetir el método duplicaría movimientos.  
5. **Permisos**: cada etapa debería requerir un permission distinto (`transfers.create`, `transfers.approve`, etc.). Aún no están registrados en Spatie.  
6. **Auditoría**: faltan logs de quién aprobó/despachó/recibió/posteó. Registrar en tabla de auditoría o `mov_inv.meta`.

## 6. Riesgos y tareas pendientes

1. **API inexistente**: los componentes trabajan con mocks. Se necesitan controladores REST en `App\Http\Controllers\Api\Inventory\TransferController` (o similar) que usen `TransferService`.  
2. **Listado sin datos**: `Transfers\Index` no consulta la BD. Conectar a `transfer_cab` y ofrecer filtros/paginación.  
3. **Servicios duplicados**: existe documentación legacy (`resources/views/transfers/README.md`) con estados BORRADOR/DESPACHADA/PARCIAL que no coincide 100% con los estados actuales. Unificar terminología (`SOLICITADA/APROBADA/...`) y mover el README antiguo a histórico.  
4. **Validaciones adicionales**: falta revisar conversión de unidades (`unidad_medida`), lotes específicos, manejo de parciales y evidencias.  
5. **Integración UI**: crear componentes para aprobar/despachar/recibir/postear (Wizards/side panels) reutilizando `<x-confirm-modal>` según lo indicado en `FRONT_BLUEPRINT_V2`.  
6. **Testing**: no hay pruebas Feature para TransferService ni para los endpoints previstos. Añadir `tests/Feature/TransferWorkflowTest.php` (existe) y extenderlo tras implementar la API real.

## 7. Checklist al modificar transferencias

- [ ] Verificaste las tablas `selemti.transfer_cab` y `transfer_det` en la BD (conexión WSL → `172.24.240.1`).  
- [ ] `TransferService` cubre la etapa que modificaste y los métodos se mantienen consistentes con los estados permitidos.  
- [ ] Cualquier nuevo endpoint está protegido con `auth:sanctum` y permisos Spatie.  
- [ ] Las vistas/Livewire que consumen mocks se actualizan para usar la API real.  
- [ ] Documentaste aquí los estados adicionales, campos nuevos o cambios en rutas antes de mergear.
