# Definición del Módulo: Catálogos

## Descripción General
El módulo de Catálogos gestiona todas las entidades maestras del sistema, incluyendo sucursales, almacenes, unidades de medida, proveedores y políticas de negocio. Es fundamental para la configuración y funcionamiento de todos los demás módulos. El sistema implementa una estructura jerárquica con prefijos específicos para cada tipo de entidad.

## Componentes del Módulo

### 1. Sucursales
**Descripción:** Gestión de locales o unidades de negocio.

**Características actuales:**
- CRUD funcional
- Configuración básica
- Prefijos para identificación única

**Requerimientos de UI/UX:**
- Información detallada de sucursal (dirección, contacto, horarios)
- Configuración de parámetros por sucursal (moneda, impuestos)
- Horarios de operación con configuración flexible
- Coordenadas geográficas (opcional)
- Relación con almacenes principales
- Vista de mapa con ubicación de sucursales
- Prefijos y configuración específica por sucursal

### 2. Almacenes
**Descripción:** Gestión de ubicaciones de almacenamiento.

**Características actuales:**
- CRUD funcional
- Configuración básica
- Campo es_principal en tabla de almacenes

**Requerimientos de UI/UX:**
- Jerarquía de almacenes con relación a sucursales
- Configuración de parámetros logísticos (capacidad, tipo)
- Relación con sucursales
- Capacidades y restricciones de almacenamiento
- Selección de almacén principal por sucursal
- Configuración de almacén por terminal
- Vista de mapa de almacenes por sucursal

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
- Bulk import/export de conversiones
- Validación de unidades base

### 4. Proveedores
**Descripción:** Gestión de información de proveedores.

**Características actuales:**
- CRUD básico funcional
- Marca de proveedor preferente (item_vendor.preferente)
- Relación con items

**Características pendientes:**
- Cotizaciones múltiples por proveedor
- Histórico de precios con comprobantes
- Evaluación y calificación de proveedores

**Requerimientos de UI/UX:**
- Información de contacto completa (teléfonos, correos, direcciones)
- Productos suministrados con precios y condiciones
- Condiciones comerciales (días de crédito, descuentos)
- Calificación y evaluación (rating, comentarios)
- Historial de compras y pagos
- Marca de proveedor preferente
- Cotizaciones múltiples por proveedor
- Histórico de precios con comprobantes
- Sistema de evaluación y calificación
- Bulk import/export de proveedores

### 5. Políticas de Stock
**Descripción:** Configuración de reglas para reposición automática.

**Características actuales:**
- UI prevista pero no implementada
- Tabla: selemti.stock_policy
- Campos: min_qty, max_qty, reorder_lote, activo

**Requerimientos de UI/UX:**
- Configuración de stock mínimo, máximo, stock de seguridad
- Lead time por ítem/sucursal
- Método de reposición (min-max, SMA, por consumo POS)
- Parámetros específicos según método seleccionado
- Bulk import/export de políticas
- Gestión a través del componente StockPolicies.php
- Políticas por ítem/sucursal/almacén
- Vista de alertas de políticas incumplidas

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
- Recetas: Implosión de recetas basada en categorías
- POS: Integración con catálogos de menú
- Caja Chica: Relación con proveedores y gastos

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

## Estructura Jerárquica

### Categorías y Subcategorías
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
- Vista de árbol de categorías
- Búsqueda jerárquica de productos

### Relaciones entre Entidades
```
Sucursal
  │
  └─→ Almacenes (1:N)
        │
        └─→ Items (N:M) → Políticas de Stock
              │
              └─→ Proveedores (N:M) → Precios
                    │
                    └─→ Unidades de Medida (1:N)
```

## Componentes Técnicos

### Modelos
- **Sucursal**: Modelo para gestión de sucursales
- **Almacen**: Modelo para gestión de almacenes
- **Unidad**: Modelo para unidades de medida
- **Proveedor**: Modelo para proveedores
- **StockPolicy**: Modelo para políticas de stock
- **ItemCategory**: Modelo para categorías de items
- **ItemSubcategory**: Modelo para subcategorías de items

### Controladores
- **CatalogsController**: Controlador para gestión general de catálogos
- **SucursalController**: Controlador específico para sucursales
- **AlmacenController**: Controlador específico para almacenes
- **UnidadController**: Controlador específico para unidades de medida
- **ProveedorController**: Controlador específico para proveedores
- **StockPolicyController**: Controlador específico para políticas de stock

### Servicios
- **CatalogService**: Servicio general para operaciones de catálogos
- **SucursalService**: Servicio específico para lógica de sucursales
- **AlmacenService**: Servicio específico para lógica de almacenes
- **UnidadService**: Servicio específico para lógica de unidades
- **ProveedorService**: Servicio específico para lógica de proveedores
- **StockPolicyService**: Servicio específico para lógica de políticas

