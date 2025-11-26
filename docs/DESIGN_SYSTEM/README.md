# Terrena POS - Sistema de Diseño
**Versión**: 1.0.0 (borrador inicial)  
**Última actualización**: 26-Nov-2025  
**Mantenedor**: Equipo de desarrollo

## Introducción
Este documento centraliza la documentación del Design System de Terrena POS. Se crea desde la Fase 1 para asegurar trazabilidad incremental mientras se definen colores, componentes y migraciones de vistas.

## Contenido
1. [Auditoría UI](./01_AUDITORIA_UI.md) - Problemas identificados en la interfaz actual.
2. [Colores y Variables](./02_COLORES_Y_VARIABLES.md) - Paleta y tokens CSS.
3. [Componentes](./03_COMPONENTES.md) - Guía de componentes Blade. *(pendiente)*
4. [Utilidades](./04_UTILIDADES.md) - Clases CSS utilitarias. *(pendiente)*
5. [Migraciones](./05_MIGRACIONES.md) - Log de vistas migradas. *(pendiente)*
6. [Ejemplos](./06_EJEMPLOS.md) - Patrones comunes de UI. *(pendiente)*

## Instalación rápida
Los assets se integrarán en `layouts/terrena.blade.php` usando:
```blade
<link href="{{ asset('assets/css/design-system.css') }}" rel="stylesheet">
<link href="{{ asset('assets/css/utilities.css') }}" rel="stylesheet">
```

## Principios
- Consistencia visual entre módulos (dashboard, inventario, transferencias).
- Reutilización de componentes Blade para reducir código duplicado.
- Tokens de color y espaciado para mantener jerarquía tipográfica y de layout.

## Próximos pasos
- Completar auditoría UI y documentar hallazgos.
- Definir paleta y variables en `design-system.css`.
- Construir componentes base y migrar vistas prioritarias.
