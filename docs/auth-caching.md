# Caching de Tokens y Permisos en TerrenaPOS

## Descripción

Se ha implementado un sistema de caché para tokens de API y permisos de usuario que mejora significativamente el rendimiento al evitar solicitudes repetidas en cada carga de página.

## Componentes de la Implementación

### 1. Almacenamiento en SessionStorage
- `terrena_api_token`: Almacena el token de API con una marca de tiempo
- `terrena_permissions`: Almacena los permisos del usuario con una marca de tiempo

### 2. Funciones JavaScript

#### `setCachedValue(key, value)`
Almacena un valor en sessionStorage con una marca de tiempo actual.

#### `getCachedValue(key, maxAge = 86400000)`
Obtiene un valor del caché, verificando si ha expirado (por defecto, 24 horas).

#### `TerrenaLoadApiToken()`
- Verifica primero si hay un token cacheado y no expirado
- Si no hay token válido, lo solicita al servidor
- Almacena el nuevo token en caché

#### `TerrenaLoadPermissions()`
- Verifica primero si hay permisos cacheados y no expirados
- Si no hay permisos válidos, los solicita al servidor
- Almacena los nuevos permisos en caché

#### `TerrenaClearAuth()`
Limpia todos los datos de autenticación del caché.

#### `handleTerrenaLogout(event)`
Función mejorada de logout que:
- Limpia el caché de autenticación
- Revoca el token de API en el servidor
- Realiza el logout normal de Laravel

### 3. Expiración de Caché
- Los tokens y permisos expiran después de 24 horas (86,400,000 milisegundos)
- Se verifica la expiración cada vez que se accede al caché
- Los datos expirados se eliminan automáticamente

### 4. Mejora del Sidebar
El sidebar ahora puede mostrar contenido de inmediato si hay permisos cacheados disponibles.

## Rutas API

### `/session/api-token` (GET)
- Middleware: `auth`
- Obtiene un token Sanctum para el usuario autenticado
- Revoca tokens anteriores para evitar acumulación

### `/session/api-token/revoke` (POST)
- Middleware: `auth`
- Revoca el token Sanctum actual del usuario

### `/api/me/permissions` (GET)
- Middleware: `auth:sanctum`
- Obtiene la lista de permisos efectivos para el usuario

## Integración con el Logout

Cuando un usuario cierra sesión:
1. Se ejecuta la función `handleTerrenaLogout()`
2. Se limpia el caché de tokens y permisos
3. Se revoca el token Sanctum en el servidor
4. Se procesa el logout normal de Laravel

## Beneficios

1. **Mejora de rendimiento**: Se evitan solicitudes HTTP repetidas en cada carga de página
2. **Persistencia de sesión**: Los tokens y permisos están disponibles inmediatamente entre navegación
3. **Seguridad**: Los datos expiran automáticamente y se limpian adecuadamente en logout
4. **Mejor experiencia de usuario**: El sidebar se muestra de inmediato con las opciones adecuadas

## Consideraciones

- La caché se almacena en sessionStorage (se borra al cerrar el navegador)
- Los datos expiran después de 24 horas para seguridad
- Se manejan adecuadamente los errores de red o datos corruptos
- La implementación es compatible con navegadores modernos