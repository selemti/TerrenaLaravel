# Definición del Módulo: Recetas

## Descripción General
El módulo de Recetas gestiona las fórmulas de producción de productos terminados, incluyendo ingredientes, cantidades, rendimientos y costos. Es fundamental para restaurantes y operaciones de producción de alimentos, permitiendo el cálculo preciso de costos y la implosión automática para consumo POS. El sistema implementa versionado automático y snapshots de costos.

## Componentes del Módulo

### 1. Gestión de Recetas
**Descripción:** Funcionalidad para crear, editar y mantener recetas de productos.

**Características actuales:**
- Listado con precio sugerido
- Editor minimal con ID, PLU, ingredientes, merma
- Alertas de costo vacío
- Relación con ingredientes del inventario

**Requerimientos de UI/UX:**
- Editor avanzado de recetas con mejor UX
- Visualización de ingredientes con cantidades y costos
- Cálculo en tiempo real del costo de la receta
- Gestión de subrecetas (bases, salsas, jarabes)
- Rendimientos por preparación y porcionamiento
- Aprobaciones multiusuario (chef, costos, gerente)
- Costeo histórico por versión

### 2. Costeo de Recetas
**Descripción:** Sistema de cálculo y seguimiento de costos de recetas.

**Características actuales:**
- Cálculo básico de costos
- Alertas por costo vacío
- Función `GET /api/recipes/{id}/cost?at=YYYY-MM-DD` para consulta de costo en fecha específica
- Función `selemti.fn_recipe_cost_at` en PostgreSQL para cálculo de costo en fecha

**Requerimientos de UI/UX:**
- Cost snapshot por versión de receta (auto cuando cambia costo insumo o presentación)
- Vista de impacto: "si aumenta 5% la leche, ¿cuánto sube mi plato?"
- Historial de costos con gráfica
- Alertas de costo con umbral configurable (% Δ)
- Comparación teórico vs real
- Costos indirectos (MO, CIF) opcionales
- Snapshots automáticos diarios/semanales
- Mermas planificadas integradas al costo estándar
- Vista de alertas de costo pendientes/atendidas con filtros por fecha

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
- Vista de tickets sin mapeo (diagnóstico POS)
- Expansión de receta a consumo de MP
- Generación de movimientos definitivos VENTA_TEO en mov_inv

### 4. Versionado y Snapshots
**Descripción:** Sistema automático de versionado y snapshots de costos de recetas.

**Características actuales:**
- Tablas: recipe_versions, recipe_cost_snapshots, yield_profiles
- Job que recalcula por cambios de costo (RecalcularCostosRecetasService)
- Recálculo automático cuando cambia costo de insumo o presentación

**Requerimientos de UI/UX:**
- Versionado automático al editar receta
- Historial de versiones con comparador de cambios
- Snapshots automáticos de costo al cambiar insumos
- Comparación de versiones (diff)
- Migración: 2025_11_01_create_recipe_versions_table.php
- Migración: 2025_11_01_create_recipe_cost_snapshots_table.php

## Requerimientos Técnicos
- Tablas: recipe_versions, recipe_cost_snapshots, yield_profiles
- Job que recalcula por cambios de costo (RecalcularCostosRecetasService.php - 460 líneas, profesional)
- Sistema de versionado automático
- Snapshots automáticos de costos
- Implosión de recetas hasta nivel de materia prima
- Integración con módulo de inventario para costos de ingredientes
- Endpoints: `GET /api/recipes/{id}/cost?at=YYYY-MM-DD`
- Funciones PostgreSQL: fn_recipe_cost_at, fn_expandir_receta, fn_confirmar_consumo, fn_reversar_consumo
- Tablas: inv_consumo_pos, inv_consumo_pos_det
- Trigger para expansión automática cuando ticket.paid=true AND ticket.voided=false
- API: `GET /api/recipes/{id}/cost` para consulta de costo de receta
- Comando Artisan: `php artisan recetas:recalcular-costos` para recálculo programado

## Integración con Otros Módulos
- Inventario: Relación con ingredientes y costos de insumos, implosión de recetas para consumo POS
- Producción: Planificación y cálculo de materias primas necesarias
- Reportes: Análisis de rentabilidad, costos
- POS: Relación con ventas para cálculo de consumo y descuento automático de inventario
- Compras: Generación de compras para materias primas faltantes
- Menú POS: Mapeo de ítems de menú a recetas

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

## Flujos de Trabajo

### Flujo de Edición de Recetas
1. **Crear/Editar**: Usuario abre editor de recetas
2. **Ingredientes**: Agrega/modifica ingredientes con cantidades
3. **Subrecetas**: Incluye recetas como ingredientes de otras recetas
4. **Merma**: Define puntos de merma esperada
5. **Rendimientos**: Establece rendimientos por preparación
6. **Aprobación**: Receta pasa por proceso de aprobación multiusuario
7. **Versión**: Sistema crea nueva versión automáticamente
8. **Snapshot**: Se genera snapshot de costo actualizado

### Flujo de Consumo POS
1. **Venta**: Cliente realiza compra en POS
2. **Pago**: Ticket se marca como pagado (ticket.paid = true)
3. **Expansión**: Sistema ejecuta fn_expandir_receta para desglosar receta
4. **Staging**: Resultados se almacenan en inv_consumo_pos_det
5. **Confirmación**: Sistema ejecuta fn_confirmar_consumo para validar
6. **Movimiento**: Se generan movimientos VENTA_TEO en mov_inv
7. **Inventario**: Stock se actualiza automáticamente

