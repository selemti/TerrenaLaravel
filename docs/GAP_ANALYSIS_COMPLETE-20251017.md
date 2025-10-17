# 📊 ANÁLISIS COMPLETO DE GAPS - Sistema de Cortes de Caja
## Fecha: 2025-10-17

---

## 🎯 RESUMEN EJECUTIVO

**Estado General:** 70% implementado
- ✅ **Tablas Core:** sesion_cajon, precorte, postcorte, precorte_efectivo, precorte_otros
- ✅ **Vistas:** vw_conciliacion_sesion, vw_sesion_dpr, vw_conciliacion_efectivo
- ✅ **Controladores API:** CajasController, PrecorteController, PostcorteController
- ⚠️ **Falta:** Triggers automáticos, tabla conciliacion, validaciones fuertes

---

## ❌ CRÍTICO - LO QUE FALTA

### 1. BASE DE DATOS

#### 1.1 Tabla `selemti.conciliacion` ⛔ NO EXISTE
```sql
CREATE TABLE selemti.conciliacion (
  id BIGSERIAL PRIMARY KEY,
  postcorte_id BIGINT NOT NULL UNIQUE REFERENCES selemti.postcorte(id) ON DELETE CASCADE,
  conciliado_por INTEGER,
  conciliado_en TIMESTAMPTZ DEFAULT now(),
  estatus TEXT NOT NULL DEFAULT 'EN_REVISION'
    CHECK (estatus IN ('EN_REVISION','CONCILIADO','OBSERVADA')),
  notas TEXT
);
```

#### 1.2 Constraint UNIQUE en `precorte(sesion_id)` ⛔ NO EXISTE
**Estado Actual:** postcorte tiene UNIQUE(sesion_id) ✅, pero precorte NO ❌
```sql
ALTER TABLE selemti.precorte
ADD CONSTRAINT uq_precorte_sesion_id UNIQUE(sesion_id);
```

#### 1.3 CHECK Constraint de `sesion_cajon.estatus` ⚠️ INCOMPLETO
**Estado Actual:** Solo permite: ACTIVA, LISTO_PARA_CORTE, CERRADA
**Requerido:** Agregar: EN_CORTE, CONCILIADA, OBSERVADA

```sql
ALTER TABLE selemti.sesion_cajon
DROP CONSTRAINT sesion_cajon_estatus_check;

ALTER TABLE selemti.sesion_cajon
ADD CONSTRAINT sesion_cajon_estatus_check
CHECK (estatus IN (
  'ACTIVA',
  'LISTO_PARA_CORTE',
  'EN_CORTE',
  'CERRADA',
  'CONCILIADA',
  'OBSERVADA'
));
```

#### 1.4 Triggers de Transición de Estados ⛔ NO EXISTEN

**A. Trigger: Precorte INSERT → sesión EN_CORTE**
```sql
CREATE OR REPLACE FUNCTION selemti.fn_precorte_after_insert()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE selemti.sesion_cajon
  SET estatus = 'EN_CORTE'
  WHERE id = NEW.sesion_id
    AND estatus = 'LISTO_PARA_CORTE';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_precorte_after_insert
AFTER INSERT ON selemti.precorte
FOR EACH ROW
EXECUTE FUNCTION selemti.fn_precorte_after_insert();
```

**B. Trigger: Precorte UPDATE (APROBADO) → genera postcorte**
```sql
CREATE OR REPLACE FUNCTION selemti.fn_precorte_after_update_aprobado()
RETURNS TRIGGER AS $$
DECLARE
  v_postcorte_id BIGINT;
BEGIN
  IF NEW.estatus = 'APROBADO' AND OLD.estatus != 'APROBADO' THEN
    -- Generar postcorte automáticamente
    SELECT selemti.fn_generar_postcorte(NEW.sesion_id) INTO v_postcorte_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_precorte_after_update_aprobado
AFTER UPDATE ON selemti.precorte
FOR EACH ROW
WHEN (NEW.estatus = 'APROBADO' AND OLD.estatus IS DISTINCT FROM 'APROBADO')
EXECUTE FUNCTION selemti.fn_precorte_after_update_aprobado();
```

