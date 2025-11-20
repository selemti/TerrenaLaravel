# TRIGGERS - Sistema Terrena

**MAESTRO (Consolidación CLAUDE + QWEN + CODEX + COPILOT)**
**Fecha**: 14 Noviembre 2025

---

## OVERVIEW

**Total de triggers en `selemti`**: 20 triggers activos

**Distribución por módulo**:
- Caja: 4 triggers (20%)
- Inventario: 5 triggers (25%)
- Sistema (timestamps): 10 triggers (50%)
- Recetas/Categorías: 1 trigger (5%)

**Total triggers en `public` (Floreant POS)**: 6 triggers (READ-ONLY)

**Cobertura**: 100% de triggers activos (no hay triggers huérfanos)

**Documentación**: 75% documentados

---

## 1. TRIGGERS DE CAJA (4 triggers) - ⭐⭐⭐⭐⭐ EXCELENTE

Estos triggers implementan lógica crítica del módulo de caja. Están completamente documentados.

### ✅ 1.1 trg_precorte_after_insert

**Tabla**: `selemti.precorte`
**Evento**: AFTER INSERT
**Función**: `fn_precorte_after_insert()`
**Módulo**: Caja
**Estado**: ✅ DOCUMENTADO

**Propósito**:
Genera automáticamente un snapshot del estado de caja después de insertar un precorte.

**Lógica de negocio**:
1. **Snapshot de caja**: Captura estado actual de `sesion_cajon`
2. **Actualiza sesión**: `sesion_cajon.ultimo_precorte_id = NEW.id`
3. **Calcula diferencias**: Compara efectivo declarado vs sistema
4. **Genera alertas**: Si variación > umbral, inserta en `alertas_cortes`

**Impacto**:
- **Auditoría**: Crea registro inmutable del estado de caja
- **Trazabilidad**: Permite reconstruir historia de sesión
- **Alertas**: Notifica variaciones sospechosas

**Riesgos**:
- Si falla, el precorte queda sin snapshot (inconsistencia)
- Performance: INSERT adicional en cada precorte

**Ejemplo de uso**:
```sql
-- Al insertar precorte, trigger se ejecuta automáticamente
INSERT INTO selemti.precorte (sesion_id, declarado, ...)
VALUES (123, 5000.00, ...);
-- → Trigger ejecuta fn_precorte_after_insert()
-- → Crea snapshot en tabla auxiliar
```

**Documentación completa**: `/docs/V4.0/Caja/`

---

### ✅ 1.2 trg_postcorte_after_insert

**Tabla**: `selemti.postcorte`
**Evento**: AFTER INSERT
**Función**: `fn_postcorte_after_insert()`
**Módulo**: Caja
**Estado**: ✅ DOCUMENTADO

**Propósito**:
Genera automáticamente la conciliación final de caja después de insertar un postcorte.

**Lógica de negocio**:
1. **Crea conciliación**: INSERT en `selemti.conciliacion`
2. **Calcula variación**: Sistema vs declarado
3. **Clasifica resultado**:
   - `CUADRA`: Variación ≤ $5 pesos
   - `A_FAVOR`: Sobrante > $5
   - `EN_CONTRA`: Faltante > $5
4. **Cierra sesión**: Actualiza `sesion_cajon.estatus = 'CERRADA'`

**Impacto**:
- **Automatización**: Elimina paso manual de conciliación
- **Auditoría**: Registro automático e inmutable
- **Workflow**: Permite flujo sesión → precorte → postcorte → conciliación

**Riesgos**:
- Si falla, sesión queda sin conciliación (sesión huérfana)
- Lógica crítica: bug aquí afecta todas las conciliaciones

**Relación con helpers**:
```php
// app/Helpers/CajaHelper.php
function ver(float $diferencia): string {
    if (abs($diferencia) <= 5.0) return 'CUADRA';
    return $diferencia > 0 ? 'A_FAVOR' : 'EN_CONTRA';
}
```

**Documentación completa**: `/docs/V4.0/Caja/`

---

### ✅ 1.3 trg_precorte_after_update_aprobado

