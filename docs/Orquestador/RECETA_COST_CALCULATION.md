# Recálculo de Costos de Recetas

## Descripción

Este módulo permite recalcular el costo unitario de recetas publicadas y subrecetas cuyo insumo cambió de precio el día anterior, y propagar el costo a recetas padre.

## Funcionalidad Principal

### `RecalcularCostosRecetasService`

El servicio principal `App\Services\Recetas\RecalcularCostosRecetasService` implementa la lógica de recálculo de costos con las siguientes características:

- **Entradas**: `branch_id` (opcional), `date` (por defecto ayer)
- **Proceso**: 
  1. Detecta insumos con cambio de costo (WAC/último) con `valid_from=date`
  2. Recalcula subrecetas afectadas (versión publicada vigente a la fecha)
  3. Recalcula recetas que referencian esas subrecetas/insumos
  4. Propaga los cambios de costo hacia arriba en la jerarquía de recetas
  5. Persiste en históricos existentes
  6. Genera alertas para recetas con margen negativo (opcional)

### Lógica de Propagación de Costos

El sistema implementa una lógica recursiva para propagar los cambios de costo a través de la jerarquía de recetas:

1. Detecta insumos con cambios de costo en la fecha objetivo
2. Recalcula recetas que usan directamente esos insumos
3. Recalcula recetas que usan esas recetas como ingredientes (subrecetas)
4. Continúa recursivamente hasta que no hay más cambios que propagar
5. Limita el proceso a 10 iteraciones para prevenir bucles infinitos

## Tablas Utilizadas

El servicio utiliza las siguientes tablas existentes del sistema:

- `selemti.items` - para obtener costos promedio de insumos
- `selemti.item_cost_history` - para detectar cambios de costo (si existe)
- `selemti.recipe_cost_history` - para registrar histórico de costos (si existe)
- `selemti.recipe_extended_cost_history` - alternativa para histórico de costos (si existe)
- `selemti.alertas_costos` - para generar alertas (si existe)
- `receta_cab`, `receta_version`, `receta_det` - para la estructura de recetas

Si las tablas históricas no existen, el sistema adapta su comportamiento:
- Para `item_cost_history`: calcula WAC desde recepciones del día
- Para `recipe_cost_history`: no registra histórico si no existe
- Para `alertas_costos`: registra alertas en logs si no existe

## Cálculo de Costos

### Fórmula de Costo Unitario
```
Costo Total = Σ (cantidad_detalle * costo_unitario_item * (1 + merma_porcentaje/100))
Costo por Porción = Costo Total / porciones_standard
```

### Cálculo de Margen
```
Margen = Precio Venta - Costo
Porcentaje Margen = (Margen / Precio Venta) * 100
```

Se generan alertas cuando:
- Margen es negativo (`MARGEN_NEGATIVO`, nivel ALTO)
- Margen es positivo pero menor al 5% (`MARGEN_BAJO`, nivel MEDIO)

## Idempotencia

El proceso implementa idempotencia mediante un lock en Redis con la clave `cost:lock:{date}` y TTL de 6 horas, evitando ejecuciones concurrentes para la misma fecha.

## Configuración

### Servicio de Inyección

El servicio puede ser inyectado en cualquier clase a través de Laravel's DI container:

```php
use App\Services\Recetas\RecalcularCostosRecetasService;

public function __construct(private RecalcularCostosRecetasService $recalcularCostosService)
{
    //
}
```

### Método Principal

```php
$result = $this->recalcularCostosService->recalcularCostos(?int $branchId = null, ?string $date = null);
```

## Dependencias

- PHP 8.1+
- Laravel 9+
- Redis para locks de idempotencia
- PostgreSQL como base de datos principal