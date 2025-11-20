# STATUS ACTUAL DEL MÓDULO: PERMISOS

## Fecha de Análisis: 30 de octubre de 2025

## 1. RESUMEN GENERAL

| Aspecto | Estado |
|--------|--------|
| **Backend Completo** | ✅ |
| **Frontend Funcional** | ⚠️ |
| **API REST Completa** | ✅ |
| **Documentación** | ✅ |
| **Nivel de Completitud** | 80% |

## 2. MODELOS (Backend)

### 2.1 Modelos Implementados
- ✅ `User.php` - Modelo de usuario con traits de Spatie Permissions
- ✅ Modelos de Spatie Permissions (internos): Role, Permission, ModelHasPermission, RoleHasPermission, etc.
- ✅ Relaciones con otros modelos del sistema

### 2.2 Relaciones y Funcionalidades
- ✅ Relaciones con todos los demás modelos del sistema
- ✅ Sistema de roles y permisos jerárquico
- ✅ Middleware de autenticación y autorización

## 3. SERVICIOS (Backend)

### 3.1 Servicios Implementados
- ✅ Integración con paquete Spatie/Laravel-Permission
- ✅ `AuditLogService.php` - Servicio para registrar acciones con control de permisos

### 3.2 Funcionalidades Completadas
- ✅ Sistema de roles basado en Spatie Permissions
- ✅ Middleware 'can' para protección de rutas
- ✅ Directivas @can en vistas Blade
- ✅ Método user->can() para verificación en componentes
- ✅ Control de acceso a nivel de UI basado en permisos
- ✅ API endpoint: `GET /api/me/permissions` para obtener permisos del usuario autenticado

### 3.3 Funcionalidades Pendientes
- ❌ UI completa de gestión de roles y permisos
- ❌ Matriz rol × permiso visual
- ❌ Auditoría completa de cambios de permisos

## 4. RUTAS Y CONTROLADORES (Backend)

### 4.1 API Endpoints
- ✅ `GET /api/me/permissions` - Obtener permisos del usuario autenticado
- ✅ Middlewares y protecciones de rutas implementados

### 4.2 Rutas Web con Permisos
- ✅ Rutas protegidas con middleware 'can'
- ✅ Rutas protegidas con middleware 'permission'
- ✅ Control de acceso en vistas blade con @can

## 5. COMPONENTES LIVEWIRE (Frontend)

### 5.1 Componentes Implementados
- ❌ No hay componentes Livewire específicos para gestión de permisos
- ⚠️ Solo se utilizan directivas en vistas Blade y middleware en componentes

### 5.2 Funcionalidades Frontend Completadas
- ✅ Control de acceso en sidebar dinámico
- ✅ Ocultar/mostrar elementos basados en permisos
- ✅ Protección de rutas con middleware
- ✅ Control de acceso a nivel de componente con @can

### 5.3 Funcionalidades Frontend Pendientes
- ❌ UI de gestión de roles y permisos
- ❌ Matriz rol × permiso visual
- ❌ Asignación de usuarios a roles
- ❌ "Probar como" funcionalidad de impersonate

## 6. VISTAS BLADE

### 6.1 Vistas Implementadas
- ✅ Directivas @can/@cannot en vistas Blade
- ✅ Control de acceso condicional en vistas
- ✅ Sidebar dinámico basado en permisos

### 6.2 Funcionalidades de UI
- ✅ Control de acceso basado en permisos (no roles)
- ✅ Sidebar dinámico que se construye basado en user()->can(...)
- ✅ Acceso visual dinámico basado en permisos efectivos

## 7. PERMISOS ESPECÍFICOS IMPLEMENTADOS

### 7.1 Permisos de Inventario
- ✅ `inventory.items.view` - Ver catálogo de ítems
- ✅ `inventory.items.manage` - Crear/Editar ítems
- ✅ `inventory.uoms.view` - Ver presentaciones
- ✅ `inventory.uoms.manage` - Gestionar presentaciones
- ✅ `inventory.uoms.convert.manage` - Gestionar conversiones
- ✅ `inventory.receptions.view` - Ver recepciones
- ✅ `inventory.receptions.post` - Postear recepciones
- ✅ `inventory.counts.view` - Ver conteos
- ✅ `inventory.counts.open` - Abrir conteo
- ✅ `inventory.counts.close` - Cerrar conteo
- ✅ `inventory.moves.view` - Ver movimientos
- ✅ `inventory.moves.adjust` - Ajuste manual
- ✅ `inventory.snapshot.generate` - Generar snapshot diario
- ✅ `inventory.snapshot.view` - Ver snapshots

### 7.2 Permisos de Compras
- ✅ `purchasing.suggested.view` - Ver pedidos sugeridos
- ✅ `purchasing.orders.manage` - Crear/Editar órdenes
- ✅ `purchasing.orders.approve` - Aprobar órdenes
- ✅ `can_manage_purchasing` - Permiso general de compras

