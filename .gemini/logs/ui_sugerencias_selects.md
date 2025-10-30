# Sugerencias para Selects Dinámicos en Vistas Blade (2025-10-24)

## Catálogos Detectados por `terrena:inspect-catalogos`

Este comando expone los siguientes catálogos desde el esquema `selemti`:

*   **Sucursales (`selemti.cat_sucursales`):**
    *   Campos: `id` (value), `nombre` (label), `clave`, `activo`.
*   **Proveedores (`selemti.cat_proveedores`):**
    *   Campos: `id` (value), `razon_social` (label), `rfc`, `activo`.
*   **Almacenes (`selemti.cat_almacenes`):**
    *   Campos: `id` (value), `descripcion` (label), `sucursal_id`, `activo`.

---

## Análisis de Vistas Blade y Propuestas de Dinamización

A continuación, se detallan los `select` encontrados en las vistas Blade, su propósito y la propuesta para su poblamiento dinámico.

### 1. `resources/views/livewire/cash-fund/open.blade.php`

**Propósito del Select:** Seleccionar la sucursal para la apertura de un fondo de caja chica.
**Fuente de Datos:** `selemti.cat_sucursales`
**Campo para `value`:** `id`
**Campo para `label`:** `nombre` (concatenado con `clave` si existe, como ya se hace en el Livewire `Open.php`)
**Snippet Blade Propuesto:**

```blade
<select class="form-select @error('form.sucursal_id') is-invalid @enderror"
        wire:model.defer="form.sucursal_id"
        {{ $loading ? 'disabled' : '' }}>
    <option value="">-- Selecciona sucursal --</option>
    @foreach($sucursales as $suc)
        <option value="{{ $suc['id'] }}">{{ $suc['nombre'] }}</option>
    @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `Open.php` a través de la propiedad `$sucursales`, que se carga desde `selemti.cat_sucursales`. No requiere cambios en la vista, pero se documenta como ejemplo de buena práctica.

---

### 2. `resources/views/inventory/items-index.blade.php`

**a) Select de Sucursal**
**Propósito del Select:** Filtrar ítems por sucursal.
**Fuente de Datos:** `selemti.cat_sucursales`
**Campo para `value`:** `id`
**Campo para `label`:** `nombre` (o `clave - nombre`)
**Snippet Blade Propuesto:**

```blade
<select wire:model="sucursal" class="form-select">
  <option value="">Sucursal: Todas</option>
  @foreach($sucursales as $suc)
      <option value="{{ $suc->id }}">{{ $suc->nombre }}</option>
  @endforeach
</select>
```
**Recomendación para Livewire (`app/Livewire/Inventory/ItemsIndex.php`):**
Se debe añadir una propiedad pública `$sucursales` al componente y poblarla en el método `mount()` o en un método dedicado, similar a como se hace en `CashFund\Open.php`.

**b) Select de Categoría**
**Propósito del Select:** Filtrar ítems por categoría.
**Fuente de Datos:** Se propone crear `selemti.cat_categorias`.
**Columnas propuestas:** `id` (PK, string/uuid), `nombre` (string, unique), `descripcion` (nullable string), `activo` (boolean).
**Campo para `value`:** `id`
**Campo para `label`:** `nombre`
**Snippet Blade Propuesto:**

```blade
<select wire:model="categoria" class="form-select">
  <option value="">Categoría: Todas</option>
  @foreach($categorias as $cat)
      <option value="{{ $cat->id }}">{{ $cat->nombre }}</option>
  @endforeach