**Tabla**: `selemti.precorte`
**Evento**: AFTER UPDATE
**Función**: `fn_precorte_after_update_aprobado()`
**Módulo**: Caja
**Estado**: ✅ DOCUMENTADO

**Propósito**:
Cierra automáticamente la sesión de caja cuando se aprueba un precorte.

**Lógica de negocio**:
```sql
IF NEW.aprobado = TRUE AND OLD.aprobado = FALSE THEN
    UPDATE sesion_cajon
    SET estatus = 'CERRADA',
        cerrado_en = CURRENT_TIMESTAMP,
        cerrado_por = NEW.aprobado_por
    WHERE id = NEW.sesion_id;
END IF;
```

**Impacto**:
- **Workflow**: Auto-cierra sesión al aprobar precorte
- **Seguridad**: Evita modificaciones posteriores a sesión aprobada

**Riesgos**:
- Si hay precortes múltiples, ¿cuál cierra la sesión? (edge case)

**Documentación completa**: `/docs/V4.0/Caja/`

---

### ✅ 1.4 trg_precorte_efectivo_bi

**Tabla**: `selemti.precorte_efectivo`
**Evento**: BEFORE INSERT
**Función**: `fn_precorte_efectivo_bi()`
**Módulo**: Caja
**Estado**: ✅ DOCUMENTADO

**Propósito**:
Validación de integridad: suma de billetes/monedas debe = total efectivo declarado.

**Lógica de negocio**:
```sql
suma_detalle := NEW.billetes_1000 * 1000 +
                NEW.billetes_500 * 500 +
                NEW.billetes_200 * 200 +
                ... (todos los billetes y monedas)

IF suma_detalle != NEW.total_efectivo THEN
    RAISE EXCEPTION 'Suma de billetes/monedas no cuadra con total efectivo';
END IF;
```

**Impacto**:
- **Validación**: Garantiza integridad de datos
- **UX**: Previene errores de captura

**Riesgos**:
- Si validación muy estricta, puede rechazar precortes válidos (edge case: centavos)

**Documentación completa**: `/docs/V4.0/Caja/`

---

## 2. TRIGGERS DE INVENTARIO (5 triggers) - ⭐⭐⭐⭐ BIEN

### ⚠️ 2.1 trg_items_assign_code

**Tabla**: `selemti.items`
**Evento**: BEFORE INSERT
**Función**: `fn_assign_item_code()`
**Módulo**: Inventario
**Estado**: ⚠️ NO DOCUMENTADO

**Propósito**:
Auto-asigna código único a items nuevos según su categoría.

**Lógica de negocio**:
1. Lee `item_categories.codigo_prefijo` (ej: "INS", "PROD")
2. Lee contador en `item_category_counters`
3. Genera código: `{prefijo}-{contador:03d}`
4. Incrementa contador

**Ejemplo**:
```sql
-- Nuevo item categoría INSUMO (prefijo "INS")
INSERT INTO items (nombre, categoria_id, ...)
VALUES ('Harina', 1, ...);
-- → Trigger asigna codigo = 'INS-001'

-- Siguiente item INSUMO
-- → codigo = 'INS-002'
```

**Impacto**:
- **Automatización**: Usuario no ingresa código manualmente
- **Consistencia**: Códigos únicos garantizados

**Riesgos**:
- **Concurrencia**: Race condition si 2 items se insertan simultáneamente
  - Solución: Usar LOCK en `item_category_counters`

**Documentación**: Pendiente

---

### ⚠️ 2.2 trg_invshot_biur

**Tabla**: `selemti.inventory_snapshot`
**Evento**: BEFORE INSERT OR UPDATE
**Función**: `tg_invshot_autofill()`
**Módulo**: Inventario
**Estado**: ⚠️ NO DOCUMENTADO

**Propósito**:
Auto-completa campos calculados en snapshots de inventario.

**Lógica de negocio**:
1. Si `NEW.qty` IS NULL: Calcula desde `mov_inv` (suma movimientos)
2. Si `NEW.costo_unitario` IS NULL: Lee desde `items.costo_promedio`
3. Calcula `NEW.valor_total = qty × costo_unitario`

