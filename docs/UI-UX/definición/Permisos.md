# Definición del Módulo: Permisos

## Descripción General
El módulo de Permisos gestiona el control de acceso al sistema mediante roles y permisos específicos. Utiliza el paquete Spatie/Laravel-Permission para implementar un sistema flexible y seguro de autorización. El sistema implementa un control de acceso basado en permisos (no en roles) con autorización a nivel de UI.

## Componentes del Módulo

### 1. Roles
**Descripción:** Agrupaciones de permisos que se asignan a usuarios.

**Características actuales:**
- 44 permisos atómicos definidos
- 7 roles base definidos
- Integración completa con Spatie Permissions

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
- 44 permisos definidos
- Cobertura de 9 módulos
- Permisos granulares (ver/editar/aprobar)

**Requerimientos de UI/UX:**
- Matriz rol × permiso (visual)
- Agrupación lógica de permisos por módulo
- Búsqueda y filtrado de permisos
- Descripción clara de cada permiso
- Validación de permisos críticos
- Permisos específicos por sucursal
- Acciones: ver/editar/aprobar por módulo

### 3. Asignación de Usuarios a Roles
**Descripción:** Asociación de usuarios con roles específicos.

**Características actuales:**
- Sistema Spatie implementado
- 44 permisos, 9 módulos, 7 roles

**Requerimientos de UI/UX:**
- Asignación múltiple de roles a usuarios
- Vista de permisos efectivos por usuario
- Historial de cambios de roles
- Búsqueda de usuarios por rol/permiso
- Autocompletado en asignación

### 4. Prueba de Roles
**Descripción:** Funcionalidad para probar el sistema como otro usuario o rol.

**Características actuales:**
- Funcionalidad no implementada

**Requerimientos de UI/UX:**
- "Probar como" funcionalidad de impersonate
- Validación de seguridad para evitar abusos
- Indicador visual cuando se está en modo "probar como"
- Registro de sesiones de impersonate

### 5. Auditoría de Permisos
**Descripción:** Registro y seguimiento de cambios en roles y permisos.

**Características actuales:**
- Funcionalidad no implementada

**Requerimientos de UI/UX:**
- Registro de quién otorgó/quitaron permisos
- Historial de cambios de roles
- Reporte de auditoría de seguridad
- Alertas de cambios sensibles

## Requerimientos Técnicos
- Middleware de impersonate
- Log de cambios de permisos
- Integración con sistema de auditoría global
- Validaciones de seguridad para operaciones sensibles
- Endpoints API para gestión de roles/permisos
- Caching de permisos para rendimiento
- Middleware 'can' para protección de rutas
- Directiva @can en vistas Blade
- Método user->can() para verificación en componentes
- Middleware de autenticación web (auth:sanctum)

## Integración con Otros Módulos
- Todos los módulos: Verificación de permisos para acceso
- Caja Chica: Acceso restringido a funciones de caja
- Inventario: Control sobre operaciones de stock
- Compras: Control sobre órdenes y aprobaciones
- Recetas: Acceso a costos y configuraciones
- Reportes: Acceso restringido a información sensible
- Producción: Ejecución de órdenes y registro de mermas
- POS: Control de reproceso y diagnósticos
- Transferencias: Aprobación y ejecución de movimientos entre almacenes

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

## Matriz de Permisos por Módulo

### Inventario
- `inventory.view` - Ver catálogo de ítems
- `inventory.items.manage` - Crear/Editar ítems
- `inventory.prices.manage` - Gestionar precios
- `inventory.receivings.manage` - Gestionar recepciones
- `inventory.receptions.validate` - Validar recepciones
- `inventory.receptions.override_tolerance` - Override tolerancia
- `inventory.receptions.post` - Postear recepciones
- `inventory.counts.manage` - Gestionar conteos
- `inventory.moves.manage` - Gestionar movimientos
- `inventory.lots.view` - Ver lotes
- `inventory.transfers.approve` - Aprobar transferencias
- `inventory.transfers.ship` - Enviar transferencias
- `inventory.transfers.receive` - Recibir transferencias
- `inventory.transfers.post` - Postear transferencias

### Compras
- `purchasing.view` - Ver compras
- `purchasing.manage` - Gestionar compras
- `purchasing.suggested.view` - Ver pedidos sugeridos
- `purchasing.orders.manage` - Crear/Editar órdenes
- `purchasing.orders.approve` - Aprobar órdenes
- `can_manage_purchasing` - Permiso general de compras

### Recetas
- `recipes.view` - Ver recetas
- `recipes.manage` - Crear/Editar recetas
- `recipes.costs.recalc.schedule` - Cron recalcular costos
- `recipes.costs.snapshot` - Snapshot manual de costo
- `can_view_recipe_dashboard` - Ver dashboard de recetas
- `can_modify_recipe` - Modificar recetas

### Producción
- `can_edit_production_order` - Ejecutar producción y registrar mermas
- `can_manage_produmix` - Ver, editar y aprobar el plan Produmix
- `production.orders.view` - Ver órdenes de producción
- `production.orders.close` - Cerrar OP (consume MP)

