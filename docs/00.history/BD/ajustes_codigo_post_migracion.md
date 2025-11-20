# Documento de Ajustes Post-Migración de Base de Datos
Fecha: jueves, 30 de octubre de 2025

## Objetivo
Documentar todos los ajustes necesarios en el código (modelos, servicios, vistas, etc.) para alinearse con la base de datos normalizada.

## Cambios Realizados en la Base de Datos

### 1. Tabla items
- Eliminado campo `unidad_medida` (VARCHAR con valores fijos)
- Mantenido campo `unidad_medida_id` (INTEGER con FK a cat_unidades)
- El campo `categoria_id` se mantiene con formato 'CAT-XXXX'

### 2. Tabla pos_map
- El campo `tipo` ahora acepta 'MENU', 'MODIFIER', 'COMBO' además de 'PLATO', 'MODIFICADOR', 'COMBO'
- El campo `receta_id` ahora es VARCHAR(20) para coincidir con `receta_cab.id`

### 3. Tabla recipe_cost_history
- El campo `recipe_id` ahora es VARCHAR(20) para coincidir con `receta_cab.id`

### 4. Tabla inventory_snapshot
- El campo `item_id` ahora es VARCHAR(20) para coincidir con `items.id`

### 5. Configuración de Conexión PostgreSQL
- **Host**: `127.0.0.1`
- **Puerto**: `5433`
- **Schemas**: `selemti,public`
- **Usuario**: `postgres`
- **Password**: `T3rr3n4#p0s`
- **Archivos sincronizados**: `config/database.php`, `phpunit.xml`, `scripts/generate_data_dictionary.php`
- **Propósito**: garantizar que las pruebas unitarias/feature y las utilerías CLI utilicen la misma instancia normalizada (`DB/00.SelemTI_Normalizada_29_10_25_10_40_v0.sql`).

## Ajustes Necesarios en el Código

### 1. Modelos

#### App\Models\Inv\Item
- **Ajuste**: Remover cualquier referencia a `unidad_medida` como campo de texto
- **Actualización**: Asegurar que las relaciones con `cat_unidades` estén correctamente definidas
- **Código**: 
  ```php
  // Cambiar de:
  // $item->unidad_medida (texto: 'KG', 'L', etc.)
  // A:
  $item->unidadMedida // Relación con cat_unidades
  ```

#### App\Models\Catalogs\Unidad (cat_unidades)
- **Ajuste**: Asegurar que este modelo esté disponible para las relaciones
- **Actualización**: Añadir relación en Item model:
  ```php
  public function unidadMedida()
  {
      return $this->belongsTo(Unidad::class, 'unidad_medida_id', 'id');
  }
  ```

#### App\Models\Rec\Receta (receta_cab)
- **Ajuste**: Confirmar que `id` es VARCHAR(20) en el modelo
- **Validación**: Asegurar consistencia con otras tablas que referencian recetas

### 2. Componentes de Livewire

#### App\Livewire\Inventory\ItemsManage
- **Ajuste**: Actualizar form para usar `unidad_medida_id` en lugar de `unidad_medida`
- **Cambio**:
  ```php
  // Antes:
  'unidad_medida' => 'required|in:KG,L,PZ,BULTO,CAJA',
  
  // Después:
  'unidad_medida_id' => 'required|exists:selemti.cat_unidades,id',
  ```
- **Actualización**: Adaptar la vista para usar select con opciones de `cat_unidades`

#### App\Livewire\Pos\PosMap
- **Ajuste**: Actualizar validación de tipo para aceptar nuevos valores
- **Cambio**:
  ```php
  // Antes:
  'form.tipo' => 'required|in:PLATO,MODIFICADOR,COMBO',
  
  // Después:
  'form.tipo' => 'required|in:MENU,MODIFIER,COMBO',
  ```
- **Consideración**: Mantener compatibilidad temporal con ambos formatos

#### App\Livewire\Inventory\OrquestadorPanel
- **Ajuste**: Verificar que consultas de validación usen tipos de datos correctos
- **Validación**: Confirmar que `recipe_cost_history` se consulte con nuevo tipo de `recipe_id`