**C. Trigger: Postcorte INSERT → sesión CERRADA**
```sql
CREATE OR REPLACE FUNCTION selemti.fn_postcorte_after_insert()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE selemti.sesion_cajon
  SET estatus = 'CERRADA',
      cierre_ts = COALESCE(cierre_ts, now())
  WHERE id = NEW.sesion_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_postcorte_after_insert
AFTER INSERT ON selemti.postcorte
FOR EACH ROW
EXECUTE FUNCTION selemti.fn_postcorte_after_insert();
```

#### 1.5 Función `fn_generar_postcorte(p_sesion_id)` ⛔ NO EXISTE
```sql
CREATE OR REPLACE FUNCTION selemti.fn_generar_postcorte(p_sesion_id BIGINT)
RETURNS BIGINT AS $$
DECLARE
  v_postcorte_id BIGINT;
  v_precorte_id BIGINT;
  v_terminal_id INT;
  v_apertura_ts TIMESTAMPTZ;
  v_cierre_ts TIMESTAMPTZ;

  -- Declarados
  v_decl_ef NUMERIC;
  v_decl_cr NUMERIC;
  v_decl_db NUMERIC;
  v_decl_tr NUMERIC;

  -- Sistema
  v_sys_ef NUMERIC;
  v_sys_cr NUMERIC;
  v_sys_db NUMERIC;
  v_sys_tr NUMERIC;

  -- Diferencias
  v_dif_ef NUMERIC;
  v_dif_tj NUMERIC;
  v_dif_tr NUMERIC;
BEGIN
  -- Obtener datos de sesión
  SELECT terminal_id, apertura_ts, cierre_ts
  INTO v_terminal_id, v_apertura_ts, v_cierre_ts
  FROM selemti.sesion_cajon
  WHERE id = p_sesion_id;

  -- Obtener precorte_id
  SELECT id INTO v_precorte_id
  FROM selemti.precorte
  WHERE sesion_id = p_sesion_id
  ORDER BY id DESC LIMIT 1;

  -- Calcular declarados (desde precorte)
  SELECT
    COALESCE(SUM(subtotal), 0)
  INTO v_decl_ef
  FROM selemti.precorte_efectivo
  WHERE precorte_id = v_precorte_id;

  SELECT
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('CREDITO') THEN monto ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('DEBITO', 'DÉBITO') THEN monto ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(tipo) IN ('TRANSFER', 'TRANSFERENCIA') THEN monto ELSE 0 END), 0)
  INTO v_decl_cr, v_decl_db, v_decl_tr
  FROM selemti.precorte_otros
  WHERE precorte_id = v_precorte_id;

  -- Calcular sistema (desde transactions POS)
  SELECT
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CASH' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CREDIT_CARD' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'DEBIT_CARD' THEN amount ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN UPPER(payment_type) = 'CUSTOM_PAYMENT' AND UPPER(custom_payment_name) LIKE 'TRANSFER%' THEN amount ELSE 0 END), 0)
  INTO v_sys_ef, v_sys_cr, v_sys_db, v_sys_tr
  FROM public.transactions
  WHERE terminal_id = v_terminal_id
    AND transaction_time BETWEEN v_apertura_ts AND COALESCE(v_cierre_ts, now())
    AND UPPER(transaction_type) = 'CREDIT'
    AND voided = false;

  -- Calcular diferencias
  v_dif_ef := v_decl_ef - v_sys_ef;
  v_dif_tj := (v_decl_cr + v_decl_db) - (v_sys_cr + v_sys_db);
  v_dif_tr := v_decl_tr - v_sys_tr;

  -- Insertar postcorte
  INSERT INTO selemti.postcorte (
    sesion_id,
    sistema_efectivo_esperado, declarado_efectivo, diferencia_efectivo, veredicto_efectivo,
    sistema_tarjetas, declarado_tarjetas, diferencia_tarjetas, veredicto_tarjetas,
    sistema_transferencias, declarado_transferencias, diferencia_transferencias, veredicto_transferencias,
    creado_en, creado_por
  ) VALUES (
    p_sesion_id,
    v_sys_ef, v_decl_ef, v_dif_ef,
    CASE WHEN ABS(v_dif_ef) < 0.01 THEN 'CUADRA' WHEN v_dif_ef > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
    v_sys_cr + v_sys_db, v_decl_cr + v_decl_db, v_dif_tj,
    CASE WHEN ABS(v_dif_tj) < 0.01 THEN 'CUADRA' WHEN v_dif_tj > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
    v_sys_tr, v_decl_tr, v_dif_tr,
    CASE WHEN ABS(v_dif_tr) < 0.01 THEN 'CUADRA' WHEN v_dif_tr > 0 THEN 'A_FAVOR' ELSE 'EN_CONTRA' END,
    now(), 1
  )
  ON CONFLICT (sesion_id) DO UPDATE SET
    sistema_efectivo_esperado = EXCLUDED.sistema_efectivo_esperado,
    declarado_efectivo = EXCLUDED.declarado_efectivo,
    diferencia_efectivo = EXCLUDED.diferencia_efectivo,
    veredicto_efectivo = EXCLUDED.veredicto_efectivo
  RETURNING id INTO v_postcorte_id;

  RETURN v_postcorte_id;
END;
$$ LANGUAGE plpgsql;
```