</select>
```
**Recomendación para Livewire (`app/Livewire/Inventory/ItemsIndex.php`):**
Se debe añadir una propiedad pública `$categorias` al componente y poblarla en el método `mount()` o en un método dedicado, consultando `selemti.cat_categorias`.

**c) Select de Estado**
**Propósito del Select:** Filtrar ítems por estado (Bajo stock, Normal).
**Fuente de Datos:** Actualmente hardcodeado. Se observa una inconsistencia: la vista usa `wire:model="estado"` mientras el componente Livewire usa `public ?string $estadoCad = null;`. Se recomienda unificar el nombre de la propiedad.
**Propuesta:** Mantener hardcodeado si los estados son fijos y no se espera que cambien. Si se prevé que los estados evolucionen, se podría considerar la creación de una tabla `selemti.cat_estados_item` con `id` y `nombre`.

---

### 3. `resources/views/inventory/receptions-create.blade.php`

**a) Select de Proveedor**
**Propósito del Select:** Seleccionar el proveedor de la recepción.
**Fuente de Datos:** `selemti.cat_proveedores`
**Campo para `value`:** `id`
**Campo para `label`:** `nombre` (o `razon_social`)
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model="supplier_id">
  <option value="">-- Seleccione --</option>
  @foreach($suppliers as $supplier)
    <option value="{{ $supplier->id }}">{{ $supplier->nombre }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente. Se asume que el componente Livewire `ReceptionsCreate.php` carga la variable `$suppliers` desde `selemti.cat_proveedores`. No se pudo verificar el componente Livewire `ReceptionsCreate.php` ya que el archivo no fue encontrado.

**b) Select de Sucursal**
**Propósito del Select:** Seleccionar la sucursal de destino de la recepción.
**Fuente de Datos:** `selemti.cat_sucursales`
**Campo para `value`:** `id`
**Campo para `label`:** `clave — nombre`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model="branch_id">
  <option value="">-- Seleccione --</option>
  @foreach($branches as $branch)
    <option value="{{ $branch->id }}">{{ $branch->clave }} — {{ $branch->nombre }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente. Se asume que el componente Livewire `ReceptionsCreate.php` carga la variable `$branches` desde `selemti.cat_sucursales`. No se pudo verificar el componente Livewire `ReceptionsCreate.php` ya que el archivo no fue encontrado.

**c) Select de Almacén**
**Propósito del Select:** Seleccionar el almacén de destino de la recepción.
**Fuente de Datos:** `selemti.cat_almacenes`
**Campo para `value`:** `id`
**Campo para `label`:** `clave — nombre` (con `sucursal_clave` opcional)
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model="warehouse_id">
  <option value="">-- Seleccione --</option>
  @foreach($warehouses as $warehouse)
    <option value="{{ $warehouse->id }}">
      {{ $warehouse->clave }} — {{ $warehouse->nombre }}
      @if($warehouse->sucursal_clave)
        ({{ $warehouse->sucursal_clave }})
      @endif
    </option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente. Se asume que el componente Livewire `ReceptionsCreate.php` carga la variable `$warehouses` desde `selemti.cat_almacenes`. No se pudo verificar el componente Livewire `ReceptionsCreate.php` ya que el archivo no fue encontrado.

**d) Select de Producto (líneas de recepción)**
**Propósito del Select:** Seleccionar el producto a recibir en cada línea.
**Fuente de Datos:** `selemti.items` (o `selemti.cat_items` si existe)
**Campo para `value`:** `id`
**Campo para `label`:** `nombre` (o `descripcion`)
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select form-select-sm" wire:model="lines.{{ $i }}.item_id">
  <option value="">--</option>
  @foreach($items as $item)
    <option value="{{ $item->id }}">{{ $item->nombre ?? $item->descripcion ?? $item->id }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente. Se asume que el componente Livewire `ReceptionsCreate.php` carga la variable `$items` desde `selemti.items`. No se pudo verificar el componente Livewire `ReceptionsCreate.php` ya que el archivo no fue encontrado.

**e) Select de UOM Compra (líneas de recepción)**
**Propósito del Select:** Seleccionar la unidad de medida de compra para el producto.
**Fuente de Datos:** `selemti.cat_unidades` (o `selemti.unidades` si existe)
**Campo para `value`:** `id` (o `codigo`)
**Campo para `label`:** `nombre` (o `codigo`)
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select form-select-sm" wire:model="lines.{{ $i }}.uom_purchase">
  @foreach($purchaseUoms as $purchaseUom)
    <option value="{{ $purchaseUom }}">{{ $purchaseUom }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente. Se asume que el componente Livewire `ReceptionsCreate.php` carga la variable `$purchaseUoms` desde un catálogo de unidades de medida. No se pudo verificar el componente Livewire `ReceptionsCreate.php` ya que el archivo no fue encontrado.

**f) Select de UOM Base (líneas de recepción)**
**Propósito del Select:** Seleccionar la unidad de medida base para el producto.
**Fuente de Datos:** `selemti.cat_unidades` (o `selemti.unidades` si existe)
**Campo para `value`:** `id` (o `codigo`)
**Campo para `label`:** `nombre` (o `codigo`)
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select form-select-sm" wire:model="lines.{{ $i }}.uom_base">
  @foreach($baseUoms as $baseUom)
    <option value="{{ $baseUom }}">{{ $baseUom }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente. Se asume que el componente Livewire `ReceptionsCreate.php` carga la variable `$baseUoms` desde un catálogo de unidades de medida. No se pudo verificar el componente Livewire `ReceptionsCreate.php` ya que el archivo no fue encontrado.

---

### 4. `resources/views/livewire/cash-fund/index.blade.php`

**a) Select de Estado**
**Propósito del Select:** Filtrar fondos de caja chica por su estado.
**Fuente de Datos:** Valores fijos que corresponden a los estados internos de la tabla `cash_funds` (`ABIERTO`, `EN_REVISION`, `CERRADO`).
**Campo para `value`:** Valores literales (`abierto`, `en_revision`, `cerrado`, `all`).
**Campo para `label`:** Descripciones legibles (`Abiertos`, `En revisión`, `Cerrados`, `Todos`).
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select" wire:model.live="estadoFilter">
    <option value="all">Todos</option>
    <option value="abierto">Abiertos</option>
    <option value="en_revision">En revisión</option>
    <option value="cerrado">Cerrados</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representan estados internos del modelo `CashFund` y no requieren un catálogo dinámico de la base de datos.

---

### 5. `resources/views/livewire/cash-fund/movements.blade.php`

**a) Select de Tipo de Movimiento**
**Propósito del Select:** Seleccionar el tipo de movimiento (Egreso, Reintegro, Depósito) para un fondo de caja chica.
**Fuente de Datos:** Valores fijos que corresponden a los tipos de movimiento internos del modelo `CashFundMovement`.
**Campo para `value`:** Valores literales (`EGRESO`, `REINTEGRO`, `DEPOSITO`).
**Campo para `label`:** Descripciones legibles (`Egreso`, `Reintegro`, `Depósito`).
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select @error('movForm.tipo') is-invalid @enderror"
        wire:model.defer="movForm.tipo">
    <option value="EGRESO">Egreso</option>
    <option value="REINTEGRO">Reintegro</option>
    <option value="DEPOSITO">Depósito</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representan tipos de movimiento fijos del sistema.

**b) Select de Método de Pago**
**Propósito del Select:** Seleccionar el método de pago (Efectivo, Transferencia) para un movimiento de caja chica.
**Fuente de Datos:** Valores fijos que corresponden a los métodos de pago internos del modelo `CashFundMovement`.
**Campo para `value`:** Valores literales (`EFECTIVO`, `TRANSFER`).
**Campo para `label`:** Descripciones legibles (`Efectivo`, `Transferencia`).
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select @error('movForm.metodo') is-invalid @enderror"
        wire:model.defer="movForm.metodo">
    <option value="EFECTIVO">Efectivo</option>
    <option value="TRANSFER">Transferencia</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representan métodos de pago fijos del sistema.

**c) Select de Proveedor**
**Propósito del Select:** Asociar un proveedor a un movimiento de egreso.
**Fuente de Datos:** `selemti.cat_proveedores`
**Campo para `value`:** `id`
**Campo para `label`:** `nombre`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select @error('movForm.proveedor_id') is-invalid @enderror"
        wire:model.defer="movForm.proveedor_id">
    <option value="">-- Ninguno --</option>
    @foreach($proveedores as $prov)
        <option value="{{ $prov['id'] }}">{{ $prov['nombre'] }}</option>
    @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `Movements.php` a través de la propiedad `$proveedores`, que se carga desde `selemti.cat_proveedores`. No requiere cambios en la vista.

---

### 6. `resources/views/livewire/catalogs/almacenes-index.blade.php`

**a) Select de Sucursal**
**Propósito del Select:** Asignar una sucursal a un almacén al crear o editar.
**Fuente de Datos:** `selemti.cat_sucursales` (a través del modelo Eloquent `App\}$.Models\}$.Catalogs\}$.Sucursal`).
**Campo para `value`:** `id`
**Campo para `label`:** `nombre`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select @error('sucursal_id') is-invalid @enderror" wire:model.defer="sucursal_id">
  <option value="">(sin asignar)</option>
  @foreach ($sucursales as $s)
    <option value="{{ $s->id }}">{{ $s->nombre }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `AlmacenesIndex.php` a través de la propiedad `$sucursales`, que se carga desde `selemti.cat_sucursales` usando el modelo `Sucursal`. No requiere cambios en la vista.

---

### 7. `resources/views/livewire/catalogs/stock-policy-index.blade.php`

**a) Select de Artículo**
**Propósito del Select:** Seleccionar un artículo para definir una política de stock.
**Fuente de Datos:** `selemti.items` (a través del modelo Eloquent `App\}$.Models\}$.Inv\}$.Item`).
**Campo para `value`:** `id`
**Campo para `label`:** `name` (o `nombre`, determinado dinámicamente en el componente)
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select @error('item_id') is-invalid @enderror" wire:model.defer="item_id">
  <option value="">-- Selecciona --</option>
  @foreach ($items as $item)
    <option value="{{ $item->id }}">{{ $item->name }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `StockPolicyIndex.php` a través de la propiedad `$items`, que se carga desde `selemti.items` usando el modelo `Item`. No requiere cambios en la vista.

**b) Select de Sucursal**
**Propósito del Select:** Seleccionar una sucursal para la política de stock.
**Fuente de Datos:** `selemti.cat_sucursales` (a través del modelo Eloquent `App\}$.Models\}$.Catalogs\}$.Sucursal`).
**Campo para `value`:** `id`
**Campo para `label`:** `name` (o `nombre`)
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select @error('sucursal_id') is-invalid @enderror" wire:model.defer="sucursal_id">
  <option value="">-- Selecciona --</option>
  @foreach ($sucursales as $s)
    <option value="{{ $s->id }}">{{ $s->name }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `StockPolicyIndex.php` a través de la propiedad `$sucursales`, que se carga desde `selemti.cat_sucursales` usando el modelo `Sucursal`. No requiere cambios en la vista.

---

### 8. `resources/views/livewire/catalogs/sucursales-index.blade.php`

**Comentario:** Esta vista no contiene ningún elemento `<select>` que requiera poblamiento dinámico. Es una interfaz para la gestión directa de sucursales.

---

### 9. `resources/views/livewire/catalogs/unidades-index.blade.php`

**a) Select de Tipo (filtro y modal)**
**Propósito del Select:** Filtrar unidades de medida por tipo y asignar un tipo al crear/editar una unidad.
**Fuente de Datos:** Valores fijos (`PESO`, `VOLUMEN`, `UNIDAD`, `TIEMPO`).
**Campo para `value`:** Valores literales.
**Campo para `label`:** Valores literales.
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select form-select-sm" wire:model.live="tipo">
  <option value="">Todos</option>
  <option value="PESO">PESO</option>
  <option value="VOLUMEN">VOLUMEN</option>
  <option value="UNIDAD">UNIDAD</option>
  <option value="TIEMPO">TIEMPO</option>
</select>
```
**Comentario:** Estos `select`s están correctamente implementados con valores hardcodeados, ya que representan tipos de unidades de medida fijos del sistema.

