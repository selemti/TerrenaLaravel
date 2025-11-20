# MATRIZ ALINEACION INICIAL v2 - QWEN

## Módulo: Inventario

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Alta de Items | OK | OK | OK | OK | Completado | OK | Catálogos | Mantener estado actual |
| Recepciones | Parcial | Parcial | OK | Parcial | Flujos incompletos BORRADOR → VALIDADA → POSTEADA | Alta | Items, Proveedores | Completar flujo con estados y validaciones |
| Conteos | OK | OK | OK | Parcial | UX operativa | Media | Items | Mejorar experiencia de conteo físico |
| Transferencias | Parcial | Parcial | OK | Parcial | Estados incompletos | Alta | Items, Almacenes | Completar flujo SOLICITADA → DESPACHADA → RECIBIDA |
| Kardex | Parcial | OK | OK | Parcial | Visualización histórica | Media | Movimientos | Implementar UI de historial |
| Mermas y Ajustes | Parcial | OK | OK | Parcial | UI de ajustes pendiente | Media | Items, Movimientos | Completar UI de ajustes |

## Módulo: Recetas

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Catálogo | OK | OK | OK | OK | Completado | OK | Items | Mantener estado actual |
| Versionado | Parcial | Parcial | OK | Parcial | UI limitada a versión 1 | Alta | Items | Completar UI de versiones múltiples |
| Costeo | OK | OK | Parcial | Parcial | Tablas opcionales faltantes | Media | Items | Documentar y crear tablas faltantes |
| Mapeo POS | OK | OK | OK | Parcial | UI de validación | Media | POS | Crear UI para recetas sombra |
| Subrecetas | Parcial | Parcial | OK | Parcial | BOM implotado no completamente funcional | Media | Recetas | Completar funcionalidad de BOM implotado |

## Módulo: Producción

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Órdenes | OK | OK | OK | Falta | UI operativa pendiente | Alta | Recetas, Items | Implementar UI de control de producción |
| Planificación | Parcial | OK | OK | Falta | UI de planificación | Media | Recetas, Items | Crear UI de planificación de OPs |
| KPIs | Parcial | OK | OK | Parcial | Visualización de métricas | Media | Producción | Completar UI de KPIs de producción |

## Módulo: Compras/Purchasing

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Solicitudes | OK | OK | OK | Parcial | UI de sugerencias | Alta | Proveedores | Desarrollar dashboard de sugerencias |
| Órdenes | OK | OK | OK | OK | Completado | OK | Solicitudes | Mantener estado actual |
| Motor Replenishment | OK | Falta | OK | Falta | No implementado | Crítica | Inventario, Recetas | Priorizar desarrollo del motor |
| Cotizaciones | Parcial | Parcial | OK | Falta | UI pendiente | Media | Proveedores | Implementar UI de cotizaciones |

## Módulo: POS

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Mapeo | OK | OK | OK | OK | Completado | OK | Recetas | Mantener estado actual |
| Consumo | OK | OK | OK | OK | Completado | OK | Tickets | Mantener estado actual |
| Endpoints | Parcial | OK | OK | Falta | No expuestos en rutas | Media | Recetas | Registrar rutas API POS |
| Reprocesamiento | Parcial | Parcial | OK | Parcial | UI de reprocesamiento | Media | Tickets | Completar funcionalidad de reprocesamiento |

## Módulo: Caja Chica

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Fondo de Caja | OK | OK | OK | OK | Completado | OK | - | Mantener estado actual |
| Movimientos | OK | OK | OK | OK | Completado | OK | - | Mantener estado actual |
| Arqueos | OK | OK | OK | OK | Completado | OK | - | Mantener estado actual |
| Cierres Diarios | OK | OK | OK | OK | Completado | OK | - | Mantener estado actual |

## Módulo: Ventas

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Tickets | Parcial | OK | OK | Parcial | UI de análisis | Media | POS | Crear dashboard de análisis de ventas |
| Consumos | Parcial | OK | OK | Parcial | UI de análisis | Media | Inventario | Crear dashboard de consumos |

## Módulo: Catálogos

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Unidades de Medida | OK | OK | OK | OK | Completado | OK | - | Mantener estado actual |
| Proveedores | OK | OK | OK | OK | Completado | OK | - | Mantener estado actual |
| Sucursales | OK | OK | OK | OK | Completado | OK | - | Mantener estado actual |
| Almacenes | OK | OK | OK | OK | Completado | OK | - | Mantener estado actual |

## Módulo: Seguridad/Permisos

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Permisos | Parcial | OK | OK | Parcial | UI de gestión | Media | Usuarios | Crear UI de gestión de permisos |
| Roles | Parcial | OK | OK | Parcial | UI de gestión | Media | Permisos | Crear UI de gestión de roles |

## Módulo: Base de Datos

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Tablas | OK | OK | OK | - | Completado | OK | - | Mantener estado actual |
| Vistas | Parcial | OK | OK | - | Documentación incompleta | Media | - | Completar documentación de vistas |
| Funciones | Parcial | OK | OK | - | Documentación incompleta | Media | - | Completar documentación de funciones |

## Módulo: Arquitectura

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Estructura | OK | OK | OK | - | Completado | OK | - | Mantener estado actual |
| Convenciones | OK | OK | OK | - | Completado | OK | - | Mantener estado actual |

## Módulo: Frontend

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Componentes | OK | OK | - | OK | Completado | OK | - | Mantener estado actual |
| Layout | OK | OK | - | OK | Completado | OK | - | Mantener estado actual |

## Módulo: Finanzas

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Caja | OK | OK | OK | OK | Completado | OK | - | Mantener estado actual |
| Cortes | OK | OK | OK | OK | Completado | OK | - | Mantener estado actual |
| Conciliaciones | Parcial | OK | OK | Parcial | UI de conciliación | Media | Caja | Completar UI de conciliación |

## Módulo: Reports

| Sub-módulo / Feature | Estado Documentación | Estado Código | Estado BD | Estado UI | Gap Detectado | Severidad | Dependencias | Recomendación inicial |
|----------------------|---------------------|---------------|-----------|-----------|----------------|-----------|--------------|----------------------|
| Exportaciones | Parcial | Parcial | OK | Falta | Funcionalidad no implementada | Media | KPIs | Implementar exportaciones CSV/PDF |
| KPIs | Parcial | Parcial | OK | Parcial | Visualización incompleta | Media | Datos | Completar UI de KPIs |
| Ventas | Parcial | OK | OK | Parcial | UI de análisis | Media | Tickets | Completar UI de análisis de ventas |