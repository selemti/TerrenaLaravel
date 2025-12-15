# Componentes UI Avanzados - TerrenaLaravel ERP

## Descripción General

Esta documentación detalla los componentes de interfaz de usuario avanzados desarrollados para el sistema TerrenaLaravel ERP. Estos componentes están diseñados para proporcionar una experiencia de usuario rica y consistente a lo largo de toda la aplicación.

## Componentes UI Detallados

### advanced-table.blade.php

Componente de tabla avanzada que proporciona funcionalidades como acciones en filas, acciones masivas y resposividad.

**Uso:**
```blade
<x-ui.advanced-table 
    :headers="['ID', 'Nombre', 'Categoría', 'Stock']" 
    :actions="true" 
    :bulk-actions="true"
    class="table table-striped">
    <!-- Contenido de filas aquí -->
</x-ui.advanced-table>
```

**Props:**
- `headers` (array): Array con los encabezados de la tabla
- `actions` (boolean): Mostrar columna de acciones por fila
- `bulkActions` (boolean): Habilitar acciones masivas
- `responsive` (boolean): Hacer la tabla responsive (por defecto `true`)

**Características:**
- Soporta encabezados como strings o arrays con clases personalizadas
- Incluye checkbox para selección múltiple si se habilitan acciones masivas
- Soporte para pie de tabla opcional

### form-field.blade.php

Componente versátil para campos de formulario que soporta múltiples tipos de inputs y validación.

**Uso:**
```blade
<x-ui.form-field 
    label="Nombre del Producto" 
    name="nombre" 
    type="text" 
    :value="old('nombre')" 
    placeholder="Introduce el nombre del producto"
    :required="true"
    model="product.name" />
```

**Props:**
- `label` (string): Etiqueta para el campo
- `type` (string): Tipo de input (text, select, textarea, checkbox, radio) - por defecto `text`
- `name` (string): Nombre del campo
- `id` (string): ID del campo (por defecto usa el nombre)
- `value` (mixed): Valor del campo
- `placeholder` (string): Placeholder del campo
- `required` (boolean): Indica si el campo es obligatorio
- `disabled` (boolean): Indica si el campo está deshabilitado
- `readonly` (boolean): Indica si el campo es de solo lectura
- `help` (string): Texto de ayuda
- `error` (string): Mensaje de error
- `model` (string): Modelo para integración con Livewire
- `options` (array): Opciones para campos select
- `multiple` (boolean): Indica si es multi-select
- `rows` (integer): Número de filas para textarea

**Características:**
- Soporta todos los tipos de input HTML estándar
- Integración directa con Livewire a través del atributo `model`
- Validación con estilos Bootstrap
- Soporte para select con múltiples opciones
- Soporte para textarea con filas personalizadas

### advanced-card.blade.php

Componente de tarjeta avanzada con soporte para header, body y footer.

**Props:**
- `title` (string): Título de la tarjeta
- `subtitle` (string): Subtítulo opcional
- `headerActions` (slot): Acciones en el encabezado
- `footer` (slot): Pie de página opcional

**Características:**
- Soporta slots para contenido personalizado
- Estilos de encabezado y pie de página diferenciados
- Responsive design

### loading-skeleton.blade.php

Componente para mostrar contenido de skeleton mientras se carga la información real.

**Props:**
- `type` (string): Tipo de skeleton ('card', 'text', 'list', etc.)
- `count` (integer): Número de elementos a mostrar

**Características:**
- Anima el contenido para indicar carga
- Soporta diferentes tipos de skeleton
- Responsive

### date-picker.blade.php

Selector de fechas con soporte para validación y internacionalización.

**Props:**
- `name` (string): Nombre del campo
- `value` (string): Fecha seleccionada
- `format` (string): Formato de fecha
- `minDate` (string): Fecha mínima permitida
- `maxDate` (string): Fecha máxima permitida
- `locale` (string): Localización para fechas

**Características:**
- Soporte para múltiples formatos de fecha
- Validación de fechas
- Internacionalización
- Integración con Livewire

### compact-multi-select.blade.php

Selector múltiple compacto para formularios.

**Props:**
- `name` (string): Nombre del campo
- `options` (array): Opciones disponibles
- `selected` (array): Opciones seleccionadas
- `placeholder` (string): Placeholder del campo
- `model` (string): Modelo para integración con Livewire

**Características:**
- Selector compacto para espacio limitado
- Búsqueda dentro de opciones
- Soporte para selección múltiple
- Integración Livewire

## Buenas Prácticas de Uso

### 1. Consistencia Visual
- Usar siempre los mismos componentes para elementos similares
- Mantener la jerarquía visual coherente
- Aplicar estilos predeterminados a menos que haya una razón específica para modificarlos

### 2. Accesibilidad
- Asegurar que todos los componentes sean accesibles con teclado
- Incluir etiquetas apropiadas y relaciones
- Proporcionar texto alternativo para elementos visuales

### 3. Rendimiento
- Evitar componentes innecesariamente complejos
- Implementar skeleton loading para operaciones que tomen tiempo
- Utilizar técnicas de lazy loading donde sea apropiado

### 4. Internacionalización
- Preparar todos los componentes para soporte de múltiples idiomas
- Usar claves de traducción en lugar de texto duro
- Considerar direccionalidad de idiomas (LTR/RTL)

## Integración con Livewire

Muchos de los componentes UI están diseñados para trabajar con Livewire:

```blade
<x-ui.form-field 
    label="Nombre" 
    name="name" 
    model="name" 
    type="text" 
    :required="true" />
```

La propiedad `model` permite la sincronización bidireccional de datos entre el componente Blade y el componente Livewire.

## Estilos y Temas

Los componentes siguen las siguientes convenciones de estilo:

1. **Colores**: Basados en la paleta de colores del sistema
2. **Tipografía**: Consistencia en tamaños y pesos de fuente
3. **Espaciado**: Uso de la escala de espaciado de Tailwind CSS
4. **Borde**: Uso consistente de radios de borde y anchos
5. **Sombra**: Aplicación coherente de sombras para profundidad

## Conclusión

Los componentes UI avanzados son fundamentales para mantener la consistencia y calidad del sistema TerrenaLaravel ERP. Al usar estos componentes reutilizables, se asegura una experiencia de usuario uniforme y se acelera el proceso de desarrollo de nuevas funcionalidades.