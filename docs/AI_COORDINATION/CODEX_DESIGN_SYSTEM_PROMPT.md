# CODEX PROMPT: DESIGN SYSTEM PROFESIONAL - Terrena POS
**Fecha**: 26-Nov-2025
**Proyecto**: TerrenaLaravel - Sistema POS Multi-Almacén
**Coordinador**: Claude Code (CLAUDE-WORKER-FRONTEND-V4.1)

---

## 🎯 OBJETIVO

Crear un **Sistema de Diseño (Design System)** profesional y consistente para Terrena POS, mejorando significativamente la apariencia y usabilidad de toda la interfaz.

---

## 🚨 REGLA CRÍTICA: DOCUMENTACIÓN INCREMENTAL

**MUY IMPORTANTE - LEE ESTO PRIMERO:**

- ✅ **DEBES DOCUMENTAR CADA PASO ANTES DE CONTINUAR AL SIGUIENTE**
- ✅ **NO ESPERES AL FINAL para documentar**
- ✅ **CADA VEZ que completes una fase, actualiza el archivo de documentación**
- ✅ **La documentación es TAN IMPORTANTE como el código**

**Formato de trabajo:**
```
1. Analizar componente X → Documentar hallazgos inmediatamente
2. Crear componente Y → Documentar uso y ejemplos inmediatamente
3. Implementar CSS Z → Documentar clases y variables inmediatamente
```

**Archivo principal de documentación:**
`docs/DESIGN_SYSTEM/README.md` (crear desde el inicio)

---

## 📋 FASE 1: ANÁLISIS Y AUDITORÍA (30 min)

### Tareas:
1. **Revisar archivos actuales:**
   - `resources/views/layouts/terrena.blade.php`
   - `public/assets/css/terrena.css`
   - `resources/views/livewire/inventory/items-index.blade.php`
   - `resources/views/livewire/transfers/index.blade.php`
   - `resources/views/dashboard.blade.php`

2. **Identificar inconsistencias:**
   - Estilos duplicados
   - Componentes sin estandarizar
   - Colores usados sin variables CSS
   - Espaciado inconsistente
   - Tipografía sin jerarquía

3. **📝 DOCUMENTAR INMEDIATAMENTE:**

**Crear archivo:** `docs/DESIGN_SYSTEM/01_AUDITORIA_UI.md`

**Contenido esperado:**
```markdown
# Auditoría de UI Actual - Terrena POS
**Fecha**: [fecha]
**Analista**: CODEX

## Problemas Identificados

### 1. Inconsistencia en Cards
**Archivos afectados:**
- `resources/views/livewire/inventory/items-index.blade.php` (línea 6)
- `resources/views/dashboard.blade.php` (línea 29)

**Problema:**
- Items usa: `<div class="card mb-3">`
- Dashboard usa: `<div class="card-kpi">` (custom)

**Impacto:** Usuarios ven estilos diferentes sin razón

**Propuesta:** Estandarizar en componente `<x-card>`

---

### 2. KPIs sin diseño profesional
**Archivo:** `resources/views/livewire/inventory/items-index.blade.php` (líneas 44-57)

**Código actual:**
```blade
<div class="p-3 border rounded">
    Ítems distintos<br>
    <span class="fs-4 fw-bold">{{ $itemsDistintos }}</span>
</div>
```

**Problemas:**
- Muy básico, sin iconos
- Border genérico sin color
- Sin jerarquía visual

**Propuesta:** Crear componente `<x-kpi-card>` con:
- Icono configurable
- Colores de acento
- Animaciones sutiles
- Tooltip opcional

---

[... continuar con TODOS los problemas encontrados ...]
```

**⏸️ PAUSA AQUÍ: NO CONTINÚES A FASE 2 HASTA COMPLETAR ESTA DOCUMENTACIÓN**

---

## 📋 FASE 2: SISTEMA DE COLORES Y VARIABLES (30 min)

### Tareas:
1. **Crear paleta de colores profesional:**
   - Colores primarios/secundarios
   - Estados (success, warning, danger, info)
   - Grises (50, 100, 200, ..., 900)
   - Colores de texto (primary, secondary, muted)