**b) Select de Categoría (filtro y modal)**
**Propósito del Select:** Filtrar unidades de medida por categoría y asignar una categoría al crear/editar una unidad.
**Fuente de Datos:** Valores fijos (`METRICO`, `IMPERIAL`, `CULINARIO`).
**Campo para `value`:** Valores literales.
**Campo para `label`:** Valores literales.
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select form-select-sm" wire:model.live="categoria">
  <option value="">Todas</option>
  <option value="METRICO">MÉTRICO</option>
  <option value="IMPERIAL">IMPERIAL</option>
  <option value="CULINARIO">CULINARIO</option>
</select>
```
**Comentario:** Estos `select`s están correctamente implementados con valores hardcodeados, ya que representan categorías de unidades de medida fijas del sistema.

**c) Select de Paginación (`perPage`)**
**Propósito del Select:** Controlar el número de elementos por página.
**Fuente de Datos:** Valores fijos (`10`, `25`, `50`, `100`).
**Comentario:** Este `select` es un control de UI estándar para paginación y no requiere poblamiento dinámico desde la base de datos.

---

### 10. `resources/views/livewire/catalogs/uom-conversion-index.blade.php`

**a) Select de Unidad Origen y Unidad Destino**
**Propósito del Select:** Seleccionar las unidades de medida para una conversión.
**Fuente de Datos:** `selemti.unidades_medida` (a través del modelo Eloquent `App\}$.Models\}$.Catalogs\}$.Unidad`).
**Campo para `value`:** `id`
**Campo para `label`:** `codigo — nombre` (formateado en el componente)
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select @error('origen_id') is-invalid @enderror" wire:model.defer="origen_id">
  <option value="">-- Selecciona --</option>
  @foreach ($unitOptions as $option)
    <option value="{{ $option->id }}">{{ $option->label }}</option>
  @endforeach
</select>
```
**Comentario:** Estos `select`s ya están siendo poblados dinámicamente por el componente Livewire `UomConversionIndex.php` a través de la propiedad `$unitOptions`, que se carga desde `selemti.unidades_medida` usando el modelo `Unidad`. No requieren cambios en la vista.

