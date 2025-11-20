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
- API endpoints: `/api/purchasing/receptions/create-from-po/{po_id}`, `/api/purchasing/receptions/{id}/lines`, `/api/purchasing/receptions/{id}/validate`, `/api/purchasing/receptions/{id}/post`, `/api/purchasing/receptions/{id}/costing`

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