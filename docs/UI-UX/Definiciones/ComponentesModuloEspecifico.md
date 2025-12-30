# Componentes Específicos por Módulo - TerrenaLaravel ERP

## Descripción General

Este documento detalla los componentes específicos desarrollados para cada módulo del sistema TerrenaLaravel ERP. Estos componentes encapsulan la lógica y presentación específica de cada área funcional del sistema.

## Módulo de Inventario (`inventory/`)

### item-card.blade.php

Componente para mostrar información resumida de un ítem del inventario en forma de tarjeta.

**Uso:**
```blade
<x-inventory.item-card 
    :item="$item" 
    :stock="$stock" 
    :show-stock="true" 
    :show-actions="true" />
```

**Props:**
- `item` (array|object): Datos del ítem con nombre, clave, categoría, etc.
- `showStock` (boolean): Indica si se debe mostrar el stock (por defecto `true`)
- `showActions` (boolean): Indica si se deben mostrar las acciones (por defecto `true`)
- `stock` (array|object): Información de stock opcional
- `actions` (slot): Acciones personalizadas para sobrescribir las predeterminadas

**Características:**
- Visualización responsiva con truncamiento de nombres largos
- Indicador visual del estado de stock (bajo/normal) con colores codificados
- Badges para mostrar SKU
- Acciones predeterminadas (ver, editar) o personalizables
- Codificación de colores para indicar stock bajo

**Ejemplo de estructura de datos esperados:**
```php
$item = [
    'nombre' => 'Hamburguesa Clásica',
    'clave' => 'HAMB-001',
    'categoria' => 'Comida',
    'sku' => 'HAMB-001',
    'stock_minimo' => 10
];

$stock = [
    'cantidad_actual' => 5,
    'unidad_medida' => 'PZ'
];
```

### transaction-card.blade.php

Componente para mostrar información de una transacción de inventario.

**Props:**
- `transaction` (array|object): Datos de la transacción
- `showDetails` (boolean): Mostrar detalles adicionales
- `actions` (slot): Acciones personalizadas

**Características:**
- Muestra tipo de transacción, cantidad, fecha y referencias
- Codificación de colores según tipo de transacción (entrada/salida/merma)
- Soporte para mostrar o esconder detalles

## Módulo de Transferencias (`transfer/`)

### transfer-form.blade.php

Formulario para creación y edición de transferencias entre almacenes.

**Props:**
- `transfer` (array|object): Datos de la transferencia (opcional para creación nueva)
- `warehouses` (array): Lista de almacenes disponibles
- `items` (array): Lista de ítems disponibles para transferencia
- `showValidation` (boolean): Mostrar validación en línea
- `model` (string): Modelo Livewire para la transferencia

**Características:**
- Formulario para definir almacén origen y destino
- Selección de ítems y cantidades
- Validación de stock disponible
- Soporte para múltiples líneas de transferencia
- Integración con Livewire para validación en tiempo real

### transfer-status-badge.blade.php

Badge para mostrar el estado de una transferencia con colores codificados.

**Props:**
- `status` (string): Estado de la transferencia
- `label` (string): Etiqueta a mostrar (opcional, se puede inferir del estado)

**Estados soportados:**
- `SOLICITADA`: Transferencia creada pero no aprobada
- `APROBADA`: Transferencia aprobada, pendiente de despacho
- `EN_TRANSITO`: Transferencia despachada, en tránsito
- `RECIBIDA`: Transferencia recibida en destino
- `POSTEADA`: Transferencia registrada en inventario
- `CANCELADA`: Transferencia cancelada

**Características:**
- Colores codificados para cada estado
- Etiquetas traducidas
- Tamaños ajustables

## Módulo de Catálogos

Aunque no se encontraron componentes específicos de catálogos en la estructura de componentes, se asume que los componentes genéricos `ui/` se utilizan para construir interfaces de catálogos como:
- Formularios para creación/edición de proveedores
- Tablas para listado de unidades de medida
- Tarjetas para visualización de almacenes

## Módulo de Recetas

### Recetas Componentes

Aunque no se encontraron componentes específicos de recetas en la estructura de componentes, se asume que se utilizan componentes genéricos para:
- Formularios de creación de recetas
- Visualización de ingredientes
- Cálculo de costos

## Módulo de Compras

De manera similar, el módulo de compras probablemente reutiliza componentes genéricos para:
- Formularios de órdenes de compra
- Listados de proveedores
- Visualización de estados de pedido

## Buenas Prácticas de Desarrollo

### 1. Estructura de Datos
- Mantener consistencia en la estructura de datos entre componentes
- Utilizar contratos de datos claros para props
- Documentar ejemplos de estructuras de datos

### 2. Reutilización
- Antes de crear un componente específico, verificar si existe uno genérico en `ui/`
- Si se repite lógica en componentes específicos, extraerla a un componente genérico
- Mantener una capa de abstracción entre modelos de datos y componentes

### 3. Performance
- Optimizar la carga de datos para componentes que muestran listas
- Implementar paginación o virtual scrolling para grandes volúmenes
- Usar skeleton loading para operaciones que tomen tiempo

### 4. UX Consistente
- Mantener el diseño y comportamiento consistente entre módulos
- Usar las mismas convenciones de colores y estados
- Asegurar que acciones similares tengan el mismo aspecto

### 5. Internacionalización
- Preparar componentes para soportar múltiples idiomas
- Usar claves de traducción
- Considerar diferencias culturales en formatos de fecha/moneda

## Estructura de Implementación

### Componentes de Presentación
Componentes que se enfocan en la presentación visual sin lógica de negocio:
- item-card.blade.php
- status-badge.blade.php

### Componentes Contenedores
Componentes que encapsulan lógica de negocio específica del dominio:
- transfer-form.blade.php
- transaction-card.blade.php

## Integración con Livewire

Muchos componentes específicos de módulos están diseñados para trabajar con Livewire:

```blade
<x-inventory.item-card 
    :item="$item" 
    :stock="$this->getStockForItem($item->id)"
    :actions="view('components.inventory.item-actions')" />
```

Esto permite mantener la lógica de recuperación de datos en los componentes Livewire mientras se mantiene la presentación en los componentes Blade reutilizables.

## Pruebas y Validación

Los componentes específicos por módulo deben ser probados en el contexto de los módulos donde se utilizan, asegurando:
- Visualización correcta de datos
- Funcionalidad de acciones
- Comportamiento responsivo
- Accesibilidad
- Internationalización

## Conclusión

Los componentes específicos por módulo son una capa de abstracción que encapsula la lógica de presentación particular de cada área funcional del ERP. Al mantener una clara separación entre componentes genéricos y específicos, se logra un equilibrio entre reutilización y especialización que mejora la mantenibilidad y la coherencia del sistema.