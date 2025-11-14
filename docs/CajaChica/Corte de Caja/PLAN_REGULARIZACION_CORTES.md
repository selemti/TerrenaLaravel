# Plan de Implementación: Sistema de Regularización de Cortes

**Fecha**: 10 Noviembre 2025
**Estado**: 🟡 En Progreso
**Prioridad**: Alta

---

## Resumen Ejecutivo

Implementar sistema de aprobación para cortes de caja que NO siguieron el flujo normal (sesiones con `skipped_precorte=true`), permitiendo a supervisores revisar y aprobar estos cortes irregulares.

---

## Progreso Actual

### ✅ Completado

1. **Esquema de Base de Datos** (`ADD_APROBACION_POSTCORTE.sql`)
   - ✅ Agregadas columnas a `selemti.postcorte`:
     - `requiere_aprobacion` (BOOLEAN)
     - `aprobado_por` (INTEGER → users.id)
     - `aprobado_en` (TIMESTAMP)
     - `motivo_irregular` (TEXT)
     - `rechazado` (BOOLEAN)
     - `motivo_rechazo` (TEXT)
   - ✅ Creada tabla `selemti.alertas_cortes`
   - ✅ Creados índices de rendimiento
   - ✅ Aplicado en LOCAL
   - ✅ Aplicado en SERVIDOR

### ⏳ Pendiente

2. **Permisos de Spatie**
   - Agregar permisos al seeder:
     - `aprobar-cortes-irregulares`
     - `rechazar-cortes-irregulares`
     - `ver-alertas-cortes`
   - Asignar permisos al rol "Super Admin"
   - Asignar a usuario `soporte@terrena.com`

3. **Backend - PostcorteController**
   - Modificar `create()`: Detectar `skipped_precorte` y marcar `requiere_aprobacion=true`
   - Modificar `update()`: NO cerrar sesión si `requiere_aprobacion && !aprobado_por`
   - Crear método `aprobar(Request, $id)`: Aprobar postcorte
   - Crear método `rechazar(Request, $id)`: Rechazar postcorte
   - Crear método `pendientesAprobacion()`: Listar postcortes pendientes

4. **Backend - Sistema de Alertas**
   - Crear `AlertasService` o helper para gestionar alertas
   - Método `crearAlertaAprobacion()`: Al crear postcorte irregular
   - Método `crearAlertaAprobado()`: Al aprobar postcorte
   - Método `crearAlertaRechazado()`: Al rechazar postcorte
   - Método `obtenerAlertasPendientes($userId)`: Para badge en menú

5. **Routes API**
   - `POST /api/caja/postcortes/{id}/aprobar` → `PostcorteController@aprobar`
   - `POST /api/caja/postcortes/{id}/rechazar` → `PostcorteController@rechazar`
   - `GET /api/caja/postcortes/pendientes-aprobacion` → `PostcorteController@pendientesAprobacion`
   - `GET /api/caja/alertas` → `AlertasController@index`
   - `PUT /api/caja/alertas/{id}/marcar-leida` → `AlertasController@marcarLeida`

6. **Frontend - Wizard de Corte** (`resources/views/caja/_wizard_modals.php` y `public/assets/js/caja/`)
   - Modificar Paso 3 (Postcorte):
     - Detectar si `sesion.skipped_precorte === true`
     - Mostrar banner de advertencia
     - Agregar campo `motivo_irregular` (textarea opcional)
     - Cambiar texto botón a "Enviar a Aprobación" en lugar de "Validar"
   - Al recibir respuesta con `requiere_aprobacion: true`:
     - Mostrar modal de éxito con mensaje personalizado
     - No cerrar el wizard, mantener en paso 3 con mensaje "Pendiente de Aprobación"

7. **Frontend - Vista de Aprobaciones**
   - Crear vista Blade: `resources/views/caja/aprobaciones.blade.php`
   - Tabla con postcortes pendientes:
     - Sesión ID
     - Terminal
     - Cajero
     - Fecha/Hora
     - Monto Total
     - Diferencias (efectivo, tarjetas, transferencias)
     - Motivo Irregular
     - Acciones: Ver Detalle | Aprobar | Rechazar
   - Modal para ver detalle completo del postcorte
   - Modal para aprobar (con textarea para notas)
   - Modal para rechazar (con textarea obligatoria para motivo)

8. **Frontend - Sistema de Alertas**
   - Badge en menú "Aprobaciones" con contador de pendientes
   - Componente de notificaciones en header/navbar
   - Auto-refresh cada X segundos

9. **Routes Web**
   - `GET /caja/cortes/aprobaciones` → Vista de aprobaciones
   - Agregar enlace en menú lateral

10. **Testing**
    - Crear sesión con `skipped_precorte=true`
    - Completar wizard hasta postcorte
    - Verificar que requiere aprobación
    - Aprobar desde vista de aprobaciones
    - Verificar que sesión se cierra correctamente
    - Verificar alertas se crean y marcan como leídas

---

## Estructura de Archivos

```
docs/docs/BD/NoviembreDocsDocs/10_11_2025/
  ├── ADD_APROBACION_POSTCORTE.sql          ✅ Completado
  ├── PLAN_REGULARIZACION_CORTES.md         ✅ Este archivo
  └── [futuros scripts SQL si necesario]

database/seeders/
  └── PermissionsSeeder.php                  ⏳ Agregar permisos

app/Http/Controllers/Api/Caja/
  ├── PostcorteController.php                ⏳ Modificar + nuevos métodos
  └── AlertasController.php                  ⏳ Crear nuevo

app/Services/
  └── AlertasService.php                     ⏳ Crear nuevo

routes/
  └── api.php                                ⏳ Agregar rutas

resources/views/caja/
  ├── _wizard_modals.php                     ⏳ Modificar Paso 3
  └── aprobaciones.blade.php                 ⏳ Crear nueva vista

public/assets/js/caja/
  ├── wizard.js                              ⏳ Modificar lógica Paso 3
  └── aprobaciones.js                        ⏳ Crear nuevo

resources/views/layouts/
  └── terrena.blade.php                      ⏳ Agregar enlace menú + badge
```

