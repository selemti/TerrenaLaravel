# Flujo Operativo de Producción y Merma
Versión: 2025-10-27  
Estado: ACTIVO / OBLIGATORIO

Este documento describe el flujo integral de producción interna, desde la planificación (Produmix) hasta la declaración de mermas y el cierre de turno. Complementa a `docs/Produccion/PRODUMIX.md` y al control de disponibilidad en `docs/POS/LIVE_AVAILABILITY.md`.

---

## 1. Principios clave
1. **Implosión obligatoria de recetas**  
   - Toda receta vendible (y sus modificadores) debe implosionarse hasta insumos crudos inventariables con UOM conocida y costo válido.  
   - Subrecetas (ej. “pollo deshebrado”, “salsa verde”) deben existir como productos producidos via `ProductionService`.  
   - Si un SKU no se puede implosionar, debe aparecer en el dashboard rojo de “faltan recetas / faltan costos” y no puede permanecer vendible sin corrección.

2. **Separación de responsabilidades**  
   - Produmix planea y aprueba; cocina ejecuta.  
   - Ajustes al POS (agotados/forzar KDS) requieren permisos específicos (`can_manage_menu_availability`) y quedan registrados en `selemti.menu_availability_log`.

3. **Trazabilidad completa**  
   - Cada lote producido, merma, reproceso o ajuste debe almacenar user_id, timestamp, motivo y referencias (Política C en `docs/SECURITY_AND_ROLES.md`).

---

## 2. Flujo resumido
1. **Planificación (Produmix)**  
   - Genera órdenes sugeridas a partir de ventas históricas, inventario terminado y par stock (`docs/Produccion/PRODUMIX.md`).
2. **Aprobación Produmix**  
   - Gerente/Dirección (permiso `can_manage_produmix`) revisa y marca como listo.
3. **Ejecución en cocina (ProductionService)**  
   - Cocina líder ejecuta órdenes (`planBatch` → `consumeIngredients` → `completeBatch` → `postBatchToInventory`).
4. **Declaración de merma**  
   - Se registran mermas planificadas o incidentales (pesaje, calidad).
5. **Disponibilidad POS**  
   - Si la producción no cubre la demanda, se actualizará la visibilidad/agotado en el POS (`docs/POS/LIVE_AVAILABILITY.md`).
6. **Cierre de turno**  
   - Conciliar inventario inicial + producción - ventas - merma vs inventario final.

---

## 3. Detalle del flujo ProductionService
| Paso | Método | Descripción | Trazabilidad mínima |
|------|--------|-------------|----------------------|
| Planificación | `planBatch(recipeId, qtyTarget, userId)` | Registra lote planificado (estado `PLANIFICADA`). | user_id, referencia plan Produmix. |
| Consumo previo | `consumeIngredients(batchId, lines[], userId)` | Descarga insumos crudos (implosión). | `mov_inv` preliminares o reservas, log de insumos. |
| Producto terminado | `completeBatch(batchId, lines[], userId)` | Registra rendimientos/mermas internas. | Rendimiento esperado vs real, notas. |
| Posteo final | `postBatchToInventory(batchId, userId)` | Genera `mov_inv` definitivos (negativo insumos, positivo producto). | `mov_inv`, `inventory_batch`, `production_log`. |

> **TODO Sprint 1.10:** Implementar descarga real, lotes terminados y bitácoras (actualmente stubs, ver sección 6).

---

## 4. Merma y control de alérgenos
- Cada receta debe identificar los puntos de merma esperada (limpieza, cocción, montaje).
- Merma se registra como tipo de movimiento en `mov_inv` (`MERMA_PRODUCCION`, `MERMA_CALIDAD`, etc.).
- Para productos congelados/refrigerados, registrar lote y fecha de descongelación.
- Ajustes manuales sin motivo quedan prohibidos (Política C).

---

## 5. Cierre de turno (futuro inmediato)
Para cada estación (barra, cocina caliente, repostería):
1. **Entrada**: inventario inicial de producto listo.
2. **+ Producción**: lotes posteados durante el turno.
3. **– Ventas POS**: consumo implosionado del turno.
4. **– Merma declarada**: desde `ProductionService` o formularios de incidente.
5. **Comparar con inventario final físico**.

Diferencias deben capturar: user_id, motivo, evidencia (foto/archivo).  
Se registra en `selemti.production_shift_close` (por implementarse).

---

## 6. Pendientes técnicos (To-Do list)
1. Completar implementación de `ProductionService` para reflejar descargas/altas reales en inventario y logs.  
2. Crear tablas: `selemti.production_order`, `production_order_log`, `production_merma`.  
3. Conectar Produmix → ProductionService automáticamente al aprobar plan.  
4. Implementar bitácora de ejecución (quién posteó, merma, observaciones).  
5. Integrar con módulo de auditoría para cierre de turno y comparativo vs POS.

---

## 7. Referencias cruzadas
- `docs/Produccion/PRODUMIX.md` – Detalle de planificación diaria.  
- `docs/POS/LIVE_AVAILABILITY.md` – Ajustes en POS y menú en vivo.  
- `docs/SECURITY_AND_ROLES.md` – Permisos `can_manage_produmix`, `can_edit_production_order`, `can_manage_menu_availability`.  
- `docs/Recetas/POS_CONSUMPTION_SERVICE.md` – Implosión y reproceso POS.  

---

## 8. Resumen de responsabilidades por rol
| Rol | Responsabilidades producción | Permisos |
|-----|------------------------------|----------|
| Cocina líder | Ejecutar órdenes aprobadas, registrar merma, reportar incidencias. | `can_edit_production_order` |
| Chef Ejecutivo | Mantener recetas y subrecetas alineadas con implosión, validar mermas estándar. | `can_modify_recipe`, `can_edit_production_order` |
| Gerente de Sucursal | Aprobar Produmix, decidir agotados/re-rutas POS, validar cierre de turno. | `can_manage_produmix`, `can_manage_menu_availability` |
| Dirección | Supervisión global, auditorías, overrides estratégicos. | `can_manage_produmix`, `can_view_recipe_dashboard` |

---

**Recordatorio:** Ningún SKU debe venderse si la cadena completa “Produmix → ProductionService → Disponibilidad POS → Cierre de turno” no está cubierta y trazada.
