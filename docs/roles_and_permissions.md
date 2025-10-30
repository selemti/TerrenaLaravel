# Roles y Permisos en Terrena

## Modelo híbrido
Terrena opera con un esquema RBAC extendido:
- **Plantillas (roles acumulables)**: representan puestos o funciones. Un usuario puede tener varias al mismo tiempo (p. ej. “Cajero” + “Encargado de Tienda” en una sucursal grande).
- **Permisos especiales (excepciones temporales)**: se asignan directo al usuario cuando requiere acciones fuera de su plantilla (p. ej. darle `cashfund.manage` por una guardia).
- **Super Admin**: acceso total al sistema, no editable ni duplicable desde la interfaz.

Este modelo permite cubrir escenarios de sucursales pequeñas (una sola plantilla) y de operaciones complejas donde la misma persona cubre múltiples responsabilidades.

## Cómo se refleja en la UI
- En la pestaña **Usuarios** se muestra primero el resumen del colaborador, seguido de “Plantillas asignadas (funciones/puestos)” y debajo “Permisos especiales (excepciones)”.
- Las plantillas se cargan desde `config/permissions_map.php`, que agrupa los permisos por módulo para que negocio entienda qué otorga cada acción.
- Los permisos heredados de una plantilla aparecen con el badge “vía plantilla”; sólo los que no tienen ese sello pueden habilitarse/deshabilitarse como excepciones.
- Para usuarios Super Admin se muestra una alerta amarilla y todos los controles quedan bloqueados.

## Flujo de actualización
1. Seleccionar al usuario y marcar/desmarcar las plantillas necesarias (se actualiza vía `syncRoles`).
2. Ajustar los permisos especiales; sólo se persisten los que no provienen de plantillas (se usa `syncPermissions`).
3. **Importante:** cuando el usuario editado es el mismo que está usando la sesión actual se debe limpiar el cache local con `sessionStorage.removeItem('terrena_permissions')` (ver TODO en el componente Livewire).

## Convenciones y archivos clave
- `config/permissions_map.php` centraliza la descripción amigable de cada permiso.
- Los campos `display_name` y `description` del rol se muestran a negocio como nombre y explicación de la plantilla.
- El seeder mantiene al usuario `soporte` con el rol `Super Admin` como acceso raíz del sistema.
- El caching de permisos/tokens de Sanctum permanece intacto (ver `docs/auth-caching.md`).

## Escenarios ilustrativos
- **Cafetería pequeña:** un colaborador puede operar sólo con la plantilla “Cajero” y cero permisos especiales.
- **Sucursal grande:** la misma persona puede tener “Cajero” + “Encargado de Tienda” y, además, un permiso especial `inventory.moves.manage` por la temporada.

## Futuras extensiones
- Expiración para permisos especiales (`expires_at`).
- Auditoría detallada de cambios de plantillas y overrides.
- Delegaciones temporales automáticas para coberturas o vacaciones.