### Flujo de Recálculo de Costos
1. **Cambio de Costo**: Se actualiza costo de insumo en inventario
2. **Trigger**: Sistema detecta cambio de costo
3. **Job**: Se ejecuta RecalcularCostosRecetasService
4. **Cálculo**: Sistema recalcula costos de recetas afectadas
5. **Snapshot**: Se generan nuevos snapshots de costo
6. **Alertas**: Se generan alertas si variación supera umbral
7. **Notificación**: Usuarios reciben notificaciones de cambios

## Estados de Recetas

### Estados de Versiones
```
BORRADOR → ACTIVA → INACTIVA
```

### Estados de Aprobación
```
SIN_APROBAR → APROBADA → RECHAZADA
```

## Componentes Técnicos

### Servicios
- **RecipeCostingService**: Servicio para cálculo de costos de recetas
  - `calculateRecipeCost()`: Calcula costo de receta
  - `calculateIngredientCost()`: Calcula costo de ingrediente
  - `calculateSubrecipeCost()`: Calcula costo de subreceta

- **RecalcularCostosRecetasService**: Servicio para recálculo automático de costos
  - `recalcularCostos()`: Recalcula costos cuando cambian insumos
  - `recalcularCostoReceta()`: Recalcula costo de receta específica
  - `generarSnapshot()`: Genera snapshot de costo
  - `generarAlerta()`: Genera alerta de variación significativa

### Controladores
- **RecipeCostController**: Controlador para endpoints de costos de recetas
  - `GET /api/recipes/{id}/cost?at=YYYY-MM-DD`
  - `POST /api/recipes/{recipeId}/recalculate`

### Modelos
- **RecetaCab**: Modelo para encabezado de recetas
- **RecetaDet**: Modelo para detalle de recetas
- **RecetaVersion**: Modelo para versiones de recetas
- **RecipeCostSnapshot**: Modelo para snapshots de costos
- **YieldProfile**: Modelo para perfiles de rendimiento

### Tablas
- `selemti.receta_cab`: Encabezado de recetas
- `selemti.receta_det`: Detalle de recetas
- `selemti.recipe_versions`: Versiones de recetas
- `selemti.recipe_cost_snapshots`: Snapshots de costos
- `selemti.yield_profiles`: Perfiles de rendimiento
- `selemti.inv_consumo_pos`: Consumo POS (cabecera)
- `selemti.inv_consumo_pos_det`: Consumo POS (detalle)

### Funciones PostgreSQL
- `selemti.fn_recipe_cost_at(timestamp, integer)`: Calcula costo de receta a fecha
- `selemti.fn_expandir_receta(bigint)`: Expande receta a consumo de MP
- `selemti.fn_confirmar_consumo(bigint)`: Confirma consumo POS
- `selemti.fn_reversar_consumo(bigint)`: Reversa consumo POS

### Vistas
- `selemti.vw_recipe_cost_history`: Historial de costos de recetas
- `selemti.vw_recipe_ingredients`: Vista de ingredientes de recetas
- `selemti.vw_recipe_yield_analysis`: Análisis de rendimiento

## Permisos y Roles

### Permisos Disponibles
- `recipes.view`: Ver recetas
- `recipes.manage`: Crear/Editar recetas
- `recipes.costs.recalc.schedule`: Cron recalcular costos (01:10)
- `recipes.costs.snapshot`: Snapshot manual de costo
- `can_view_recipe_dashboard`: Ver dashboard de recetas
- `can_modify_recipe`: Modificar recetas
- `can_reprocess_sales`: Reprocesar ventas POS

### Roles Sugeridos
- **Chef**: `recipes.view`, `recipes.manage`, `can_modify_recipe`
- **Costos**: `recipes.view`, `recipes.costs.*`, `can_view_recipe_dashboard`
- **Gerente**: `recipes.*`, `can_reprocess_sales`
- **Auditor**: `recipes.view`, `can_view_recipe_dashboard`

## Consideraciones Especiales

### Implosión de Recetas
- Obligatoria para todas las recetas
- Debe llegar hasta insumos crudos inventariables
- Validación automática de disponibilidad de materias primas
- Generación automática de alertas si faltan insumos críticos

### Control de Costos
- Recálculo automático cuando cambia costo de insumo
- Generación de snapshots de costo
- Alertas cuando variación supera umbral configurable
- Histórico completo de cambios de costo

### Seguridad y Auditoría
- Versionado automático de recetas
- Registro completo de cambios en recetas
- Trazabilidad de modificaciones (quién, cuándo, qué)
- Aprobaciones multiusuario para cambios críticos

### Performance
- Caching de costos recientes
- Índices optimizados en tablas de recetas
- Jobs asíncronos para recálculo de costos
- Vistas materializadas para reportes

## Próximos Pasos

### Implementaciones Pendientes
1. Completar UI de gestión de versiones de recetas
2. Implementar comparador de versiones (diff)
3. Agregar sistema de alertas de costo con umbral configurable
4. Completar UI de snapshots automáticos de costos
5. Implementar simulador de impacto de costos
6. Agregar rendimientos por preparación y porcionamiento
7. Completar sistema de mermas planificadas
8. Implementar dashboard de recetas con alertas

### Mejoras Sugeridas
1. Integración con sistemas externos de proveedores para costos
2. Predicción de costos basada en tendencias
3. Análisis de sensibilidad de costos
4. Optimización de recetas para minimizar costos
5. Integración con contabilidad para costos indirectos
6. Notificaciones automáticas de cambios de costo
7. Sistema de benchmarking de costos contra competencia
8. Exportación de reportes de costos en formatos estándar