# Terrena ERP - Frontend Blueprint

## 1. Resumen Técnico

Este documento detalla la arquitectura, componentes y flujos del frontend del sistema Terrena ERP. El objetivo es proporcionar un mapa claro para el desarrollo, mantenimiento y escalabilidad de la interfaz de usuario.

- **Framework Principal:** [Laravel 12](https://laravel.com/docs/12.x)
- **Componentes Reactivos:** [Livewire 3.7](https://livewire.laravel.com/docs)
- **Framework CSS:** [Bootstrap 5](https://getbootstrap.com/) (inferido por la ausencia de `tailwind.config.js` y la presencia de clases no-tailwind en vistas)
- **Javascript Adicional:** [Alpine.js](https://alpinejs.dev/) (comúnmente usado con Livewire)
- **Autenticación:** Laravel Breeze/Jetstream (basado en `routes/auth.php`)

## 2. Mapa de Módulos y Componentes

A continuación se presenta la relación entre Módulos, Vistas, Componentes Livewire y Rutas.

| Módulo | Componente / Vista | Ruta | Descripción | Layout |
|---|---|---|---|---|
| **Dashboard** | `dashboard.blade.php` | `/dashboard` | Página principal post-login. | `layouts.app` |
| **Autenticación** | `auth/` | `/login`, `/register`, etc. | Flujos de inicio de sesión, registro, etc. | `layouts.guest` |
| **Perfil** | `profile/` | `/profile` | Edición de perfil de usuario. | `layouts.app` |
| **Compras** | `compras.blade.php` | `/compras` | Vista estática para el módulo de compras. | `layouts.app` |
| | `Purchasing\Requests\Index` | `/purchasing/requests` | Listado de solicitudes de compra. | `layouts.app` |
| | `Purchasing\Requests\Create` | `/purchasing/requests/create` | Creación de solicitud de compra. | `layouts.app` |
| | `Purchasing\Requests\Detail` | `/purchasing/requests/{id}/detail` | Detalle de solicitud de compra. | `layouts.app` |
| | `Purchasing\Orders\Index` | `/purchasing/orders` | Listado de órdenes de compra. | `layouts.app` |
| | `Purchasing\Orders\Detail` | `/purchasing/orders/{id}/detail` | Detalle de orden de compra. | `layouts.app` |
| **Inventario** | `inventario.blade.php` | `/inventario` | Vista estática para el módulo de inventario. | `layouts.app` |
| | `Inventory\ItemsManage` | `/inventory/items` | Gestión de artículos de inventario. | `layouts.app` |
| | `Inventory\ReceptionsIndex` | `/inventory/receptions` | Listado de recepciones de inventario. | `layouts.app` |
| | `Inventory\ReceptionCreate` | `/inventory/receptions/new` | Creación de recepción de inventario. | `layouts.app` |
| | `Inventory\ReceptionDetail` | `/inventory/receptions/{id}/detail` | Detalle de recepción de inventario. | `layouts.app` |
| | `Inventory\LotsIndex` | `/inventory/lots` | Listado de lotes de inventario. | `layouts.app` |
| | `Inventory\AlertsList` | `/inventory/alerts` | Listado de alertas de inventario. | `layouts.app` |
| | `InventoryCount\Index` | `/inventory/counts` | Listado de conteos de inventario. | `layouts.app` |
| | `InventoryCount\Create` | `/inventory/counts/create` | Creación de conteo de inventario. | `layouts.app` |
| | `InventoryCount\Capture` | `/inventory/counts/{id}/capture` | Captura de conteo de inventario. | `layouts.app` |
| | `InventoryCount\Review` | `/inventory/counts/{id}/review` | Revisión de conteo de inventario. | `layouts.app` |
| | `InventoryCount\Detail` | `/inventory/counts/{id}/detail` | Detalle de conteo de inventario. | `layouts.app` |
| **Recetas** | `recetas.blade.php` | `/recetas` | Vista estática para el módulo de recetas. | `layouts.app` |
| | `Recipes\RecipesIndex` | `/recipes` | Listado de recetas. | `layouts.app` |
| | `Recipes\RecipeEditor` | `/recipes/editor/{id?}` | Editor de recetas. | `layouts.app` |
| **Producción** | `produccion.blade.php` | `/produccion` | Vista estática para el módulo de producción. | `layouts.app` |
| **Catálogos** | `catalogos-index.blade.php` | `/catalogos` | Índice de catálogos. | `layouts.app` |
| | `Catalogs\UnidadesIndex` | `/catalogos/unidades` | Catálogo de unidades. | `layouts.app` |
| | `Catalogs\UomConversionIndex` | `/catalogos/uom` | Catálogo de conversión de unidades. | `layouts.app` |
| | `Catalogs\AlmacenesIndex` | `/catalogos/almacenes` | Catálogo de almacenes. | `layouts.app` |
| | `Catalogs\ProveedoresIndex` | `/catalogos/proveedores` | Catálogo de proveedores. | `layouts.app` |
| | `Catalogs\SucursalesIndex` | `/catalogos/sucursales` | Catálogo de sucursales. | `layouts.app` |
| | `Catalogs\StockPolicyIndex` | `/catalogos/stock-policy` | Catálogo de políticas de stock. | `layouts.app` |
| **Personal** | `People\UsersIndex` | `/personal` | Listado de usuarios. | `layouts.app` |
| **Caja Chica** | `CashFund\Index` | `/cashfund` | Listado de fondos de caja chica. | `layouts.app` |
| | `CashFund\Open` | `/cashfund/open` | Apertura de fondo de caja chica. | `layouts.app` |
| | `CashFund\Movements` | `/cashfund/{id}/movements` | Movimientos de fondo de caja chica. | `layouts.app` |
| | `CashFund\Arqueo` | `/cashfund/{id}/arqueo` | Arqueo de fondo de caja chica. | `layouts.app` |
| | `CashFund\Detail` | `/cashfund/{id}/detail` | Detalle de fondo de caja chica. | `layouts.app` |
| | `CashFund\Approvals` | `/cashfund/approvals` | Aprobaciones de fondo de caja chica. | `layouts.app` |
| **Transferencias** | `Transfers\Index` | `/transfers` | Listado de transferencias. | `layouts.app` |
| | `Transfers\Create` | `/transfers/create` | Creación de transferencia. | `layouts.app` |
| | `Inventory\TransferDetail` | `/transfers/{id}/detail` | Detalle de transferencia. | `layouts.app` |
| **Reportes** | `placeholder.blade.php` | `/reportes` | Vista placeholder para reportes. | `layouts.app` |
| **Admin** | `placeholder.blade.php` | `/admin` | Vista placeholder para administración. | `layouts.app` |

## 3. Arquitectura UI y Navegación

### 3.1. Layouts y Vistas Parciales

- **`layouts/app.blade.php`**: Layout principal para usuarios autenticados. Incluye la barra de navegación, menú lateral y el contenido principal.
- **`layouts/guest.blade.php`**: Layout para vistas públicas como login y registro.
- **`partials/`**: Contiene vistas parciales reutilizables (ej. `_header.blade.php`, `_sidebar.blade.php`).
- **`components/`**: Componentes de Blade reutilizables (ej. `button.blade.php`, `modal.blade.php`).

### 3.2. Flujo de Navegación Post-Login

1.  El usuario inicia sesión y es redirigido a `/dashboard`.
2.  El `dashboard` presenta un resumen general y accesos directos a los módulos principales.
3.  El menú lateral (definido en `partials/_sidebar.blade.php`) permite la navegación a los diferentes módulos (Compras, Inventario, etc.).
4.  Cada módulo tiene una página de inicio (generalmente estática) que a su vez enlaza a las vistas dinámicas gestionadas por Livewire.

## 4. Conexiones Livewire -> Backend

- Los componentes Livewire se comunican con el backend a través de `wire:model` para el bindeo de datos y `wire:click` para la ejecución de acciones.
- La mayoría de los componentes Livewire son de página completa, gestionando la totalidad de la vista.
- Se observa un uso consistente de `Route::get('/ruta', ComponenteLivewire::class)`, lo que indica que Livewire gestiona la renderización completa de la página.

## 5. Vistas Pendientes o Incompletas

- **`compras.blade.php`, `inventario.blade.php`, `produccion.blade.php`, `recetas.blade.php`**: Parecen ser vistas estáticas que actúan como páginas de inicio para los módulos, pero no contienen lógica dinámica.
- **`placeholder.blade.php`**: Utilizado para las secciones de Reportes y Admin, indicando que estas áreas aún no han sido desarrolladas.
- **`under-construction.blade.php`**: Vista genérica para funcionalidades en desarrollo.

## 6. Recomendaciones de Estructura

### 6.1. Reorganización de Carpetas

La estructura actual de `resources/views` y `app/Livewire` es modular y está bien organizada. Se recomienda mantener esta estructura y continuar agrupando los componentes y vistas por módulo.

**`resources/views/` (Estructura recomendada)**
```
resources/views/
├── modules/
│   ├── inventory/
│   ├── purchasing/
│   ├── production/
│   ├── recipes/
│   └── reports/
├── layouts/
├── partials/
└── components/
```

**`app/Livewire/` (Estructura recomendada)**
```
app/Livewire/
├── Inventory/
├── Purchasing/
├── Production/
├── Recipes/
└── Shared/
```

### 6.2. Layout Base Optimizado

Se recomienda un layout base (`layouts/app.blade.php`) que incluya:

- **Header:** Con notificaciones, perfil de usuario y selector de sucursal.
- **Sidebar:** Menú de navegación principal, colapsable.
- **Main Content:** Área principal donde se renderizan los componentes Livewire.
- **Footer:** Información de la aplicación y enlaces de interés.

Componentes compartidos a desarrollar:

- **Alertas/Notificaciones:** Un componente Livewire para mostrar notificaciones (éxito, error, advertencia) en tiempo real.
- **Modal Genérico:** Un componente Blade/Alpine.js para la creación de modales.
- **Loader/Spinner:** Un indicador de carga global para las acciones de Livewire.

### 6.3. Mejoras UX

- **Consistencia en la interfaz:** Estandarizar el uso de botones, formularios y tablas en todos los módulos.
- **Feedback al usuario:** Proveer feedback visual inmediato en las acciones (ej. mostrar un spinner al hacer click en un botón).
- **Carga progresiva:** Utilizar `wire:poll` para actualizar datos en tiempo real donde sea necesario (ej. dashboards, alertas).
- **Optimización de rendimiento:** Utilizar `wire:loading` para deshabilitar botones y formularios durante la carga, y `wire:defer` para optimizar el bindeo de datos.
