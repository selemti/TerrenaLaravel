# Documentación de Componentes Reusables - TerrenaLaravel ERP

## Introducción

Este documento describe los componentes reusables desarrollados para el sistema TerrenaLaravel ERP con el fin de mantener consistencia en la UI/UX y acelerar el desarrollo de nuevas funcionalidades.

## Estructura General

Los componentes reusables se organizan en las siguientes categorías:

- **UI Genéricos**: Componentes genéricos para interfaz de usuario
- **Específicos de Módulos**: Componentes especializados por módulo de negocio
- **Funcionales**: Componentes que encapsulan funcionalidades específicas

## Componentes en `resources/views/components/ui/`

### 1. `advanced-card.blade.php`
Componente de tarjeta avanzada con posibilidad de encabezado, cuerpo y pie de página.

**Props:**
- `title`: Título de la tarjeta
- `subtitle`: Subtítulo opcional
- `headerActions`: Acciones en el encabezado
- `footer`: Pie de página opcional

### 2. `advanced-table.blade.php`
Tabla responsive con soporte para acciones en filas y acciones masivas.

**Props:**
- `headers`: Array con los encabezados de columna
- `actions`: Columna para acciones de fila
- `bulkActions`: Componente para acciones masivas
- `responsive`: Indica si debe ser responsive en móviles

### 3. `banner.blade.php`
Componente para mostrar banners informativos, de alerta o de error.

### 4. `card.blade.php`
Tarjeta Bootstrap estándar.

### 5. `checkbox.blade.php`
Checkbox con estilo Bootstrap con soporte para validación.

### 6. `compact-multi-select.blade.php`
Selector múltiple compacto para formularios.

### 7. `date-picker.blade.php`
Componente para selección de fechas con soporte para internacionalización.

### 8. `dropdown.blade.php`
Menú desplegable con estilos consistentes.

### 9. `form-field.blade.php`
Campo de formulario genérico que soporta múltiples tipos (input, select, textarea, checkbox, etc.).

**Props:**
- `label`: Etiqueta del campo
- `type`: Tipo de campo (text, select, textarea, etc.)
- `name`: Nombre del campo
- `value`: Valor del campo
- `placeholder`: Placeholder
- `required`: Indica si es obligatorio
- `disabled`: Indica si está deshabilitado
- `readonly`: Indica si es de solo lectura
- `help`: Texto de ayuda
- `error`: Mensaje de error
- `model`: Modelo para integración con Livewire
- `options`: Opciones para select
- `multiple`: Para multi-select
- `rows`: Número de filas para textarea

### 10. `input.blade.php`
Input básico con estilos Bootstrap.

### 11. `loading-skeleton.blade.php`
Componente para mostrar skeleton loading mientras se carga contenido.

### 12. `modal.blade.php`
Modal con estilos Bootstrap y soporte para header, body y footer.

### 13. `notification-manager.blade.php`
Gestor de notificaciones de sistema.

### 14. `search-input.blade.php`
Input de búsqueda con icono y funcionalidad.

### 15. `select.blade.php`
Selector con estilos Bootstrap y soporte para validación.

### 16. `status-badge.blade.php`
Badge para mostrar estados con colores codificados.

### 17. `table.blade.php`
Tabla básica con estilos Bootstrap.

### 18. `table-row.blade.php`
Fila de tabla reutilizable.

### 19. `toast.blade.php`
Componente para mostrar notificaciones tipo toast.

## Componentes en `resources/views/components/inventory/`

### 1. `item-card.blade.php`
Tarjeta para mostrar información de un ítem del inventario.

**Props:**
- `item`: Datos del ítem
- `showStock`: Mostrar información de stock
- `showActions`: Mostrar acciones
- `stock`: Información de stock
- `actions`: Acciones personalizadas

### 2. `transaction-card.blade.php`
Tarjeta para mostrar información de una transacción de inventario.

## Componentes en `resources/views/components/transfer/`

### 1. `transfer-form.blade.php`
Formulario para creación y edición de transferencias.

### 2. `transfer-status-badge.blade.php`
Badge para mostrar el estado de una transferencia con colores codificados.

## Componentes Genéricos en `resources/views/components/`

### 1. `action-buttons.blade.php`
Grupo de botones de acción común (Guardar, Cancelar, etc.).

### 2. `alert.blade.php`
Componente para mostrar alertas con diferentes estilos.

### 3. `application-logo.blade.php`
Logo de la aplicación.

### 4. `auth-session-status.blade.php`
Estatus de sesión en pantallas de autenticación.

### 5. `badge.blade.php`
Badge genérico con estilos Bootstrap.

### 6. `button.blade.php`
Botón con estilos Bootstrap y variantes.

### 7. `danger-button.blade.php`
Botón de acción peligrosa (eliminar, etc.).

### 8. `dropdown-link.blade.php`
Enlace para menú desplegable.

### 9. `input-error.blade.php`
Mensaje de error de input.

### 10. `input-label.blade.php`
Etiqueta de input.

### 11. `kpi-card.blade.php`
Tarjeta para mostrar indicadores clave de rendimiento (KPIs).

### 12. `loading-spinner.blade.php`
Spinner de carga.

### 13. `modal.blade.php`
Modal con estilos Bootstrap.

### 14. `nav-link.blade.php`
Enlace de navegación.

### 15. `primary-button.blade.php`
Botón primario para acciones principales.

### 16. `responsive-nav-link.blade.php`
Enlace de navegación responsive.

### 17. `search-input.blade.php`
Input de búsqueda.

### 18. `secondary-button.blade.php`
Botón secundario.

### 19. `stat.blade.php`
Componente para mostrar estadísticas.

### 20. `status-badge.blade.php`
Badge para mostrar estados.

### 21. `text-input.blade.php`
Input de texto básico.

### 22. `toast-notification.blade.php`
Componente para mostrar notificaciones tipo toast.

## Buenas Prácticas

1. **Props Claros**: Cada componente debe tener props bien documentados y con valores por defecto donde sea apropiado.

2. **Estilos Coherentes**: Todos los componentes deben seguir las guías de estilo de la aplicación, principalmente usando Tailwind CSS y Bootstrap 5.

3. **Integración con Livewire**: Muchos componentes incluyen soporte para la integración con Livewire a través de `wire:model.defer` y otros atributos.

4. **Accesibilidad**: Todos los componentes deben seguir prácticas de accesibilidad web (a11y).

5. **Internationalización**: Componentes que muestran texto deben estar preparados para soporte de múltiples idiomas.

## Cómo Crear Nuevos Componentes

Cuando se necesite un nuevo componente reutilizable:

1. Determinar la categoría adecuada (`ui`, `inventory`, `transfer`, etc.)
2. Crear el archivo `.blade.php` en el directorio correspondiente
3. Definir las props adecuadas con valores por defecto
4. Escribir la lógica de renderizado
5. Documentar el componente en esta guía
6. Crear tests unitarios si aplica

## Conclusión

Esta biblioteca de componentes reusables es fundamental para mantener la coherencia visual y funcional del ERP TerrenaLaravel, acelerar el desarrollo y garantizar una experiencia de usuario consistente en todos los módulos.