# Frontend V4.0 · Componentes reutilizables

## 1. Propósito y fuentes

Define el design system operativo: qué componentes existen, dónde viven en código y cómo deben verse en todos los módulos. Basado en:

- `resources/views/components/ui/*` y `resources/views/components/*.blade.php`
- `public/assets/css/terrena.css` (paleta y layout)
- `docs/Front/FRONT_BLUEPRINT*.md`, `docs/UI-UX/MASTER/PROMPTS_SABADO/PROMPT_QWEN_FRONTEND_SABADO.md`

Cualquier componente nuevo debe agregarse aquí antes de merge.

## 2. Tokens visuales comunes

| Token | Valor | Uso |
|-------|-------|-----|
| Fuente principal | `'Montserrat', 'Segoe UI', Arial` (`public/assets/css/terrena.css:1-40`) | Layout Terrena, cards, dashboards. |
| Colores | `--green-dark:#234330`, `--green-darker:#1E3A2A`, `--orange:#E97A3A`, `--gold:#D2B464`, `--bg-main:#EAEAEA` | Sidebar, headings, highlights. |
| Iconografía | Font Awesome 6 (`public/assets/fontawesome-free-7.0.1-web`) | Toda iconografía; evita mezclar librerías. |
| Bordes/Shadow | `border-radius:1rem`, `box-shadow:0 4px 15px rgba(0,0,0,.05)` | Cards KPI, filtros, paneles. |

> Nunca hardcodees hex distintos en vistas; usa las variables de `terrena.css` o utilidades Tailwind/Bootstrap equivalentes.

## 3. Catálogo de componentes UI

### 3.1 Cards & contenedores

| Componente | Blade | Notas |
|------------|-------|-------|
| Card estándar | `resources/views/components/ui/card.blade.php` | Props `title`, `subtitle`, `padding`, slots `content`/`footer`. Para dashboards en Tailwind. |
| Card avanzada | `components/ui/advanced-card.blade.php` | Incluye toolbar, badges y acciones (`actions` slot). Úsala en listados complejos (Transferencias, Conteos). |
| Banners | `components/ui/banner.blade.php` | Mensajes contextuales (success/warning/info) con icono. Sustituye alerts sueltas. |

Regla: no crees `div.card` manual; wrappea tu contenido con `<x-ui.card>` y sobrescribe clases vía `$attributes`.

### 3.2 Tablas y filas

| Componente | Blade | Capacidades |
|------------|-------|-------------|
| Tabla básica | `components/ui/table.blade.php` | Recibe `headers`, slot `{{ $slot }}` para filas y `pagination`. |
| Fila flexible | `components/ui/table-row.blade.php` | Alinea celdas con utilidades `grid-cols`. Útil para tablas responsivas. |
| Tabla avanzada | `components/ui/advanced-table.blade.php` | Toolbar con filtros/search integrado; usar cuando la tabla necesita acciones masivas. |

Todas las tablas deben usar `min-w-full divide-y divide-gray-200` y alternar con `bg-white`. Evita estilos inline.

### 3.3 Modales y diálogos

| Componente | Blade | Uso |
|------------|-------|-----|
| Modal Alpine | `components/ui/modal.blade.php` | Escucha eventos `open-modal`/`close-modal`, tamaños `max-w-{lg,xl,2xl}`. |
| Modal base Bootstrap | `components/modal.blade.php` | Sólo para pantallas heredadas de Bootstrap puro. Preferir `x-ui.modal` para nuevas vistas. |
| Confirm genérico | (blueprint) `<x-confirm-modal />` (por crear) | Documentado en `FRONT_BLUEPRINT_V2`: debe heredar de `x-ui.modal`. |

Buenas prácticas:
1. Lanza eventos con `Livewire.dispatch('open-modal', { id: 'itemModal' })`.
2. No repliques markup Bootstrap en cada vista.
3. Footer obligatorio para acciones (`@slot('footer')`).

### 3.4 Formularios y entradas

| Componente | Blade | Detalle |
|------------|-------|---------|
| Inputs básicos | `components/ui/input.blade.php`, `text-input.blade.php` | Incluyen estados de error via `input-error`. |
| Campos compuestos | `components/ui/form-field.blade.php` | Label, hint y error agrupados. |
| Select / multiselect compacto | `components/ui/select.blade.php`, `components/ui/compact-multi-select.blade.php` | Multiselect usado en reportes (ver docs VentasReport). |
| Search input | `components/ui/search-input.blade.php` | Trae icono y `wire:model.debounce`. |
| Date picker | `components/ui/date-picker.blade.php` | Base para filtros temporales. |
| Botones | `components/{primary-button,secondary-button,danger-button}.blade.php` | Mantienen clases consistentes Tailwind. |
| Status badge | `components/ui/status-badge.blade.php` | Prop `type`, `status`, `withIcon`; mapea estados DRAFT/APROBADA/… a colores. |