### Componentes Livewire
- **Catalogs\UnidadesIndex**: Listado de unidades de medida
- **Catalogs\UomConversionIndex**: Gestión de conversiones
- **Catalogs\AlmacenesIndex**: Listado de almacenes
- **Catalogs\ProveedoresIndex**: Listado de proveedores
- **Catalogs\SucursalesIndex**: Listado de sucursales
- **Catalogs\StockPolicyIndex**: Gestión de políticas de stock

## API Endpoints

### Unidades de Medida
- `GET /api/catalogs/unidades` - Listado de unidades
- `POST /api/catalogs/unidades` - Crear unidad
- `PUT /api/catalogs/unidades/{id}` - Actualizar unidad
- `DELETE /api/catalogs/unidades/{id}` - Eliminar unidad

### Conversiones
- `GET /api/catalogs/unidades/conversiones` - Listado de conversiones
- `POST /api/catalogs/unidades/conversiones` - Crear conversión
- `PUT /api/catalogs/unidades/conversiones/{id}` - Actualizar conversión
- `DELETE /api/catalogs/unidades/conversiones/{id}` - Eliminar conversión

### Sucursales
- `GET /api/catalogs/sucursales` - Listado de sucursales
- `POST /api/catalogs/sucursales` - Crear sucursal
- `PUT /api/catalogs/sucursales/{id}` - Actualizar sucursal
- `DELETE /api/catalogs/sucursales/{id}` - Eliminar sucursal

### Almacenes
- `GET /api/catalogs/almacenes` - Listado de almacenes
- `POST /api/catalogs/almacenes` - Crear almacén
- `PUT /api/catalogs/almacenes/{id}` - Actualizar almacén
- `DELETE /api/catalogs/almacenes/{id}` - Eliminar almacén

### Proveedores
- `GET /api/catalogs/proveedores` - Listado de proveedores
- `POST /api/catalogs/proveedores` - Crear proveedor
- `PUT /api/catalogs/proveedores/{id}` - Actualizar proveedor
- `DELETE /api/catalogs/proveedores/{id}` - Eliminar proveedor

### Políticas de Stock
- `GET /api/catalogs/stock-policies` - Listado de políticas
- `POST /api/catalogs/stock-policies` - Crear política
- `PUT /api/catalogs/stock-policies/{id}` - Actualizar política
- `DELETE /api/catalogs/stock-policies/{id}` - Eliminar política

## Permisos y Roles

### Permisos Específicos
- `catalogs.view` - Ver catálogos
- `catalogs.manage` - Gestionar catálogos
- `catalogs.units.view` - Ver unidades de medida
- `catalogs.units.manage` - Gestionar unidades de medida
- `catalogs.suppliers.view` - Ver proveedores
- `catalogs.suppliers.manage` - Gestionar proveedores
- `catalogs.locations.view` - Ver sucursales y almacenes
- `catalogs.locations.manage` - Gestionar sucursales y almacenes
- `catalogs.policies.view` - Ver políticas de stock
- `catalogs.policies.manage` - Gestionar políticas de stock

### Roles Sugeridos
- **Catalog Manager**: `catalogs.*`
- **Inventory Manager**: `catalogs.units.*`, `catalogs.policies.*`
- **Purchasing Manager**: `catalogs.suppliers.*`, `catalogs.policies.*`
- **Ops Manager**: `catalogs.*`
- **Viewer**: `catalogs.view`

## Consideraciones Especiales

### Estandarización de Códigos
- Prefijos consistentes: MP-, SR-, PT-
- Códigos únicos por tipo de entidad
- Validación automática de formato de códigos
- Generación automática de códigos cuando sea necesario

### Integración con Módulos Externos
- POS: Sincronización de catálogos de menú
- Compras: Proveedores y políticas de compra
- Inventario: Items y unidades de medida
- Producción: Recetas y materias primas
- Reportes: Filtros y dimensiones

### Auditoría y Seguimiento
- Registro completo de cambios en catálogos
- Trazabilidad de modificaciones (quién, cuándo, qué)
- Versionado de registros críticos
- Alertas de cambios que afectan otros módulos

### Performance y Escalabilidad
- Caching de catálogos frecuentes
- Índices optimizados en tablas de catálogos
- Paginación en listados extensos
- Búsqueda optimizada con filtros

## Próximos Pasos

### Implementaciones Pendientes
1. UI completa de gestión de políticas de stock
2. Asistente de conversiones de unidad
3. Validación de circularidad en conversiones
4. Bulk import/export de políticas de stock
5. Sistema de evaluación de proveedores
6. Histórico de precios con comprobantes
7. Vista jerárquica de categorías
8. Sincronización avanzada con proveedores

### Mejoras Sugeridas
1. Sistema de alertas para datos inconsistentes
2. Validación cruzada entre catálogos
3. Importación desde formatos estándar (CSV, Excel)
4. Exportación a formatos estándar
5. Búsqueda global en todos los catálogos
6. Sistema de sugerencias de datos basado en uso
7. Integración con sistemas externos de catálogos
8. Versionado de catálogos con rollback