---

### 11. `resources/views/livewire/crud/generic-index.blade.php`

**a) Select de Paginación (`perPage`)**
**Propósito del Select:** Controlar el número de elementos por página.
**Fuente de Datos:** Valores fijos (`10`, `25`, `50`).
**Comentario:** Este `select` es un control de UI estándar para paginación y no requiere poblamiento dinámico desde la base de datos.

**b) Componente `x-ui.select` (dinámico)**
**Propósito del Select:** Componente genérico para renderizar `select`s dinámicos.
**Fuente de Datos:** Las opciones (`:options="$field['options'] ?? []"`) se pasan al componente `x-ui.select` a través de la propiedad `$formSchema` del componente Livewire que utiliza esta vista genérica.
**Comentario:** Este `select` es dinámico por diseño. La responsabilidad de poblar sus opciones recae en el componente Livewire que implementa `generic-index.blade.php` y en la configuración de su `$formSchema`. No hay `select`s hardcodeados directamente en esta vista que necesiten ser dinamizados.

---

### 12. `resources/views/livewire/inventory-count/create.blade.php`

**a) Select de Sucursal**
**Propósito del Select:** Seleccionar la sucursal para un nuevo conteo de inventario.
**Fuente de Datos:** `selemti.cat_sucursales`
**Campo para `value`:** `id`
**Campo para `label`:** `nombre`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model="form.sucursal_id">
    <option value="">-- Seleccionar --</option>
    @foreach($sucursales as $suc)
        <option value="{{ $suc->id }}">{{ $suc->nombre }}</option>
    @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `Create.php` a través de la propiedad `$sucursales`, que se carga desde `selemti.cat_sucursales`. No requiere cambios en la vista.

