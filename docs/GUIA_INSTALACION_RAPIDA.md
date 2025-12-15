# 🚀 Guía de Instalación Rápida
## Sistema de Sincronización Floreant-Laravel

---

## ⚡ Instalación (5 minutos)

### 1️⃣ Aplicar Trigger Principal
```bash
psql -h localhost -p 5433 -U postgres -d pos -f trigger_corregido.sql
```
**Resultado esperado:**
```
TRIGGER CORREGIDO CREADO
```

### 2️⃣ Crear Vistas de Monitoreo
```bash
psql -h localhost -p 5433 -U postgres -d pos -f vista_monitoreo_corregida.sql
```
**Resultado esperado:**
```
Vistas de monitoreo corregidas correctamente
```

### 3️⃣ Verificar Instalación
```sql
SELECT * FROM vw_sync_resumen;
```
**Resultado esperado:**
```
sync_status   | total_eventos | usuarios_unicos
---------------+---------------+-----------------
NO_SINCronizado|      27       |        7
SESION_CERRADA |       2       |        1
```

---

## 🔍 Verificación Rápida

### Test de Sincronización
```sql
-- Insertar evento de prueba
INSERT INTO public.drawer_assigned_history (time, operation, a_user)
VALUES (CURRENT_TIMESTAMP, 'ASIGNAR', 12)
RETURNING id;

-- Verificar si se creó sesión
SELECT * FROM selemti.sesion_cajon
WHERE dah_evento_id = [ID_RETORNADO];
```

### Verificar Trigger Activo
```sql
SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgrelid = 'public.drawer_assigned_history'::regclass;
```

---

## 📊 Monitoreo Básico

### Estados Actuales
```sql
SELECT * FROM vw_sync_resumen ORDER BY total_eventos DESC;
```

### Sesiones Activas
```sql
SELECT COUNT(*) as sesiones_activas
FROM selemti.sesion_cajon
WHERE estatus = 'ACTIVA';
```

### Errores Recientes
```sql
SELECT * FROM vw_sync_errores LIMIT 5;
```

---

## 🛠️ Mantenimiento

### Reiniciar Sistema (si es necesario)
```bash
# 1. Desactivar trigger
DROP TRIGGER IF EXISTS trg_selemti_dah_ai ON public.drawer_assigned_history;

# 2. Reaplicar
psql -f trigger_corregido.sql

# 3. Verificar
SELECT * FROM vw_sync_resumen;
```

### Limpiar Logs Antiguos (Opcional)
```sql
DELETE FROM selemti.auditoria
WHERE creado_en < CURRENT_DATE - INTERVAL '90 days';
```

---

## ⚠️ Troubleshooting

### Problema: No se crean sesiones
**Verificar:**
```sql
-- ¿Usuario tiene terminal asignada?
SELECT t.id, t.name, u.first_name
FROM public.terminal t
JOIN public.users u ON t.assigned_user = u.auto_id
WHERE u.auto_id = [USER_ID];
```

### Problema: Trigger no funciona
**Reinstalar:**
```bash
psql -f trigger_corregido.sql
```

### Problema: Errores de sincronización
**Verificar logs:**
```sql
SELECT creado_en, que, payload::text
FROM selemti.auditoria
WHERE creado_en >= CURRENT_DATE
ORDER BY creado_en DESC;
```

---

## 🎯 Checklist Final

- [ ] ✅ Trigger instalado y activo
- [ ] ✅ Vistas de monitoreo funcionando
- [ ] ✅ Test de sincronización validado
- [ ] ✅ Usuarios con terminales asignadas
- [ ] ✅ Sin errores recientes

---

## 📞 Soporte Rápido

### Comandos de Emergencia
```sql
-- Estado general del sistema
SELECT 'Eventos totales:' || COUNT(*) FROM public.drawer_assigned_history
UNION ALL
SELECT 'Sesiones totales:' || COUNT(*) FROM selemti.sesion_cajon
UNION ALL
SELECT 'Sesiones activas:' || COUNT(*) FROM selemti.sesion_cajon WHERE estatus = 'ACTIVA'
UNION ALL
SELECT 'Errores recientes:' || COUNT(*) FROM selemti.auditoria WHERE creado_en >= CURRENT_DATE AND que LIKE 'ERROR%';
```

### Verificación Completa
```sql
SELECT * FROM vw_sync_status
WHERE event_time >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
ORDER BY event_time DESC LIMIT 10;
```

---

## 🏆 Resultado Esperado

Si todo está correcto, deberías ver:
- ✅ **2+ vistas** de monitoreo funcionando
- ✅ **Trigger activo** en drawer_assigned_history
- ✅ **Sesiones creándose** cuando asignas cajones en Floreant
- ✅ **Timestamps exactos** con milisegundos
- ✅ **Cero errores** en operación normal

---

**¡Listo! Sistema sincronización instalado y funcionando.** 🚀

*Para más detalles, ver `docs/SINCRONIZACION_FLOREANT_LARAVEL.md`*