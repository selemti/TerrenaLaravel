# Log de Migraciones

## Dashboard - KPIs (26-Nov-2025)

### Archivo: `resources/views/dashboard.blade.php`

#### Cambios realizados:
- ✅ Reemplazados 5 bloques `div.card-kpi` por componentes `<x-kpi-card>` con variantes semánticas.
- ✅ IDs de métricas mantenidos (`kpi-sales-today`, `kpi-star-product`, etc.) en los componentes para compatibilidad con JS.

#### Antes:
Bloques con `.card-kpi` y texto plano sin tokens de color.

#### Después:
```blade
<x-kpi-card
  icon="fa-sack-dollar"
  label="Ventas de hoy"
  value="—"
  helper="Total vendido en el rango seleccionado"
  variant="primary"
  id="kpi-sales-today"
/>
```

#### Beneficios:
- Estilo consistente con el Design System.
- Tokens de color y sombras unificados.

#### Problemas encontrados:
Ninguno.

---

## Inventario - Items Index (26-Nov-2025)

### Archivo: `resources/views/livewire/inventory/items-index.blade.php`

#### Cambios realizados:
- ✅ Filtros envueltos en `<x-card variant="bordered">` con botón `<x-button>`.
- ✅ KPIs reemplazados por `<x-kpi-card>` con iconos y helper.
- ✅ Tabla dentro de `<x-card padding="none">` con header slot y botón `<x-button>`.
- ✅ Badges reemplazadas por `<x-badge>` semánticos para estado, tipo y perishable.

#### Antes:
`div.card` y `div` con `border rounded` para KPIs; badges con clases Bootstrap y hex en línea.

#### Después:
```blade
<x-kpi-card
    icon="fa-hourglass-half"
    label="Caducan < 15 días"
    :value="$porVencer"
    helper="Vigilar lotes"
    variant="danger"
/>
```
Badges:
```blade
<x-badge type="warning" pill icon="fa-lemon">Perecedero</x-badge>
```

#### Beneficios:
- KPI y cards alineados a tokens de color y espaciado.
- Estado y tipos usan semántica consistente; eliminación de hex hardcodeado.

#### Problemas encontrados:
Ninguno.

---

## Layout - Inclusión de assets (26-Nov-2025)

### Archivo: `resources/views/layouts/terrena.blade.php`

#### Cambios realizados:
- ✅ Se agregan `design-system.css` y `utilities.css` en el `<head>` para habilitar tokens y utilidades en todas las vistas.

#### Beneficios:
- Garantiza carga de estilos del Design System sin alterar assets legacy.

#### Problemas encontrados:
Ninguno.

---

## Personal - Gestión de usuarios/roles (26-Nov-2025)

### Archivo: `resources/views/livewire/people/users-index.blade.php`

#### Cambios realizados:
- ✅ Alertas a `<x-alert type="success" dismissible>`.
- ✅ Listado de usuarios envuelto en `<x-card>` con header y botones `<x-button>`.
- ✅ Badges de roles/estado migradas a `<x-badge>` semánticos.
- ✅ Tab de roles en `<x-card>`; contadores con badges DS.
- ✅ Tab de permisos con `<x-card>` y stats en cards DS.

#### Beneficios:
- Consistencia visual con el design system en gestión de personal.
- Eliminación de badges Bootstrap y alerts legacy.

#### Problemas encontrados:
Ninguno.