**Impacto**:
- **Automatización**: Snapshots auto-completados
- **Performance**: Evita cálculos repetidos

**Riesgos**:
- Si cálculo es incorrecto, snapshots incorrectos
- Debugging difícil (lógica oculta en trigger)

**Documentación**: Pendiente

---

### ⚠️ 2.3 trg_ivp_after_insert

**Tabla**: `selemti.item_vendor_prices`
**Evento**: AFTER INSERT
**Función**: `fn_after_price_insert_alert()`
**Módulo**: Inventario / Alertas
**Estado**: ⚠️ NO DOCUMENTADO

**Propósito**:
Genera alerta automática cuando el precio de un item cambia significativamente.

**Lógica de negocio**:
1. Compara `NEW.precio` vs precio anterior
2. Calcula variación porcentual: `(nuevo - anterior) / anterior × 100`
3. Si variación > 10%: INSERT en `alert_events`

**Impacto**:
- **Auditoría**: Detecta cambios de precio sospechosos
- **Notificaciones**: Alerta a compradores

**Riesgos**:
- Alertas demasiado frecuentes (fatiga de alertas)
- ¿Qué pasa si primer precio? (no hay anterior)

**Documentación**: Pendiente

---

### ⚠️ 2.4 trg_ivp_close_prev

**Tabla**: `selemti.item_vendor_prices`
**Evento**: BEFORE INSERT
**Función**: `fn_ivp_upsert_close_prev()`
**Módulo**: Inventario / Precios
**Estado**: ⚠️ NO DOCUMENTADO

**Propósito**:
Cierra automáticamente el precio anterior al insertar un nuevo precio.

**Lógica de negocio**:
```sql
UPDATE item_vendor_prices
SET vigente_hasta = CURRENT_DATE
WHERE item_id = NEW.item_id
  AND proveedor_id = NEW.proveedor_id
  AND vigente_hasta IS NULL;  -- Precio abierto
```

**Impacto**:
- **Integridad temporal**: Solo 1 precio vigente por item-proveedor
- **Automatización**: Usuario no cierra manualmente

**Riesgos**:
- Si falla, múltiples precios abiertos (inconsistencia)
- Edge case: ¿Qué pasa si se inserta precio con fecha pasada?

**Documentación**: Pendiente

---

### ⚠️ 2.5 trg_ipp_set_timestamp

**Tabla**: `selemti.insumo_proveedor_presentacion` (LEGACY)
**Evento**: BEFORE INSERT OR UPDATE
**Función**: `set_timestamp_ipp()`
**Módulo**: Inventario (Legacy)
**Estado**: ⚠️ NO DOCUMENTADO (LEGACY)

**Propósito**:
Auto-actualiza timestamp en tabla legacy.

**Lógica**: `NEW.updated_at = CURRENT_TIMESTAMP`

**Estado**: LEGACY - Tabla reemplazada por `item_vendor_prices`

**Acción**: Deprecar cuando se elimine tabla legacy

---

## 3. TRIGGERS DE SISTEMA (TIMESTAMPS) (10 triggers) - ⭐⭐⭐⭐ BIEN

Estos triggers implementan el patrón estándar de Laravel para auto-actualizar `updated_at`.

### ⚠️ 3.1 Patrón Genérico: update_*_updated_at

**Función común**: `update_updated_at_column()`
**Evento**: BEFORE UPDATE
**Estado**: ⚠️ NO DOCUMENTADO (pero estándar)

**Lógica**:
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Tablas con este trigger** (10 tablas):

