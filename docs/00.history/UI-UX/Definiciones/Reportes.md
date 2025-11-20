# Definición del Módulo: Reportes

## Descripción General
El módulo de Reportes proporciona herramientas para la generación, visualización y análisis de información del negocio. Incluye KPIs, dashboards y reportes especializados para la toma de decisiones. El sistema implementa tablas base para análisis (fact_ventas, fact_costos, dim_tiempo) y dashboards específicos por rol.

## Componentes del Módulo

### 1. Dashboard Principal
**Descripción:** Panel de control con KPIs principales del negocio.

**Características actuales:**
- Dashboard principal que muestra KPIs de ventas
- Reportes: ventas, costos, mermas, conciliaciones, stock valorizado
- API endpoints: /api/reports/kpis/sucursal, /api/reports/kpis/terminal, etc.

**Requerimientos de UI/UX:**
- KPIs personalizables por rol de usuario
- Visualizaciones gráficas (gráficas de barras, líneas, etc.)
- Widgets configurables
- Filtros por fecha, sucursal, categoría
- Actualización en tiempo real (opcional)
- Dashboards específicos: Chef, Gerente, Finanzas
- Actualización diaria y comparativos históricos

### 2. Reportes Especializados
**Descripción:** Reportes detallados por área funcional.

**Características actuales:**
- Reportes de ventas, costos, mermas, conciliaciones, stock valorizado
- Motor configurable con filtros, vistas guardadas y exportación PDF/Excel

**Requerimientos de UI/UX:**
- Reportes de ventas: por producto, categoría, periodo, forma de pago
- Reportes de inventario: valorizado, rotación, stock crítico
- Reportes de costos: análisis de rentabilidad, desviaciones
- Reportes de producción: eficiencia, rendimiento, mermas
- Reportes de caja: movimientos, conciliaciones, excepciones
- Reportes de compras: proveedores, análisis de costos, pendientes
- Reportes de POS: ingeniería de menú con indicadores Star, Plowhorse, Puzzle, Dog
- Recomendaciones automáticas (subir/bajar precio, promover, retirar)
- Tablero interactivo exportable a PDF/Excel

### 3. Exportaciones
**Descripción:** Funcionalidad para exportar reportes en diferentes formatos.

**Características actuales:**
- Funcionalidad pendiente

**Requerimientos de UI/UX:**
- Descargas CSV/PDF de reportes
- Programación de envíos por correo
- Opción de favoritos para reportes frecuentes
- Generación en segundo plano para reportes pesados
- Exportes: CSV/XML/API REST
- Vistas guardadas
- Reportes programados
- Exportación a Excel/PDF

### 4. Drill-down
**Descripción:** Navegación jerárquica desde resúmenes a detalles.

**Características actuales:**
- Funcionalidad pendiente

**Requerimientos de UI/UX:**
- Drill-down desde tablero general a origen (orden, lote, receta)
- Navegación jerárquica: resumen → detalle → transacciones
- Filtros contextuales al navegar
- Historial de navegación

### 5. BI y Análisis
**Descripción:** Sistema de business intelligence y KPIs analíticos.

**Características actuales:**
- Tablas base: fact_ventas, fact_costos, dim_tiempo
- Dashboards: Chef, Gerente, Finanzas

**Requerimientos de UI/UX:**
- Tablas base: fact_ventas, fact_costos, dim_tiempo
- Dashboards específicos por rol
- Actualización diaria y comparativos históricos
- Objetivos: reducir mermas 15%, elevar precisión inventario a 98%, margen bruto +5%
- Comparativos históricos
- Indicadores de Star, Plowhorse, Puzzle, Dog para ingeniería de menú

## Requerimientos Técnicos
- Endpoints de exportación (CSV/PDF)
- Colas de reportes con expiración
- Caching de reportes pesados
- Sistema de programación de reportes
- Optimización de consultas para reportes
- Integración con módulos de autenticación para accesos restringidos
- Tablas base: fact_ventas, fact_costos, dim_tiempo
- Reportes programables
- Motor de reportes configurable
- Integraciones ERP y analítica avanzada
- Actualización diaria de tablas base

## Integración con Otros Módulos
- Inventario: Reportes de stock, movimientos, kardex
- Recetas: Análisis de costos y rentabilidad
- Compras: Análisis de proveedores y compras
- Producción: KPIs de eficiencia y rendimiento
- Caja Chica: Movimientos y conciliaciones
- POS: Ventas y consumo real
- Ventas: Cortes, tickets, movimientos

## KPIs Asociados
- Visualizaciones de KPIs clave
- Tasa de conversión
- Promedio de ticket
- Rotación de inventario
- Margen de utilidad
- Eficiencia operativa
- Nivel de servicio
- Margen de contribución
- Costo teórico vs real
- Rotación de inventario
- Diferencias de arqueo
- Variancia por sucursal
- Reducción de mermas
- Precisión de inventario
- Margen bruto
- KPIs por rol: Chef (rendimiento real/teórico), Gerente (margen/rentabilidad), Finanzas (costos históricos)