# Sistema de Colores y Variables CSS
**Fecha**: 26-Nov-2025

## Paleta de Colores

### Colores Primarios (Verde Corporativo)
| Variable | Hex | Uso |
|----------|-----|-----|
| `--color-primary-600` | #234330 | Color principal de marca |
| `--color-primary-500` | #3a916d | Hover states y acentos |
| `--color-primary-700` | #1e3a2a | Títulos en fondos claros |

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
| Variable | Hex | Uso |
|----------|-----|-----|
| `--color-secondary-500` | #e97a3a | Acento principal |
| `--color-secondary-600` | #d4581f | Hover/active |
| `--color-secondary-400` | #f58246 | Fondos suaves |

### Colores de Estado
| Estado | Variable | Cuándo usar |
|--------|----------|-------------|
| Éxito | `--color-success` | Operaciones completadas |
| Advertencia | `--color-warning` | Alertas que requieren atención |
| Peligro | `--color-danger` | Errores o acciones destructivas |
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
| `--shadow-sm` | 0 1px 3px... | Cards normales, tablas |
| `--shadow-md` | 0 4px 6px... | Cards elevados, dropdowns |
| `--shadow-lg` | 0 10px 15px... | Modales, overlays |

## Variables de Espaciado

Escala de 4px:
- `--spacing-1` = 4px
- `--spacing-2` = 8px
- `--spacing-3` = 12px
- `--spacing-4` = 16px
- `--spacing-5` = 20px
- `--spacing-6` = 24px
- `--spacing-8` = 32px
- `--spacing-10` = 40px

**Guía de uso:**
- Padding interno de cards: `--spacing-5` (20px)
- Margen entre secciones: `--spacing-6` (24px)
- Gap entre elementos: `--spacing-3` (12px)

## Tipografía
- Sans principal: `--font-sans` (`'Montserrat', 'Segoe UI', Arial, sans-serif`)
- Heading: `--font-heading` (`'Anton', sans-serif`)
- Mono: `--font-mono` (`'Consolas', 'Monaco', monospace`)

Escala:
- `--text-sm` = 0.875rem
- `--text-base` = 1rem
- `--text-2xl` = 1.5rem
- `--text-4xl` = 2.25rem

## Border Radius
- `--radius-sm` = 4px
- `--radius-md` = 8px
- `--radius-lg` = 16px
- `--radius-xl` = 24px
- `--radius-full` = 9999px

## Transiciones
- `--transition-fast` = 150ms ease
- `--transition-base` = 250ms ease
- `--transition-slow` = 350ms ease