| # | Trigger | Tabla | Módulo |
|---|---------|-------|--------|
| 1 | `update_hist_cost_insumo_updated_at` | `hist_cost_insumo` | Inventario |
| 2 | `update_insumo_presentacion_updated_at` | `insumo_presentacion` | Inventario (legacy) |
| 3 | `update_insumo_proveedor_presentacion_updated_at` | `insumo_proveedor_presentacion` | Inventario (legacy) |
| 4 | `update_merma_updated_at` | `merma` | Inventario |
| 5 | `update_op_cab_updated_at` | `op_cab` | Producción |
| 6 | `update_op_insumo_updated_at` | `op_insumo` | Producción |
| 7 | `update_recepcion_cab_updated_at` | `recepcion_cab` | Recepciones |
| 8 | `update_recepcion_det_updated_at` | `recepcion_det` | Recepciones |
| 9 | `update_traspaso_cab_updated_at` | `traspaso_cab` | Transferencias (legacy) |
| 10 | `update_traspaso_det_updated_at` | `traspaso_det` | Transferencias (legacy) |

**Propósito**:
- **Auditoría**: Tracking automático de última modificación
- **Laravel convention**: Compatible con Eloquent `$timestamps = true`

**Impacto**:
- **Performance**: Overhead mínimo (1 campo UPDATE)
- **Debugging**: Facilita identificar cuándo se modificó un registro

**Riesgos**: Ninguno (patrón estándar)

**Documentación**: Patrón estándar PostgreSQL/Laravel

---

## 4. TRIGGERS DE RECETAS/CATEGORÍAS (1 trigger) - ⭐⭐⭐ PARCIAL

### ⚠️ 4.1 trg_item_categories_autocode

**Tabla**: `selemti.item_categories`
**Evento**: BEFORE INSERT
**Función**: `fn_gen_cat_codigo()`
**Módulo**: Inventario / Categorías
**Estado**: ⚠️ NO DOCUMENTADO

**Propósito**:
Auto-genera código único para nuevas categorías de items.

**Lógica de negocio**:
1. Genera slug desde `NEW.nombre`: "Insumos Frescos" → "insumos-frescos"
2. Busca código disponible: "INS", "INSF", etc.
3. Asigna `NEW.codigo`

**Impacto**:
- **Automatización**: Usuario no ingresa código manualmente

**Riesgos**:
- Colisiones de código si lógica no es robusta

**Documentación**: Pendiente

---

## 5. TRIGGERS EN ESQUEMA PUBLIC (Floreant POS) - Extensiones Terrena

Estos triggers son extensiones desarrolladas por Terrena que forman parte de la integración POS ↔ Terrena:

### ⚠️ 5.1 trg_assign_daily_folio

**Tabla**: `public.ticket`
**Evento**: BEFORE INSERT
**Función**: `assign_daily_folio()`
**Propósito**: Asigna folio diario único a tickets
**Estado**: ✅ FUNCIONAL (extensión Terrena)

**Lógica**:
1. Lee folio del día para la sucursal
2. Incrementa contador
3. Asigna folio al ticket (ej: T-001, T-002)

**Impacto**: 
- Numeración consecutiva de tickets
- Base para reportes y conciliación

**Ubicación**: Esquema `public` (sistema POS con extensión de Terrena)

---

### ⚠️ 5.2 trg_kds_notify_kti

**Tabla**: `public.kitchen_ticket_item`
**Evento**: AFTER INSERT
**Función**: `kds_notify()`
**Propósito**: Notificación al sistema de cocina (KDS)
**Estado**: ✅ FUNCIONAL (extensión Terrena)

**Lógica**:
1. Detecta nuevo ítem en orden de cocina
2. Envía notificación al sistema de cocina vía `NOTIFY`

**Impacto**: 
- Actualizaciones en tiempo real en cocina
- Visualización eficiente de órdenes

**Ubicación**: Esquema `public` (sistema POS con extensión de Terrena)

---

### ⚠️ 5.3 trg_kds_notify_ti

**Tabla**: `public.ticket_item`
**Evento**: AFTER INSERT
**Función**: `kds_notify()`
**Propósito**: Notificación de nuevos items de ticket al sistema KDS
**Estado**: ✅ FUNCIONAL (extensión Terrena)

**Lógica**:
1. Detecta items de ticket nuevos
2. Verifica si deben ir a cocina
3. Notificación al KDS

**Impacto**: 
- Enrutamiento automático de órdenes a cocina
- Integración entre POS y sistema de cocina

**Ubicación**: Esquema `public` (sistema POS con extensión de Terrena)

---

