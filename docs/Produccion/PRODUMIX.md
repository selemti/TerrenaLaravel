# Produmix – Plan Diario de Producción
Versión: 2025-10-27  
Estado: ACTIVO / OBLIGATORIO

Este documento describe el proceso **Produmix**, responsable de transformar la demanda estimada en órdenes de producción listas para ejecutar en cocina. Produmix se integra con el flujo descrito en `docs/Produccion/PRODUCTION_FLOW.md` y alimenta la disponibilidad en vivo del POS detallada en `docs/POS/LIVE_AVAILABILITY.md`.

---

## 1. Objetivo operativo
- Asegurar que cada SKU vendible cuente con stock terminado suficiente al inicio y durante el turno.
- Generar órdenes de producción basadas en datos (ventas históricas, inventario actual y par stocks).
- Trazar quién aprobó el plan y cuándo se convirtió en producción real.

---

## 2. Entradas del cálculo Produmix
| Fuente | Descripción | Tabla / Servicio |
|--------|-------------|------------------|
| Histórico POS | Ventas recientes por SKU (últimos 7/14 días, configurable) | `public.ticket`, `public.ticket_item` (solo lectura) |
| Inventario terminado | Batches listos para barra | `selemti.inventory_batch` (estado = PRODUCIDO/ACTIVO) |
| Par stock / metas | Cantidad objetivo por SKU o familia | `selemti.produmix_targets` (futuro) |
| Ventas programadas | Eventos especiales, pedidos anticipados | `selemti.produmix_overrides` (futuro) |

> **Nota:** Todos los cálculos se realizan en el esquema `selemti`; POS es únicamente fuente de lectura conforme a la Política A.

---

## 3. Algoritmo de planificación (versión inicial)
1. **Consolidar consumo histórico**  
   - Implosionar cada receta/modificador hasta insumo crudo (ver `docs/Produccion/PRODUCTION_FLOW.md#implosion-de-recetas`).  
   - Calcular promedio diario y desviación estándar por SKU terminado.
2. **Restar inventario disponible**  
   - Inventario actual de batches terminados (`inventory_batch` con `cantidad_actual > 0`).  
   - Considerar órdenes en proceso (`ProductionService` estado EN_PROCESO/COMPLETADA).
3. **Aplicar par stock / buffer operativo**  
   - Si `(stock disponible + producción programada) < par_stock`, generar cantidad sugerida.
4. **Generar plan Produmix**  
   - Crear registros en `selemti.produmix_plan` (cabecera) y `selemti.produmix_plan_det` (detalle por SKU).  
   - Estado inicial: `PLANIFICADO`.
5. **Publicar para aprobación**  
   - Usuario con permiso `can_manage_produmix` valida, ajusta y marca como `LISTO`.
6. **Emitir órdenes de producción**  
   - Al confirmar, se crean órdenes en `ProductionService` (estado `PLANIFICADA`).  
   - Cocina recibe lista priorizada (ver `docs/Produccion/PRODUCTION_FLOW.md#ejecucion-en-cocina`).

---

## 4. Roles y permisos
| Permiso | Descripción | Roles sugeridos |
|---------|-------------|-----------------|
| `can_manage_produmix` | Ver, editar y aprobar el plan Produmix, emitir órdenes a cocina. | Gerente de Sucursal, Dirección |
| `can_edit_production_order` | Ejecutar producción y registrar mermas. | Cocina líder, Chef Ejecutivo |
| `can_view_recipe_dashboard` | Consultar métricas de disponibilidad y pendientes. | Gerente, Chef Ejecutivo, Dirección |

> El permiso `can_manage_produmix` se documenta también en `docs/SECURITY_AND_ROLES.md` y es obligatorio para acceder a la UI de Produmix y al endpoint correspondiente.

---

## 5. Integración con ProductionService
- Cada línea PRODUMIX genera una orden en `ProductionService` con estado inicial `PLANIFICADA`.
- Cocina solo puede ejecutar órdenes que provienen del plan aprobado.
- Las ejecuciones (CONSUME / COMPLETE / POST) deben registrar user_id y motivo (Política C) y actualizan lotes en `inventory_batch`.
- La implosión de recetas asegura que la producción descargue insumos hasta nivel crudo inventariable.
- Referencia cruzada: `docs/Produccion/PRODUCTION_FLOW.md#ejecucion-en-cocina`.

---

## 6. Relación con disponibilidad POS
Produmix alimenta el componente `MenuAvailabilityService`:
- Si un SKU crítico no alcanza la producción objetivo, se genera alerta para el dashboard (`docs/POS/LIVE_AVAILABILITY.md`).
- Gerente con permiso `can_manage_menu_availability` decide:
  - Marcar SKU como agotado en POS.
  - Re-rutar el SKU a cocina (Level 1 – intervención operativa autorizada).
- Cualquier cambio se registra en `selemti.menu_availability_log` con user_id, timestamp y motivo.

---

## 7. Trazabilidad y auditoría
- Tabla `selemti.produmix_plan` debe incluir: `creado_por`, `aprobado_por`, `aprobado_en`, `comentarios`.
- Detalles (`produmix_plan_det`) guardan cantidades sugeridas, ajustadas, ejecutadas.
- Al cierre de turno, la producción real vs. plan se compara en el corte operativo (ver `docs/Produccion/PRODUCTION_FLOW.md#cierre-de-turno`).
- Todos los reportes del módulo Produmix requieren permiso `can_manage_produmix`.

---

## 8. UI / UX sugerida
1. **Dashboard Produmix** (`/production/produmix`)
   - Resumen por SKU (objetivo, stock actual, sugerido, aprobado).
   - Indicadores por familia (Salsa, Proteínas, Empanadas, etc.).
   - Botones: “Generar plan”, “Aprobar plan”, “Emitir órdenes”.
2. **Detalle por SKU**
   - Historial de consumo POS (gráfico).
   - Inventario terminado y lotes próximos a caducar.
   - Relación con subrecetas y mermas recientes.
3. **Log de decisiones**
   - Cada ajuste manual requiere motivo y se registra en `produmix_plan_log`.

---

## 9. KPIs asociados
- Cumplimiento de plan (`producción ejecutada / producción sugerida`).
- Desviación vs. par stock.
- Incidencias de agotados POS por falta de producción.
- Tiempo promedio entre aprobación de plan y cierre de órdenes de producción.

---

## 10. Dependencias y próximos pasos
- Implementar tablas `selemti.produmix_plan`, `produmix_plan_det`, `produmix_plan_log`.
- Incorporar algoritmo estadístico (mínimo promedio móvil, ideal ARIMA/ETS futuro).
- Ajustar `ProductionService` para recibir lote objetivo (uom, costo, shelf life).
- Integrar alertas automáticas cuando Produmix no cubre ventas previstas.
- Coordinar con `docs/POS/LIVE_AVAILABILITY.md` para los mecanismos de agotado/forzado KDS.

---

**Referencias cruzadas:**  
- `docs/Produccion/PRODUCTION_FLOW.md` – Flujo completo de producción y merma.  
- `docs/POS/LIVE_AVAILABILITY.md` – Intervenciones en POS y control de disponibilidad.  
- `docs/SECURITY_AND_ROLES.md` – Políticas de permisos y trazabilidad.
