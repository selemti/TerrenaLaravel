# Definición del Módulo: POS

## Descripción General
El módulo de POS (Point of Sale) gestiona la integración con el sistema de ventas Floreant POS, incluyendo el mapeo de menú, diagnóstico de tickets, reprocesamiento de ventas y control de disponibilidad en vivo. El sistema implementa integración bidireccional con Floreant POS y control automático de agotados/re-ruteo.

## Componentes del Módulo

### 1. Mapeo de Menú POS
**Descripción:** Funcionalidad para mapear ítems del menú de Floreant POS con recetas del sistema.

**Características actuales:**
- Vista `pos_map` con relación entre items POS y recetas
- CRUD funcional para mapeos
- Validación de unicidad (item_id, pos_menu_id, pos_modifier_id)
- Soporte para items y modificadores de POS
- Integración con triggers para validación automática

**Requerimientos de UI/UX:**
- Listado con filtros `tipo`, `plu`, vigencia
- CRUD de filas `MENU/MODIFIER`
- Acción rápida: "Auditar hoy" → ejecuta validación de mapeos faltantes
- Visualización de estado de mapeos (vigente, expirado, pendiente)
- Indicadores visuales de mapeos faltantes
- Asistente para crear mapeos masivos
- Preview de items sin mapeo
- Filtros por sucursal y fecha de vigencia

### 2. Diagnóstico y Reprocesamiento
**Descripción:** Sistema para diagnosticar tickets problemáticos y reprocesar ventas POS.

**Características actuales:**
- Endpoints: `/api/pos/tickets/{ticketId}/diagnostics`, `/api/pos/tickets/{ticketId}/reprocess`, `/api/pos/tickets/{ticketId}/reverse`
- Dashboard de tickets sin mapeo: `/api/pos/dashboard/missing-recipes`
- Costo de recetas: `/api/recipes/{recipeId}/cost`, `/api/recipes/{recipeId}/recalculate`
- Implementación completa del servicio PosConsumptionService
- Integración con triggers para expansión automática de recetas
- Tablas: `inv_consumo_pos`, `inv_consumo_pos_det`

**Requerimientos de UI/UX:**
- Dashboard de tickets problemáticos con filtros por hora/fecha
- Diagnóstico detallado por ticket (items sin receta, faltantes de empaque)
- Reprocesamiento 1-click con confirmación y justificación
- Reversa de tickets con auditoría completa
- Vista de tickets sin mapeo de recetas
- Indicadores visuales de problemas críticos
- Filtros avanzados por tipo de problema
- Exportación de tickets problemáticos
- Notificaciones automáticas de tickets sin mapeo

### 3. Disponibilidad en Vivo
**Descripción:** Control automático de disponibilidad de productos en POS con ruteo dinámico.

**Características actuales:**
- Documentación en `docs/POS/LIVE_AVAILABILITY.md`
- Integración con Produmix y ProductionService
- Control de agotados y re-ruteo a cocina
- Tabla `selemti.menu_availability_log` para auditoría
- Permisos: `can_manage_menu_availability`

**Requerimientos de UI/UX:**
- Dashboard Live Availability con estado de SKUs
- Indicadores por categoría (proteínas, salsas, postres)
- Botones de acción (agotado / reactivar / forzar cocina)
- Histórico de intervenciones con motivo y usuario
- Filtros por estado y categoría
- Alertas automáticas de productos en riesgo
- Vista de SKUs con estados `OK`, `RIESGO`, `AGOTADO`
- Integración con Produmix para identificar brechas de producción

## Requerimientos Técnicos
- Integración con Floreant POS vía triggers
- Tablas: `pos_map`, `inv_consumo_pos`, `inv_consumo_pos_det`, `menu_availability_log`
- Funciones PostgreSQL: `fn_expandir_consumo_ticket`, `fn_confirmar_consumo_ticket`, `fn_reversar_consumo_ticket`
- Servicios: `PosConsumptionService` con métodos para diagnosis, reprocesamiento y reversa
- Endpoints RESTful para todas las operaciones
- Sistema de auditoría para cambios en disponibilidad
- Jobs para procesamiento asíncrono de diagnósticos
- Colas para reprocesamiento masivo
- Tablas: `pos_reverse_log`, `pos_reprocess_log`
- Trigger para expansión automática cuando ticket.paid=true AND ticket.voided=false
- Trigger para reverso cuando ticket.voided=true

## Integración con Otros Módulos
- Recetas: Implosión de recetas para consumo POS, cálculo de costos
- Inventario: Descuento automático de inventario al vender, control de disponibilidad
- Producción: Validación de producción planificada vs demanda real
- Reportes: KPIs de ventas, costos teóricos vs reales
- Compras: Alertas de faltantes basadas en consumo POS
- Catálogos: Mapeo de items POS con recetas del sistema

## KPIs Asociados
- Tickets sin mapeo de recetas
- Tiempo promedio de diagnóstico de problemas
- Tasa de reprocesamiento exitoso
- Número de reversas realizadas
- Productos marcados como agotados
- Productos forzados a cocina
- Discrepancias teórico vs real
- Tiempo de respuesta en diagnóstico
- Número de tickets problemáticos
- Tasa de resolución de tickets sin mapeo

## Flujos de Trabajo

### Flujo de Mapeo POS
1. **Identificación**: Sistema detecta items/modificadores sin mapeo
2. **Asignación**: Usuario asigna receta a item/modificador POS
3. **Validación**: Sistema valida unicidad y vigencia
4. **Activación**: Mapeo se activa y queda disponible para consumo
5. **Auditoría**: Registro completo en `pos_map_log`