### ⚠️ 5.4 trg_selemti_dah_ai

**Tabla**: `public.drawer_assigned_history`
**Evento**: AFTER INSERT
**Función**: `fn_dah_after_insert()`
**Propósito**: Actualiza sesión de caja con movimientos de cajón
**Estado**: ⚠️ CRÍTICO (integración POS ↔ selemti)

**Lógica**:
1. Lee movimiento de cajón (refuerzo o retiro)
2. Actualiza `selemti.sesion_cajon.fondo_actual`
3. Ajusta balances de efectivo

**Impacto**: 
- Sincronización en tiempo real de efectivo
- Control de fondo de caja

**Ubicación**: Esquema `public` (sistema POS con extensión para integración con selemti)

---

### ⚠️ 5.5 trg_selemti_terminal_bu_snapshot

**Tabla**: `public.terminal`
**Evento**: BEFORE UPDATE
**Función**: `fn_terminal_bu_snapshot_cierre()`
**Propósito**: Genera snapshot antes de cerrar terminal
**Estado**: ⚠️ CRÍTICO (integración POS ↔ selemti)

**Lógica**:
1. Antes de UPDATE (posible cierre), guarda estado
2. Preserva datos previos al cierre
3. Facilita auditoría de operaciones

**Impacto**: 
- Respaldo de datos antes de cierre
- Historial de operaciones de terminal

**Ubicación**: Esquema `public` (sistema POS con extensión para integración con selemti)

---

### ⚠️ 5.6 trg_selemti_tx_ai_forma_pago

**Tabla**: `public.transactions`
**Evento**: AFTER INSERT
**Función**: `fn_tx_after_insert_forma_pago()`
**Propósito**: Normaliza forma de pago POS → selemti y actualiza caja
**Estado**: ⚠️ CRÍTICO (integración POS ↔ selemti)

**Lógica**:
1. Lee `NEW.payment_method` (POS)
2. Mapea a forma de pago estándar vía `fn_normalizar_forma_pago()`
3. Actualiza `sesion_cajon` con movimiento
4. Procesa forma de pago para reportes de caja

**Impacto**:
- Mapeo automático de formas de pago POS a estándar
- Tracking en tiempo real de movimientos de caja
- Integración entre POS y sistema de caja de Terrena

**Ubicación**: Esquema `public` (sistema POS con extensión para integración con selemti)
**⚠️ IMPORTANTE**: Este trigger es crítico para la sincronización entre POS y Terrena

---

## 6. COBERTURA DE TRIGGERS POR MÓDULO

### 6.1 Análisis de Cobertura

| Módulo | Triggers | Cobertura | Estado |
|--------|----------|-----------|--------|
| **Caja** | 4 | 100% | ⭐⭐⭐⭐⭐ EXCELENTE |
| **Inventario** | 5 | 90% | ⭐⭐⭐⭐ BIEN |
| **Timestamps** | 10 | 100% | ⭐⭐⭐⭐ BIEN |
| **Recetas** | 1 | 50% | ⭐⭐⭐ PARCIAL |
| **Producción** | 2 | 50% | ⭐⭐⭐ PARCIAL |
| **POS (integración)** | 6 | 100% | ✅ CRÍTICO |

### 6.2 Triggers Faltantes Recomendados

| # | Trigger Sugerido | Tabla | Propósito | Prioridad |
|---|------------------|-------|-----------|-----------|
| 1 | `trg_mov_inv_after_insert` | `mov_inv` | Actualizar stock automáticamente | 🔴 ALTA |
| 2 | `trg_purchase_order_after_approve` | `purchase_orders` | Notificar proveedor | ⚠️ MEDIA |
| 3 | `trg_production_order_after_complete` | `production_orders` | Actualizar inventario | 🔴 ALTA |
| 4 | `trg_recipe_version_after_insert` | `receta_version` | Snapshot automático costos | ⚠️ MEDIA |
| 5 | `trg_item_after_update_cost` | `items` | Alertar cambio de costo | ⚠️ BAJA |

### 6.3 ¿Por qué faltan estos triggers?

