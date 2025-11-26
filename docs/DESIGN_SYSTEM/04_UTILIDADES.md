# Clases Utilitarias

## Espaciado

Escala basada en 4px:
- `--spacing-1` = 4px
- `--spacing-2` = 8px
- `--spacing-3` = 12px
- `--spacing-4` = 16px
- `--spacing-5` = 20px
- `--spacing-6` = 24px
- `--spacing-8` = 32px
- `--spacing-10` = 40px

### Márgenes
```html
<div class="mt-4">  <!-- margin-top: 16px -->
<div class="mb-3">  <!-- margin-bottom: 12px -->
<div class="mx-2">  <!-- margin-left y margin-right: 8px -->
<div class="my-5">  <!-- margin-top y margin-bottom: 20px -->
```

Sufijos disponibles:
- `t` (top), `b` (bottom), `l` (left), `r` (right), `x` (left/right), `y` (top/bottom)
- Valores: 1, 2, 3, 4, 5, 6, 8, 10

### Paddings
```html
<div class="pt-4">  <!-- padding-top: 16px -->
<div class="px-5">  <!-- padding-left y padding-right: 20px -->
<div class="py-6">  <!-- padding-top y padding-bottom: 24px -->
```

## Colores de Texto

| Clase | Color | Uso |
|-------|-------|-----|
| `.text-primary` | Verde oscuro | Textos importantes, títulos |
| `.text-secondary` | Naranja | Acentos, CTAs |
| `.text-success` | Verde | Mensajes de éxito |
| `.text-warning` | Naranja | Advertencias |
| `.text-danger` | Rojo | Errores |
| `.text-info` | Azul | Información |
| `.text-muted` | Gris | Textos secundarios |

**Ejemplo:**
```blade
<p class="text-primary">Texto en color primario</p>
<small class="text-muted">Nota secundaria</small>
```

## Fondos
- `.bg-primary`, `.bg-primary-light`
- `.bg-secondary`, `.bg-secondary-light`
- `.bg-success`, `.bg-warning`, `.bg-danger`, `.bg-info`
- `.bg-muted`

## Sombras
- `.shadow-sm`, `.shadow-md`, `.shadow-lg`, `.shadow-none`

## Border Radius
- `.rounded-sm`, `.rounded-md`, `.rounded-lg`, `.rounded-xl`, `.rounded-full`