### Flujo de Diagnóstico
1. **Detección**: Sistema identifica tickets problemáticos
2. **Clasificación**: Tickets se clasifican por tipo de problema
3. **Notificación**: Alertas se generan para usuarios autorizados
4. **Diagnóstico**: Usuario revisa detalles del problema
5. **Acción**: Usuario decide reprocesar, reversar o ignorar
6. **Registro**: Acción se registra en logs correspondientes

### Flujo de Disponibilidad
1. **Monitoreo**: Sistema monitorea producción vs demanda
2. **Alerta**: Se generan alertas cuando hay riesgo de agotados
3. **Intervención**: Usuario con permiso decide acción
4. **Ejecución**: Sistema marca productos como agotados o re-rutea
5. **Auditoría**: Registro completo en `menu_availability_log`

## Estados de Items POS

### Estados de Disponibilidad
```
DISPONIBLE → AGOTADO
DISPONIBLE → FORZAR_COCINA
AGOTADO → DISPONIBLE
FORZAR_COCINA → DISPONIBLE
```

### Estados de Mapeo
```
ACTIVO → EXPIRADO
PENDIENTE → ACTIVO
ACTIVO → INACTIVO
```

## Componentes Técnicos

### Servicios
- **PosConsumptionService**: Servicio principal para operaciones POS
  - `expandTicket()`: Expande receta de ticket
  - `confirmTicket()`: Confirma consumo de ticket
  - `reverseTicket()`: Reversa consumo de ticket
  - `normalizeLine()`: Normaliza línea de consumo

### Controladores
- **PosConsumptionController**: Controlador para operaciones de consumo POS
  - `GET /api/pos/tickets/{ticketId}/diagnostics`
  - `POST /api/pos/tickets/{ticketId}/reprocess`
  - `POST /api/pos/tickets/{ticketId}/reverse`

### Modelos
- **PosMap**: Modelo para mapeo de items POS
- **InvConsumoPos**: Modelo para consumo POS (cabecera)
- **InvConsumoPosDet**: Modelo para consumo POS (detalle)
- **MenuAvailabilityLog**: Modelo para auditoría de disponibilidad

### Tablas
- `selemti.pos_map`: Mapeo de items POS con recetas
- `selemti.inv_consumo_pos`: Consumo POS (cabecera)
- `selemti.inv_consumo_pos_det`: Consumo POS (detalle)
- `selemti.menu_availability_log`: Auditoría de disponibilidad
- `selemti.pos_reverse_log`: Log de reversas
- `selemti.pos_reprocess_log`: Log de reprocesamientos

### Funciones PostgreSQL
- `selemti.fn_expandir_consumo_ticket(bigint)`: Expande receta de ticket
- `selemti.fn_confirmar_consumo_ticket(bigint)`: Confirma consumo de ticket
- `selemti.fn_reversar_consumo_ticket(bigint)`: Reversa consumo de ticket

### Triggers
- Trigger en `public.ticket` para expansión automática cuando ticket.paid=true AND ticket.voided=false
- Trigger en `public.ticket` para reverso cuando ticket.voided=true

## Permisos y Roles

### Permisos Disponibles
- `can_view_recipe_dashboard`: Ver dashboard de recetas
- `can_reprocess_sales`: Reprocesar ventas POS
- `can_manage_menu_availability`: Gestionar disponibilidad de menú
- `pos.mapping.view`: Ver mapeos POS
- `pos.mapping.manage`: Gestionar mapeos POS
- `pos.diagnostic.view`: Ver diagnósticos POS
- `pos.diagnostic.manage`: Gestionar diagnósticos POS

### Roles Sugeridos
- **Cajero**: `pos.mapping.view`, `pos.diagnostic.view`
- **Chef**: `can_view_recipe_dashboard`, `can_reprocess_sales`
- **Gerente**: `can_manage_menu_availability`, `can_reprocess_sales`
- **Director de Operaciones**: Todos los permisos POS

## Consideraciones Especiales

### Integración con Floreant POS
- Conexión vía triggers en base de datos
- Tablas en esquema `public` (lectura)
- Tablas en esquema `selemti` (escritura)
- Sincronización automática de tickets pagados
- Validación de integridad referencial

### Control de Disponibilidad
- Sistema automático de agotados basado en producción vs demanda
- Re-ruteo dinámico a cocina cuando hay stock limitado
- Auditoría completa de todas las intervenciones
- Validación de permisos para cada acción

### Auditoría y Trazabilidad
- Registro automático de todas las acciones
- Quién hizo qué y cuándo
- Motivo de cada intervención
- Evidencia digital adjunta (cuando aplica)

### Performance
- Uso de vistas materializadas para consultas pesadas
- Índices optimizados en tablas críticas
- Jobs asíncronos para procesamiento de grandes volúmenes
- Caching de información frecuente

## Próximos Pasos

### Implementaciones Pendientes
1. Completar UI de dashboard de mapeo POS
2. Implementar asistente de mapeo masivo
3. Agregar sistema de notificaciones automáticas
4. Completar UI de diagnóstico y reprocesamiento
5. Implementar filtros avanzados en dashboard POS
6. Agregar exportación de reportes POS
7. Completar sistema de auditoría de disponibilidad
8. Implementar vista de SKUs con estado RIESGO

### Mejoras Sugeridas
1. Integración con dispositivos móviles para diagnóstico
2. Machine learning para predicción de tickets problemáticos
3. Sistema de calificación de problemas por severidad
4. Notificaciones push para alertas críticas
5. Dashboard móvil responsive para cocina
6. Integración con sistemas de monitoreo externos
7. Predicción de agotados basada en tendencias
8. Exportación de logs a sistemas externos de BI