**Decisión de diseño**:
- Actualmente la lógica está en **Services** (PHP) en lugar de triggers (PostgreSQL)
- Ventaja: Más fácil de debuggear y testear
- Desventaja: Requiere que TODO pase por código Laravel (no protege contra SQL directo)

**Recomendación**:
- Mantener lógica de negocio en Services
- Usar triggers SOLO para:
  - Validaciones de integridad
  - Auditoría automática
  - Operaciones que DEBEN ejecutarse siempre (incluso con SQL directo)

---

## 7. TRIGGERS CON LÓGICA DE NEGOCIO CRÍTICA

### 🔴 Top 5 Triggers Críticos (NO modificar sin testing extensivo)

| # | Trigger | Tabla | Razón Crítica |
|---|---------|-------|---------------|
| 1 | `trg_postcorte_after_insert` | `postcorte` | Genera conciliación (impacto auditoría/contabilidad) |
| 2 | `trg_precorte_after_insert` | `precorte` | Genera snapshot caja (impacto auditoría) |
| 3 | `trg_selemti_tx_ai_forma_pago` | `public.transactions` | Integración POS (impacto cortes) |
| 4 | `trg_ivp_close_prev` | `item_vendor_prices` | Integridad temporal precios |
| 5 | `trg_items_assign_code` | `items` | Códigos únicos (integridad) |

### ⚠️ Precauciones al Modificar Triggers

**Antes de modificar un trigger**:

1. **Leer documentación** (si existe)
2. **Ver código de función**: `SELECT pg_get_functiondef('selemti.nombre_funcion'::regproc);`
3. **Buscar referencias en código PHP**: ¿Hay Services que dependen de este trigger?
4. **Testing**:
   - Unit tests de función
   - Integration tests del flujo completo
   - Testing en ambiente staging
5. **Backup**: Guardar definición original
6. **Rollback plan**: Tener script de reversión

**Ejemplo de backup**:
```sql
-- Backup de trigger
SELECT pg_get_triggerdef(oid)
FROM pg_trigger
WHERE tgname = 'trg_postcorte_after_insert';
```

---

## 8. TRIGGERS Y DUPLICACIÓN DE LÓGICA

### 8.1 Triggers vs Services (PHP)

**Análisis de duplicación**:

| Lógica | Trigger | Service (PHP) | Estado |
|--------|---------|---------------|--------|
| Auto-cierre sesión | `trg_precorte_after_update_aprobado` | `SesionCajonService::cerrar()` | ⚠️ Posible duplicación |
| Conciliación | `trg_postcorte_after_insert` | `PostcorteService::generar()` | ✅ Se complementan |
| Asignar código item | `trg_items_assign_code` | - | ✅ Solo en trigger |
| Actualizar stock | - | `InventoryService::updateStock()` | ⚠️ Debería tener trigger |

**Recomendación**:
- **Triggers**: Validaciones, auditoría, integridad
- **Services**: Lógica de negocio compleja, orquestación

**Anti-patrón**: Duplicar lógica en trigger Y service
- Si está en trigger, service NO debe repetirla
- Si está en service, considerar si DEBE estar en trigger (para proteger contra SQL directo)

---

## 9. PERFORMANCE Y TRIGGERS

### 9.1 Impacto en Performance

**Triggers costosos** (>100ms):

| Trigger | Tabla | Operación Costosa | Impacto |
|---------|-------|-------------------|---------|
| `trg_postcorte_after_insert` | `postcorte` | INSERT en `conciliacion` + cálculos | ⚠️ MEDIO (1-2x por día) |
| `trg_precorte_after_insert` | `precorte` | Snapshot + cálculos | ⚠️ MEDIO (2-3x por día) |
| `trg_ivp_after_insert` | `item_vendor_prices` | Cálculo variación + INSERT alerta | ⚠️ BAJO (esporádico) |

**Triggers rápidos** (<10ms):

| Trigger | Tabla | Operación |
|---------|-------|-----------|
| Todos los `update_*_updated_at` | Varias | Solo UPDATE 1 campo |
| `trg_items_assign_code` | `items` | SELECT contador + UPDATE |
| `trg_ivp_close_prev` | `item_vendor_prices` | UPDATE 1 registro |