---

## Lógica de Flujo Detallada

### Flujo Normal (sin skipped_precorte)

```
Precorte → DPR → Postcorte → Validar
  ↓
sesion.estatus = 'CERRADA'
postcorte.validado = true
```

### Flujo con Regularización (skipped_precorte=true)

```
Precorte → DPR → Postcorte → "Enviar a Aprobación"
  ↓
postcorte.requiere_aprobacion = true
postcorte.validado = false
sesion.estatus = 'CERRADA' (pero postcorte sin aprobar)
Crear alerta para usuarios con permiso 'aprobar-cortes-irregulares'
  ↓
Supervisor revisa en /caja/cortes/aprobaciones
  ↓
[Aprobar]                          [Rechazar]
  ↓                                  ↓
postcorte.aprobado_por = user_id   postcorte.rechazado = true
postcorte.aprobado_en = NOW()      postcorte.motivo_rechazo = X
postcorte.validado = true          sesion.estatus = 'LISTO_PARA_CORTE' (reabrir)
Crear alerta "APROBADO"            Crear alerta "RECHAZADO"
```

---

## Queries Útiles

### Ver Postcortes Pendientes de Aprobación

```sql
SELECT
  p.id,
  p.sesion_id,
  s.terminal_id,
  s.cajero_usuario_id,
  u.first_name || ' ' || u.last_name as cajero,
  p.total_declarado_efectivo,
  p.total_sistema_efectivo,
  p.diferencia_efectivo,
  p.veredicto_efectivo,
  p.motivo_irregular,
  p.creado_en
FROM selemti.postcorte p
JOIN selemti.sesion_cajon s ON p.sesion_id = s.id
LEFT JOIN public.users u ON s.cajero_usuario_id = u.auto_id
WHERE p.requiere_aprobacion = TRUE
  AND p.aprobado_por IS NULL
  AND p.rechazado = FALSE
ORDER BY p.creado_en DESC;
```

### Ver Alertas Pendientes para un Usuario

```sql
SELECT
  a.id,
  a.tipo,
  a.sesion_id,
  a.postcorte_id,
  s.terminal_id,
  a.creada_en
FROM selemti.alertas_cortes a
LEFT JOIN selemti.sesion_cajon s ON a.sesion_id = s.id
WHERE a.destinatario_id = 3 -- user_id de soporte
  AND a.leida = FALSE
ORDER BY a.creada_en DESC;
```

### Marcar Sesiones Históricas con `requiere_aprobacion`

```sql
-- Marcar postcortes existentes con skipped_precorte como pendientes
UPDATE selemti.postcorte p
SET requiere_aprobacion = TRUE
FROM selemti.sesion_cajon s
WHERE p.sesion_id = s.id
  AND s.skipped_precorte = TRUE
  AND p.validado = FALSE
  AND p.aprobado_por IS NULL
  AND p.requiere_aprobacion = FALSE;
```

---

## Consideraciones de Seguridad

1. **Autorización**: Usar middleware `can:aprobar-cortes-irregulares` en rutas
2. **Auditoría**: Todos los cambios quedan registrados con user_id y timestamp
3. **Validación**: No permitir aprobar postcortes ya aprobados o rechazados
4. **Transacciones**: Usar DB::transaction() al aprobar/rechazar

---

## Casos Especiales

### Caso 1: Postcorte ya Validado con skipped_precorte

**Sesión 162**: Tiene `skipped_precorte=true` y `postcorte.validado=true`

**Solución**: No requiere acción. Ya está completa. El sistema solo aplica a futuros cortes.

### Caso 2: Postcorte No Validado con skipped_precorte

**Sesión 163**: Tiene `skipped_precorte=true` y `postcorte.validado=false`

**Solución**: Marcar `requiere_aprobacion=true` con el UPDATE query arriba. Crear alerta manual.

### Caso 3: Sesiones Abiertas Históricas (sin cerrar)

**Ejemplos**: Terminal 201, 301, 401 con estado "Abierta" desde hace días

**Solución**: Tema separado. Requiere herramienta de "Mantenimiento de Sesiones Huérfanas".

---

## Próximos Pasos (Orden Recomendado)

1. **Agregar permisos al seeder** (`PermissionsSeeder.php`)
2. **Crear AlertasService** para centralizar lógica de alertas
3. **Modificar PostcorteController** con lógica de aprobación
4. **Crear AlertasController** para API de alertas
5. **Agregar rutas API**
6. **Modificar wizard frontend** (Paso 3)
7. **Crear vista de aprobaciones**
8. **Agregar sistema de alertas en header**
9. **Testing completo del flujo**
10. **Documentar en manual de usuario**

---

## Referencias

- **Código existente**: `app/Http/Controllers/Api/Caja/PostcorteController.php:121-235`
- **Wizard JS**: `public/assets/js/caja/wizard.js`
- **Documentación**: `docs/CajaChica/WIZARD_CORTE_CAJA-20251017-0258.md`

---

**Creado por**: Claude Code
**Última actualización**: 2025-11-10 23:00