#### 1.6 Índices de Performance ⚠️ FALTAN
```sql
-- Índice en precorte_efectivo(precorte_id) para FK
CREATE INDEX IF NOT EXISTS idx_precorte_efectivo_precorte_id
ON selemti.precorte_efectivo(precorte_id);

-- Índice en precorte_otros(precorte_id) para FK
CREATE INDEX IF NOT EXISTS idx_precorte_otros_precorte_id
ON selemti.precorte_otros(precorte_id);

-- Índice parcial en public.ticket para preflight check
CREATE INDEX IF NOT EXISTS idx_ticket_terminal_open
ON public.ticket(terminal_id, closing_date)
WHERE closing_date IS NULL;
```

---

### 2. BACKEND (Controllers/Requests)

#### 2.1 FormRequests ⚠️ INCOMPLETOS

**StorePrecorteRequest.php** - tiene `authorize(): false` (no se usa)

**Faltan crear:**
```php
// app/Http/Requests/Caja/UpdatePrecorteRequest.php
public function rules(): array
{
    return [
        'denoms_json' => 'required|json',
        'declarado_credito' => 'required|numeric|min:0',
        'declarado_debito' => 'required|numeric|min:0',
        'declarado_transfer' => 'required|numeric|min:0',
        'notas' => 'nullable|string|max:500',
    ];
}

// app/Http/Requests/Caja/CreatePostcorteRequest.php
// app/Http/Requests/Caja/UpdatePostcorteRequest.php
public function rules(): array
{
    return [
        'veredicto_efectivo' => 'nullable|in:CUADRA,A_FAVOR,EN_CONTRA',
        'veredicto_tarjetas' => 'nullable|in:CUADRA,A_FAVOR,EN_CONTRA',
        'veredicto_transferencias' => 'nullable|in:CUADRA,A_FAVOR,EN_CONTRA',
        'notas' => 'nullable|string|max:1000',
        'validado' => 'nullable|boolean',
        'sesion_estatus' => 'nullable|in:CERRADA',
    ];
}
```

#### 2.2 Controllers - Lógica Faltante

**PrecorteController::updateLegacy()** ✅ Ya existe y funciona

**PostcorteController::create()** ⚠️ Revisar si marca estatus de sesión
```php
// Después de crear postcorte, debe actualizar:
DB::update("UPDATE selemti.sesion_cajon SET estatus = 'CERRADA' WHERE id = ?", [$sesionId]);
```

**PostcorteController::update()** ⚠️ Revisar validación de `validado`
```php
// Al validar postcorte (validado=true), debe:
// 1. Verificar que no esté ya validado
// 2. Marcar timestamps
// 3. Cerrar sesión si no está cerrada
```

#### 2.3 Middleware de Autenticación ⚠️ NO APLICADO
**Estado:** Rutas `/api/caja/*` están sin middleware `auth`

```php
// routes/api.php - FALTA aplicar:
Route::middleware(['auth:sanctum'])->prefix('caja')->group(function () {
    // ... todas las rutas de caja
});
```

---

### 3. FRONTEND (JavaScript/Blade)

