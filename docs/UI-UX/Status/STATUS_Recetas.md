# STATUS ACTUAL DEL MÓDULO: RECETAS

## Fecha de Análisis: 30 de octubre de 2025

## 1. RESUMEN GENERAL

| Aspecto | Estado |
|--------|--------|
| **Backend Completo** | ✅ |
| **Frontend Funcional** | ✅ |
| **API REST Completa** | ✅ |
| **Documentación** | ✅ |
| **Nivel de Completitud** | 50% |

## 2. MODELOS (Backend)

### 2.1 Modelos Implementados
- ✅ `RecetaCAB.php` - Cabecera de recetas
- ✅ `RecetaDET.php` - Detalle de recetas (ingredientes)
- ⚠️ `Recipe.php` - Modelo base (posible duplicación con recetacab)
- ❌ `RecipeVersion.php` - Versionado de recetas (pendiente)
- ❌ `RecipeCostSnapshot.php` - Snapshots de costos (pendiente)

### 2.2 Relaciones y Funcionalidades
- ✅ Relaciones con items/insumos (ingredientes)
- ✅ Relaciones con unidades de medida
- ⚠️ Sistema de versionado no implementado
- ⚠️ Sistema de costeo automático incompleto
- ❌ Rendimientos y mermas por batch no implementados

## 3. SERVICIOS (Backend)

### 3.1 Servicios Implementados
- ✅ `Recetas/RecipeCostingService.php` - Cálculo básico de costos
- ✅ `Recetas/RecalcularCostosRecetasService.php` - Recálculo de costos (460 líneas, profesional)
- ⚠️ `RecipeService.php` - Servicio base incompleto

### 3.2 Funcionalidades Completadas
- ✅ Cálculo básico de costo de receta
- ✅ Suma de ingredientes para costo
- ✅ Recálculo de costos masivo (RecalcularCostosRecetasService)
- ✅ Función `GET /api/recipes/{id}/cost?at=YYYY-MM-DD` para consulta de costo en fecha
- ✅ Función `selemti.fn_recipe_cost_at` en PostgreSQL para cálculo de costo en fecha
- ✅ Sistema de alertas por márgenes negativos

### 3.3 Funcionalidades Pendientes
- ❌ Versionado automático de recetas
- ❌ Snapshots automáticos de costos
- ❌ Sistema de impacto de costos
- ❌ Simulador de impacto
- ❌ Rendimientos por preparación y porcionamiento
- ❌ Comparación teórico vs real

## 4. RUTAS Y CONTROLADORES (Backend)

### 4.1 Rutas Web Implementadas
- ✅ `/recipes` - Listado de recetas
- ✅ `/recipes/editor/{id?}` - Editor de recetas

### 4.2 API Endpoints
- ✅ `GET /api/recipes/{id}/cost` - Consulta de costo de receta
- ✅ `GET /api/recipes/{id}/cost?at=YYYY-MM-DD` - Consulta de costo en fecha específica
- ✅ `POST /api/recipes/{recipeId}/recalculate` - Recalcular costo de receta

## 5. COMPONENTES LIVEWIRE (Frontend)

### 5.1 Componentes Implementados
- ✅ `Recipes/RecipesIndex.php` - Listado de recetas
- ✅ `Recipes/RecipeEditor.php` - Editor de recetas

### 5.2 Funcionalidades Frontend Completadas
- ✅ Listado con precios sugeridos
- ✅ Editor básico con ID, PLU, ingredientes, merma
- ✅ Visualización de ingredientes con cantidades
- ✅ Cálculo en tiempo real del costo de la receta
- ✅ Alertas de costo vacío

### 5.3 Funcionalidades Frontend Pendientes
- ⚠️ Editor avanzado de recetas
- ❌ Gestión de versiones
- ❌ Comparación teórico vs real
- ❌ Vista de impacto de costos
- ❌ Simulador de impacto

## 6. VISTAS BLADE

### 6.1 Vistas Implementadas
- ✅ `recetas.blade.php` - Vista principal de recetas
- ✅ `livewire/recipes/*.blade.php` - Vistas para componentes

### 6.2 Funcionalidades de UI
- ✅ Layout responsivo con Bootstrap 5
- ✅ Visualización de ingredientes
- ✅ Cálculo de costos en tiempo real

## 7. IMPLOSIÓN DE RECETAS (Consumo POS)

### 7.1 Funcionalidades Completadas
- ✅ Función de expansión de receta (fn_expandir_receta)
- ✅ Confirmación de consumo (fn_confirmar_consumo)
- ✅ Reverso de consumo (fn_reversar_consumo)
- ✅ Tablas: inv_consumo_pos, inv_consumo_pos_det
- ✅ Expansión de receta a consumo de MP en tabla de staging

### 7.2 Funcionalidades Pendientes
- ❌ Confirmación automática cuando ticket.paid = true AND ticket.voided = false
- ❌ Reverso automático cuando ticket.voided = true
- ❌ Manejo de modificadores/combos
- ❌ Generación automática de movimientos VENTA_TEO

## 8. PERMISOS IMPLEMENTADOS

### 8.1 Permisos de Recetas
- ✅ `recipes.view` - Ver recetas
- ✅ `recipes.manage` - Crear/Editar recetas
- ✅ `recipes.costs.recalc.schedule` - Cron recalcular costos (01:10)
- ✅ `recipes.costs.snapshot` - Snapshot manual de costo
- ✅ `can_view_recipe_dashboard` - Ver dashboard de recetas
- ✅ `can_modify_recipe` - Modificar recetas

## 9. ESTADO DE AVANCE

### 9.1 Completo (✅)
- Listado y edición básica de recetas
- Cálculo básico de costos
- Recálculo de costos masivo
- API RESTful para operaciones
- Sistema de implosión para consumo POS

### 9.2 En Desarrollo (⚠️)
- Funcionalidad de costeo avanzado
- Validación de ingredientes
- Dashboard de recetas

### 9.3 Pendiente (❌)
- Versionado de recetas
- Snapshots automáticos de costos
- Sistema de impacto de costos
- Comparación teórico vs real
- Rendimientos por preparación
- Implosión automática con triggers POS

## 10. KPIs MONITOREADOS

- Costo por porción
- Margen de utilidad por producto
- Desviación de costo teórico vs real
- Rendimiento de producción
- Merma por producto
- Recetas con margen negativo
- Comparativos teórico vs real
- Rendimiento real vs teórico por receta/turno
- Variación de costos

## 11. PRÓXIMOS PASOS

1. Implementar sistema de versionado de recetas
2. Agregar snapshots automáticos de costos
3. Completar sistema de impacto de costos
4. Implementar implosión automática con triggers POS

**Responsable:** Equipo TerrenaLaravel  
**Última actualización:** 30 de octubre de 2025