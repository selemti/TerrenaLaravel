# 🎯 TRIGGER DE INVENTARIO DESACTIVADO - Documentación Rápida

**Fecha**: 15 Diciembre 2025
**Trigger**: `trg_ticket_inventory_consumption`
**Estado**: 🔴 **DESACTIVADO** (temporalmente)
**Nombre fácil**: **Trigger Inventario Ticket**

---

## 🤔 **¿Qué hace este trigger?**

### **Propósito Original**
El trigger `trg_ticket_inventory_consumption` se ejecuta **automáticamente** cada vez que Floreant crea un ticket y se encarga de:

1. **🛒 Detectar venta**: Se activa cuando `NEW.paid = true` y `NEW.voided = false`
2. **📋 Crear consumo**: Inserta registros en `selemti.inv_consumo_pos` por cada item vendido
3. **🍳 Expande recetas**: Si el item es una receta, busca sus ingredientes y los consume del inventario
4. **📊 Registrar log**: Crea un registro en `selemti.inv_consumo_pos_log`

### **Flujo Esperado**
```
Floreant crea ticket
     ↓
Trigger se dispara
     ↓
Crea consumo POS (inv_consumo_pos)
     ↓
Busca receta (recipe_details) ❌ AQUÍ FALLA
     ↓
Consume ingredientes del inventario
     ↓
Registra en kardex de inventario
```

---

## 🚨 **¿Por qué lo desactivamos?**

### **Problema Detectado**
El trigger intenta acceder a la tabla `selemti.recipe_details` que **NO EXISTE**:

```sql
-- Línea problemática en la función del trigger
v_has_recipes boolean := coalesce(
    to_regclass('selemti.recipe_details') IS NOT NULL,
    false
);
```

### **Error en Cadena**
1. ✅ Cliente pide cuenta en Floreant
2. ✅ Floreant intenta crear ticket
3. 🔴 Trigger se dispara
4. 🔴 Intenta verificar tabla `recipe_details` (❌ NO EXISTE)
5. 🔴 **ERROR**: "Lo sentimos, ocurrió un error"
6. 🔴 ❌ **NO SE PUEDE COBRAR**

---

## 📊 **¿Qué impacta tenerlo desactivado?**

### **✅ Lo que SÍ funciona**
- 🟢 **Cobrar en Floreant** - Operación normal restaurada
- 🟢 **Crear tickets** - Sin problemas
- 🟢 **Reportes de ventas** - Todos funcionan
- 🟢 **Cortes de caja** - Operación normal
- 🟢 **Inventario manual** - Recepciones, ajustes, etc.

### **⚠️ Lo que NO funciona temporalmente**
- 🔵 **Consumo automático de inventario** - No se registra al cobrar
- 🔵 **Expansión de recetas** - No se consumen ingredientes automáticamente
- 🔵 **Kardex de ventas** - No se registran salidas por ventas

---

## 📋 **Estado Actual**

```sql
-- Verificar estado del trigger
SELECT tgname, tgenabled FROM pg_trigger
WHERE tgrelid = 'public.ticket'::regclass
  AND tgname = 'trg_ticket_inventory_consumption';
```

**Resultado**: `trg_ticket_inventory_consumption | D` (D = Disabled/Desactivado)

---

## 🔧 **Soluciones Futuras**

### **Opción 1: Crear Tabla Faltante (Recomendado)**
```sql
-- Crear tabla que necesita el trigger
CREATE TABLE selemti.recipe_details (
    id BIGSERIAL PRIMARY KEY,
    recipe_id BIGINT,
    item_id INTEGER,
    recipe_item_id INTEGER,
    required_uom VARCHAR(10),
    cantidad DECIMAL(10,3),
    factor DECIMAL(10,3)
);
```

### **Opción 2: Corregir Trigger (Más Simple)**
Modificar el trigger para que maneje la ausencia de la tabla sin error.

### **Opción 3: Mantener Desactivado**
Si no necesitas consumo automático de inventario, puedes dejarlo así.

---

## 🎯 **Para Reactivarlo**

Cuando decidas reactivarlo:

```sql
-- Reactivar trigger
ALTER TABLE public.ticket ENABLE TRIGGER trg_ticket_inventory_consumption;

-- Verificar que esté activo
SELECT tgname, tgenabled FROM pg_trigger
WHERE tgrelid = 'public.ticket'::regclass
  AND tgname = 'trg_ticket_inventory_consumption';
-- Debe mostrar: trg_ticket_inventory_consumption | O (O = Enabled)
```

---

## 📞 **Recordatorio Rápido**

**Estado**: 🔴 Desactivado para permitir cobrar en Floreant
**Causa**: Tabla `selemti.recipe_details` no existe
**Impacto**: Solo afecta consumo automático de inventario
**Acción**: Decidir si crear tabla faltante o dejar desactivado

---

## 🏷️ **Nombres Alternativos para Búsqueda**

- **Trigger Inventario Ticket** ← Nombre fácil
- `trg_ticket_inventory_consumption` ← Nombre técnico
- **Trigger de Consumo de Inventario**
- **Error Floreant Cobro** ← Por el síntoma
- **Missing recipe_details Table** ← Por la causa

---

**Nota importante**: Esta desactivación es SEGURA y no afecta las operaciones críticas de caja y ventas. Solo impacta el consumo automático de inventario por recetas.

**Creado**: 15 Dic 2025
**Estado**: Documentado para retomar cuando sea necesario