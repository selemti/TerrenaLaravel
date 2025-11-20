# Documentación - Sistema de Cortes de Caja

**Ubicación**: `docs/CajaChica/Corte de Caja/`
**Última actualización**: 2025-11-11

---

## Descripción General

Este directorio contiene toda la documentación relacionada con el sistema de Cortes de Caja, incluyendo el flujo normal de cortes (Precorte → DPR → Postcorte) y el sistema de regularización para cortes irregulares.

---

## Archivos de Documentación

### 📋 Planes e Implementación

**PLAN_REGULARIZACION_CORTES.md**
- Plan completo de implementación del sistema de aprobación
- 10 fases de desarrollo
- Estructura de archivos y lógica de flujo
- Casos especiales y consideraciones de seguridad
- Estado: 🟡 En Progreso (Fase 2/10)

**MODIFICACIONES_POSTCORTE_CONTROLLER.md**
- Guía detallada de modificaciones al PostcorteController
- Incluye: imports, constructor, métodos modificados y nuevos métodos
- Código listo para aplicar
- Estado: 📝 Documentado

### 📊 Resúmenes de Sesión

**RESUMEN_SESION_10_NOV_2025.md**
- Resumen completo de la sesión de desarrollo del 10 de noviembre 2025
- Problemas encontrados y soluciones implementadas
- Scripts SQL ejecutados
- Comandos y verificaciones realizadas
- Métricas de progreso

### 🗄️ Scripts SQL

**ADD_APROBACION_POSTCORTE.sql**
- Agrega columnas para sistema de aprobación en `selemti.postcorte`
- Crea tabla `selemti.alertas_cortes`
- Crea índices de rendimiento
- Compatible con PostgreSQL 9.5
- Estado: ✅ Aplicado en local y servidor

**CREATE_VW_SESION_DPR.sql**
- Crea vista `selemti.vw_sesion_dpr`
- Vincula sesiones de caja con Drawer Pull Reports (DPR)
- Crítico para validar que el corte POS fue completado
- Estado: ✅ Aplicado en local y servidor

**FIX_SESION_CAJON_ESTATUS_CHECK.sql**
- Corrige CHECK constraint en `selemti.sesion_cajon.estatus`
- Agrega estado 'EN_CORTE' que faltaba
- Resuelve Error 500 al crear precortes
- Estado: ✅ Aplicado en local y servidor

---

## Flujo de Cortes de Caja

### Flujo Normal

```
1. Precorte
   ↓
2. Corte POS (Drawer Pull Report)
   ↓
3. Postcorte
   ↓
4. Validación
   ↓
5. Sesión CERRADA
```

### Flujo con Regularización (skipped_precorte=true)

```
1. ❌ Precorte saltado
   ↓
2. Corte POS realizado
   ↓
3. Precorte tardío (marcado como irregular)
   ↓
4. Postcorte → Requiere Aprobación
   ↓
5. Alerta enviada a supervisores
   ↓
6. Supervisor revisa y decide:

   [APROBAR]                    [RECHAZAR]
      ↓                            ↓
   Postcorte validado         Sesión reabierta
   Sesión CERRADA             Estado: LISTO_PARA_CORTE
   Alerta a cajero            Alerta a cajero con motivo
```

---

## Problemas Resueltos

### ✅ Error 412: pos_cut_missing
- **Causa**: Vista `selemti.vw_sesion_dpr` no existía
- **Solución**: Creada vista desde definición en dump
- **Archivo**: `CREATE_VW_SESION_DPR.sql`

### ✅ Error 500: CHECK constraint violation
- **Causa**: Constraint no incluía estado 'EN_CORTE'
- **Solución**: Modificado constraint para incluir todos los estados
- **Archivo**: `FIX_SESION_CAJON_ESTATUS_CHECK.sql`

### ✅ Falta de sistema de aprobación para cortes irregulares
- **Causa**: No existía flujo para sesiones con `skipped_precorte=true`
- **Solución**: Sistema de aprobación híbrido implementado
- **Archivos**: `ADD_APROBACION_POSTCORTE.sql`, `PLAN_REGULARIZACION_CORTES.md`

---

## Permisos del Sistema

El sistema de aprobación usa 3 permisos de Spatie:

1. **aprobar-cortes-irregulares** - Permite aprobar postcortes irregulares
2. **rechazar-cortes-irregulares** - Permite rechazar postcortes irregulares
3. **ver-alertas-cortes** - Permite ver alertas de cortes pendientes

**Asignados a**: Rol "Super Admin" y usuario soporte@terrena.com

---

## Archivos de Código

### Backend

**app/Services/Caja/AlertasService.php**
- Servicio para gestión de alertas
- Métodos: crear, obtener, marcar como leída
- Estado: ✅ Creado

**app/Http/Controllers/Api/Caja/PostcorteController.php**
- Controlador principal de postcortes
- Métodos modificados: `create()`, `update()`
- Nuevos métodos: `pendientesAprobacion()`, `aprobar()`, `rechazar()`
- Estado: ⏳ Pendiente aplicar modificaciones

**app/Http/Controllers/Api/Caja/AlertasController.php**
- Controlador API para alertas
- Estado: ⏳ Pendiente crear

### Frontend

**resources/views/caja/_wizard_modals.php**
- Wizard de 3 pasos para cortes
- Estado: ⏳ Pendiente modificar Paso 3

**resources/views/caja/aprobaciones.blade.php**
- Vista para supervisores: lista de postcortes pendientes
- Estado: ⏳ Pendiente crear

**public/assets/js/caja/wizard.js**
- Lógica JavaScript del wizard
- Estado: ⏳ Pendiente modificar

---

## Queries Útiles

### Ver postcortes pendientes de aprobación

```sql
SELECT
  p.id,
  p.sesion_id,
  s.terminal_id,
  p.total_declarado_efectivo,
  p.diferencia_efectivo,
  p.motivo_irregular,
  p.creado_en
FROM selemti.postcorte p
JOIN selemti.sesion_cajon s ON p.sesion_id = s.id
WHERE p.requiere_aprobacion = TRUE
  AND p.aprobado_por IS NULL
  AND p.rechazado = FALSE
ORDER BY p.creado_en DESC;
```

### Ver alertas pendientes para un usuario

```sql
SELECT
  a.id,
  a.tipo,
  a.sesion_id,
  s.terminal_id,
  a.creada_en
FROM selemti.alertas_cortes a
LEFT JOIN selemti.sesion_cajon s ON a.sesion_id = s.id
WHERE a.destinatario_id = 3  -- user_id
  AND a.leida = FALSE
ORDER BY a.creada_en DESC;
```

---

## Referencias Cruzadas

- **Código PostcorteController**: `app/Http/Controllers/Api/Caja/PostcorteController.php:121-235`
- **Wizard JS**: `public/assets/js/caja/wizard.js`
- **Documentación Wizard**: `docs/WIZARD_CORTE_CAJA-20251017-0258.md`
- **Esquema DB**: `BD/00.SelemTI_Normalizada_29_10_25_10_40_v0.sql`

---

**Creado por**: Claude Code
**Última actualización**: 2025-11-11
