# Definición del Módulo: Inventario

## Descripción General
El módulo de Inventario es uno de los componentes centrales del sistema TerrenaLaravel, encargado de gestionar todos los aspectos relacionados con los productos, materias primas y suministros del negocio. Incluye funcionalidades para dar de alta ítems, recibir mercancía, gestionar lotes y caducidades, realizar conteos físicos y transferencias internas. El sistema implementa FEFO (First Expire First Out) para la gestión de inventario por caducidad.

## Componentes del Módulo

### 1. Items / Altas
**Descripción:** Funcionalidad para la creación y administración de artículos de inventario.

**Características actuales:**
- Filtro claro de búsqueda
- Generación automática de código CAT-SUB-#####
- Validación básica con mensaje genérico ("No se pudo guardar el insumo...")
- Asociación de UOM base
- Catálogo de insumos con proveedor-presentación

**Requerimientos de UI/UX:**
- Validación inline con mensajes específicos (nombre duplicado, UOM requerido, etc.)
- Sugerencias de nombres normalizados
- Vista previa del código CAT-SUB-##### antes de guardar
- Wizard de alta en 2 pasos: (1) Datos maestros, (2) Presentaciones/Proveedor
- Botón "Crear y seguir con presentaciones"
- Búsqueda global con SKU, CAT-SUB, alias, proveedor
- Autosuggest de nombres normalizados y preview de código

### 2. Recepciones
**Descripción:** Funcionalidad para recibir mercancía de proveedores, con trazabilidad completa.

**Características actuales:**
- Modal "Nueva recepción" con Proveedor/Sucursal/Almacén
- Línea con Producto, Qty presentación, UOM compra, Pack size, UOM base, Lote, Caducidad, Temperatura, Evidencia
- Estructura alineada a ERP comercial
- Campos correctos para FEFO y trazabilidad
- Estructura base para snapshots de precios

**Requerimientos de UI/UX:**
- Auto-lookup por código proveedor
- Conversión automática presentación→base con tooltip que muestre el factor aplicado
- Adjuntos múltiples (arrastrar y soltar) y OCR pequeño para leer lote/caducidad (opcional)
- Plantillas de recepción frecuentes por proveedor
- Estados: Pre-validada → Aprobada → Posteada
- Snapshot de costo al postear
- Tolerancias de cantidad con control de discrepancias

**Integración con otros módulos:**
- Requiere tablas de snapshots de precios
- Auditoría (quién cambió qué)
- Colas para procesar adjuntos/OCR

### 3. Lotes / Caducidades / Conteos
**Descripción:** Gestión de lotes, fechas de caducidad y conteos físicos de inventario.

**Características actuales:**
- Rejillas y filtros preparados
- Conteos con tablero y estados
- Lotes con tablero por caducidad
- Sistema de conteos implementado con estados (BORRADOR → EN_PROCESO → AJUSTADO)

**Requerimientos de UI/UX:**
- Vistas de tarjeta con chips de estado (OK, Bajo stock, Por caducar)
- Acciones masivas: "Imprimir etiquetas", "Ajuste", "Programar conteo"
- Mobile-first para conteo rápido (escanear código, +/- cantidad)
- Cálculo automático de variaciones
- Generación automática de ajustes en kardex
- Estadísticas y reportes de exactitud

### 4. Transferencias
**Descripción:** Gestión de movimientos internos entre almacenes/sucursales.

**Características actuales:**
- Listado con estados (Borrador/Despachada)
- Creación con origen/destino
- Líneas con UOM

**Requerimientos de UI/UX:**
- Flujo 3 pasos: Borrador → Despachada (descuenta origen / prepara recibo) → Recibida (abona destino por lote)
- Confirmaciones parciales y discrepancias (corto/exceso)
- Botón "Recibir" en destino
- UI de "reconciliación" simple

### 5. Costos e inventario
**Descripción:** Gestión de costos unitarios históricos y actuales de los ítems.

**Características actuales:**
- Función `selemti.fn_item_unit_cost_at` para consulta de costo unitario "a fecha"
- Vista `selemti.vw_item_last_price` para consulta de precios vigentes
- Vista `selemti.vw_item_last_price_pref` para precios del proveedor preferente
- API: `POST /api/inventory/prices` para registrar precios históricos
- API: `GET /api/recipes/{id}/cost?at=YYYY-MM-DD` para consulta de costos

**Requerimientos de UI/UX:**
- Interfaz de captura de precios desde UI (modal "Cargar precio")
- Validación contra catálogo de UOM y `item_vendor` antes de registrar el precio
- Toast de confirmación tras guardar
- Refresco del listado con vigencia y proveedor preferente
- Vista de alertas de costo pendientes/atendidas

## Requerimientos Técnicos
- Endpoints granulares para validaciones del backend
- Tabla de snapshots de precios en recepción (price_snapshot)
- Auditoría de quién cambió qué (audit_log_global)
- Soporte de colas para procesar adjuntos/OCR
- Endpoints para bulk actions
- Soporte de código de barras
- Vistas responsive
- Tablas recipe_versions, recipe_cost_snapshots, yield_profiles
- Job que recalcula por cambios de costo
- Funciones PostgreSQL: fn_item_unit_cost_at
- Vistas: vw_item_last_price, vw_item_last_price_pref
- Tabla: item_vendor_prices (con control de vigencia vía trigger)

## Integración con Otros Módulos
- Recetas: Uso de ingredientes del inventario, implosión de recetas para consumo POS
- Compras: Recepción de órdenes de compra, políticas de stock
- Producción: Consumo de materias primas, producción de terminados
- Reportes: KPIs de inventario, valorización
- POS: Integración con consumo POS vía triggers que descuentan inventario al vender

## KPIs Asociados
- Stock disponible
- Valor de inventario
- Rotación de inventario
- Desviación de conteo físico vs sistema
- Artículos con fecha de caducidad próxima
- Costo teórico vs real
- Margen de contribución
- Tiempo de reposición
- Precisión de inventario
- Tasa de agotados
- Variación de costos