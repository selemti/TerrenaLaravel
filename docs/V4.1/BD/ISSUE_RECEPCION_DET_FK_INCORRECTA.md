# ISSUE: FK Incorrecta en `recepcion_det.um_id`

**Proyecto**: TerrenaLaravel V4.1
**Fecha Detección**: 2025-11-24
**Severidad**: 🔴 **CRÍTICA** (Bloqueador de producción)
**Estado**: ✅ **RESUELTO**

---

## 🎯 Resumen

La FK `recepcion_det.um_id` apuntaba a `selemti.unidad_medida_legacy` (tabla VACÍA con 0 registros), causando error al intentar crear recepciones.

---

## 🔍 Detección

**Trigger**: Ejecución de test end-to-end de recepciones en Tinker

**Error obtenido**:
```
SQLSTATE[23503]: Foreign key violation: 7 ERROR:  inserción o actualización en la tabla «recepcion_det» viola la llave foránea «recepcion_det_um_id_fkey»
DETAIL:  La llave (um_id)=(1) no está presente en la tabla «unidad_medida_legacy».
```

**Código que falló**:
```php
$receptionService->createDraftReception($header, $lines);
// ReceptionService.php:86
DB::table('selemti.recepcion_det')->insert([
    'recepcion_id' => $receptionId,
    'item_id' => $line['item_id'],
    'bodega_id' => $header['warehouse_id'] ?? 1,
    'qty' => $qtyCanonical,
    'um_id' => 1,  // ❌ FALLA: FK apunta a tabla vacía
    // ...
]);
```

---

## 🐛 Causa Raíz

### Problema de Diseño de BD

**9 tablas de unidades de medida** coexisten en `selemti`:

| Tabla | Registros | Propósito | Estado |
|-------|-----------|-----------|--------|
| `cat_unidades` | 26 | ✅ Tabla principal (normalizada) | **ACTIVA** |
| `unidad_medida` | 26 | Alias/vista de cat_unidades | ACTIVA |
| `unidades_medida` | 26 | Alias/vista de cat_unidades | ACTIVA |
| `unidad_medida_legacy` | **0** | ❌ Legacy vacía | **VACÍA** |
| `unidades_medida_legacy` | **0** | ❌ Legacy vacía | **VACÍA** |
| `conversiones_unidad` | ? | Conversiones UOM | ? |
| `conversiones_unidad_legacy` | ? | Legacy conversiones | ? |
| `v_cat_unidades_compat` | - | Vista compatibilidad | VISTA |
| `v_unidad_medida_singular_compat` | - | Vista compatibilidad | VISTA |

**FK incorrecta**:
```sql
-- ❌ ANTES (INCORRECTA)
ALTER TABLE selemti.recepcion_det
ADD CONSTRAINT recepcion_det_um_id_fkey
FOREIGN KEY (um_id) REFERENCES selemti.unidad_medida_legacy(id);
```

**FK correcta**:
```sql
-- ✅ DESPUÉS (CORRECTA)
ALTER TABLE selemti.recepcion_det
ADD CONSTRAINT recepcion_det_um_id_fkey
FOREIGN KEY (um_id) REFERENCES selemti.cat_unidades(id) ON DELETE RESTRICT;
```

---

## 📊 Evidencia

### Conteo de registros:
```sql
SELECT 'cat_unidades' as tabla, COUNT(*) as total FROM selemti.cat_unidades
UNION ALL SELECT 'unidad_medida_legacy', COUNT(*) FROM selemti.unidad_medida_legacy
UNION ALL SELECT 'unidades_medida_legacy', COUNT(*) FROM selemti.unidades_medida_legacy;

-- Resultado:
--     tabla          | total
-- -------------------+-------
-- cat_unidades      |    26
-- unidad_medida_legacy |  0
-- unidades_medida_legacy | 0
```

### FK antes de la corrección:
```sql
\d selemti.recepcion_det

-- FK incorrecta:
-- "recepcion_det_um_id_fkey" FOREIGN KEY (um_id) REFERENCES selemti.unidad_medida_legacy(id)
```

---

## ✅ Solución Aplicada

### Comandos SQL ejecutados:

```sql
-- 1. Eliminar FK incorrecta
ALTER TABLE selemti.recepcion_det
DROP CONSTRAINT IF EXISTS recepcion_det_um_id_fkey;

-- 2. Crear FK correcta
ALTER TABLE selemti.recepcion_det
ADD CONSTRAINT recepcion_det_um_id_fkey
FOREIGN KEY (um_id) REFERENCES selemti.cat_unidades(id) ON DELETE RESTRICT;
```