**b) Select de Almacén**
**Propósito del Select:** Seleccionar el almacén para un nuevo conteo de inventario.
**Fuente de Datos:** `selemti.cat_almacenes`
**Campo para `value`:** `id`
**Campo para `label`:** `nombre`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model.live="form.almacen_id">
    <option value="">-- Seleccionar --</option>
    @foreach($almacenes as $alm)
        <option value="{{ $alm->id }}">{{ $alm->nombre }}</option>
    @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `Create.php` a través de la propiedad `$almacenes`, que se carga desde `selemti.cat_almacenes`. No requiere cambios en la vista.

---

### 13. `resources/views/livewire/inventory-count/index.blade.php`

**a) Select de Estado**
**Propósito del Select:** Filtrar conteos de inventario por su estado.
**Fuente de Datos:** Valores fijos que corresponden a los estados internos del modelo `InventoryCount` (`BORRADOR`, `EN_PROCESO`, `AJUSTADO`, `CANCELADO`).
**Campo para `value`:** Valores literales (`all`, `BORRADOR`, `EN_PROCESO`, `AJUSTADO`, `CANCELADO`).
**Campo para `label`:** Descripciones legibles (`Todos`, `Borrador`, `En Proceso`, `Ajustado`, `Cancelado`).
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select" wire:model.live="estadoFilter">
    <option value="all">Todos</option>
    <option value="BORRADOR">Borrador</option>
    <option value="EN_PROCESO">En Proceso</option>
    <option value="AJUSTADO">Ajustado</option>
    <option value="CANCELADO">Cancelado</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representan estados internos del modelo `InventoryCount` y no requieren un catálogo dinámico de la base de datos.

**b) Select de Sucursal**
**Propósito del Select:** Filtrar conteos de inventario por sucursal.
**Fuente de Datos:** `selemti.cat_sucursales`
**Campo para `value`:** `id`
**Campo para `label`:** `nombre` (o `clave - nombre`)
**Snippet Blade Propuesto:**
```blade
<select class="form-select" wire:model.live="sucursalFilter">
    <option value="all">Todos</option>
    @foreach($sucursales as $suc)
        <option value="{{ $suc->id }}">{{ $suc->nombre }}</option>
    @endforeach
</select>
```
**Recomendación para Livewire (`app/Livewire/InventoryCount/Index.php`):**
La propiedad `$sucursales` debe ser poblada desde `selemti.cat_sucursales` obteniendo `id` y `nombre` (o `clave`). Actualmente, solo se obtienen los `sucursal_id` de la tabla `InventoryCount`. Se debe modificar el método `render()` para cargar las sucursales completas.

**c) Select de Almacén**
**Propósito del Select:** Filtrar conteos de inventario por almacén.
**Fuente de Datos:** `selemti.cat_almacenes`
**Campo para `value`:** `id`
**Campo para `label`:** `nombre` (o `clave - nombre`)
**Snippet Blade Propuesto:**
```blade
<select class="form-select" wire:model.live="almacenFilter">
    <option value="all">Todos</option>
    @foreach($almacenes as $alm)
        <option value="{{ $alm->id }}">{{ $alm->nombre }}</option>
    @endforeach
</select>
```
**Recomendación para Livewire (`app/Livewire/InventoryCount/Index.php`):**
La propiedad `$almacenes` debe ser poblada desde `selemti.cat_almacenes` obteniendo `id` y `nombre` (o `clave`). Actualmente, solo se obtienen los `almacen_id` de la tabla `InventoryCount`. Se debe modificar el método `render()` para cargar los almacenes completos.

---

### 14. `resources/views/livewire/inventory/alerts-list.blade.php`

**a) Select de Estado**
**Propósito del Select:** Filtrar alertas de costo por su estado (pendientes, atendidas, todas).
**Fuente de Datos:** Valores fijos que corresponden al estado de la columna `handled` en la tabla `alert_events`.
**Campo para `value`:** Valores literales (`pending`, `handled`, `all`).
**Campo para `label`:** Descripciones legibles (`Pendientes`, `Atendidas`, `Todas`).
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select" wire:model="handled">
  <option value="pending">Pendientes</option>
  <option value="handled">Atendidas</option>
  <option value="all">Todas</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representan estados fijos del sistema que se mapean directamente a una columna booleana en la base de datos.

---

### 15. `resources/views/livewire/inventory/item-price-create.blade.php`

