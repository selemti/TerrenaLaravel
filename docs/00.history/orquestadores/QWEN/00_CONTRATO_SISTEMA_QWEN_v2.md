# CONTRATO SISTEMA TERRENA POS/ERP v2 - QWEN

## Objetivo General

Terrena es un sistema POS/ERP integral para restaurantes que gestiona operaciones de inventario, producción, compras, recetas, caja y reportes. El sistema debe proporcionar una plataforma unificada para la gestión de recursos, control de costos y toma de decisiones basada en datos operativos reales.

## Alcance Completo

- **Inventario**: Gestión de items, recepciones, conteos, transferencias, kardex
- **Recetas**: Catálogo, versionado, costeo, mapeo con POS
- **Producción**: Órdenes de producción, planificación, KPIs
- **Compras/Replenishment**: Solicitudes, órdenes, motor de sugerencias
- **POS**: Integración de tickets, mapeo de productos, auditoría
- **Caja Chica**: Fondo de caja, movimientos, arqueos, cierres diarios
- **Reportes**: KPIs, ventas, inventario, producción, análisis de costos
- **Catálogos**: Unidades de medida, proveedores, sucursales, almacenes
- **Seguridad**: Permisos, roles, auditoría de acciones
- **Ventas**: Tickets, consumos, mapeo de productos
- **Arquitectura**: Estructura del sistema, convenciones
- **Frontend**: Componentes, layout, UI/UX
- **BD**: Estructura de base de datos, vistas, funciones
- **Finanzas**: Caja, cortes, conciliaciones
- **Purchasing**: Compras, cotizaciones, reposición

## Principios Rectores

1. **Consistencia entre Docs, Código y BD**: Todo cambio debe reflejarse en los tres componentes
2. **Modularidad Estricta**: Cada módulo opera de forma independiente
3. **Backlog Centralizado**: Todo trabajo se registra en el backlog oficial
4. **Convención de Carpetas y Namespaces**: Estructura clara y consistente
5. **Regla de Oro para Agentes IA**: No modificar carpetas o módulos que no te son asignados

## Fuente de Verdad

La documentación canónica del sistema se encuentra en `docs/V4.0/`. Todo cambio en la funcionalidad debe reflejarse en los archivos correspondientes de esta carpeta antes de cualquier implementación.

## Estructura Documental

- **docs/V4.0/**: Documentación oficial activa
- **docs/00.history/**: Documentación histórica, auditorías, fases 1-6 y archivos referencias
- **docs/00.history/orquestadores/**: Versiones de orquestadores por IA (QWEN, GPT, CODEX, GEMINI)

## Reglas para Agentes IA

Todo agente que trabaje en el sistema Terrena debe leer y seguir los siguientes documentos:
- El contrato del sistema (este archivo)
- La matriz de alineación inicial
- El backlog de sprints
- La documentación específica de su módulo en `docs/V4.0/<su módulo>/`

## Reglas de Gobernanza

- Cambios cross-módulo requieren revisión del Orquestador
- Todo pull request debe pasar auditoría de consistencia
- Documentación debe actualizarse antes de merge
- Tests deben pasar antes de implementación
- Aprobación de cambios estructurales requiere validación técnica

## Definición de Roles

- **Orquestador**: Coordina trabajo de agentes, gestiona dependencias, aprueba cambios estructurales
- **Agente de Módulo**: Implementa funcionalidades dentro de su módulo asignado
- **Auditor Técnico IA**: Revisa consistencia entre documentación, código y base de datos

## Modelo de Trabajo IA-en-Paralelo

Los agentes trabajan simultáneamente en módulos diferentes basándose en una visión común del sistema. Cada agente se enfoca en su área de responsabilidad mientras mantiene coherencia con el resto del sistema a través de la documentación centralizada y el backlog común.