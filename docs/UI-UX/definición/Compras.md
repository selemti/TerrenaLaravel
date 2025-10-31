# Definición del Módulo: Compras

## Descripción General
El módulo de Compras gestiona todo el proceso de adquisición de bienes y servicios, desde la generación de solicitudes hasta la recepción de productos. Incluye funcionalidades para la gestión de órdenes de compra, proveedores, políticas de stock y el motor de sugerencias de pedidos. El sistema implementa flujos completos de aprobación y conciliación.

## Componentes del Módulo

### 1. Solicitudes y Órdenes
**Descripción:** Funcionalidad para crear y aprobar solicitudes de compra y convertirlas en órdenes de compra.

**Características actuales:**
- Estructura completa para solicitudes y órdenes
- Workflow de aprobación (5 paso workflow para recepciones)
- Integración con proveedores
- Relación con inventario
- API endpoints: `/api/purchasing/receptions/create-from-po/{purchase_order_id}`, `/api/purchasing/receptions/{id}/lines`, `/api/purchasing/receptions/{id}/validate`, `/api/purchasing/receptions/{id}/post`, `/api/purchasing/receptions/{id}/costing`

**Requerimientos de UI/UX:**
- Conversión 1-click a Solicitud → Cotización → Orden con tracking
- Simulación de costo antes de ordenar
- Filtros avanzados para búsquedas
- Seguimiento de órdenes (estado, fechas, proveedores)
- Recepciones con 5 pasos: Crear desde PO → Setear líneas → Validar → Contabilizar → Finalizar costeo

### 2. Reposición / Replenishment
**Descripción:** Motor de sugerencias de compra basado en políticas y consumo real.

**Características actuales:**
- Estructura completa
- "Pedidos sugeridos" con filtros
- "Generar Sugerencias" implementado
- ReplenishmentService con 40% de completitud
- Comando `php artisan replenishment:generate`

**Requerimientos de UI/UX:**
- Políticas de stock por ítem/sucursal (min/max, seguridad, lead time, consumo promedio)
- Motor de sugerencias con métodos: min-max, media móvil, consumo últimos n días, estacionalidad básica
- Vista de sugerencias con razones del cálculo
- Filtros: sucursal, categoría, proveedor
- Conversión 1-click: Sugerencia → Solicitud → Orden
- Simulador de costo y ruptura de stock (lead time)
- Dashboard con estadísticas de sugerencias
- Acciones masivas: aprobar/rechazar múltiples sugerencias
- Priorización automática: URGENTE/ALTA/NORMAL/BAJA
- Bulk actions para múltiples items
- Filtros avanzados y estadísticas

### 3. Proveedores
**Descripción:** Gestión de información de proveedores y precios vigentes.

**Características actuales:**
- Catálogo de proveedores
- Relación con items (proveedor-presentación)
- Histórico de precios

**Requerimientos de UI/UX:**
- Información de contacto completa
- Productos suministrados
- Condiciones comerciales
- Calificación y evaluación
- Historial de compras
- Precios históricos con comprobantes
- Cotizaciones múltiples por proveedor
- Histórico de precios con comprobantes
- Sistema de evaluación y calificación
- Bulk import/export de proveedores

## Requerimientos Técnicos
- Tablas: stock_policies, replenishment_runs, replenishment_lines, vendor_pricelist, vendor_pricelist_snapshots
- Motor de cálculo de sugerencias (ReplenishmentService.php - 40% completo)
- Snapshot de costos
- Jobs para procesamiento asíncrono
- Integración con POS para consumo real
- Endpoints RESTful para todas las operaciones
- Sistema de colas para procesamiento de sugerencias
- Funciones PostgreSQL para FEFO
- Vistas materializadas para reportes
- Tabla: replenishment_suggestions con campos para tipo, prioridad, estado, análisis de stock/consumo
- Comando Artisan: `php artisan replenishment:generate`

## Integración con Otros Módulos
- Inventario: Afecta stock disponible, políticas de stock, FEFO
- Recetas: Relación con costos de ingredientes
- Reportes: Análisis de compras, proveedores, costos
- Catálogos: Proveedores y políticas de stock
- POS: Integración con consumo POS (lectura de ventas)
- Producción: Solicitud de materias primas faltantes para producción

## KPIs Asociados
- Tasa de cumplimiento de pedidos
- Tiempo promedio de entrega
- Costo de adquisición
- Nivel de servicio (satisfacción de demanda)
- Rotación de inventario
- Desviación del presupuesto
- Proveedores por encima de stock máximo
- Stockouts evitados
- Precisión de consumo (comparar estimado vs real)
- Tasa de aprobación de sugerencias
- Tiempo de reposición (días desde sugerencia hasta recepción)

## Flujos de Trabajo

### Flujo de Solicitudes y Órdenes
1. **Solicitud**: Usuario crea solicitud de compra
2. **Aprobación**: Autoridad correspondiente aprueba solicitud
3. **Orden**: Sistema convierte solicitud en orden de compra
4. **Envío**: Proveedor envía mercancía
5. **Recepción**: Almacén recibe mercancía con proceso de 5 pasos
6. **Validación**: Sistema valida cantidades vs PO aplicando tolerancias
7. **Contabilización**: Sistema genera movimientos de inventario
8. **Costeo Final**: Sistema aplica costeo final valuando la recepción

