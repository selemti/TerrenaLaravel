# Live Availability POS & Menu Routing
Versión: 2025-10-27  
Estado: ACTIVO / OBLIGATORIO

Este documento define cómo Terrena controla la disponibilidad en vivo de productos POS (Floreant) y las intervenciones operativas autorizadas. Se integra con `docs/Produccion/PRODUMIX.md`, `docs/Produccion/PRODUCTION_FLOW.md` y las políticas de seguridad en `docs/SECURITY_AND_ROLES.md`.

---

## 1. Objetivo
- Reflejar en el POS el inventario real de producto terminado y empaques.
- Permitir decisiones operativas rápidas (agotado, forzar a cocina) con trazabilidad completa.
- Garantizar que cualquier intervención se registre y esté protegida por permisos.

---

## 2. Entradas necesarias
| Fuente | Descripción |
|--------|-------------|
| Produmix | Plan aprobado vs producción ejecutada (`docs/Produccion/PRODUMIX.md`). |
| ProductionService | Batches posteados (producto listo) y mermas (`docs/Produccion/PRODUCTION_FLOW.md`). |
| POS | Ventas en tiempo real (solo lectura de `public.ticket`/`public.ticket_item`). |
| Inventario barra | Conteos físicos rápidos (opcional) para refrescar disponibilidad. |

---

## 3. Intervenciones operativas nivel 1
*(ver sección 5 de `docs/SECURITY_AND_ROLES.md`)*

Estas acciones se disparan principalmente cuando:
- no se pudo producir el batch planeado por Produmix,
- se agotó stock en barra.

1. **Marcar SKU como agotado**  
   - Requiere permiso `can_manage_menu_availability`.  
   - Crea registro en `selemti.menu_availability_log` con user_id, timestamp, motivo, SKU.
   - Puede originarse cuando Produmix no se completó o existió merma inesperada.

2. **Forzar SKU a cocina (cambiar routing / KDS)**  
   - Permite atender bajos inventarios en barra, enviando el armado al line cook.  
   - También requiere `can_manage_menu_availability` y queda registrado en la misma bitácora.

> Estas acciones **NO** alteran tickets históricos, precios, impuestos ni totales de venta; sólo afectan la visibilidad/flujo operativo del menú.
> Cada intervención alimenta el corte de cocina/barra de fin de turno para cuadrar inventario vs ventas.

---

## 4. Flujo Live Availability
1. **Consumo Produmix**  
   - Si la producción planificada (Produmix) no se ejecutó, el SKU entra en “riesgo”.  
   - El plan Produmix es la principal señal para disparar agotados o reroutes.
   - Se genera alerta en dashboard (semáforo amarillo/rojo).
2. **Evaluar inventario barra**  
   - Datos de `inventory_batch` + ventas en tiempo real.  
   - Umbrales configurables por SKU.
3. **Decidir acción**  
   - `agotado` → desactivar SKU en POS.  
   - `force_kitchen` → cambiar destino KDS.  
   - `sin acción` → monitorear.
4. **Registrar intervención (Nivel 1)**  
   - Requiere `can_manage_menu_availability`.
   - Tabla `selemti.menu_availability_log` campos mínimos:
     - `sku`, `accion` (agotado/force_kitchen/restablecido),
     - `user_id`, `ejecutado_en`,
     - `motivo`, `meta` (JSON opcional).
5. **Restablecer**  
   - Cuando se produce el batch faltante y el inventario se normaliza, se reactiva el SKU y se registra en la misma bitácora.

---

## 5. Roles y permisos
| Permiso | Descripción | Roles sugeridos |
|---------|-------------|-----------------|
| `can_manage_menu_availability` | Ejecutar intervenciones (agotado/forzar) y ver dashboard Live Availability. | Gerente de Sucursal, Dirección |
| `can_manage_produmix` | Requerido para validar si la falta de stock fue por producción no ejecutada. | Gerente, Dirección |
| `can_edit_production_order` | Permite a cocina declarar producción y mermas, alimentando disponibilidad. | Cocina líder, Chef Ejecutivo |

> Ver `docs/SECURITY_AND_ROLES.md` para matriz completa de permisos.

---

## 6. Dashboard Live Availability
**Ruta sugerida:** `/pos/live-availability`  
**Componentes clave:**
- Lista de SKUs con estados `OK`, `RIESGO`, `AGOTADO`.
- Indicadores por categoría (proteínas, salsas, postres).  
- Botones de acción (agotado / reactivar / forzar cocina) visibles sólo con permiso `can_manage_menu_availability`.
- Histórico de intervenciones (últimas 24h) con motivo y usuario.

---

## 7. Integración con Produmix y Production Flow
- Produmix señala la brecha entre demanda y stock; si la producción no llega, se dispara agotado/reroute.  
- ProductionFlow registra ejecución real, mermas y lotes; su información alimenta el cálculo de disponibilidad.  
- El corte operativo de cocina/barra usa estas intervenciones para justificar diferencias al cierre.

---

## 8. Trazabilidad y auditoría
- Tabla `selemti.menu_availability_log` debe contar con índice por `sku`, `ejecutado_en`.  
- Cada entrada incluye:
  - `accion` (`MARK_OUT`, `FORCE_KITCHEN`, `RESTORE`),
  - `user_id`,
  - `motivo` (texto breve),
  - `meta` (JSON – puede guardar lote crítico, ticket que motivó el cambio, etc.).
- Informes se cruzan con Produmix y producción para identificar causas raíz.

---

## 9. Escenarios típicos
| Situación | Acción Live Availability | Registro |
|-----------|-------------------------|----------|
| Produmix no ejecutado a tiempo | Marcar SKU en riesgo, notificar Gerente. | Alerta dashboard + log si se marca agotado. |
| Venta mayor a pronóstico | Forzar a cocina temporalmente, ajustar Produmix siguiente turno. | Log con motivo “spike demanda”. |
| Merma inesperada (contaminación) | Comentario en log + agotado inmediato, registrar merma en ProductionService. | Log + `mov_inv` merma. |

---

## 10. Referencias cruzadas
- `docs/Produccion/PRODUMIX.md` – Algoritmo de planificación y permisos `can_manage_produmix`.  
- `docs/Produccion/PRODUCTION_FLOW.md` – Ejecución en cocina, merma y cierre de turno.  
- `docs/SECURITY_AND_ROLES.md` – Políticas de intervención POS y permisos `can_manage_menu_availability`.  
- `docs/Recetas/POS_CONSUMPTION_SERVICE.md` – Implosión y consumo POS.