2. **Actualizar CSS con variables:**

**Archivo:** `public/assets/css/design-system.css` (nuevo)

```css
/**
 * Terrena POS - Design System
 * Variables de color y sistema de diseño
 */

:root {
  /* === COLORES PRIMARIOS === */
  --color-primary-50: #f0f9f4;
  --color-primary-100: #dbf0e4;
  --color-primary-200: #b9e1cd;
  --color-primary-300: #8ccaad;
  --color-primary-400: #5cad88;
  --color-primary-500: #3a916d;
  --color-primary-600: #234330;  /* Principal - Verde oscuro */
  --color-primary-700: #1e3a2a;
  --color-primary-800: #1a2f23;
  --color-primary-900: #15271d;

  /* === COLORES SECUNDARIOS === */
  --color-secondary-50: #fef5ee;
  --color-secondary-100: #fde8d7;
  --color-secondary-200: #fbcdae;
  --color-secondary-300: #f8ab7b;
  --color-secondary-400: #f58246;
  --color-secondary-500: #e97a3a;  /* Naranja acento */
  --color-secondary-600: #d4581f;
  --color-secondary-700: #b0421a;
  --color-secondary-800: #8d361c;
  --color-secondary-900: #732f19;

  /* === COLORES DE ESTADO === */
  --color-success: #10b981;
  --color-success-light: #d1fae5;
  --color-success-dark: #065f46;

  --color-warning: #f59e0b;
  --color-warning-light: #fef3c7;
  --color-warning-dark: #92400e;

  --color-danger: #ef4444;
  --color-danger-light: #fee2e2;
  --color-danger-dark: #991b1b;

  --color-info: #3b82f6;
  --color-info-light: #dbeafe;
  --color-info-dark: #1e40af;

  /* === GRISES === */
  --color-gray-50: #f9fafb;
  --color-gray-100: #f3f4f6;
  --color-gray-200: #e5e7eb;
  --color-gray-300: #d1d5db;
  --color-gray-400: #9ca3af;
  --color-gray-500: #6b7280;
  --color-gray-600: #4b5563;
  --color-gray-700: #374151;
  --color-gray-800: #1f2937;
  --color-gray-900: #111827;

  /* === SOMBRAS === */
  --shadow-xs: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-sm: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1);

  /* === ESPACIADO === */
  --spacing-1: 0.25rem;  /* 4px */
  --spacing-2: 0.5rem;   /* 8px */
  --spacing-3: 0.75rem;  /* 12px */
  --spacing-4: 1rem;     /* 16px */
  --spacing-5: 1.25rem;  /* 20px */
  --spacing-6: 1.5rem;   /* 24px */
  --spacing-8: 2rem;     /* 32px */
  --spacing-10: 2.5rem;  /* 40px */

  /* === TIPOGRAFÍA === */
  --font-sans: 'Montserrat', 'Segoe UI', Arial, sans-serif;
  --font-heading: 'Anton', sans-serif;
  --font-mono: 'Consolas', 'Monaco', monospace;

  --text-xs: 0.75rem;    /* 12px */
  --text-sm: 0.875rem;   /* 14px */
  --text-base: 1rem;     /* 16px */
  --text-lg: 1.125rem;   /* 18px */
  --text-xl: 1.25rem;    /* 20px */
  --text-2xl: 1.5rem;    /* 24px */
  --text-3xl: 1.875rem;  /* 30px */
  --text-4xl: 2.25rem;   /* 36px */

  /* === BORDER RADIUS === */
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 1rem;
  --radius-xl: 1.5rem;
  --radius-full: 9999px;

  /* === TRANSICIONES === */
  --transition-fast: 150ms ease;
  --transition-base: 250ms ease;
  --transition-slow: 350ms ease;
}
```

3. **📝 DOCUMENTAR INMEDIATAMENTE:**

**Actualizar archivo:** `docs/DESIGN_SYSTEM/02_COLORES_Y_VARIABLES.md`

