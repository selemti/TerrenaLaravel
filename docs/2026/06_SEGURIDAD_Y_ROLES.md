# Seguridad y Roles — TerrenaLaravel
> Actualizado: Abril 2026 | Spatie Laravel Permission 6.x

## Sistema de Autenticación

| Mecanismo | Uso | Estado |
|-----------|-----|--------|
| Laravel Sanctum | Web sessions + API tokens | ✅ activo |
| JWT (tymon/jwt-auth) | API móvil / tablets POS | ✅ disponible |
| Spatie Permissions | RBAC (roles + permisos) | ✅ activo |

---

## Roles Definidos

| Rol | Descripción | Módulos de Acceso |
|-----|------------|-------------------|
| `admin` | Administrador total | Todos |
| `gerente` | Gerente de cafetería | Caja, Reportes, Inventario, Compras, Aprobaciones |
| `cajero` | Operador de caja | Caja (precorte), Caja Chica (movimientos) |
| `almacen` | Encargado de almacén | Inventario, Recepciones, Transferencias |
| `chef` | Chef / producción | Recetas, Producción, Conteos |
| `compras` | Encargado de compras | Compras, Proveedores, Reposición |
| `auditor` | Solo lectura | Auditoría, Reportes |

---

## Permisos Clave

| Permiso | Módulo | Quién lo tiene |
|---------|--------|----------------|
| `reports.view` | Reportes | gerente, admin, auditor |
| `audit.view` | Auditoría | admin, auditor |
| `admin.access` | Panel admin | admin |
| `pos.mapping.view` | POS Sync mapeo | admin, gerente |
| `approve-cash-funds` | Aprobaciones caja chica | gerente, admin |
| `can:admin.access` | Tickets admin | admin |

---

## Middlewares en Rutas

```php
// API con autenticación completa
Route::middleware(['auth:sanctum', 'permission:reports.view'])

// Auditoría
Route::middleware(['auth:sanctum', 'permission:audit.view'])

// Admin
Route::middleware(['can:admin.access'])

// Caja (⚠️ PENDIENTE REACTIVAR)
// Actualmente: sin middleware
// Debería ser: Route::middleware(['auth:sanctum'])
```

---

## Tablas RBAC (Spatie)

| Tabla | Contenido |
|-------|----------|
| `selemti.roles` | Definición de roles |
| `selemti.permissions` | Definición de permisos |
| `selemti.model_has_roles` | Usuario → Rol |
| `selemti.model_has_permissions` | Usuario → Permiso directo |
| `selemti.role_has_permissions` | Rol → Permisos |

---

## API Token de Sesión

```
GET  /session/api-token    → Generar token para la sesión actual
POST /session/api-token/revoke → Revocar token
```

Usado principalmente por las tablets POS para autenticarse contra la API.

---

## Auditoría

- `AuditLog` model registra operaciones importantes
- Middleware de auditoría en rutas críticas
- `GET /audit/logs` — visible solo con `permission:audit.view`
- Política de retención en `docs/AUDIT_LOG_POLICY.md`

---

## Consideraciones de Seguridad

1. **CRÍTICO:** Reactivar `auth:sanctum` en `/api/caja/*` antes de producción
2. Tokens Sanctum tienen expiración configurada en `config/sanctum.php`
3. CORS configurado en `config/cors.php` — revisar origins permitidos en producción
4. Passwords hasheados con bcrypt (Laravel default)
5. **AUDITORÍA FISCAL**: El log de consumo recursivo en `selemti.inv_consumo_pos_det` es la evidencia legal para mermas masivas; no debe permitir borrados incluso por el rol `admin`.