### 3.5 Tooltips, loaders y notificaciones

- **Tooltips**: usa `data-bs-toggle="tooltip"`; el layout Terrena inicializa todo vía `window.TerrenaInitTooltips`. No montes tooltips de librerías extra.
- **Skeleton/loading**: `<x-ui.loading-skeleton />` para placeholders.
- **Toasts / notifications**: `<x-ui.toast />` y `notification-manager` (gestiona colas). Los triggers Livewire deben emitir eventos estándar (`browserEvent('notify', {...})`).
- **Banners en página**: `<x-ui.banner type="warning">` para alertas persistentes.

### 3.6 Iconografía y badges

- Icon set único: Font Awesome 6 (ya cargado por layout). Para iconos adicionales, agrega el kit al asset y documenta el uso aquí.
- Status mapping sugerido (`status-badge`):
  - `success`: verde `bg-green-100 text-green-800` para estados APROBADA/POSTEADA.
  - `warning`: amarillo para BORRADOR/EN_PROCESO.
  - `danger`: rojo para CANCELADA/RECHAZADA.
  - `info`: azul para EN_TRANSITO/DIAGNÓSTICOS.
  - `secondary`: gris para INACTIVO.

## 4. Reglas de estandarización

1. **Un solo set de componentes**: cualquier vista bajo V4.0 debe importar exclusivamente `<x-ui.*>` (o los botones `x-primary-button`). Si falta alguna variante, primero amplia el componente existente.
2. **Colores**: usa clases derivadas de Tailwind (`text-gray-500`) o variables `var(--green-dark)` desde `terrena.css`. Nada de hex arbitrarios.
3. **Espaciados**: cards usan `p-5`, tablas `px-6 py-3`, modales `px-4 py-3`. Mantén esos tokens para coherencia.
4. **Tooltips/JS**: aprovecha el inicializador global; no agregues librerías (Tippy, Popper) sin aprobación.
5. **Responsividad**: tablas y cards deben envolver su contenido en `overflow-x-auto` y `grid` siguiendo las clases definidas en los componentes.

## 5. Registro de componentes (control de cambios)

Actualiza esta tabla cada vez que modifiques un componente o crees uno nuevo. Es la “bitácora” mínima para saber qué se tocó y cuándo.

| Componente | Blade | Uso principal | Última revisión |
|------------|-------|---------------|-----------------|
| Card estándar | `components/ui/card.blade.php` | Dashboards, listados básicos | 2025-11-12 |
| Card avanzada | `components/ui/advanced-card.blade.php` | Inventario/Transferencias | 2025-11-12 |
| Tabla básica | `components/ui/table.blade.php` | Listas generales | 2025-11-12 |
| Tabla avanzada | `components/ui/advanced-table.blade.php` | Tablas con filtros | 2025-11-12 |
| Modal Alpine | `components/ui/modal.blade.php` | Formularios y confirmaciones | 2025-11-12 |
| Status badge | `components/ui/status-badge.blade.php` | Estados operativos | 2025-11-12 |
| Toast / notification manager | `components/ui/{toast,notification-manager}.blade.php` | Alertas en vivo | 2025-11-12 |
| Search input | `components/ui/search-input.blade.php` | Filtros globales | 2025-11-12 |
| Compact multiselect | `components/ui/compact-multi-select.blade.php` | Reportes Venta / filtros avanzados | 2025-11-12 |

## 6. Procedimiento para mantener el control real

1. **Antes de codificar**: revisa esta ficha y el componente existente. Si aplica, extiéndelo; si no, documenta la necesidad aquí antes de crear algo nuevo.
2. **Durante el cambio**: actualiza el componente Blade y sus pruebas/usos. Corre `php artisan view:clear` si necesitas verificar paths.
3. **Documentación obligatoria**: en cada PR que toque componentes UI:
   - Actualiza el registro anterior (fecha y, si aplica, descripción breve en el diff).
   - Añade notas en la sección correspondiente (ej. nueva prop en `<x-ui.card>`).
4. **Checklist de PR**:
   - `docs/V4.0/Frontend/Componentes.md` actualizado.
   - Capturas o GIF del componente aplicado.
   - Referencia al módulo que lo consumirá y validación en layout Terrena + responsive.
5. **Bitácora complementaria**: usa la sección “Documentos publicados / Backlog” en `docs/V4.0/README.md` para anotar cuando un componente queda listo o queda por ajustar. Opcionalmente, podemos abrir `docs/V4.0/CHANGELOG.md` para versionar componentes si necesitamos granularidad mayor.

Siguiendo este proceso, cada ajuste al sistema visual queda trazado en un único lugar y cualquier módulo nuevo sabrá qué pieza debe reutilizar.