```markdown
# Sistema de Colores y Variables CSS
**Fecha**: [fecha]

## Paleta de Colores

### Colores Primarios (Verde Corporativo)
| Variable | Hex | Uso |
|----------|-----|-----|
| `--color-primary-600` | #234330 | Color principal de marca |
| `--color-primary-500` | #3a916d | Hover states |
| `--color-primary-700` | #1e3a2a | Textos sobre fondos claros |

**Ejemplos de uso:**
```css
.btn-primary {
  background-color: var(--color-primary-600);
}
.btn-primary:hover {
  background-color: var(--color-primary-500);
}
```

### Colores Secundarios (Naranja Acento)
[... documentar cada color ...]

### Colores de Estado
| Estado | Variable | Cuándo usar |
|--------|----------|-------------|
| Éxito | `--color-success` | Operaciones completadas |
| Advertencia | `--color-warning` | Alertas que requieren atención |
| Peligro | `--color-danger` | Errores, acciones destructivas |
| Información | `--color-info` | Mensajes informativos |

**Ejemplos en componentes:**
```blade
{{-- Badge de estado POSTEADO --}}
<span class="badge" style="background-color: var(--color-success)">
    Posteado
</span>
```

## Sistema de Sombras

| Variable | Valor | Uso recomendado |
|----------|-------|-----------------|
| `--shadow-sm` | 0 1px 3px... | Cards normales |
| `--shadow-md` | 0 4px 6px... | Cards elevados, dropdowns |
| `--shadow-lg` | 0 10px 15px... | Modales, overlays |

## Variables de Espaciado

Todos los espaciados siguen escala de 4px:
- `--spacing-1` = 4px
- `--spacing-2` = 8px
- `--spacing-4` = 16px
- etc.

**Guía de uso:**
- Padding interno de cards: `--spacing-5` (20px)
- Margen entre secciones: `--spacing-6` (24px)
- Gap entre elementos: `--spacing-3` (12px)
```

**⏸️ PAUSA AQUÍ: NO CONTINÚES A FASE 3 HASTA COMPLETAR ESTA DOCUMENTACIÓN**

---

## 📋 FASE 3: COMPONENTES BLADE REUTILIZABLES (1.5 horas)

### Tareas:
1. **Crear componentes base:**

**Componente 1: Card**
**Archivo:** `resources/views/components/card.blade.php`

```blade
@props([
    'variant' => 'default', // default, elevated, bordered
    'padding' => 'normal',  // none, sm, normal, lg
    'borderColor' => null,  // primary, secondary, success, etc.
])

@php
$classes = 'card-ds';

// Variantes
$classes .= match($variant) {
    'elevated' => ' card-ds--elevated',
    'bordered' => ' card-ds--bordered',
    default => ''
};

// Padding
$classes .= match($padding) {
    'none' => ' p-0',
    'sm' => ' p-3',
    'lg' => ' p-5',
    default => ' p-4'
};

// Border color
if ($borderColor) {
    $classes .= ' card-ds--border-' . $borderColor;
}
@endphp

<div {{ $attributes->merge(['class' => $classes]) }}>
    @isset($header)
        <div class="card-ds__header">
            {{ $header }}
        </div>
    @endisset

    <div class="card-ds__body">
        {{ $slot }}
    </div>

    @isset($footer)
        <div class="card-ds__footer">
            {{ $footer }}
        </div>
    @endisset
</div>
```

**CSS correspondiente en `design-system.css`:**
```css
/* === COMPONENTE: CARD === */
.card-ds {
  background: white;
  border-radius: var(--radius-lg);
  transition: transform var(--transition-base), box-shadow var(--transition-base);
}

.card-ds--elevated {
  box-shadow: var(--shadow-md);
}

.card-ds--elevated:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-2px);
}

.card-ds--bordered {
  border: 1px solid var(--color-gray-200);
}

.card-ds--border-primary {
  border-left: 4px solid var(--color-primary-600);
}

.card-ds--border-secondary {
  border-left: 4px solid var(--color-secondary-500);
}

.card-ds__header {
  padding: var(--spacing-4) var(--spacing-5);
  border-bottom: 1px solid var(--color-gray-100);
  font-weight: 600;
  color: var(--color-gray-900);
}

.card-ds__body {
  /* El padding se controla con la prop 'padding' */
}

.card-ds__footer {
  padding: var(--spacing-4) var(--spacing-5);
  border-top: 1px solid var(--color-gray-100);
  background: var(--color-gray-50);
  border-radius: 0 0 var(--radius-lg) var(--radius-lg);
}
```

