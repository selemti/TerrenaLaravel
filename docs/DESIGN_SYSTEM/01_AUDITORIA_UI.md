# Auditoría de UI Actual - Terrena POS
**Fecha**: 26-Nov-2025  
**Analista**: CODEX

## Problemas Identificados

### 1. Inconsistencia de cards y contenedores
**Archivos afectados:**
- resources/views/livewire/inventory/items-index.blade.php:6,60
- resources/views/dashboard.blade.php:27-176
- resources/views/livewire/transfers/index.blade.php:20,38

**Problema:**
- Inventario usa `<div class="card ...">` de Bootstrap, Dashboard emplea clases custom (`card-kpi`, `card-vo`, `chart-container`) con sombras y padding distintos, y Transferencias mezcla `card shadow-sm` sin header definido.
- No hay un componente común de card que estandarice bordes, sombras y paddings.

**Impacto:** La jerarquía visual cambia entre pantallas, dificultando el reconocimiento de secciones y el mantenimiento de estilos.

**Propuesta:** Crear `<x-card>` con variantes (`default`, `elevated`, `bordered`) y props de padding/borde de color para unificar contenedores.

---

### 2. KPIs sin diseño profesional ni jerarquía
**Archivos afectados:**
- resources/views/livewire/inventory/items-index.blade.php:44-57
- resources/views/dashboard.blade.php:27-56

**Problema:**
- Inventario muestra KPIs como `div` con borde genérico (`p-3 border rounded`) sin iconos ni estados de color. Dashboard usa `card-kpi` con estilos distintos y sin variables de color.

**Impacto:** Los KPIs no comparten tipografía, colores ni layout; el usuario percibe módulos diferentes y no hay acentos visuales.

**Propuesta:** Crear `<x-kpi-card>` con icono, valor, label y variantes (`primary`, `success`, `warning`, `info`), utilizando tokens de color y sombras consistentes.

---

### 3. Colores hardcodeados y sin tokens centralizados
**Archivos afectados:**
- public/assets/css/terrena.css:1-120
- resources/views/livewire/inventory/items-index.blade.php:118-123
- resources/views/livewire/transfers/index.blade.php:61-74

**Problema:**
- `terrena.css` define colores base en `:root` pero luego se usan valores fijos (`#6c757d`, `#0d6efd`, `#198754`, bordes `var(--orange)` en todas las cards). Las badges de estado se pintan con hex inline.

**Impacto:** No hay paleta escalable ni modo de cambiar branding sin modificar múltiples archivos; los estados no siguen un sistema de semántica de color.

**Propuesta:** Definir paleta completa en `design-system.css` (primario, secundario, estados, grises) y mapear badges/estados a variables (`--color-success`, `--color-warning`, etc.).

---

### 4. Espaciados y tipografía sin escala común
**Archivos afectados:**
- public/assets/css/terrena.css:70-118
- resources/views/dashboard.blade.php:12-25
- resources/views/livewire/inventory/items-index.blade.php:6-57

**Problema:**
- Se usan clases Bootstrap (`p-3`, `mb-3`) mezcladas con paddings custom (1.25rem, 1.5rem) y sin una escala declarada. Top bar usa `font-family: 'Anton'` pero no hay tokens tipográficos ni jerarquía documentada.

**Impacto:** Inconsistencias de separación entre secciones y títulos; difícil asegurar alineación y ritmo vertical homogéneo.

**Propuesta:** Declarar escala de espaciado (`--spacing-1 ... --spacing-10`) y tipografía (`--text-sm ... --text-4xl`, `--font-sans`, `--font-heading`) en `design-system.css`, usar utilidades (`mt-*`, `pt-*`) para aplicar.

---

### 5. CSS duplicado y difícil de mantener
**Archivos afectados:**
- public/assets/css/terrena.css:54-176

**Problema:**
- El sidebar tiene definiciones repetidas (desktop y móvil) con estilos duplicados y sobrescrituras (`.sidebar` se redefine varias veces). No hay separación entre tokens, componentes y utilidades.

**Impacto:** Riesgo de efectos secundarios al ajustar estilos; aumenta el tiempo de depuración y complica la migración a un design system.

**Propuesta:** Extraer tokens a `design-system.css`, crear utilidades en `utilities.css` y refactorizar estilos de layout/componentes para evitar duplicidad.

---
