# Módulo de Recepciones de Inventario — Blueprint Técnico

## Objetivo
Implementar recepciones con trazabilidad completa proveedor → lote → movimiento → valuación, alineado con Terrena POS v1.2.

## Alcance
- Crear cabecera/detalle de recepción con numeración diaria y estado de flujo.
- Registrar lotes (`inventory_batch`) y amarrarlos con movimientos `mov_inv`.
- Incluir adjuntos, controles de calidad y aprobaciones.
- Integrar con precios históricos y alertas.

## Modelo de datos propuesto
| Tabla | Campos clave | Notas |
| --- | --- | --- |
| `selemti.recepcion_cab` | `id`, `numero_recepcion`, `proveedor_id`, `sucursal_id`, `almacen_id`, `fecha_recepcion`, `estado`, `total_items`, `peso_total_kg` | Usa secuencia `recepcion_daily_seq`. Estados: BORRADOR → RECIBIDO → VERIFICADO → APROBADO → CERRADO/RECHAZADO. | 
| `selemti.recepcion_det` | `id`, `recepcion_id`, `item_id`, `inventory_batch_id`, `lote_proveedor`, `fecha_caducidad`, `cantidad_declarada`, `cantidad_recibida`, `cantidad_rechazada`, `temperatura_recepcion`, `certificado_calidad_url` | Validaciones perishable = requiere lote/caducidad; control de rechazos.
| `selemti.inventory_batch` | `id`, `item_id`, `lote_proveedor`, `cantidad_original`, `cantidad_actual`, `fecha_caducidad`, `estado`, `temperatura_recepcion`, `doc_url`, `sucursal_id`, `almacen_id` | Permite stock multi almacén. `estado` = ACTIVO/BLOQUEADO/RECALL.
| `selemti.mov_inv` | `id`, `item_id`, `inventory_batch_id`, `tipo` (RECEPCION, TRASPASO, AJUSTE, PRODUCCION), `qty`, `uom`, `sucursal_id`, `almacen_id`, `ref_tipo`, `ref_id`, `user_id`, `meta` | Movimientos positivos/negativos.
| `selemti.recepcion_adjuntos` | `id`, `recepcion_id`, `tipo` (FACTURA, GUIA, FOTO, OTRO), `file_url`, `notas`, `uploaded_by` | Evidencias.

## Flujo funcional
1. **Alta BORRADOR**
   - Seleccionar proveedor, sucursal, almacén.
   - Agregar líneas con: producto, cantidad declarada/recibida, lote, caducidad, temperatura, adjunto.
   - Validar en vivo (Livewire) con catálogos.
2. **Confirmar recepción**
   - Al guardar, crear `inventory_batch` (uno por línea) y registrar `mov_inv` tipo `RECEPCION`.
   - Registrar precio: opción de insertar en `item_vendor_prices` si se marca.
   - Generar alertas: variancia vs precio esperado, caducidad corta.
3. **Verificación**
   - Usuario con permiso revisa y cambia estado → `VERIFICADO`. Pueden capturar diferencias, rechazos.
4. **Aprobación**
   - Roles de finanzas/gerencia cierran la recepción; se bloquea edición, se dispara notificación compras.

## Integraciones
- **Precios**: si se captura costo distinto ±X%, registrar alerta `precio_atipico`.
- **Alertas caducidad**: cron `job_alertas_stock` revisa lotes proximos a caducar.
- **Producción**: lotes quedan disponibles para órdenes; `mov_inv` detalla `inventory_batch_id`.
- **API**: `POST /api/inventory/receivings` (futuro) y `GET /api/inventory/receivings/{id}`.

## UI / UX
- **ReceptionsIndex**: tabla paginada, filtros sucursal, proveedor, estado, rango fechas.
- **ReceptionCreate**: wizard 3 pasos (datos generales → líneas → adjuntos); usar modales para adjuntos.
- **Detalle**: timeline estados, totales, lotes generados, botones aprobar/rechazar.
- **Permisos**: `inventory.receivings.view`, `.manage`, `.approve`.

## Validaciones clave
- `cantidad_recibida + cantidad_rechazada = cantidad_declarada`.
- Perishable requiere `fecha_caducidad` y `temperatura_recepcion`.
- `temperatura_recepcion` entre -30 y 60 °C.
- `fecha_caducidad >= CURRENT_DATE`.
- Documentos obligatorios para proveedores con `requiere_factura`.

## Consideraciones técnicas
- PostgreSQL 9.5: triggers con `EXECUTE PROCEDURE`, usar `CREATE OR REPLACE VIEW`.
- `search_path` ya configurado a `selemti,public`; migraciones pueden usar `Schema::create('recepcion_cab', ...)`.
- Para nuevos campos en tablas legadas, usar bloque `DO $$` con verificación `information_schema`.
- Asegurar compatibilidad con `item_id` tipo texto (aplicar cast `::text ~ '^\d+$'`).

## Roadmap de implementación
1. **Migraciones**
   - Normalizar tablas `recepcion_cab/det`, `inventory_batch`, `mov_inv` si faltan.
   - Crear secuencias diarias y triggers autopopuladas.
2. **Servicios backend**
   - `ReceptionService::create` consolidado: batch, mov_inv, alertas.
   - Eventos `ReceptionCreated`, `ReceptionApproved`.
3. **Livewire**
   - Refactor `ReceptionsIndex` y `ReceptionCreate` según wizard.
   - Modal de adjuntos con previsualización.
4. **Permisos / Policies**
   - Gates para ver/editar/aprobar.
   - Ajustar seeds (`PermissionsSeeder`).
5. **Tests**
   - Feature: crear recepción, validar lotes/mov_inv, permisos.
   - Unit: normalización de líneas.
6. **Documentación**
   - Actualizar `docs/V3/README.md` (capítulo Inventario) y guías de operación.

## Métricas iniciales
- Tiempo promedio de recepción.
- Diferencia % entre cantidad declarada vs recibida.
- Recepciones con adjuntos incompletos.
- Alertas generadas por recepción.

