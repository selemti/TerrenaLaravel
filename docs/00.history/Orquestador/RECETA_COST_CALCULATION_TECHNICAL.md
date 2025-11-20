# Detalles Técnicos del Servicio de Recálculo de Costos

## Arquitectura del Servicio

El servicio `RecalcularCostosRecetasService` sigue una arquitectura modular con métodos específicos para cada etapa del proceso:

### Métodos Principales

#### `recalcularCostos(?int $branchId = null, ?string $date = null): array`
- Punto de entrada principal
- Implementa el lock de idempotencia
- Orquesta todo el proceso
- Retorna un array con resultados detallados

#### `detectarInsumosConCambioCosto(string $date, ?int $branchId = null): array`
- Detecta insumos con cambios de costo en la fecha objetivo
- Verifica si existe `selemti.item_cost_history`
- Si no existe, calcula WAC desde recepciones del día
- Retorna array de objetos `Item` con costos actualizados

#### `recalcularSubrecetasAfectadas(array $insumosConCambioCosto, string $date): array`
- Busca recetas con versiones publicadas vigentes a la fecha
- Recalcula el costo de recetas que usan insumos afectados
- Actualiza solo si el costo ha cambiado
- Registra en histórico y retorna detalles de cambios

#### `recalcularRecetasAfectadas(array $insumosConCambioCosto, array $subrecetasAfectadas, string $date): array`
- Implementa lógica recursiva para propagar cambios hacia arriba
- Busca recetas que usan subrecetas/insumos afectados como ingredientes
- Limita a 10 iteraciones para prevenir bucles infinitos
- Actualiza costos y registra cambios

#### `generarAlertasMargenNegativo(array $recetasAfectadas, string $date): array`
- Calcula márgenes para recetas recalculadas
- Genera alertas para márgenes negativos o bajos
- Verifica existencia de tabla `selemti.alertas_costos`
- Si no existe, registra en logs con formato JSON

## Estructura de Datos

### Parámetros de Entrada
```php
$branchId  // ID opcional de la sucursal
$date      // Fecha objetivo (formato Y-m-d), por defecto ayer
```

### Resultado de Ejecución
```php
[
    'success' => bool,                    // Indica si la operación fue exitosa
    'date' => string,                     // Fecha procesada
    'affected_items' => int,              // Número de insumos con cambios
    'affected_subrecetas' => int,         // Número de subrecetas recalculadas
    'affected_recetas' => int,            // Número de recetas recalculadas
    'alerts_generated' => int,            // Número de alertas generadas
    'message' => string                   // Mensaje descriptivo
]
```

## Lógica de Costos

### Cálculo de Costo por Receta
```php
foreach ($version->detalles as $detalle) {
    $item = $detalle->item;
    if (!$item) continue;
    
    $costoUnitario = $item->costo_promedio ?? 0;
    $factorMerma = 1 + ($detalle->merma_porcentaje / 100);
    $costoConMerma = $costoUnitario * $factorMerma;
    $costoTotal += $detalle->cantidad * $costoConMerma;
}

$costoPorPorcion = $costoTotal / ($receta->porciones_standard ?? 1);
```

### Cálculo de Margen
```php
$margen = $precioVenta - $costo;
$porcentajeMargen = $precioVenta > 0 ? ($margen / $precioVenta) * 100 : 0;
```

## Persistencia y Control de Versiones

El servicio respeta las vigencias de versiones de recetas:
- Solo procesa versiones con `version_publicada = true`
- Solo procesa versiones con `fecha_efectiva <= $date`
- No reescribe costos de días anteriores
- Mantiene la integridad de la línea de tiempo de costos

## Seguridad y Validaciones

### Idempotencia
- Lock en Redis con clave `cost:lock:{$date}`
- TTL de 6 horas (21600 segundos)
- Verificación al inicio y liberación al finalizar
- Prevención de ejecuciones concurrentes

### Validaciones
- Verificación de existencia de tablas antes de usarlas
- Validación de fechas y rangos
- Control de iteraciones recursivas (máximo 10)
- Manejo de errores y excepciones

## Dependencias y Requerimientos

### Extensiones PHP Requeridas
- `phpredis` o `predis/predis` para manejo de Redis
- `ext-pgsql` para conexiones PostgreSQL

### Paquetes Laravel
- `illuminate/database`
- `illuminate/console`
- `illuminate/support`

### Permisos y Acceso
- El servicio opera con permisos del contexto de ejecución
- No requiere permisos especiales más allá de los necesarios para leer/escribir en las tablas