**a) Select de Ítem**
**Propósito del Select:** Seleccionar un ítem para registrar su precio de proveedor.
**Fuente de Datos:** `selemti.items` (con join a `selemti.item_vendor` para proveedor preferente).
**Campo para `value`:** `id`
**Campo para `label`:** `id · name (item_code)` (formateado en el componente)
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model="itemId">
  <option value="">-- Selecciona un ítem --</option>
  @foreach($itemOptions as $option)
    <option value="{{ $option['id'] }}">
      {{ $option['id'] }} · {{ $option['name'] }}
      @if($option['item_code'])
        ({{ $option['item_code'] }})
      @endif
    </option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `ItemPriceCreate.php` a través de la propiedad `$itemOptions`, que se carga desde `selemti.items`. No requiere cambios en la vista.

**b) Select de Proveedor**
**Propósito del Select:** Seleccionar un proveedor para el precio del ítem.
**Fuente de Datos:** `selemti.cat_proveedores` (con join a `selemti.item_vendor`).
**Campo para `value`:** `id`
**Campo para `label`:** `name` (con indicador "Preferente" opcional)
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model="vendorId" {{ $itemId ? '' : 'disabled' }}>
  <option value="">-- Selecciona un proveedor --</option>
  @foreach($vendorOptions as $option)
    <option value="{{ $option['id'] }}">
      {{ $option['name'] }}
      @if($option['preferente'])
        · Preferente
      @endif
    </option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `ItemPriceCreate.php` a través de la propiedad `$vendorOptions`, que se carga desde `selemti.cat_proveedores`. No requiere cambios en la vista.

---

### 16. `resources/views/livewire/inventory/items-manage.blade.php`

**a) Select de Categoría (filtro)**
**Propósito del Select:** Filtrar ítems por categoría.
**Fuente de Datos:** `selemti.item_categories`
**Campo para `value`:** `id`
**Campo para `label`:** `id · nombre`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model="categoryFilter">
  <option value="">Todas</option>
  @foreach($categoryOptions as $category)
    <option value="{{ $category['id'] }}">
      {{ $category['id'] }} · {{ $category['nombre'] }}
    </option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `ItemsManage.php` a través de la propiedad `$categoryOptions`, que se carga desde `selemti.item_categories`. No requiere cambios en la vista.

**b) Select de Estado (filtro)**
**Propósito del Select:** Filtrar ítems por su estado (activo/inactivo).
**Fuente de Datos:** Valores fijos (`all`, `active`, `inactive`) que mapean a la columna booleana `activo` en la tabla `selemti.items`.
**Campo para `value`:** Valores literales.
**Campo para `label`:** Descripciones legibles.
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select" wire:model="statusFilter">
  <option value="all">Todos</option>
  <option value="active">Solo activos</option>
  <option value="inactive">Solo inactivos</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representa estados fijos del sistema.

**c) Select de Proveedor Preferente (filtro)**
**Propósito del Select:** Filtrar ítems según tengan o no un proveedor preferente.
**Fuente de Datos:** Valores fijos (`all`, `with`, `without`) que mapean a la existencia de un proveedor preferente en la tabla `selemti.item_vendor`.
**Campo para `value`:** Valores literales.
**Campo para `label`:** Descripciones legibles.
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select" wire:model="preferredFilter">
  <option value="all">Todos</option>
  <option value="with">Con proveedor</option>
  <option value="without">Sin proveedor</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representa opciones de filtro fijas.

**d) Select de Ordenar por (`sortField`)**
**Propósito del Select:** Seleccionar el campo por el cual ordenar la lista de ítems.
**Fuente de Datos:** Valores fijos (`name`, `effective_from`) que corresponden a campos de la base de datos o propiedades derivadas.
**Campo para `value`:** Valores literales.
**Campo para `label`:** Descripciones legibles.
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select" wire:model="sortField">
  <option value="name">Nombre</option>
  <option value="effective_from">Vigencia precio</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representa opciones de ordenamiento fijas.

**e) Select de Dirección de Ordenamiento (`sortDirection`)**
**Propósito del Select:** Seleccionar la dirección de ordenamiento (ascendente/descendente).
**Fuente de Datos:** Valores fijos (`asc`, `desc`).
**Campo para `value`:** Valores literales.
**Campo para `label`:** Descripciones legibles.
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select" wire:model="sortDirection">
  <option value="asc">Ascendente</option>
  <option value="desc">Descendente</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representa opciones de ordenamiento fijas.

**f) Select de Tipo de Ítem (modal)**
**Propósito del Select:** Asignar un tipo al ítem al crear o editar.
**Fuente de Datos:** Valores fijos (`MATERIA_PRIMA`, `ELABORADO`, `ENVASADO`) definidos en el componente Livewire.
**Campo para `value`:** Valores literales.
**Campo para `label`:** Valores literales.
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select" wire:model.defer="form.tipo">
  @foreach($tipoOptions as $option)
    <option value="{{ $option }}">{{ $option }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representa tipos de ítems fijos del sistema.

**g) Select de Estado de Ítem (modal)**
**Propósito del Select:** Asignar el estado (activo/inactivo) al ítem al crear o editar.
**Fuente de Datos:** Valores fijos (`1`, `0`) que mapean a la columna booleana `activo`.
**Campo para `value`:** Valores literales.
**Campo para `label`:** Descripciones legibles.
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select" wire:model.defer="form.activo">
  <option value="1">Activo</option>
  <option value="0">Inactivo</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representa estados booleanos fijos.

