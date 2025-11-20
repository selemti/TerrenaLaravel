# MAPA DE BASE DE DATOS POR MÓDULOS

## 1. Módulo: Inventario

### Tablas Núcleo
- `items` - Catálogo de ítems/insumos
- `inventory_batch` - Lotes de inventario
- `mov_inv` - Movimientos de inventario
- `inventory_counts` - Conteos físicos
- `inventory_count_lines` - Detalles de conteos

### Tablas Auxiliares
- `item_categories` - Categorías de ítems
- `cat_unidades` - Unidades de medida
- `conversiones_unidad` - Conversiones entre unidades
- `item_vendor` - Proveedores por ítem
- `item_vendor_prices` - Precios de proveedores
- `stock_policy` - Políticas de stock
- `historial_costos_item` - Histórico de costos por ítem

### Tablas de Recepciones
- `recepcion_cab` - Cabecera de recepciones
- `recepcion_det` - Detalle de recepciones
- `recepcion_adjuntos` - Adjuntos de recepciones

### Tablas de Transferencias
- `traspaso_cab` - Cabecera de transferencias
- `traspaso_det` - Detalle de transferencias

### Tablas de Mermas/Ajustes
- `inventory_wastes` - Mermas de inventario
- `perdida_log` - Registro de pérdidas

### Tablas FALTA DOC
- `v_items_con_uom` - Vista con ítems y unidades de medida
- `v_stock_actual` - Vista de stock actual
- `v_stock_brechas` - Vista de brechas de stock

## 2. Módulo: Recetas

### Tablas Núcleo
- `receta_cab` - Cabecera de recetas
- `receta_version` - Versiones de recetas
- `receta_det` - Detalle de recetas (ingredientes)

### Tablas de Costeo
- `recipe_cost_history` - Histórico de costos
- `recipe_cost_snapshots` - Snapshots de costos
- `recipe_extended_cost_history` - Costos extendidos
- `recipe_labor_steps` - Pasos de mano de obra
- `recipe_overhead_allocations` - Gastos indirectos

### Tablas de Sombra
- `receta_shadow` - Recetas inferidas del POS

### Tablas FALTA DOC
- `v_ingenieria_menu_completa` - Vista con recetas y costos
- `fn_recipe_cost_at` - Función de cálculo de costo

## 3. Módulo: Producción

### Tablas Núcleo
- `production_orders` - Órdenes de producción
- `production_order_inputs` - Insumos de producción
- `production_order_outputs` - Productos terminados

### Tablas de Operación
- `op_produccion_cab` - Cabecera de operaciones
- `op_insumo` - Insumos de operación
- `op_yield` - Rendimientos

### Tablas FALTA DOC
- `prod_cab` - Cabecera de producción (legacy)
- `prod_det` - Detalle de producción (legacy)

## 4. Módulo: Purchasing/Compras

### Tablas Núcleo
- `purchase_orders` - Órdenes de compra
- `purchase_order_lines` - Líneas de órdenes
- `purchase_requests` - Solicitudes de compra
- `purchase_request_lines` - Líneas de solicitudes

### Tablas de Sugerencias
- `replenishment_suggestions` - Sugerencias de reposición
- `purchase_suggestions` - Sugerencias de compra
- `purchase_suggestion_lines` - Líneas de sugerencias

### Tablas de Cotizaciones
- `purchase_vendor_quotes` - Cotizaciones de proveedores
- `purchase_vendor_quote_lines` - Líneas de cotizaciones

### Tablas FALTA DOC
- `vendor_quotes` - Cotizaciones (posible duplicado)
- `vendor_quote_lines` - Líneas de cotizaciones (posible duplicado)

## 5. Módulo: POS

### Tablas de Integración
- `pos_map` - Mapeo POS ↔ Terrena
- `pos_modifiers_map` - Mapeo de modificadores
- `menu_items` - Ítems del menú POS

### Tablas de Consumo
- `inv_consumo_pos` - Consumo POS
- `inv_consumo_pos_det` - Detalle de consumo POS
- `inv_consumo_pos_log` - Log de consumo POS

