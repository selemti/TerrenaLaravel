# Componentes Blade - Guía de Uso

## Card Component

### Descripción
Contenedor versátil para agrupar contenido relacionado con variantes elevadas, bordes y padding configurable.

### Ubicación
`resources/views/components/card.blade.php`

### Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `variant` | string | 'default' | Variante visual: `default`, `elevated`, `bordered` |
| `padding` | string | 'normal' | Padding interno: `none`, `sm`, `normal`, `lg` |
| `borderColor` | string | null | Color de borde izquierdo: `primary`, `secondary`, `success`, `warning`, `danger`, `info` |

### Slots

| Slot | Opcional | Descripción |
|------|----------|-------------|
| `default` | No | Contenido principal del card |
| `header` | Sí | Encabezado del card |
| `footer` | Sí | Pie del card |

### Ejemplos de Uso

#### Card básico
```blade
<x-card>
    <p>Contenido del card</p>
</x-card>
```

#### Card elevado con header
```blade
<x-card variant="elevated">
    <x-slot name="header">
        <h5 class="mb-0">Título del Card</h5>
    </x-slot>

    <p>Contenido principal aquí...</p>
</x-card>
```

#### Card con borde de color
```blade
<x-card variant="elevated" borderColor="primary">
    <h6>Inventario</h6>
    <p>Estadísticas de inventario...</p>
</x-card>
```

#### Card sin padding (para tablas)
```blade
<x-card padding="none">
    <div class="table-responsive">
        <table class="table mb-0">
            ...
        </table>
    </div>
</x-card>
```

### CSS Relacionado
- `.card-ds` - Clase base
- `.card-ds--elevated` - Con sombra y efecto hover
- `.card-ds--bordered` - Con borde
- `.card-ds--border-{color}` - Borde izquierdo de color

### Usado en
- Pendiente de migrar (dashboard e inventario)

---

## KPI Card Component

### Descripción
Tarjeta de métrica con icono, valor prominente y helper, con variantes de color según el estado.

### Ubicación
`resources/views/components/kpi-card.blade.php`

### Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `icon` | string | 'fa-chart-line' | Icono FontAwesome sólido |
| `label` | string | — | Etiqueta de la métrica |
| `value` | string | '—' | Valor principal a mostrar |
| `helper` | string | null | Texto secundario (ej. descripción corta) |
| `variant` | string | 'primary' | `primary`, `success`, `warning`, `info`, `danger`, `neutral` |
| `badge` | string | null | Texto breve en la esquina superior derecha |

### Ejemplos de Uso

#### KPI primario
```blade
<x-kpi-card
    icon="fa-sack-dollar"
    label="Ventas de hoy"
    value="$123,450"
    helper="Actualizado hace 5 min"
/>
```

#### KPI de éxito con badge
```blade
<x-kpi-card
    variant="success"
    icon="fa-boxes"
    label="Ítems distintos"
    :value="$itemsDistintos"
    badge="Al día"
/>
```

#### KPI de advertencia
```blade
<x-kpi-card
    variant="warning"
    icon="fa-triangle-exclamation"
    label="Bajo stock"
    :value="$bajoStock"
    helper="Revise reposición"
/>
```

### CSS Relacionado
- `.kpi-card` base con sombra suave y borde izquierdo coloreado
- `.kpi-card--{variant}` aplica color de acento (primary, success, warning, danger, info, neutral)
- `.kpi-card__icon`, `__value`, `__helper`, `__badge`

### Usado en
- Pendiente de migrar (dashboard e inventario)

---

## Badge Component

### Descripción
Chips/badges para estados y etiquetas con soporte para colores semánticos e iconos.

### Ubicación
`resources/views/components/badge.blade.php`

### Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `type` | string | 'neutral' | `primary`, `secondary`, `success`, `warning`, `danger`, `info`, `neutral` |
| `icon` | string | null | Clase FontAwesome sólida opcional |
| `pill` | bool | false | Si es true, aplica borde redondeado completo |