2. **📝 DOCUMENTAR INMEDIATAMENTE:**

**Actualizar:** `docs/DESIGN_SYSTEM/03_COMPONENTES.md`

```markdown
# Componentes Blade - Guía de Uso

## Card Component

### Descripción
Contenedor versátil para agrupar contenido relacionado.

### Ubicación
`resources/views/components/card.blade.php`

### Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `variant` | string | 'default' | Variante visual: `default`, `elevated`, `bordered` |
| `padding` | string | 'normal' | Padding interno: `none`, `sm`, `normal`, `lg` |
| `borderColor` | string | null | Color de borde izquierdo: `primary`, `secondary`, etc. |

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
- `resources/views/dashboard.blade.php`
- `resources/views/livewire/inventory/items-index.blade.php`
- [actualizar conforme se migre]

---

[... continuar documentando cada componente ...]
```

**⏸️ PAUSA: Documentar CADA componente antes de crear el siguiente**

3. **Componentes a crear (documentar UNO POR UNO):**

- ✅ `<x-card>` (documentar primero)
- ✅ `<x-kpi-card>` (documentar después de crear)
- ✅ `<x-badge>` (documentar después de crear)
- ✅ `<x-button>` (documentar después de crear)
- ✅ `<x-stat>` (documentar después de crear)
- ✅ `<x-alert>` (documentar después de crear)

---

## 📋 FASE 4: CLASES UTILITARIAS CSS (45 min)

### Tareas:
1. **Crear sistema de utilidades:**

**Archivo:** `public/assets/css/utilities.css` (nuevo)

```css
/**
 * Terrena POS - Utilities
 * Clases utilitarias para uso común
 */

/* === ESPACIADO === */
.mt-1 { margin-top: var(--spacing-1) !important; }
.mt-2 { margin-top: var(--spacing-2) !important; }
.mt-3 { margin-top: var(--spacing-3) !important; }
.mt-4 { margin-top: var(--spacing-4) !important; }
/* ... continuar con mb-, ml-, mr-, mx-, my-, pt-, pb-, etc. */

/* === COLORES DE TEXTO === */
.text-primary { color: var(--color-primary-600) !important; }
.text-secondary { color: var(--color-secondary-500) !important; }
.text-success { color: var(--color-success) !important; }
.text-warning { color: var(--color-warning) !important; }
.text-danger { color: var(--color-danger) !important; }
.text-muted { color: var(--color-gray-500) !important; }

/* === FONDOS === */
.bg-primary { background-color: var(--color-primary-600) !important; }
.bg-primary-light { background-color: var(--color-primary-50) !important; }
/* ... continuar */

/* === SOMBRAS === */
.shadow-sm { box-shadow: var(--shadow-sm) !important; }
.shadow-md { box-shadow: var(--shadow-md) !important; }
.shadow-lg { box-shadow: var(--shadow-lg) !important; }
.shadow-none { box-shadow: none !important; }

/* === BORDER RADIUS === */
.rounded-sm { border-radius: var(--radius-sm) !important; }
.rounded-md { border-radius: var(--radius-md) !important; }
.rounded-lg { border-radius: var(--radius-lg) !important; }
.rounded-full { border-radius: var(--radius-full) !important; }
```

2. **📝 DOCUMENTAR INMEDIATAMENTE:**

**Crear:** `docs/DESIGN_SYSTEM/04_UTILIDADES.md`

