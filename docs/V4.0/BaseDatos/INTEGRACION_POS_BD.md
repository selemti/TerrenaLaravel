# INTEGRACIÓN POS - BASE DE DATOS

## 1. Arquitectura de Datos

La integración entre el POS (en esquema `public`) y Terrena (en esquema `selemti`) se realiza principalmente mediante:

- **Esquema `public`**: Datos originales del POS (tickets, ítems, sesiones)
- **Esquema `selemti`**: Datos procesados y enriquecidos por Terrena
- **Proceso de sincronización**: Mediante triggers y funciones específicas

## 2. Flujo de Datos

### 2.1 Proceso Inicial: Confirmación de Consumo
- Función principal: `fn_confirmar_consumo_ticket`
- Convierte tickets POS en entradas de `inv_consumo_pos`
- Expande el consumo en `inv_consumo_pos_det` con ingredientes

### 2.2 Proceso de Expansión
- Función principal: `fn_expandir_consumo_ticket`
- Utiliza el mapeo `pos_map` para relacionar ítems POS con recetas de Terrena
- Genera consumo detallado por ingredientes de recetas

### 2.3 Proceso de Reversión
- Función principal: `fn_reversar_consumo_ticket`
- Maneja tickets anulados o modificaciones
- Actualiza inventario y registros de consumo

## 3. Tablas de Integración

### 3.1 Tablas de Origen (public)
- `public.ticket` - Tickets POS
- `public.ticket_item` - Detalle de tickets POS
- `public.ticket_payment` - Pagos de tickets POS
- `public.menu_item` - Ítems del menú POS
- `public.menu_modifier` - Modificadores POS

### 3.2 Tablas de Destino (selemti)
- `selemti.pos_map` - Mapeo POS ↔ Terrena
- `selemti.inv_consumo_pos` - Consumo POS confirmado
- `selemti.inv_consumo_pos_det` - Detalle de consumo POS
- `selemti.inv_consumo_pos_log` - Log de operaciones de consumo

### 3.3 Tablas de Relación
- `selemti.modificadores_pos` - Modificadores mapeados
- `selemti.receta_shadow` - Recetas inferidas del POS
- `selemti.menu_items` - Ítems del menú para sincronización

## 4. Triggers de Integración

### 4.1 Trigger de Confirmación
- `trg_ticket_inventory_consumption` - Se ejecuta al confirmar tickets
- Asegura que se registre el consumo en `inv_consumo_pos`
- Se ejecuta en `public.ticket`

### 4.2 Triggers de Ingreso de Ventas
- `fn_dah_after_insert` - Procesa tickets al insertar
- `fn_dah_after_insert_refuerzo` - Refuerzo de procesamiento

## 5. Funciones Clave

### 5.1 Funciones de Registro
- `fn_confirmar_consumo_ticket` - Confirma consumo de ticket
- `fn_reversar_consumo_ticket` - Revierte consumo de ticket
- `fn_expandir_consumo_ticket` - Expande consumo por ingredientes
- `fn_recipes_using_item` - Identifica recetas que usan un ítem

### 5.2 Funciones de Sincronización
- `ingesta_ticket` - Procesa tickets nuevos
- `inferir_recetas_de_ventas` - Genera recetas sombra desde ventas
- `fn_normalizar_forma_pago` - Normaliza formas de pago

## 6. Campos Clave de Relación

### 6.1 Identificación de Tickets
- `public.ticket.id` ↔ `selemti.inv_consumo_pos.ticket_id`
- `public.ticket.folio` ↔ `selemti.inv_consumo_pos.numero_ticket`
- `public.ticket.folio_date` - Fecha del ticket para contexto

### 6.2 Identificación de Items
- `public.ticket_item.menu_item_id` ↔ `selemti.pos_map.pos_item_id`
- `selemti.pos_map.receta_id` - Receta mapeada
- `public.ticket_item.id` ↔ `selemti.inv_consumo_pos_det.ticket_det_id`

### 6.3 Identificación de Sesión
- `public.ticket.ticket_session_id` ↔ `selemti.sesion_cajon.id`
- `public.ticket.terminal_id` ↔ `selemti.cat_almacenes.codigo` (mapeo)

## 7. Riesgos Detectados

### 7.1 Tickets Abiertos
- Consulta: `SELECT * FROM public.ticket WHERE closed = false AND created_date > current_date - 7`
- Riesgo: Tickets sin cierre pueden no reflejar consumo real
- Acción: Proceso diario de cierre de tickets antiguos

### 7.2 Tickets Anulados
- Consulta: `SELECT * FROM public.ticket WHERE status = 'voided'`
- Riesgo: Si no se revierte correctamente, afecta inventario
- Acción: Verificación de triggers de reversión

### 7.3 Descuentos 100%
- Consulta: `SELECT * FROM public.ticket WHERE total_discount = total_price`
- Riesgo: Consumo sin cobro, impacto en inventario vs ingresos
- Acción: Alertas y autorizaciones requeridas

### 7.4 Tickets con Modificaciones
- Consulta: `SELECT * FROM public.ticket WHERE modified = true`
- Riesgo: Cambios de ítems después de registro de consumo
- Acción: Proceso de reprocesamiento automático

### 7.5 Tickets Duplicados
- Consulta: `SELECT * FROM public.ticket GROUP BY folio HAVING COUNT(*) > 1`
- Riesgo: Doble conteo de consumo
- Acción: Validación única de folios

## 8. Procesos de Re-procesamiento

### 8.1 Log de Reprocesamiento
- `selemti.pos_reprocess_log` - Registra intentos de reprocesamiento
- `selemti.pos_reverse_log` - Registra reversos ejecutados

### 8.2 Funciones de Reprocesamiento
- `reprocesar_costos_historicos` - Recalcula costos históricos
- `fn_reparar_sesion_apertura` - Repara inconsistencias de sesión

## 9. Alertas y Monitoreo

### 9.1 Campos para Alertas
- `selemti.pos_reprocess_log.status` - Estado de reprocesamiento
- `selemti.pos_reverse_log.reason` - Motivo de reverso
- `selemti.inv_consumo_pos_log.error_code` - Código de error

### 9.2 Consultas de Monitoreo
- Tickets sin confirmar consumo: `SELECT * FROM public.ticket t WHERE NOT EXISTS (SELECT 1 FROM selemti.inv_consumo_pos icp WHERE icp.ticket_id = t.id)`
- Tickets con inconsistencias: `SELECT * FROM selemti.inv_consumo_pos_log WHERE status = 'ERROR'`

## 10. Consideraciones de Performance

- El trigger `trg_ticket_inventory_consumption` puede ralentizar operaciones POS
- Las vistas en `vw_*` deben optimizarse para consultas frecuentes
- El proceso de expansión debe ser asincrónico para no bloquear POS