### Tablas de Reprocesamiento
- `pos_reprocess_log` - Log de reprocesamiento
- `pos_reverse_log` - Log de reversos POS

### Tablas FALTA DOC
- `ticket_venta_cab` - Cabecera de tickets POS
- `ticket_venta_det` - Detalle de tickets POS
- `ticket_det_consumo` - Consumo por detalle de ticket

## 6. Módulo: Caja Chica

### Tablas Núcleo
- `cash_funds` - Fondos de caja
- `cash_fund_movements` - Movimientos de caja
- `cash_fund_arqueos` - Arqueos de caja

### Tablas de Auditoría
- `cash_fund_movement_audit_log` - Log de auditoría de movimientos

### Tablas FALTA DOC
- `caja_fondo` - Fondo de caja (posible duplicado)
- `caja_fondo_mov` - Movimientos de caja (posible duplicado)
- `caja_fondo_arqueo` - Arqueos de caja (posible duplicado)

## 7. Módulo: Finanzas/Cortes

### Tablas Núcleo
- `sesion_cajon` - Sesiones de caja
- `precorte` - Precortes
- `postcorte` - Postcortes

### Tablas de Detalle
- `precorte_efectivo` - Detalle de efectivo en precorte
- `precorte_otros` - Otros medios en precorte
- `conciliacion` - Conciliación de caja

### Tablas FALTA DOC
- `vw_sesion_dpr` - Vista de detalles de sesión
- `vw_conciliacion_sesion` - Vista de conciliación por sesión

## 8. Módulo: Seguridad

### Tablas Núcleo
- `users` - Usuarios del sistema
- `permissions` - Permisos
- `roles` - Roles
- `model_has_permissions` - Relación modelo-permisos
- `model_has_roles` - Relación modelo-roles
- `role_has_permissions` - Relación rol-permisos

### Tablas FALTA DOC
- `personal_access_tokens` - Tokens de acceso personal

## 9. Módulo: Catálogos

### Tablas Núcleo
- `cat_sucursales` - Sucursales
- `cat_almacenes` - Almacenes
- `cat_proveedores` - Proveedores

### Tablas FALTA DOC
- `almacen` - Almacén (posible duplicado)
- `sucursal` - Sucursal (posible duplicado)
- `proveedor` - Proveedor (posible duplicado)

## 10. Tablas Huérfanas (sin asignación clara a módulo)

- `alert_events` - Eventos de alerta
- `alert_rules` - Reglas de alerta
- `audit_log` - Log de auditoría
- `audit_log_global` - Log global de auditoría
- `sessions` - Sesiones de usuario
- `jobs` - Trabajos
- `failed_jobs` - Trabajos fallidos
- `job_batches` - Lotes de trabajos
- `cache` - Caché
- `cache_locks` - Bloqueos de caché
- `password_reset_tokens` - Tokens de reset de contraseña

## 11. Tablas Duplicadas Detectadas

- `items` vs `v_insumo` - Posible duplicado con vistas
- `cat_sucursales` vs `v_sucursal` - Posible duplicado con vistas
- `cat_unidades` vs `v_unidad_medida_singular_compat` - Posible duplicado con vistas
- `cat_almacenes` vs `v_almacen` - Posible duplicado con vistas

## 12. Matriz de Consistencia BD → Código → Documentación

| Tabla | Documentada | Código | Estado |
|-------|-------------|--------|---------|
| items | ✓ | ✓ | Consistente |
| mov_inv | ✓ | ✓ | Consistente |
| receta_cab | ✓ | ✓ | Consistente |
| production_orders | ✓ | ✓ | Consistente |
| cash_funds | ✓ | ✓ | Consistente |
| v_stock_actual | Parcial | ✓ | Documentación incompleta |
| pos_map | ✓ | ✓ | Consistente |
| recipe_cost_history | Parcial | ✓ | Documentación incompleta |
| vw_dashboard_* | Parcial | ✓ | Documentación incompleta |
| report_* | Parcial | ✓ | Documentación incompleta |