#### 3.1 IDs de Modal Inconsistentes ⛔ BUG CONOCIDO
**Archivos afectados:**
- `resources/views/caja/_wizard_modals.php` → usa `id="wizardPrecorte"`
- `public/assets/js/caja/wizard.js:61` → busca `'czModalPrecorte'`
- `public/assets/js/caja/state.js:14,50` → mezcla ambos IDs

**Solución:**
```html
<!-- _wizard_modals.blade.php -->
<div class="modal fade" id="czModalPrecorte" ...>
```

#### 3.2 store_id Hardcodeado ⚠️ MALA PRÁCTICA
**Archivo:** `public/assets/js/caja/mainTable.js:32`
```javascript
// ❌ ACTUAL
const store = 1;

// ✅ DEBE SER
const store = currentSession.store_id; // desde API
```

#### 3.3 Función `puedeWizard()` Siempre Retorna `true` ⚠️
**Archivo:** `public/assets/js/caja/mainTable.js:27`
```javascript
// ❌ ACTUAL
return true;

// ✅ DEBE SER
return asignadaActiva || validacionSinPC || saltoSinPrecorte;
```

#### 3.4 Inputs sin atributo `name` ⚠️
**Archivos:** inputs en modal wizard no tienen `name=""`, lo que dificulta debugging

---

## ⚠️ IMPORTANTE - RECOMENDACIONES

### Orden de Implementación

**FASE 1: Base de Datos (1-2 días)**
1. Crear tabla `conciliacion`
2. Agregar UNIQUE constraint en `precorte(sesion_id)`
3. Actualizar CHECK constraint de `sesion_cajon.estatus`
4. Crear triggers de transición de estados
5. Crear función `fn_generar_postcorte()`
6. Crear índices de performance

**FASE 2: Backend (2-3 días)**
1. Crear FormRequests con validaciones fuertes
2. Aplicar middleware `auth:sanctum` a rutas `/api/caja/*`
3. Revisar lógica de PostcorteController
4. Agregar auditoría completa (logs)

**FASE 3: Frontend (1-2 días)**
1. Unificar IDs de modal a `czModalPrecorte`
2. Eliminar `store_id` hardcodeado
3. Reactivar lógica real de `puedeWizard()`
4. Agregar `name=""` a inputs

**FASE 4: Testing (1-2 días)**
1. Tests Feature de preflight/precorte/postcorte
2. Tests de concurrencia
3. Tests de idempotencia

---

## 📋 CHECKLIST DE VALIDACIÓN

### Database
- [ ] Tabla `selemti.conciliacion` creada
- [ ] UNIQUE constraint en `precorte(sesion_id)`
- [ ] CHECK constraint actualizado en `sesion_cajon.estatus`
- [ ] Trigger: precorte INSERT → EN_CORTE
- [ ] Trigger: precorte UPDATE (APROBADO) → postcorte
- [ ] Trigger: postcorte INSERT → CERRADA
- [ ] Función `fn_generar_postcorte()` creada
- [ ] Índices de performance creados

### Backend
- [ ] FormRequests creados y aplicados
- [ ] Middleware `auth` aplicado
- [ ] PostcorteController actualiza estatus
- [ ] Auditoría implementada

### Frontend
- [ ] IDs de modal unificados
- [ ] `store_id` desde API
- [ ] `puedeWizard()` lógica real
- [ ] Inputs con `name` attribute

### Testing
- [ ] Tests de flujo completo
- [ ] Tests de concurrencia
- [ ] Tests de idempotencia

---

## 🎯 ESTADO FINAL ESPERADO

Cuando todo esté implementado:

1. ✅ Sesión pasa automáticamente de `ACTIVA` → `EN_CORTE` → `CERRADA` → `CONCILIADA`
2. ✅ No puede haber múltiples precortes activos por sesión
3. ✅ No puede haber múltiples postcortes por sesión
4. ✅ Postcorte se genera automáticamente al aprobar precorte
5. ✅ Todas las transiciones están auditadas
6. ✅ Validaciones fuertes en backend
7. ✅ UI consistente y sin hardcoding
8. ✅ Autenticación y autorización aplicadas

---

**Generado:** 2025-10-17
**Autor:** Sistema de Análisis Automatizado
**Versión:** 1.0