### Ejemplos de Uso

```blade
<x-badge type="success" icon="fa-circle-check">Activo</x-badge>
<x-badge type="warning" pill>Caducidad &lt; 15 días</x-badge>
<x-badge type="danger" icon="fa-triangle-exclamation">Error</x-badge>
```

### CSS Relacionado
- `.badge-ds` base
- `.badge-ds--{type}` para variantes de color
- `.badge-ds--pill` para forma redondeada

### Usado en
- Pendiente de migrar (inventario y transferencias)

---

## Button Component

### Descripción
Botón estilizado con variantes sólidas, outline y ghost, compatible con iconos y tamaños.

### Ubicación
`resources/views/components/button.blade.php`

### Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `variant` | string | 'primary' | `primary`, `secondary`, `danger`, `outline`, `ghost` |
| `size` | string | 'md' | `sm`, `md`, `lg` |
| `icon` | string | null | Clase FontAwesome sólida opcional |
| `iconPosition` | string | 'left' | `left` o `right` |
| `block` | bool | false | True para ancho completo (`w-100`) |

### Ejemplos de Uso

```blade
<x-button icon="fa-plus">Nuevo</x-button>
<x-button variant="secondary" size="sm" icon="fa-filter" iconPosition="right">Filtros</x-button>
<x-button variant="outline" block>Exportar</x-button>
<x-button variant="danger" icon="fa-trash">Eliminar</x-button>
```

### CSS Relacionado
- `.btn-ds` base con radios y transiciones
- `.btn-ds--{variant}` para colores
- `.btn-ds--sm|md|lg` para tamaños

### Usado en
- Pendiente de migrar (botones de acciones en tablas y filtros)

---

## Stat Component

### Descripción
Bloque compacto para mostrar valores con etiqueta, subtexto y tendencia opcional.

### Ubicación
`resources/views/components/stat.blade.php`

### Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `label` | string | — | Título de la estadística |
| `value` | string | '—' | Valor principal |
| `subtext` | string | null | Texto secundario |
| `icon` | string | null | Icono FontAwesome opcional |
| `trend` | string | null | Texto de tendencia (ej. `+12%`) |
| `trendDirection` | string | 'up' | `up`, `down`, `flat` ajusta color e icono |

### Ejemplos de Uso

```blade
<x-stat label="Ticket promedio" value="$240.50" subtext="Últimos 7 días" trend="+4.2%" />
<x-stat label="Variación inventario" value="-32" trend="-12%" trendDirection="down" icon="fa-boxes-stacked" />
<x-stat label="Órdenes pendientes" value="18" subtext="En preparación" trendDirection="flat" trend="=0%" />
```

### CSS Relacionado
- `.stat-ds` base con borde suave
- `.stat-ds__trend--up|down|flat` para color de tendencia

### Usado en
- Pendiente de migrar (tablas de KPIs y resúmenes)

---

## Alert Component

### Descripción
Alertas semánticas con icono, color y opción dismissible compatibles con Bootstrap JS (`data-bs-dismiss`).

### Ubicación
`resources/views/components/alert.blade.php`

### Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `type` | string | 'info' | `info`, `success`, `warning`, `danger`, `neutral` |
| `icon` | string | null | Sobrescribe el icono por defecto |
| `dismissible` | bool | false | Muestra botón de cierre |

### Ejemplos de Uso

```blade
<x-alert type="info">Se generó el reporte correctamente.</x-alert>
<x-alert type="warning" dismissible>Revise transferencias pendientes.</x-alert>
<x-alert type="danger" icon="fa-bolt">Error al sincronizar con ERP.</x-alert>
```

### CSS Relacionado
- `.alert-ds` base
- `.alert-ds--{type}` para esquema de color
- `.alert-ds__icon`, `__content`, `__close`

### Usado en
- Pendiente de migrar (notificaciones de inventario y dashboard)
