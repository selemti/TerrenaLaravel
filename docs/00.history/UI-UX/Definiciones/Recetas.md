# Definición del Módulo: Recetas

## Descripción General
El módulo de Recetas permite la creación y gestión de fórmulas de producción de productos terminados, incluyendo ingredientes, cantidades, rendimientos y costos. Es fundamental para restaurantes y operaciones de producción de alimentos.

## Componentes del Módulo

### 1. Gestión de Recetas
**Descripción:** Funcionalidad para crear, editar y mantener recetas de productos.

**Características actuales:**
- Listado con precio sugerido
- Editor minimal con ID, PLU, ingredientes, merma
- Alertas de costo vacío

**Requerimientos de UI/UX:**
- Editor avanzado de recetas con mejor UX
- Visualización de ingredientes con cantidades y costos
- Cálculo en tiempo real del costo de la receta
- Gestión de subrecetas
- Rendimientos por preparación y porcionamiento

### 2. Costeo de Recetas
**Descripción:** Sistema de cálculo y seguimiento de costos de recetas.

**Características actuales:**
- Cálculo básico de costos
- Alertas por costo vacío

**Requerimientos de UI/UX:**
- Cost snapshot por versión de receta (auto cuando cambia costo de insumo o presentación)
- Vista de impacto: "si aumenta 5% la leche, ¿cuánto sube mi plato?"
- Historial de costos con gráfica
- Alertas de costo con umbral configurable
- Comparación teórico vs real

## Requerimientos Técnicos
- Tablas: recipe_versions, recipe_cost_snapshots, yield_profiles
- Job que recalcula por cambios de costo
- Sistema de versionado de recetas
- Cálculos de rendimiento y merma
- Integración con módulo de inventario para costos de ingredientes
- Endpoints para recálculo de costos

## Integración con Otros Módulos
- Inventario: Relación con ingredientes y costos de insumos
- Producción: Planificación y cálculo de materias primas necesarias
- Reportes: Análisis de rentabilidad, costos
- POS: Relación con ventas para cálculo de consumo

## KPIs Asociados
- Costo por porción
- Margen de utilidad por producto
- Desviación de costo teórico vs real
- Rendimiento de producción
- Merma por producto
- Recetas con margen negativo

### 3. Implosión de Recetas (Consumo POS)
**Descripción:** Sistema que descompone las ventas del POS en sus ingredientes para control de inventario.

**Características actuales:**
- Función de expansión de receta (fn_expandir_receta)
- Confirmación de consumo (fn_confirmar_consumo)
- Reverso de consumo (fn_reversar_consumo)
- Tablas: inv_consumo_pos, inv_consumo_pos_det
- Expansión de receta a consumo de MP en tabla de staging

**Requerimientos de UI/UX:**
- Confirmación del consumo cuando ticket.paid = true AND ticket.voided = false
- Reverso si ticket.voided = true o se procesa devolución
- Manejo de modificadores/combos
- Soporte para cancelaciones/devoluciones
- Expansión de receta a consumo de MP
- Generación de movimientos definitivos VENTA_TEO en mov_inv

## Requerimientos Técnicos
- Tablas: recipe_versions, recipe_cost_snapshots, yield_profiles
- Job que recalcula por cambios de costo
- Sistema de versionado de recetas
- Cálculos de rendimiento y merma
- Integración con módulo de inventario para costos de ingredientes
- Endpoints para recálculo de costos
- Función PostgreSQL: selemti.fn_recipe_cost_at
- Trigger para expansión de receta a consumo POS
- Tablas: inv_consumo_pos, inv_consumo_pos_det
- Funciones: fn_expandir_receta, fn_confirmar_consumo, fn_reversar_consumo
- Costeo = Σ(ingrediente × cantidad) × costo unitario

## KPIs Asociados
- Costo por porción
- Margen de utilidad por producto
- Desviación de costo teórico vs real
- Rendimiento de producción
- Merma por producto
- Recetas con margen negativo
- Comparativos teórico vs real
- Rendimiento real vs teórico por receta/turno
- Variación de costos
- Ticket promedio