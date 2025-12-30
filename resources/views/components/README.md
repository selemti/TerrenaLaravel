# Componentes Reusables - TerrenaLaravel ERP

## Introducción

Este directorio contiene componentes Blade reusables desarrollados para el sistema TerrenaLaravel ERP con el fin de mantener consistencia en la UI/UX y acelerar el desarrollo de nuevas funcionalidades.

## Estructura de Directorios

```
resources/views/components/
├── ui/                    # Componentes genéricos de interfaz de usuario
├── inventory/             # Componentes específicos del módulo de inventario
├── transfer/              # Componentes específicos del módulo de transferencias
└── [otros módulos]/       # Componentes para otros módulos del sistema
```

## Tipos de Componentes

### Componentes UI Genéricos (`ui/`)
Componentes reutilizables para elementos comunes de interfaz de usuario como tablas, formularios, tarjetas, etc.

### Componentes de Módulo Específico
Componentes especializados para las funcionalidades particulares de cada módulo del sistema ERP.

## Documentación

Para una descripción detallada de cada componente, consulte los siguientes documentos:

- [ComponentesReusables.md](../../docs/UI-UX/Definiciones/ComponentesReusables.md) - Documentación general de componentes reusables
- [ComponentesUIAvanzados.md](../../docs/UI-UX/Definiciones/ComponentesUIAvanzados.md) - Documentación de componentes UI avanzados
- [ComponentesModuloEspecifico.md](../../docs/UI-UX/Definiciones/ComponentesModuloEspecifico.md) - Documentación de componentes específicos por módulo

## Buenas Prácticas

1. **Consistencia**: Todos los componentes siguen las guías de estilo del sistema
2. **Accesibilidad**: Todos los componentes cumplen con estándares de accesibilidad web
3. **Integración con Livewire**: Soporte para integración directa con componentes Livewire
4. **Internationalización**: Preparados para soporte multilenguaje
5. **Responsive Design**: Todos los componentes son responsive

## Cómo Usar

Para usar un componente en una vista Blade:

```blade
<x-ui.form-field 
    label="Nombre del Producto" 
    name="nombre" 
    model="nombreProducto" 
    :required="true" />

<x-inventory.item-card 
    :item="$item" 
    :stock="$stock" 
    :show-stock="true" />
```

## Contribución

Al crear nuevos componentes:
1. Coloque el componente en el directorio apropiado
2. Siga las convenciones de nomenclatura existentes
3. Documente las props y uso del componente
4. Asegúrese de que sea responsive y accesible