**h) Select de Unidad Base (modal)**
**Propósito del Select:** Asignar la unidad de medida base al ítem.
**Fuente de Datos:** `selemti.unidades_medida`
**Campo para `value`:** `id`
**Campo para `label`:** `codigo · nombre`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model.defer="form.unidad_base_id">
  <option value="">-- Selecciona --</option>
  @foreach($units as $unit)
    <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }} · {{ $unit['nombre'] }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `ItemsManage.php` a través de la propiedad `$units`, que se carga desde `selemti.unidades_medida`. No requiere cambios en la vista.

**i) Select de Unidad Compra (modal)**
**Propósito del Select:** Asignar la unidad de medida de compra al ítem.
**Fuente de Datos:** `selemti.unidades_medida`
**Campo para `value`:** `id`
**Campo para `label`:** `codigo · nombre`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model.defer="form.unidad_compra_id">
  <option value="">-- Selecciona --</option>
  @foreach($units as $unit)
    <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }} · {{ $unit['nombre'] }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `ItemsManage.php` a través de la propiedad `$units`, que se carga desde `selemti.unidades_medida`. No requiere cambios en la vista.

**j) Select de Unidad Salida (modal)**
**Propósito del Select:** Asignar la unidad de medida de salida al ítem.
**Fuente de Datos:** `selemti.unidades_medida`
**Campo para `value`:** `id`
**Campo para `label`:** `codigo · nombre`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select" wire:model.defer="form.unidad_salida_id">
  <option value="">-- Selecciona --</option>
  @foreach($units as $unit)
    <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }} · {{ $unit['nombre'] }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `ItemsManage.php` a través de la propiedad `$units`, que se carga desde `selemti.unidades_medida`. No requiere cambios en la vista.

**k) Select de Proveedor (líneas de proveedor en modal)**
**Propósito del Select:** Seleccionar un proveedor para una línea de proveedor del ítem.
**Fuente de Datos:** `selemti.cat_proveedores`
**Campo para `value`:** `id`
**Campo para `label`:** `nombre`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select form-select-sm"
        wire:model.defer="providers.{{ $index }}.vendor_id">
  <option value="">-- Selecciona --</option>
  @foreach($providerOptions as $option)
    <option value="{{ $option['id'] }}">{{ $option['nombre'] }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `ItemsManage.php` a través de la propiedad `$providerOptions`, que se carga desde `selemti.cat_proveedores`. No requiere cambios en la vista.

**l) Select de Unidad de Presentación (líneas de proveedor en modal)**
**Propósito del Select:** Seleccionar la unidad de medida de presentación para una línea de proveedor del ítem.
**Fuente de Datos:** `selemti.unidades_medida`
**Campo para `value`:** `id`
**Campo para `label`:** `codigo`
**Snippet Blade Propuesto:** (Ya implementado dinámicamente)
```blade
<select class="form-select form-select-sm"
        wire:model.defer="providers.{{ $index }}.unidad_presentacion_id">
  <option value="">--</option>
  @foreach($units as $unit)
    <option value="{{ $unit['id'] }}">{{ $unit['codigo'] }}</option>
  @endforeach
</select>
```
**Comentario:** Este `select` ya está siendo poblado dinámicamente por el componente Livewire `ItemsManage.php` a través de la propiedad `$units`, que se carga desde `selemti.unidades_medida`. No requiere cambios en la vista.

**m) Select de Moneda (líneas de proveedor en modal)**
**Propósito del Select:** Seleccionar la moneda para el costo de una línea de proveedor del ítem.
**Fuente de Datos:** Valores fijos (`MXN`, `USD`).
**Campo para `value`:** Valores literales.
**Campo para `label`:** Valores literales.
**Snippet Blade Propuesto:** (Ya implementado y es adecuado)
```blade
<select class="form-select form-select-sm"
        wire:model.defer="providers.{{ $index }}.moneda">
  <option value="MXN">MXN</option>
  <option value="USD">USD</option>
</select>
```
**Comentario:** Este `select` está correctamente implementado con valores hardcodeados, ya que representa opciones de moneda fijas.

---

## Soporte a Pedido Sugerido

Para el módulo de Pedido Sugerido de compras, los siguientes catálogos son fundamentales:

1.  **Sucursales (`selemti.cat_sucursales`):**
    *   **Relevancia:** Esencial para determinar la sucursal de destino del pedido.
    *   **Estado actual:** El catálogo existe y está siendo utilizado dinámicamente en varias vistas (`cash-fund/open.blade.php`, `inventory/items-index.blade.php`, `inventory-count/create.blade.php`, `inventory-count/index.blade.php`, `catalogs/almacenes-index.blade.php`, `catalogs/stock-policy-index.blade.php`, `purchasing/requests/create.blade.php`, `purchasing/requests/index.blade.php`).
    *   **Listo para usar:** Sí, el catálogo de sucursales está listo para ser utilizado en una pantalla de "pedido sugerido".

2.  **Almacenes (`selemti.cat_almacenes`):**
    *   **Relevancia:** Fundamental para especificar el almacén de destino dentro de una sucursal.
    *   **Estado actual:** El catálogo existe y está siendo utilizado dinámicamente en varias vistas (`inventory-count/create.blade.php`, `inventory-count/index.blade.php`, `catalogs/almacenes-index.blade.php`).
    *   **Listo para usar:** Sí, el catálogo de almacenes está listo para ser utilizado en una pantalla de "pedido sugerido".

3.  **Proveedores (`selemti.cat_proveedores`):**
    *   **Relevancia:** Necesario para seleccionar el proveedor al que se realizará el pedido.
    *   **Estado actual:** El catálogo existe y está siendo utilizado dinámicamente en varias vistas (`cash-fund/movements.blade.php`, `inventory/item-price-create.blade.php`, `inventory/items-manage.blade.php`, `purchasing/orders/index.blade.php`, `purchasing/requests/create.blade.php`).
    *   **Listo para usar:** Sí, el catálogo de proveedores está listo para ser utilizado en una pantalla de "pedido sugerido".

4.  **Ítems (`selemti.items`):**
    *   **Relevancia:** La base de cualquier pedido, para seleccionar los productos a comprar.
    *   **Estado actual:** El catálogo existe y está siendo utilizado dinámicamente en varias vistas (`inventory/receptions-create.blade.php`, `inventory/item-price-create.blade.php`, `inventory/items-manage.blade.php`, `inventory-count/create.blade.php`).
    *   **Listo para usar:** Sí, el catálogo de ítems está listo para ser utilizado en una pantalla de "pedido sugerido".

5.  **Unidades de Medida (`selemti.unidades_medida`):**
    *   **Relevancia:** Para especificar las unidades de compra de los ítems.
    *   **Estado actual:** El catálogo existe y está siendo utilizado dinámicamente en varias vistas (`catalogs/unidades-index.blade.php`, `catalogs/uom-conversion-index.blade.php`, `inventory/items-manage.blade.php`).
    *   **Listo para usar:** Sí, el catálogo de unidades de medida está listo para ser utilizado en una pantalla de "pedido sugerido".

**Elementos adicionales necesarios para un módulo de "Pedido Sugerido" completo (TODOs):**

Para un módulo de pedido sugerido robusto, se necesitarían los siguientes datos y funcionalidades adicionales, que actualmente no se han identificado como catálogos directos o campos existentes en las tablas revisadas:

*   **Lead Time del Proveedor por Ítem/Presentación:**
    *   **Descripción:** Días que tarda un proveedor en entregar un ítem específico.
    *   **Propuesta de Migración:** Agregar una columna `lead_time_dias` (INTEGER, NULLABLE) a la tabla `selemti.item_vendor` (ya existe y se usa en `items-manage.blade.php` para captura).
*   **Stock Mínimo/Máximo por Producto/Sucursal/Almacén:**
    *   **Descripción:** Cantidades de stock deseadas para cada ítem en una ubicación específica.
    *   **Estado actual:** Existe la tabla `inv_stock_policy` (`selemti.inv_stock_policy`) que ya maneja `min_qty`, `max_qty`, `reorder_qty` por `item_id` y `sucursal_id`. Esto es directamente utilizable.
*   **Historial de Ventas/Consumo por Ítem/Sucursal:**
    *   **Descripción:** Datos históricos para calcular la demanda y proyectar necesidades.
    *   **Propuesta de Migración:** Se necesitaría una tabla `selemti.historial_consumo` o similar, con columnas como `item_id`, `sucursal_id`, `fecha`, `cantidad_consumida`. Esto requeriría integración con el módulo de ventas/POS.
*   **Parámetros de Reorden (EOQ, ROP):**
    *   **Descripción:** Cálculos avanzados para optimizar las cantidades de pedido.
    *   **Propuesta de Migración:** Podrían ser campos adicionales en `selemti.inv_stock_policy` o calculados en tiempo real por un servicio.

**Conclusión:**

Los catálogos básicos (sucursales, almacenes, proveedores, ítems, unidades de medida) están bien establecidos y listos para ser consumidos por un módulo de pedido sugerido. Los datos de políticas de stock (`min_qty`, `max_qty`, `reorder_qty`) también están disponibles. Los principales "TODOs" se centran en la integración de datos de consumo histórico y la implementación de lógica de cálculo de reorden, así como la consolidación del `lead_time_dias` en la tabla `item_vendor`.
