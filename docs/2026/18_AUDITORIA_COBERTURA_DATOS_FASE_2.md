# 18 Auditoría de Cobertura de Datos: Fase 2 (Inventarios)

Este documento evalúa la viabilidad técnica de iniciar la Fase 2 (Inventarios, WAC y Food Cost) basándose en la disponibilidad real de datos en la base de datos de producción (Esquema `selemti` y `public`).

## 1. Resumen de Hallazgos (Volumetría)
La auditoría ejecutada el 2026-04-14 revela una **cobertura crítica insuficiente** para pruebas de lógica financiera.

| Dominio | Tabla Principal | Registros | Utilidad Actual |
| :--- | :--- | :--- | :--- |
| **Insumos** | `selemti.items` | 6 | ❌ Solo datos de prueba (Aceite, Leche). |
| **Proveedores**| `selemti.cat_proveedores` | 20 | ✅ Catálogo funcional disponible. |
| **UOM / Unidades**| `selemti.cat_unidades` | 6 | ⚠️ Solo unidades básicas (L, Kg, Pz). |
| **Recetas** | `selemti.receta_cab` | 0 | ⚠️ Pendiente de sincronización automática desde POS vía `recipes:sync-pos` (205 platillos detectados). |
| **Precios** | `selemti.vendor_price` | 0 | ❌ No existe histórico para WAC. |
| **Producción** | `selemti.production_orders`| 0 | ❌ No hay registros de transformación. |
| **Stock Actual** | `selemti.inventory_batch` | 2 | ❌ Almacenes vacíos. |

---

## 2. Análisis por Hito (Fase 2)

### A. Cálculo de WAC (Weighted Average Cost)
- **Estado:** NO VIABLE.
- **Razón:** El WAC requiere un histórico de recepciones (`purchase_orders` o `inventory_transactions`) con costos de compra reales. Actualmente no existen movimientos de entrada que alimenten el motor de costeo.

### B. Food Cost y Margen
- **Estado:** VIABLE (Estructuralmente).
- **Razón:** El Food Cost depende de la relación `Receta -> Menú Item`. Mediante el comando `php artisan recipes:sync-pos`, se crearán los 205 "shells" de recetas alineados 1-a-1 con el POS. La brecha se reduce ahora a la carga de los INGREDIENTES de cada receta.

### C. Gestión de Mermas
- **Estado:** VIABLE (Estructuralmente).
- **Razón:** La tabla `selemti.merma` está vacía pero lista. Se puede implementar la taxonomía de la Fase 2, pero no será auditable hasta que los insumos existan y tengan stock.

---

## 3. Dictamen Técnico
**NO SE RECOMIENDA** proceder con el desarrollo de lógica financiera de Fase 2 sin una carga masiva previa. El sistema se encuentra en un estado "embrionario" de datos de inventario.

> [!WARNING]
> Implementar WAC o Food Cost sobre 6 items de prueba generará una "ilusión de funcionalidad" que colapsará al cargar los miles de registros reales si las conversiones de unidades (UOM) no están estandarizadas.

---

## 4. Próximo Paso
Mover el foco a la **Población de Datos Maestro (Etapa B y C)**.
