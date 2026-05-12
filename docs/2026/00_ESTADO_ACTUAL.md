# Estado Actual del Sistema — TerrenaLaravel
> Actualizado: Abril 2026 | Rama: work/inicio-limpio-abril-2026

## Resumen Ejecutivo

TerrenaLaravel es un ERP para gestión de cafeterías/restaurantes que integra:
- **FloreantPOS** (Java) como POS de punto de venta
- **Laravel 12 + Livewire 3** como backend ERP/reporting
- **PostgreSQL 9.5** con dos schemas: `public` (FloreantPOS, read-only) y `selemti` (ERP propio)

**Avance global estimado: ~80%** del sistema core funcional.

---

## Métricas del Código

| Capa | Estado |
|------|--------|
| Endpoints API REST | 150+ en 15 grupos |
| Rutas Web (Livewire) | 60+ |
| Controladores API | 25 |
| Servicios (Services/) | 43 archivos — 42/43 implementados |
| Componentes Livewire | 60+ |
| Modelos Eloquent | 85+ |
| Stack tecnológico | Laravel 12, Livewire 3.7, Tailwind 4, Alpine.js 3, Bootstrap 5 |

---

## Estado por Módulo

| Módulo | API | UI (Livewire) | Servicio | Estado |
|--------|-----|--------------|---------|--------|
| **Caja / Precorte** | ✅ 18 endpoints | ✅ integrado | ✅ completo | Funcional — bug descuentos pendiente |
| **Postcorte / Conciliación** | ✅ 7 endpoints | ⚠️ parcial | ✅ completo | Funcional |
| **Inventario / Stock** | ✅ 27 endpoints | ✅ 10 componentes | ✅ completo | Funcional |
| **Conteo Físico** | ✅ integrado | ✅ 5 componentes | ✅ completo | Funcional |
| **Compras / OC** | ✅ 11 endpoints | ✅ 5 componentes | ✅ completo | Funcional |
| **Reposición** | ✅ 6 endpoints | ✅ 1 componente | ✅ completo | Funcional |
| **Recetas / Costeo** | ✅ 5 endpoints | ✅ 7 componentes | ✅ completo | Funcional |
| **Producción** | ✅ 4 endpoints | ❌ sin UI | ⚠️ parcial | API lista, sin frontend |
| **Transferencias** | ✅ 7 endpoints | ✅ 5 componentes | ✅ completo | Funcional |
| **Caja Chica** | ⚠️ integrado | ✅ 6 componentes | ✅ completo | Funcional |
| **Catálogos** | ✅ 5 endpoints | ✅ 6 componentes | ✅ impl. | Funcional |
| **Reportes** | ✅ 25 endpoints | ✅ 2 componentes | ✅ completo | Funcional — algunos con bugs |
| **POS Sync** | ✅ endpoints | ✅ 4 componentes | ✅ completo | Funcional |
| **KDS** | ✅ integrado | ✅ 1 componente | ✅ completo | Funcional |
| **Auditoría** | ✅ 4 endpoints | ✅ 2 componentes | ⚠️ stub | Parcial |

---

## Bugs Críticos Activos

### 1. Bug de Descuentos en Reportes FloreantPOS
- **Archivo:** `DrawerpullReportService.java:146` y `SalesExceptionReport.java:78`
- **Síntoma:** El reporte muestra "100" en vez del monto real del descuento por ticket
- **Causa:** Usa `discount.getValue()` que retorna el porcentaje (100%), no el monto
- **Fix:** Usar `ticket.getTotalDiscount()` — ya almacenado correctamente en `public.ticket.total_discount`
- **Impacto:** Cortes de caja no cuadran

### 2. Divergencia de Esquema en Postcorte (RESUELTO: FASE 3 Completada)
- **Estado:** Resuelto (Abril 2026).
- **Contexto Histórico:** Un bot anterior inyectó un modelo extendido falso con columnas analíticas huérfanas (`total_ventas_brutas`, etc). Esto causó colapsos nulos. Ya fue revertido y homologado al contrato canónico de Producción.

### 3. Auth Deshabilitado en APIs de Caja
- **Ruta:** `/api/caja/*`
- **Estado:** Middleware `auth:sanctum` deshabilitado para desarrollo, nunca reactivado
- **Impacto:** Seguridad en producción

---

## Deuda Técnica

| Tipo | Detalle |
|------|---------|
| Modelos duplicados | `Inventory/Item` vs `Inv/Item`, `Caja/Postcorte` vs `Core/PostCorte` |
| Servicios duplicados | `PosConsumptionService` existe en 3 namespaces distintos |
| Sin UI | Módulo de Producción completo sin frontend |
| Sin tests | ReceivingService, TransferService, ProductionService sin cobertura |
| Legacy routes | `/api/legacy/*` — rutas de compatibilidad hacia atrás |

---

## Integración FloreantPOS ↔ Laravel

- Schema `public` (Floreant): solo lectura desde Laravel
- Schema `selemti` (ERP): lectura/escritura completa
- Sincronización: `PosConsumptionService` consume tickets de Floreant → actualiza stock `selemti` (ítems genéricos)
- Mapeo de items POS → insumos: vía tabla `selemti.pos_item_mapping`
- Relación de Compras: ítems genéricos asociados a presentaciones comerciales vía `selemti.insumo_proveedor_presentacion`

---

## Ambiente de Desarrollo

```
Servidor web:  php artisan serve (puerto 8000)
Assets:        npm run dev / vite (puerto 5173)
Queue:         php artisan queue:listen --tries=1
Logs:          php artisan pail --timeout=0
BD local:      localhost:5433 / postgres / T3rr3n4#p0s
BD prod:       100.126.124.101:5432 (read-only)
```

Ver `07_GUIA_DESARROLLO.md` para instrucciones completas.
