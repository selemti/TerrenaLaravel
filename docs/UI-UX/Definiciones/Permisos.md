# Definición del Módulo: Permisos

## Descripción General
El módulo de Permisos gestiona el control de acceso al sistema mediante roles y permisos específicos. Utiliza el paquete Spatie/Laravel-Permission para implementar un sistema flexible y seguro de autorización. El sistema implementa un control de acceso basado en permisos (no en roles) con autorización a nivel de UI.

## Componentes del Módulo

### 1. Roles
**Descripción:** Agrupaciones de permisos que se asignan a usuarios.

**Características actuales:**
- 9 módulos identificados
- 7 roles base definidos
- 45 permisos atómicos
- Roles definidos: Chef, Almacén, Compras, Gerente, Finanzas, Auditor

**Requerimientos de UI/UX:**
- CRUD de roles con asignación de permisos
- Plantillas predefinidas de roles
- Clonación rápida de roles existentes
- Validación de permisos conflictivos
- Vista de permisos heredados por rol
- Asignación por sucursal (permisos específicos por ubicación)

### 2. Permisos Atómicos
**Descripción:** Acciones específicas que se pueden permitir o denegar.

**Características actuales:**
- 45 permisos definidos
- Cobertura de 9 módulos
- Permisos granulares (ver/editar/aprobar) por módulo/sucursal

**Requerimientos de UI/UX:**
- Matriz rol × permiso (visual)
- Agrupación lógica de permisos por módulo
- Búsqueda y filtrado de permisos
- Descripción clara de cada permiso
- Validación de permisos críticos
- Permisos específicos por sucursal
- Acciones: ver/editar/aprobar por módulo

### 3. Control de Acceso en UI
**Descripción:** Ocultar o mostrar elementos basados en permisos del usuario.

**Características actuales:**
- Implementación basada en permisos (no roles)
- Middleware 'can' a nivel de rutas
- Directiva @can en vistas Blade

**Requerimientos de UI/UX:**
- El acceso visual es dinámico y depende de permisos efectivos del usuario (Spatie Permission)
- Los roles son solo agrupadores convenientes
- Operativamente se pueden reasignar permisos temporales (ej: gerente ausente)
- El frontend NUNCA se basa en "rol de nómina", solo en user->can(...)
- Sidebar dinámico que se construye basado en user()->can(...)

### 4. Asignación de Usuarios a Roles
**Descripción:** Asociación de usuarios con roles específicos.

**Características actuales:**
- Sistema Spatie implementado
- 45 permisos, 9 módulos, 7 roles
- Middleware de autenticación web
- Middleware can: en rutas

**Requerimientos de UI/UX:**
- Asignación múltiple de roles a usuarios
- Vista de permisos efectivos por usuario
- Historial de cambios de roles
- Búsqueda de usuarios por rol/permiso
- Autocompletado en asignación
- Asignación temporal de permisos
- Control de acceso por sucursal

### 5. Permisos Específicos por Módulo
**Descripción:** Permisos granulares para diferentes funcionalidades del sistema.

**Características actuales:**
- Permisos específicos por módulo (inventory.*, purchasing.*, production.*, etc.)
- Permisos para control de caja (approve-cash-funds, close-cash-funds)
- Control de acceso a niveles: sidebar, vista, acción

**Requerimientos de UI/UX:**
- can_manage_purchasing: Acceso a compras/inventario
- inventory.view: Ver inventario
- inventory.items.manage: Gestionar items
- purchasing.manage: Gestionar compras
- can_manage_menu_availability: Control de disponibilidad POS
- can_manage_produmix: Aprobar plan Produmix
- can_edit_production_order: Ejecutar producción
- can_reprocess_sales: Reprocesar ventas POS
- can_view_recipe_dashboard: Ver recetas y costos
- approve-cash-funds: Aprobar fondos de caja
- close-cash-funds: Cerrar fondos de caja
- people.users.manage: Gestionar usuarios

### 6. Auditoría de Seguridad
**Descripción:** Registro de acciones basadas en permisos y roles.

**Características actuales:**
- Sistema de auditoría con user_id, timestamp, antes/después
- Logs inmutables (retención ≥ 12 meses)
- Cumplimiento Ley de Protección de Datos y NOM-151

**Requerimientos de UI/UX:**
- Registro de quién otorgó/quitaron permisos
- Historial de cambios de roles
- Reporte de auditoría de seguridad
- Alertas de cambios sensibles
- Bitácora completa de acciones críticas (quién, cuándo, qué)
- Aprobación dual para ajustes y costos sensibles

## Requerimientos Técnicos
- Middleware de impersonate
- Log de cambios de permisos
- Integración con sistema de auditoría global
- Validaciones de seguridad para operaciones sensibles
- Endpoints API para gestión de roles/permisos
- Caching de permisos para rendimiento
- Middleware 'can' para protección de rutas
- Directivas @can en vistas Blade
- Método user->can() para verificación en componentes
- Middleware de autenticación web (auth)

## Integración con Otros Módulos
- Todos los módulos: Verificación de permisos para acceso
- Caja Chica: Acceso restringido a funciones de caja (approve-cash-funds, close-cash-funds)
- Inventario: Control sobre operaciones de stock (inventory.items.manage, etc.)
- Compras: Control sobre órdenes y aprobaciones (purchasing.manage)
- Recetas: Acceso a costos y configuraciones (can_view_recipe_dashboard)
- Reportes: Acceso restringido a información sensible
- POS: Control de reproceso y diagnósticos (can_reprocess_sales, can_view_recipe_dashboard)
- Producción: Ejecución de órdenes (can_edit_production_order)
- Menú POS: Control de disponibilidad (can_manage_menu_availability)

## KPIs Asociados
- Usuarios con roles asignados
- Permisos críticos protegidos
- Tiempo promedio de gestión de permisos
- Incidencias por falta de permisos
- Uso de impersonate (para seguridad)
- Cumplimiento de políticas de acceso
- Número de accesos no autorizados detectados
- Usuarios con permisos excesivos
- Aprobaciones requeridas por tipo de acción
- Seguimiento de cambios en configuración de seguridad