```markdown
# Clases Utilitarias

## Espaciado

Todas las clases de espaciado siguen la escala de 4px:

### Márgenes
```html
<div class="mt-4">  <!-- margin-top: 16px -->
<div class="mb-3">  <!-- margin-bottom: 12px -->
<div class="mx-2">  <!-- margin-left y margin-right: 8px -->
<div class="my-5">  <!-- margin-top y margin-bottom: 20px -->
```

Sufijos disponibles:
- `t` - top
- `b` - bottom
- `l` - left
- `r` - right
- `x` - left y right
- `y` - top y bottom

Valores: 1, 2, 3, 4, 5, 6, 8, 10

### Paddings
Mismo sistema que márgenes, con prefijo `p`:
```html
<div class="pt-4">  <!-- padding-top: 16px -->
<div class="px-5">  <!-- padding-left y padding-right: 20px -->
```

## Colores de Texto

| Clase | Color | Uso |
|-------|-------|-----|
| `.text-primary` | Verde oscuro | Textos importantes, títulos |
| `.text-secondary` | Naranja | Acentos, CTAs |
| `.text-success` | Verde | Mensajes de éxito |
| `.text-warning` | Naranja | Advertencias |
| `.text-danger` | Rojo | Errores |
| `.text-muted` | Gris | Textos secundarios |

**Ejemplo:**
```blade
<p class="text-primary">Texto en color primario</p>
<small class="text-muted">Nota secundaria</small>
```

## Fondos

[... continuar documentando ...]
```

**⏸️ PAUSA AQUÍ**

---

## 📋 FASE 5: MIGRACIÓN DE COMPONENTES EXISTENTES (1 hora)

### Tareas:
1. **Migrar componente por componente:**

**Ejemplo: Migrar KPIs del Dashboard**

**ANTES (dashboard.blade.php):**
```blade
<div class="p-3 border rounded">
    Ítems distintos<br>
    <span class="fs-4 fw-bold">{{ $itemsDistintos }}</span>
</div>
```

**DESPUÉS:**
```blade
<x-kpi-card
    icon="fa-boxes"
    label="Ítems distintos"
    value="{{ $itemsDistintos }}"
    variant="primary"
/>
```

2. **📝 DOCUMENTAR CADA MIGRACIÓN:**

**Actualizar:** `docs/DESIGN_SYSTEM/05_MIGRACIONES.md`

```markdown
# Log de Migraciones

## Dashboard - KPIs (26-Nov-2025 15:30)

### Archivo: `resources/views/dashboard.blade.php`

#### Cambios realizados:
- ✅ Líneas 44-57: Reemplazados 4 divs con borders por `<x-kpi-card>`
- ✅ Agregado import de componente en layout

#### Antes:
```blade
<div class="p-3 border rounded">
    Ítems distintos<br>
    <span class="fs-4 fw-bold">{{ $itemsDistintos }}</span>
</div>
```

#### Después:
```blade
<x-kpi-card icon="fa-boxes" label="Ítems distintos" :value="$itemsDistintos" />
```

#### Beneficios:
- Código reducido en 70%
- Estilo consistente
- Más fácil de mantener

#### Problemas encontrados:
Ninguno

---

## Items Index - Tabla y filtros (26-Nov-2025 16:00)

[... siguiente migración ...]
```

**⏸️ PAUSA después de cada migración**

---

## 📋 FASE 6: GUÍA DE ESTILO Y EJEMPLOS (30 min)

**Crear:** `docs/DESIGN_SYSTEM/README.md` (índice principal)

```markdown
# Terrena POS - Sistema de Diseño

**Versión**: 1.0.0
**Última actualización**: 26-Nov-2025
**Mantenedor**: Equipo de desarrollo

## Introducción

Este Design System define los estándares visuales y componentes reutilizables para Terrena POS.

## Contenido

1. [Auditoría UI](./01_AUDITORIA_UI.md) - Problemas identificados en interfaz actual
2. [Colores y Variables](./02_COLORES_Y_VARIABLES.md) - Paleta de colores y variables CSS
3. [Componentes](./03_COMPONENTES.md) - Guía de componentes Blade
4. [Utilidades](./04_UTILIDADES.md) - Clases CSS utilitarias
5. [Migraciones](./05_MIGRACIONES.md) - Log de componentes migrados
6. [Ejemplos](./06_EJEMPLOS.md) - Patrones comunes de UI

## Inicio Rápido

### Instalación
Los archivos del Design System ya están incluidos en el proyecto:

```blade
{{-- En layouts/terrena.blade.php --}}
<link href="{{ asset('assets/css/design-system.css') }}" rel="stylesheet">
<link href="{{ asset('assets/css/utilities.css') }}" rel="stylesheet">
```

### Uso básico

```blade
{{-- Card simple --}}
<x-card>
    <p>Contenido</p>
