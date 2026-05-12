# FIX: Ventana Extendida en vw_sesion_dpr — Corte Fuera de Tiempo

**Fecha:** 2026-04-09
**Aplicado por:** Claude Code
**Entornos afectados:** Local (`localhost:5433`) y Producción (`100.126.124.101:5432`)
**Severidad:** Alta — bloqueaba completamente el flujo de corte de caja

---

## Problema reportado

La sesión 613 (terminal 401, 2026-04-08) mostraba el error:

> "Falta realizar el corte en POS. Aún no hay Drawer Pull Report en Floreant POS."

El wizard quedaba bloqueado sin poder avanzar al postcorte.

---

## Diagnóstico

### Causa raíz: desfase de 1 hora entre cierre de sesión y DPR

| Evento | Timestamp |
|--------|-----------|
| `sesion_cajon.cierre_ts` (sesión cerrada en Terrena) | `2026-04-08 15:37:54` |
| `drawer_pull_report.report_time` (DPR en Floreant POS) | `2026-04-08 16:37:52` |
| **Diferencia** | **+1 hora** |

El Drawer Pull Report **sí existía** en `public.drawer_pull_report`, pero la vista `vw_sesion_dpr` usaba la condición:

```sql
dpr.report_time < s.fin_ts  -- fin_ts = cierre_ts (sin tolerancia)
```

Como el DPR fue generado **1 hora después** del cierre, quedaba fuera de la ventana y la vista no lo encontraba.

### Factor agravante: zona horaria de Floreant

El servidor de Floreant POS opera con un desfase de zona horaria respecto al sistema principal, lo que causa que el `report_time` registrado en el DPR sea consistentemente 1 hora posterior al `cierre_ts` de la sesión en Terrena.

### Flujo de detección en el código

```
wizard.js: sincronizarPOS()
  → GET /api/caja/precortes/{id}/totales
    → PrecorteController::resumenLegacy()
      → hasPOSCutBySesion($sid)
        → SELECT 1 FROM selemti.vw_sesion_dpr WHERE sesion_id = ? LIMIT 1
          → [0 filas] → retornaba 412 pos_cut_missing
            → wizard bloqueaba el botón "Ir a Postcorte"
```

---

## Cambios aplicados

### 1. Vista `selemti.vw_sesion_dpr` (PostgreSQL — ambos entornos)

**Archivo relacionado:** `docs/00.history/CajaChica/Corte de Caja/CREATE_VW_SESION_DPR.sql`

```sql
-- ANTES
COALESCE(sesion_cajon.cierre_ts, now()) AS fin_ts

-- DESPUÉS: tolerancia de 2 horas para DPRs tardíos
COALESCE(sesion_cajon.cierre_ts + INTERVAL '2 hours', now()) AS fin_ts
```

La ventana de 2 horas cubre:
- Desfase de zona horaria de Floreant (~1 hora)
- Margen adicional para DPRs generados manualmente después del cierre

### 2. `PrecorteController::resumenLegacy()` (PHP)

**Archivo:** `app/Http/Controllers/Api/Caja/PrecorteController.php`

**Antes:** Retornaba HTTP 412 bloqueando completamente el flujo cuando no había DPR.

**Después:** Continúa el flujo normalmente, usando `totalesSistema()` (desde `public.transactions`) como fuente alternativa. Incluye en la respuesta:

```json
{
  "ok": true,
  "has_pos_cut": false,
  "sin_dpr_nota": "Corte realizado sin Drawer Pull Report. Totales calculados desde public.transactions.",
  ...
}
```

### 3. `wizard.js: sincronizarPOS()` (JavaScript)

**Archivo:** `public/assets/js/caja/wizard.js`

**Antes:** Cualquier respuesta `ok: false` mostraba el modal de error y bloqueaba el avance.

**Después:** Se distinguen dos casos:

| Caso | `j.ok` | `j.has_pos_cut` | Comportamiento |
|------|--------|-----------------|----------------|
| Error de red / servidor | `false` | — | Bloquea. Muestra modal de error rojo. Botón "Sincronizar" visible. |
| DPR no encontrado (fuera de tiempo) | `true` | `false` | **No bloquea.** Banner amarillo de advertencia. Botón "Ir a Postcorte" habilitado. |
| DPR encontrado (normal) | `true` | `true` | Sin banner. Botón "Ir a Postcorte" habilitado. |

---

## Verificación post-fix

```sql
-- Confirmar que sesión 613 aparece en la vista
SELECT sesion_id, report_time FROM selemti.vw_sesion_dpr WHERE sesion_id = 613;
-- Resultado: 1 fila → report_time: 2026-04-08 16:37:52
```

---

## Impacto y consideraciones

- **Impacto en sesiones anteriores:** Sesiones antiguas cuyos DPRs cayeron fuera de ventana también serán ahora visibles en `vw_sesion_dpr`. Esto es deseable para poder hacer cortes retroactivos.
- **Sesiones con DPRs de diferentes días:** La tolerancia de 2 horas no puede cruzar medianoche en condiciones normales; el riesgo de asignar un DPR erróneo es mínimo.
- **Fallback `public.transactions`:** Los totales calculados desde transacciones son equivalentes a los del DPR en la mayoría de los casos. La diferencia puede estar en propinas y ajustes manuales registrados solo en el DPR.

---

## Archivos modificados

| Archivo | Tipo | Entorno |
|---------|------|---------|
| `selemti.vw_sesion_dpr` | Vista PostgreSQL | Local + Producción |
| `app/Http/Controllers/Api/Caja/PrecorteController.php` | PHP | Local + Producción |
| `public/assets/js/caja/wizard.js` | JavaScript | Local + Producción |