### Caja Chica
- `cashfund.manage` - Acceso general a caja chica
- `cashfund.view` - Ver caja chica (solo lectura)
- `approve-cash-funds` - Aprobar fondos de caja
- `close-cash-funds` - Cerrar fondos de caja

### Reportes
- `reports.kpis.view` - Ver KPIs/dashboard
- `reports.audit.view` - Ver auditoría
- `reports.view` - Ver reportes

### POS
- `can_reprocess_sales` - Reprocesar ventas POS
- `can_view_recipe_dashboard` - Ver recetas y costos
- `can_manage_menu_availability` - Control de disponibilidad POS

### Transferencias
- `can_manage_transfers` - Permiso general para transferencias
- `inventory.transfers.approve` - Aprobar transferencias
- `inventory.transfers.ship` - Enviar transferencias
- `inventory.transfers.receive` - Recibir transferencias
- `inventory.transfers.post` - Postear transferencias

### Personas
- `people.users.manage` - Gestionar usuarios
- `people.roles.manage` - Gestionar roles
- `people.permissions.manage` - Gestionar permisos

### Sistema
- `admin.access` - Acceso a administración
- `audit.view` - Ver auditoría
- `legacy.view` - Ver rutas legacy

## Roles Predefinidos

### Super Admin
- Todos los permisos (*)

### Ops Manager
- Permisos completos de inventario, compras, recetas, producción
- Acceso a reportes y auditoría
- Gestión de usuarios y permisos

### Inventario Manager
- Permisos de gestión de inventario y recetas
- Acceso a reportes de inventario
- Gestión de usuarios de inventario

### Compras
- Permisos de gestión de compras y recepciones
- Acceso a proveedores
- Gestión de órdenes de compra

### Cocina
- Permisos de producción y recetas
- Acceso a reportes de cocina
- Gestión de órdenes de producción

### Cajero
- Permisos de caja chica y reportes básicos
- Vista limitada de inventario
- Acceso a funciones de POS

### Viewer
- Permisos de solo lectura en módulos básicos
- Acceso a reportes públicos
- Vista limitada de información sensible

## Componentes Técnicos

### Middleware
- `auth:sanctum` - Autenticación de usuarios
- `permission:{permiso}` - Verificación de permisos específicos
- `role:{rol}` - Verificación de roles
- `can:{permiso}` - Verificación de permisos a nivel de acción

### Directivas Blade
- `@can('{permiso}')` - Mostrar contenido si el usuario tiene el permiso
- `@cannot('{permiso}')` - Mostrar contenido si el usuario NO tiene el permiso
- `@hasrole('{rol}')` - Mostrar contenido si el usuario tiene el rol
- `@hasanyrole('{rol1},{rol2}')` - Mostrar contenido si el usuario tiene alguno de los roles

### Métodos de Usuario
- `$user->can('{permiso}')` - Verificar si el usuario tiene un permiso específico
- `$user->hasRole('{rol}')` - Verificar si el usuario tiene un rol específico
- `$user->getAllPermissions()` - Obtener todos los permisos del usuario
- `$user->getRoleNames()` - Obtener todos los roles del usuario

### Controladores
- `PermissionController` - Gestión de permisos
- `RoleController` - Gestión de roles
- `UserController` - Gestión de usuarios y asignación de roles

### Modelos
- `Permission` - Modelo de permisos de Spatie
- `Role` - Modelo de roles de Spatie
- `User` - Modelo de usuarios con traits de Spatie

### Servicios
- `PermissionService` - Lógica de negocio para permisos
- `RoleService` - Lógica de negocio para roles
- `UserService` - Lógica de negocio para usuarios

## Consideraciones de Seguridad

### Políticas de Acceso
- Control basado en permisos, no en roles
- Verificación en frontend y backend
- Auditoría completa de accesos
- Protección contra privilege escalation

### Validaciones
- Middleware para protección de rutas
- Validaciones en controladores
- Validaciones en componentes Livewire
- Validaciones en vistas Blade

### Logging
- Registro de intentos de acceso no autorizados
- Registro de cambios en permisos
- Registro de sesiones de impersonate
- Alertas automáticas para accesos sospechosos

## Próximos Pasos

### Implementaciones Pendientes
1. UI de gestión de roles y permisos
2. Matriz rol × permiso visual
3. Funcionalidad de "probar como" (impersonate)
4. Sistema de auditoría de permisos
5. Clonación rápida de roles
6. Asignación masiva de permisos
7. Exportación/importación de configuración de permisos
8. Dashboard de seguridad con métricas de acceso

### Mejoras Sugeridas
1. Sistema de permisos temporales
2. Herencia de permisos entre roles
3. Validaciones de permisos conflictivos
4. Sistema de aprobación para cambios críticos
5. Notificaciones de cambios de permisos
6. Reportes de cumplimiento de políticas de acceso
7. Integración con sistemas externos de IAM
8. Autenticación multifactor para permisos críticos