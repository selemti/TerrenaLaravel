# Operaciones · Seguridad y Accesos

## 1. Autenticación

- **Laravel Breeze** instalado (rutas web `/login`, `/register`, etc.).
- **Spatie Permission 6.21**: tablas creadas (`permissions`, `roles`, `model_has_*`). Falta definir seeds y middleware (`role`, `permission`).
- **JWT (tymon/jwt-auth 2.2)**: controlador `Api\Caja\AuthController` implementa login básico. Pendiente configurar:
  - Generación y renovación de tokens.
  - Guards `api` y `web` diferenciados.
  - Blacklist / revocación en logout.
  - Expiración y refresh tokens.

## 2. Autorización

- Middleware `auth` activo en rutas protegidas (`/profile`).  
- Rutas API actualmente sin guard → **riesgo**: exponen datos sensibles.
- Recomendado crear middleware `auth:api` + `role:...` para módulos:
  - Caja (cajero, supervisor).
  - Inventario (almacenista).
  - Recetas (chef, administrador).

## 3. Protección de Datos

- Sanitizar inputs vía validaciones (`FormRequest`, reglas Livewire).
- Usar `escapes` en vistas Blade (dom).  
- Revisar archivos subidos (`ReceptionCreate`: validar tamaño/tipo y limpiar metadatos).

## 4. Configuración del Servidor

- HTTPS obligatorio (configurar `APP_URL` y `trusted_proxies`).  
- Deshabilitar `APP_DEBUG` en producción.  
- Cachear config y rutas.
- Limitar acceso a `/__probe` y endpoints de diagnóstico.

## 5. Base de Datos

- Usuarios de DB con privilegios mínimos (separar lectura/escritura).  
- Registrar roles en `pg_hba.conf` y usar SSL si está disponible.  
- Asegurar `search_path` controlado (`DB_SCHEMA=selemti,public`).

## 6. Logging y Auditoría

- Laravel registra en `storage/logs/laravel.log`.  
- Revisar necesidad de logs específicos para caja (precortes/postcortes).  
- Considerar integrar Monolog con syslog/Elastic.

## 7. Próximos Pasos

- [ ] Definir matrix de roles/permisos y crear seeders.  
- [ ] Proteger rutas API con JWT y scopes.  
- [ ] Implementar rate limiting (`ThrottleRequests`) en endpoints públicos.  
- [ ] Configurar CORS para apps externas.  
- [ ] Auditar dependencias (`composer audit`, `npm audit`) antes de cada release.  
- [ ] Documentar procedimiento de alta/baja usuarios.

Actualiza este archivo conforme se habiliten nuevas políticas de seguridad.