</x-card>

{{-- KPI --}}
<x-kpi-card icon="fa-boxes" label="Stock" value="1,234" />

{{-- Badge --}}
<x-badge type="success">Activo</x-badge>
```

## Principios de Diseño

1. **Consistencia**: Mismos componentes para mismas funciones
2. **Simplicidad**: Interfaces limpias y fáciles de usar
3. **Accesibilidad**: Diseño inclusivo para todos los usuarios
4. **Escalabilidad**: Componentes reutilizables y mantenibles

## Soporte

Para preguntas sobre el Design System, consulta la documentación o contacta al equipo de desarrollo.
```

---

## ✅ CHECKLIST FINAL

Antes de dar por completado, verificar:

- [ ] Todos los archivos de documentación creados
- [ ] Cada componente tiene ejemplos de uso
- [ ] Variables CSS documentadas con ejemplos
- [ ] Migraciones registradas con antes/después
- [ ] README principal con índice completo
- [ ] Componentes probados en al menos 2 vistas diferentes

---

## 📊 ENTREGABLES ESPERADOS

Al finalizar, CODEX debe haber creado:

### Archivos de código:
1. `public/assets/css/design-system.css` (sistema de variables)
2. `public/assets/css/utilities.css` (clases utilitarias)
3. `resources/views/components/card.blade.php`
4. `resources/views/components/kpi-card.blade.php`
5. `resources/views/components/badge.blade.php`
6. `resources/views/components/button.blade.php`
7. `resources/views/components/stat.blade.php`
8. `resources/views/components/alert.blade.php`

### Archivos de documentación (CRÍTICO):
1. `docs/DESIGN_SYSTEM/README.md`
2. `docs/DESIGN_SYSTEM/01_AUDITORIA_UI.md`
3. `docs/DESIGN_SYSTEM/02_COLORES_Y_VARIABLES.md`
4. `docs/DESIGN_SYSTEM/03_COMPONENTES.md`
5. `docs/DESIGN_SYSTEM/04_UTILIDADES.md`
6. `docs/DESIGN_SYSTEM/05_MIGRACIONES.md`
7. `docs/DESIGN_SYSTEM/06_EJEMPLOS.md`

### Archivos migrados:
- Al menos 2 vistas actualizadas usando los nuevos componentes

---

## 🚨 RESTRICCIONES

- ❌ NO modificar base de datos
- ❌ NO ejecutar migraciones
- ❌ NO modificar lógica de backend
- ✅ SÍ modificar solo archivos CSS, Blade y documentación
- ✅ SÍ mantener compatibilidad con Bootstrap 5 existente

---

## 📞 FORMATO DE REPORTE

Al finalizar cada fase, CODEX debe reportar:

```markdown
## FASE X COMPLETADA - [Nombre Fase]

**Tiempo invertido**: [tiempo]
**Archivos creados**:
- [lista de archivos]

**Archivos modificados**:
- [lista de archivos]

**Documentación actualizada**:
- ✅ [documento 1]
- ✅ [documento 2]

**Problemas encontrados**:
- [si hubo problemas]

**Siguiente paso**:
FASE Y - [nombre siguiente fase]
```

---

**Última actualización**: 26-Nov-2025
**Preparado por**: Claude Code
**Para**: CODEX (Design System Specialist)
**Estado**: Listo para ejecución

---

## ▶️ SIGUIENTE ACCIÓN

CODEX: Iniciar con **FASE 1 - ANÁLISIS Y AUDITORÍA**

Recuerda: **DOCUMENTAR INMEDIATAMENTE** antes de pasar a la siguiente fase.