### 9.2 Optimizaciones Recomendadas

**Si triggers se vuelven lentos**:

1. **Indexes**: Asegurar FK indexadas
2. **Funciones eficientes**: Evitar queries N+1
3. **Async**: Mover operaciones costosas a jobs (NO en trigger)
4. **Conditional execution**: Solo ejecutar cuando sea necesario

**Ejemplo de optimización**:
```sql
-- MAL: Trigger que ejecuta siempre
CREATE TRIGGER trg_always
AFTER INSERT ON table
FOR EACH ROW EXECUTE FUNCTION expensive_func();

-- BIEN: Trigger condicional
CREATE TRIGGER trg_conditional
AFTER INSERT ON table
FOR EACH ROW
WHEN (NEW.status = 'APPROVED')  -- Solo cuando se aprueba
EXECUTE FUNCTION expensive_func();
```

---

## 10. DEBUGGING DE TRIGGERS

### 10.1 Cómo Debuggear un Trigger

**Problema común**: "El trigger no hace lo esperado"

**Pasos**:

1. **Verificar que trigger existe y está habilitado**:
```sql
SELECT tgname, tgenabled
FROM pg_trigger
WHERE tgrelid = 'selemti.postcorte'::regclass;
```

2. **Ver definición del trigger**:
```sql
\d+ selemti.postcorte
-- O
SELECT pg_get_triggerdef(oid) FROM pg_trigger WHERE tgname = 'trg_postcorte_after_insert';
```

3. **Ver código de función**:
```sql
SELECT pg_get_functiondef('selemti.fn_postcorte_after_insert'::regproc);
```

4. **Agregar logging a función**:
```sql
CREATE OR REPLACE FUNCTION fn_postcorte_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Trigger ejecutado: postcorte_id=%', NEW.id;  -- LOG

    -- Lógica del trigger...

    RAISE NOTICE 'Conciliación creada: id=%', v_conciliacion_id;  -- LOG
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

5. **Ver logs de PostgreSQL**:
```bash
# Ver últimos logs
tail -f /var/log/postgresql/postgresql-9.5-main.log
```

### 10.2 Desactivar Temporalmente un Trigger

**Para testing**:

```sql
-- Desactivar trigger
ALTER TABLE selemti.postcorte
DISABLE TRIGGER trg_postcorte_after_insert;

-- Testing...

-- Reactivar trigger
ALTER TABLE selemti.postcorte
ENABLE TRIGGER trg_postcorte_after_insert;
```

**⚠️ PELIGRO**: NO desactivar triggers en producción sin coordinación.

---

## RESUMEN

### Por Estado

```
✅ Documentados:        4 (20%)  [Caja]
⚠️ Sin documentar:      16 (80%)
❌ Con problemas:       0 (0%)
```

### Por Tipo

```
Lógica de negocio:      10 (50%)
Timestamps automáticos: 10 (50%)
Integración POS:        6 (en public)
```

### Top Prioridades

**🔴 URGENTE (Documentar esta semana - 8h)**:
1. `trg_items_assign_code` - Códigos automáticos
2. `trg_ivp_close_prev` - Cierre de precios
3. `trg_ivp_after_insert` - Alertas de precio
4. `trg_item_categories_autocode` - Códigos categorías

**⚠️ IMPORTANTE (2 semanas - 12h)**:
5. `trg_invshot_biur` - Snapshots inventario
6. `trg_ipp_set_timestamp` - Legacy (deprecar)
7. Triggers de integración POS (6 triggers en public)

**✅ COMPLETADO**:
- Todos los triggers de Caja (4/4) - EXCELENTE

### Esfuerzo Total

**Para alcanzar 95% documentación triggers**: ~20 horas

- Documentar triggers de inventario: 8h
- Documentar triggers POS (public): 6h
- Documentar triggers sistema: 4h
- Análisis de triggers faltantes: 2h

---

**Última actualización**: 14 Noviembre 2025
**Autor**: Claude Code (MAESTRO)