### Flujo de Reposición Automática
1. **Generación**: Sistema ejecuta comando diario `php artisan replenishment:generate`
2. **Cálculo**: Motor calcula sugerencias basadas en políticas y consumo
3. **Priorización**: Sistema asigna prioridad automática (URGENTE/ALTA/NORMAL/BAJA)
4. **Visualización**: Dashboard muestra sugerencias con razones del cálculo
5. **Aprobación**: Usuario autorizado aprueba/rechaza sugerencias
6. **Conversión**: Sistema convierte sugerencias aprobadas en solicitudes/órdenes
7. **Ejecución**: Flujo normal de solicitudes/órdenes

## Estados de Documentos

### Estados de Órdenes de Compra
```
BORRADOR → APROBADA → ENVIADA → RECIBIDA → CERRADA
```

### Estados de Sugerencias de Reposición
```
PLANIFICADA → REVISADA → APROBADA → CONVERTIDA → CERRADA
              ↘ RECHAZADA → CERRADA
```

## Componentes Técnicos

### Servicios
- **ReplenishmentService**: Servicio principal para motor de sugerencias
  - `generateDailySuggestions()`: Genera sugerencias automáticas diarias
  - `convertToPurchaseRequest()`: Convierte sugerencia en solicitud de compra
  - `convertToProductionOrder()`: Convierte sugerencia en orden de producción
  - `createManualSuggestion()`: Crea sugerencia manual

### Controladores
- **ReplenishmentController**: Controlador para operaciones de reposición
  - `POST /api/purchasing/suggestions`
  - `POST /api/purchasing/suggestions/{id}/approve`
  - `POST /api/purchasing/suggestions/{id}/convert`

### Comandos Artisan
- **ReplenishmentGenerateCommand**: Comando para generación diaria de sugerencias
  - `php artisan replenishment:generate`
  - Opciones: `--sucursal`, `--almacen`, `--dias`, `--auto-approve`, `--dry-run`

### Modelos
- **ReplenishmentSuggestion**: Modelo para sugerencias de reposición
- **StockPolicy**: Modelo para políticas de stock
- **VendorQuote**: Modelo para cotizaciones de proveedores
- **VendorQuoteLine**: Modelo para líneas de cotizaciones

### Tablas
- `selemti.replenishment_suggestions`: Almacena sugerencias generadas
- `selemti.stock_policy`: Políticas de stock por item/sucursal
- `selemti.vendor_quote`: Cotizaciones de proveedores
- `selemti.vendor_quote_line`: Líneas de cotizaciones
- `selemti.vw_replenishment_dashboard`: Vista optimizada para dashboard

## Permisos y Roles

### Permisos Disponibles
- `purchasing.view`: Ver compras
- `purchasing.manage`: Gestionar compras
- `purchasing.suggested.view`: Ver pedidos sugeridos
- `purchasing.orders.manage`: Crear/Editar órdenes
- `purchasing.orders.approve`: Aprobar órdenes
- `can_manage_purchasing`: Permiso general de compras
- `inventory.receptions.validate`: Validar recepciones
- `inventory.receptions.override_tolerance`: Override tolerancia
- `inventory.receptions.post`: Postear recepciones

### Roles Sugeridos
- **Comprador**: `purchasing.view`, `purchasing.orders.manage`, `purchasing.suggested.view`
- **Gerente de Compras**: `purchasing.*`, `can_manage_purchasing`
- **Supervisor de Almacén**: `inventory.receptions.*`, `purchasing.suggested.view`
- **Director de Operaciones**: Todos los permisos de compras

## Consideraciones Especiales

### Políticas de Stock
- **Min-Max**: Reabastecer cuando stock < mínimo hasta nivel máximo
- **SMA**: Media móvil de consumo para predecir demanda
- **POS Consumption**: Basado en consumo real de ventas POS
- **Lead Time**: Considerar tiempo de entrega del proveedor
- **Safety Stock**: Stock de seguridad para variaciones

### Tolerancias en Recepciones
- Sistema verifica cantidades recibidas vs ordenadas
- Configuración de tolerancia porcentual (default: 5%)
- Bloqueo de posteo si excede tolerancia sin aprobación
- Requiere aprobación manual para recepciones fuera de tolerancia

### Validaciones Críticas
- Verificación de existencia de ítems en catálogo
- Validación de proveedores autorizados
- Control de fechas de entrega
- Verificación de precios unitarios
- Validación de unidades de medida
- Chequeo de existencias en almacén destino

## Próximos Pasos

### Implementaciones Pendientes
1. Completar UI de políticas de stock
2. Implementar cotizaciones múltiples por proveedor
3. Agregar sistema de evaluación de proveedores
4. Completar dashboard de sugerencias con estadísticas avanzadas
5. Implementar bulk actions en dashboard de sugerencias
6. Agregar filtros avanzados en dashboard de sugerencias
7. Implementar simulador de costos en sugerencias
8. Completar reportes de compras y proveedores

### Mejoras Sugeridas
1. Integración con sistemas externos de proveedores
2. Notificaciones automáticas de órdenes pendientes
3. Sistema de calificación de proveedores
4. Análisis de tendencias de precios
5. Predicción de demanda avanzada
6. Optimización de pedidos agrupando por proveedor
7. Alertas de precios atípicos
8. Integración con contabilidad para facturas