### 3. Servicios

#### App\Services\Recetas\RecalcularCostosRecetasService
- **Ajuste**: Verificar que las consultas a `recipe_cost_history` usen VARCHAR en lugar de BIGINT
- **Validación**: Confirmar que las relaciones con recetas usen formato compatible

#### App\Services\Operations\DailyCloseService
- **Ajuste**: Validar que `inventory_snapshot` se acceda con nuevo formato de `item_id`
- **Verificación**: Confirmar que las FKs se respetan en todas las operaciones

### 4. Vistas y Componentes de UI

#### Recetas y Costos
- **Cambio**: Actualizar vistas que muestren unidad de medida para usar relación con `cat_unidades`
- **Ejemplo**:
  ```blade
  {{-- Antes --}}
  {{ $item->unidad_medida }}
  
  {{-- Después --}}
  {{ $item->unidadMedida->nombre ?? $item->unidad_medida }}
  ```

#### Mapeos POS
- **Cambio**: Actualizar vistas para mostrar 'MENU'/'MODIFIER' en lugar de 'PLATO'/'MODIFICADOR'
- **Consideración**: Mantener compatibilidad visual durante transición

#### Inventarios
- **Cambio**: Ajustar vistas que muestran unidades de medida
- **Validación**: Asegurar que los selects de unidades usen la tabla `cat_unidades`

### 5. Controladores y APIs

#### Controladores de Recetas
- **Ajuste**: Validar tipos de parámetros recibidos para `recipe_id`
- **Cambio**: Asegurar que las respuestas JSON usen formato compatible

#### Controladores de Inventario
- **Ajuste**: Validar tipos de parámetros para `item_id`
- **Cambio**: Adaptar serialización de unidades de medida

### 6. Migraciones y Seeds

#### Nueva migración para aplicar cambios definitivos
- **Ajuste**: Crear migración para eliminar campos redundantes permanentemente
- **Cambio**: Aplicar CHECK definitivo en pos_map.tipo (solo MENU/MODIFIER/COMBO)

#### Actualización de seeds
- **Ajuste**: Asegurar que los datos semilla usen nuevo formato
- **Cambio**: Actualizar seeds para usar IDs de unidades en lugar de códigos de texto

### 7. Tests

#### Tests de modelo
- **Ajuste**: Actualizar tests que verifican campos eliminados
- **Validación**: Añadir tests para nuevas relaciones

#### Tests de integración
- **Ajuste**: Revisar tests que dependen de formato de datos específicos
- **Actualización**: Asegurar que tests usen tipos de datos correctos

### 8. Comandos de Artisan

#### App\Console\Commands\RecalcularCostosRecetasCommand
- **Ajuste**: Validar que los parámetros recibidos coincidan con nuevo esquema
- **Verificación**: Confirmar que el comando funcione con nuevo formato de recetas

#### Otros comandos relacionados
- **Revisión**: Validar todos los comandos que interactúan con las tablas modificadas

## Consideraciones Adicionales

1. **Vistas de Compatibilidad**: Las vistas de compatibilidad creadas durante la migración pueden mantenerse como capa intermedia durante la transición.

2. **Cache y Sesiones**: Limpiar cache y sesiones después de aplicar los cambios para evitar conflictos con modelos antiguos.

3. **Documentación de API**: Actualizar documentación de endpoints afectados para reflejar nuevos formatos de datos.

4. **Configuración de Loggers**: Verificar que los logs no dependan de campos eliminados.

## Prioridad de Implementación

### Alta Prioridad
- Modelos de dominio afectados (Item, Receta, etc.)
- Validaciones en componentes Livewire
- Servicios críticos de cálculo de costos

### Media Prioridad
- Vistas y componentes de UI
- Controladores y APIs
- Tests

### Baja Prioridad
- Documentación y comentarios
- Optimizaciones menores
- Eliminación final de campos redundantes

## Seguimiento

1. Crear issues/tickets para cada grupo de ajustes
2. Asignar a desarrolladores responsables
3. Realizar pruebas unitarias e integradas
4. Validar funcionalidad en entorno de pruebas
5. Desplegar en producción con plan de rollback