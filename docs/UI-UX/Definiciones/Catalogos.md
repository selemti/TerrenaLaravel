# Definición del Módulo: Catálogos

## Descripción General
El módulo de Catálogos gestiona todas las entidades maestras del sistema, incluyendo sucursales, almacenes, unidades de medida, proveedores y políticas de negocio. Es fundamental para la configuración y funcionamiento de todos los demás módulos. El sistema implementa una estructura jerárquica: Categoría → Subcategoría → Artículo con prefijos específicos.

## Componentes del Módulo

### 1. Sucursales
**Descripción:** Gestión de locales o unidades de negocio.

**Características actuales:**
- CRUD funcional
- Configuración básica
- Soporte para múltiples sucursales

**Requerimientos de UI/UX:**
- Información detallada de sucursal
- Configuración de parámetros por sucursal
- Horarios de operación
- Coordenadas geográficas (opcional)
- Configuración específica por sucursal (moneda, impuestos, etc.)

### 2. Almacenes
**Descripción:** Gestión de ubicaciones de almacenamiento.

**Características actuales:**
- CRUD funcional
- Configuración básica
- Múltiples almacenes por sucursal
- Campo es_principal en tabla de almacenes

**Requerimientos de UI/UX:**
- Jerarquía de almacenes
- Configuración de parámetros logísticos
- Relación con sucursales
- Capacidades y restricciones de almacenamiento
- Selección de almacén principal por sucursal
- Configuración de almacén por terminal

### 3. Unidades de Medida y Conversiones
**Descripción:** Gestión de unidades de medida y factores de conversión.

**Características actuales:**
- Unidades y conversiones funcional
- Muy bien implementado el tip de caja de 12
- Prefijos de categorías y conversiones básicas de unidades de medida
- API: POST /api/inventory/prices para registrar precios históricos

**Requerimientos de UI/UX:**
- Asistente de conversiones (crear par directo e inverso)
- Validación de circularidad en conversiones
- Vista de árbol de conversiones
- Preview de conversiones
- Formulario de carga de precios con validación contra catálogo de UOM
- Prefijos de categorías (MP-: materia prima, SR-: subreceta, PT-: producto terminado)

### 4. Proveedores
**Descripción:** Gestión de información de proveedores.

**Características actuales:**
- CRUD básico funcional
- Relación con items y precios
- Marca de proveedor preferente (item_vendor.preferente)

**Requerimientos de UI/UX:**
- Información de contacto completa
- Productos suministrados
- Condiciones comerciales
- Calificación y evaluación
- Historial de compras
- Marca de proveedor preferente
- Cotizaciones múltiples por proveedor
- Histórico de precios con comprobantes
- Sincronización de catálogos maestros

### 5. Políticas de Stock
**Descripción:** Configuración de reglas para reposición automática.

**Características actuales:**
- Estructura base en tabla stock_policy
- Campos: min_qty, max_qty, reorder_lote, activo
- Utilizado por el motor de replenishment

**Requerimientos de UI/UX:**
- Configuración de stock mínimo, máximo, stock de seguridad
- Lead time por ítem/sucursal
- Método de reposición (min-max, SMA, por consumo POS)
- Parámetros específicos según método seleccionado
- Bulk import/export de políticas
- Gestión a través del componente StockPolicies.php
- Políticas por ítem/sucursal/almacén

### 6. Categorías y Subcategorías
**Descripción:** Estructura jerárquica para clasificación de productos.

**Características actuales:**
- Estructura jerárquica: Categoría → Subcategoría → Artículo
- Prefijos: MP- (materia prima), SR- (subreceta), PT- (producto terminado)

**Requerimientos de UI/UX:**
- Gestión jerárquica de categorías
- Asignación de artículos a categorías/subcategorías
- Prefijos y códigos estandarizados
- Alergénicos y categorías contables
- Asociación con impuestos y reglas de negocio

## Requerimientos Técnicos
- Validadores para datos de catálogos
- Colas de importación para bulk operations
- Logs de auditoría de cambios
- Sistema de cache para entidades maestras
- Endpoints RESTful para todas las entidades
- Relaciones referenciadas en otros módulos
- Prefijos de categorías (MP-, SR-, PT-)
- Función fn_item_unit_cost_at para cálculo de costos
- Vistas: vw_item_last_price, vw_item_last_price_pref
- Tabla: item_vendor con campo preferente
- Tabla: item_vendor_prices con control de vigencia

## Integración con Otros Módulos
- Inventario: Relación con items, recepciones, conteos
- Compras: Relación con órdenes y políticas de stock
- Producción: Relación con batches y asignación
- Reportes: Filtros y configuración por entidad
- POS: Integración con catálogos de menú
- Recetas: Implosión de recetas basada en categorías

## KPIs Asociados
- Completitud de catálogos
- Consistencia de datos
- Actualización de proveedores
- Cumplimiento de políticas de stock
- Eficiencia en búsquedas de referencias
- Tiempos de respuesta por volumen de datos
- Número de categorías/subcategorías definidas
- Nivel de estandarización en códigos de productos
- Actualización de precios de proveedores
- Precisión de datos de catálogo