### 7.3 Permisos de Recetas
- ✅ `recipes.view` - Ver recetas
- ✅ `recipes.manage` - Crear/Editar recetas
- ✅ `recipes.costs.recalc.schedule` - Cron recalcular costos
- ✅ `recipes.costs.snapshot` - Snapshot manual de costo
- ✅ `can_view_recipe_dashboard` - Ver dashboard de recetas
- ✅ `can_modify_recipe` - Modificar recetas

### 7.4 Permisos de Producción
- ✅ `can_edit_production_order` - Ejecutar producción y registrar mermas
- ✅ `can_manage_produmix` - Ver, editar y aprobar el plan Produmix
- ✅ `production.orders.view` - Ver órdenes de producción
- ✅ `production.orders.close` - Cerrar OP (consume MP)

### 7.5 Permisos de POS
- ✅ `can_reprocess_sales` - Reprocesar ventas POS
- ✅ `can_view_recipe_dashboard` - Ver recetas y costos
- ✅ `can_manage_menu_availability` - Control de disponibilidad POS
- ✅ `pos.mapping.view` - Ver mapeo POS

### 7.6 Permisos de Caja Chica
- ✅ `cashfund.manage` - Acceso general a caja chica
- ✅ `cashfund.view` - Ver caja chica (solo lectura)
- ✅ `approve-cash-funds` - Aprobar fondos de caja
- ✅ `close-cash-funds` - Cerrar fondos de caja

### 7.7 Permisos de Reportes
- ✅ `reports.kpis.view` - Ver KPIs/dashboard
- ✅ `reports.audit.view` - Ver auditoría
- ✅ `reports.view` - Ver reportes

### 7.8 Permisos de Usuarios y Sistema
- ✅ `people.users.manage` - Gestionar usuarios
- ✅ `admin.access` - Acceso a administración
- ✅ `audit.view` - Ver auditoría
- ✅ `legacy.view` - Ver rutas legacy

## 8. SISTEMA DE ROLES

### 8.1 Roles Definidos
- ✅ 44 permisos atómicos definidos
- ✅ 7 roles base definidos
- ✅ 9 módulos cubiertos
- ✅ Roles específicos: Chef, Almacén, Compras, Gerente, Finanzas, Auditor

### 8.2 Estructura de Roles
- ✅ Roles basados en agrupaciones de permisos
- ✅ Asignación flexible de permisos individuales
- ✅ Control de acceso por sucursal

## 9. ESTADO DE AVANCE

### 9.1 Completo (✅)
- ✅ Implementación de paquete Spatie Permissions
- ✅ Middleware de autorización
- ✅ Directivas de autorización en vistas Blade
- ✅ Control de acceso a nivel de componente Livewire
- ✅ API para obtener permisos del usuario
- ✅ 44 permisos atómicos definidos
- ✅ 7 roles base definidos
- ✅ Control de acceso basado en permisos (no roles)
- ✅ Sidebar dinámico por permisos

### 9.2 En Desarrollo (⚠️)
- ⚠️ Asignación de usuarios a roles (funcional por backend)
- ⚠️ Control de acceso por sucursal (implementado en algunos módulos)

### 9.3 Pendiente (❌)
- ❌ UI de gestión de roles y permisos
- ❌ Matriz rol × permiso visual
- ❌ Clonación rápida de roles
- ❌ "Probar como" funcionalidad de impersonate
- ❌ Auditoría completa de cambios de permisos
- ❌ Historial de cambios de roles

## 10. KPIs MONITOREADOS

- ✅ Usuarios con roles asignados
- ✅ Permisos críticos protegidos
- ❌ Tiempo promedio de gestión de permisos
- ❌ Incidencias por falta de permisos
- ❌ Uso de impersonate (para seguridad)
- ❌ Cumplimiento de políticas de acceso
- ❌ Número de accesos no autorizados detectados
- ❌ Usuarios con permisos excesivos
- ❌ Aprobaciones requeridas por tipo de acción
- ❌ Seguimiento de cambios en configuración de seguridad

## 11. INTEGRACIONES

### 11.1 Con Todos los Módulos
- ✅ Todos los módulos: Verificación de permisos para acceso
- ✅ Caja Chica: Acceso restringido a funciones de caja
- ✅ Inventario: Control sobre operaciones de stock
- ✅ Compras: Control sobre órdenes y aprobaciones
- ✅ Recetas: Acceso a costos y configuraciones
- ✅ Reportes: Acceso restringido a información sensible
- ✅ POS: Control de reproceso y diagnósticos
- ✅ Producción: Ejecución de órdenes
- ✅ Menú POS: Control de disponibilidad

## 12. PRÓXIMOS PASOS

1. Implementar UI de gestión de roles y permisos
2. Crear matriz rol × permiso visual
3. Agregar funcionalidad de clonación de roles
4. Implementar "probar como" con impersonate
5. Completar auditoría de cambios de permisos

**Responsable:** Equipo TerrenaLaravel  
**Última actualización:** 30 de octubre de 2025