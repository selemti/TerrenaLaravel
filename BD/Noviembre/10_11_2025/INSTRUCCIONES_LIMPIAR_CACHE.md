# Instrucciones para Limpiar Caché de Permisos

**Problema**: Los archivos de caché pertenecen al usuario `www-data` (Apache) y el usuario `terrena` no puede eliminarlos sin `sudo`.

**Fecha**: 10 Noviembre 2025

---

## Opción 1: Limpiar Caché Manualmente (MÁS SIMPLE)

Conéctate al servidor y ejecuta estos comandos **uno por uno**:

```bash
# 1. Conectar al servidor
ssh terrena@100.126.124.101
# Password: T3rr3n4#123

# 2. Navegar al directorio de la aplicación
cd /var/www/kds/terrenaPos

# 3. Arreglar permisos de los archivos de caché (necesita sudo)
sudo chmod -R 775 storage/framework/cache/data
sudo chown -R terrena:www-data storage/framework/cache/data

# 4. Ahora sí, limpiar el caché (ya no necesita sudo)
rm -rf storage/framework/cache/data/*

# 5. Limpiar también el caché de configuración
php artisan config:clear

# 6. Verificar que se limpió correctamente
ls storage/framework/cache/data/
# Debería mostrar solo directorios vacíos o nada

echo "✓ Cache cleared successfully!"
```

---

## Opción 2: Usar Artisan (ALTERNATIVA - Puede requerir permisos)

Si prefieres usar los comandos de Laravel:

```bash
ssh terrena@100.126.124.101
cd /var/www/kds/terrenaPos

# Intentar limpiar con artisan
php artisan cache:clear
php artisan config:clear

# Si falla por permisos, primero ejecutar:
sudo chown -R terrena:www-data storage/
sudo chmod -R 775 storage/

# Luego volver a intentar
php artisan cache:clear
php artisan config:clear
```

---

## Opción 3: Reiniciar Apache (SI LAS ANTERIORES NO FUNCIONAN)

Como último recurso, reiniciar Apache también limpia el caché en memoria:

```bash
ssh terrena@100.126.124.101
sudo systemctl restart apache2
```

---

## PASO FINAL MUY IMPORTANTE

Una vez que hayas limpiado el caché en el servidor:

### **DEBES hacer lo siguiente en la aplicación web:**

1. **Cerrar sesión** completamente de la aplicación (logout)
2. **Cerrar el navegador** o limpiar cookies (Ctrl+Shift+Del → Cookies)
3. **Abrir el navegador de nuevo**
4. **Iniciar sesión** nuevamente con `soporte@terrena.com`
5. **Verificar que ahora ves TODOS los menús**

⚠️ **MUY IMPORTANTE**: Si no cierras sesión y vuelves a entrar, es muy probable que **AÚN no veas los menús** porque tu sesión mantiene datos cacheados.

---

## Verificación Final

Una vez que hayas hecho login nuevamente, verifica que puedes ver estos menús:

- Inventario
  - Items
  - Recepciones
  - Lotes
  - Traslados
  - Conteos físicos
- Recetas
  - Ver recetas
  - Crear/editar recetas
  - Análisis de costos
- Compras
  - Solicitudes de compra
  - Órdenes de compra
  - Proveedores
- Reportes
  - Ventas
  - Producción
  - Inventario
- Administración
  - Usuarios
  - Roles
  - Permisos
  - Configuración

Si puedes ver **todos** estos menús, el problema está resuelto ✅

---

## Si AÚN NO funciona

Si después de hacer todo lo anterior todavía no ves los menús, ejecuta este comando para verificar el estado de los permisos en la base de datos:

```bash
ssh terrena@100.126.124.101

PGPASSWORD='T3rr3n4#p0s' psql -h localhost -U postgres -d pos -c "
  SELECT
    u.email,
    r.name as role_name,
    COUNT(DISTINCT p.id) as permissions_count
  FROM selemti.users u
  JOIN selemti.model_has_roles mhr ON u.id = mhr.model_id
  JOIN selemti.roles r ON mhr.role_id = r.id
  LEFT JOIN selemti.role_has_permissions rp ON r.id = rp.role_id
  LEFT JOIN selemti.permissions p ON rp.permission_id = p.id
  WHERE u.email = 'soporte@terrena.com'
  GROUP BY u.email, r.name;
"
```

**Resultado esperado**:
```
         email          | role_name   | permissions_count
------------------------+-------------+-------------------
 soporte@terrena.com    | Super Admin |                45
```

Si el resultado muestra 45 permisos, entonces **la base de datos está correcta** y el problema es 100% de caché/sesión.

---

## Resumen de lo que hiciste antes

Ya completaste estos pasos correctamente (NO repetir):

✅ Ejecutar seeder `PermissionsSeeder` (119 role_has_permissions creados)
✅ Asignar rol "Super Admin" al usuario soporte@terrena.com
✅ Verificar que la base de datos tiene todos los datos correctos

---

**Próximo paso**: Limpiar caché + Re-login del usuario

**Tiempo estimado**: 3 minutos

**Dificultad**: Fácil (solo necesitas ejecutar comandos en SSH)