### Verificación post-corrección:

```sql
\d selemti.recepcion_det

-- FK correcta:
-- "recepcion_det_um_id_fkey" FOREIGN KEY (um_id) REFERENCES selemti.cat_unidades(id) ON DELETE RESTRICT
```

---

## 🧪 Prueba de Validación

**Test ejecutado**: `TEST_FLUJO_INVENTARIO_COMPLETO.php`

**Resultado**:
```
✅ Recepción creada: ID=2
✅ Recepción validada
✅ Recepción posteada
✅ Lote creado: ID=1
✅ Movimiento creado (kardex): ID=108
✅ TEST 1 COMPLETADO: Recepción flujo completo OK
```

---

## 📝 Impacto

### Antes de la Corrección
- ❌ **100% de recepciones fallaban** al intentar crear `recepcion_det`
- ❌ No se podía crear ninguna recepción (ni BORRADOR)
- ❌ **Bloqueador total de producción**

### Después de la Corrección
- ✅ Recepciones funcionan end-to-end
- ✅ State machine completa: BORRADOR → VALIDADA → POSTEADA
- ✅ Lotes creados correctamente
- ✅ Kardex registrado correctamente

---

## 🔧 Causa del Error de Diseño

**Hipótesis**: Este error fue introducido por CODEX al crear la migración de `recepcion_det` sin validar contra la BD real.

**Evidencia**:
1. La tabla `unidad_medida_legacy` existe pero está vacía (nunca se pobló)
2. La tabla correcta `cat_unidades` tiene 26 registros y es la usada por `items`
3. La FK debió apuntar a `cat_unidades` desde el inicio

**Patrón detectado**: Múltiples tablas legacy creadas pero nunca pobladas, causando confusión en diseño.

---

## 🚨 Acciones Preventivas

### Inmediatas
1. ✅ FK corregida en BD producción
2. ⏳ Crear migración para formalizar el cambio
3. ⏳ Actualizar documentación de BD

### A Mediano Plazo
1. **Consolidar tablas de unidades**:
   - Eliminar tablas legacy vacías: `unidad_medida_legacy`, `unidades_medida_legacy`
   - Mantener solo: `cat_unidades` (principal) + vistas de compatibilidad
   - Migrar todas las FKs a `cat_unidades`

2. **Validar otras FKs similares**:
   - Buscar FKs que apunten a tablas legacy vacías
   - Revisar todas las tablas con sufijo `_legacy`

3. **Proceso de auditoría**:
   - ANTES de crear FKs, verificar que tabla destino tiene datos
   - CODEX debe consultar BD real antes de definir FKs

---

## 📄 Migración Propuesta

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Corregir FK de recepcion_det.um_id
        DB::statement('
            ALTER TABLE selemti.recepcion_det
            DROP CONSTRAINT IF EXISTS recepcion_det_um_id_fkey;
        ');

        DB::statement('
            ALTER TABLE selemti.recepcion_det
            ADD CONSTRAINT recepcion_det_um_id_fkey
            FOREIGN KEY (um_id) REFERENCES selemti.cat_unidades(id)
            ON DELETE RESTRICT;
        ');
    }

    public function down(): void
    {
        // Revertir a FK incorrecta (solo para rollback, NO USAR)
        DB::statement('
            ALTER TABLE selemti.recepcion_det
            DROP CONSTRAINT IF EXISTS recepcion_det_um_id_fkey;
        ');

        DB::statement('
            ALTER TABLE selemti.recepcion_det
            ADD CONSTRAINT recepcion_det_um_id_fkey
            FOREIGN KEY (um_id) REFERENCES selemti.unidad_medida_legacy(id);
        ');
    }
};
```

**Nombre sugerido**: `2025_11_24_180000_fix_recepcion_det_um_id_fk.php`

---

## 🔗 Referencias

- **Script de testing**: `docs/V4.1/Testing/TEST_FLUJO_INVENTARIO_COMPLETO.php`
- **Auditoría completa**: `docs/V4.1/BD/AUDITORIA_TECNICA_INVENTARIO_COMPLETA.md`
- **Servicio corregido**: `app/Services/Inventory/ReceptionService.php`
- **Modelo**: `app/Models/Inventory/Reception.php` (si existe)

---

**FIN DEL ISSUE**
