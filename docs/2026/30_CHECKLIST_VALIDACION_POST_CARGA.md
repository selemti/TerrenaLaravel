# ⚠️ DOCUMENTO SUPERSEDIDO
Este documento no define el orden actual de ejecución.
Consultar primero: [00_README_EJECUCION_FASE_2.md](00_README_EJECUCION_FASE_2.md)

# 30 Checklist de Validación Post-Carga (Fase 2)

Este protocolo permite certificar que la carga de datos maestros se realizó con integridad referencial y sin duplicidades.

## 🟥 Bloque 1: UOM y Conversiones (Control D0)
- [ ] **Existencia**: ¿Existen PZ, KG, G, L, ML en `cat_unidades`?
- [ ] **Matemática**: ¿KG -> G tiene factor 1000? ¿L -> ML tiene factor 1000?
- [ ] **Unicidad**: ¿Se eliminó la unidad 'CAJA' si no era necesaria?
- [ ] **Ids**: ¿Las claves de unidad coinciden exactamente con lo definido en el Doc 26?

## 🟥 Bloque 2: Almacenes (Control D0)
- [ ] **Claves**: ¿Existen ALM-SEC, ALM-REF y ALM-COC?
- [ ] **Mapeo**: ¿Cada almacén tiene su nombre correcto y está activo?
- [ ] **Duplicidad**: ¿Hay solo 3 almacenes en `cat_almacenes`?

## 🟥 Bloque 3: Insumos (Control D1)
- [ ] **IDs Normalizados**: ¿Todos los ítems inician con `INS-`? (Revisar en `selemti.items`).
- [ ] **Desacoplamiento**: ¿Se cargaron las marcas/formatos en `insumo_proveedor_presentacion` sin ensuciar la tabla `items`?
- [ ] **Integridad UOM**: ¿Todos los insumos tienen asignada una UOM válida de la tabla `cat_unidades`?
- [ ] **Clasificación**: ¿Toda la muestra de 26 ítems tiene su `categoria_id` (CAT-XX) asignada?
- [ ] **Costos**: ¿Se cargaron costos iniciales positivos (> 0)?

## 🟥 Bloque 4: Inventario Inicial (Control D2)
- [ ] **Referencia ítem**: ¿El `item_id` del inventario existe en la tabla de ítems?
- [ ] **Referencia Almacén**: ¿El `almacen_id` existe en la tabla de almacenes?
- [ ] **Cantidades**: ¿Las cantidades son positivas y coinciden con el conteo físico del "Punto Cero"?

---

## 🏁 Dictamen Final de Carga

| Resultado | Criterio |
| :--- | :--- |
| **CERTIFICADA** | 100% de los puntos anteriores verificados. |
| **OBSERVADA** | Errores menores en descripciones (no bloqueantes). |
| **RECHAZADA** | Duplicados, UOMs huérfanas o fallos de FK. |

**Auditado por:** ____________________  
**Fecha:** ____________________
