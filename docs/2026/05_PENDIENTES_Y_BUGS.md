# Pendientes y Bugs — TerrenaLaravel
> Actualizado: Abril 2026 | Rama: work/inicio-limpio-abril-2026

## Bugs Críticos (bloquean operación)

### BUG-01: Descuentos en Reportes FloreantPOS
- **Prioridad:** 🔴 CRÍTICO
- **Archivos:** 
  - `FloreantPOS 1.5/.../DrawerpullReportService.java:146`
  - `FloreantPOS 1.5/.../SalesExceptionReport.java:78`
- **Síntoma:** Drawer Pull Report muestra "100" por cada descuento en lugar del monto real
- **Causa:** `discount.getValue()` retorna el porcentaje, no el monto. Usar `ticket.getTotalDiscount()`
- **Impacto:** Cortes de caja no cuadran, reportes gerenciales incorrectos

### BUG-02: [RESUELTO] Postcorte — Campos NULL / Esquema Expandido
- **Estado:** ✅ RESUELTO (Abril 2026)
- **Resolución:** El bug no era lógico; era una divergencia de esquema. Se neutralizó el "injerto" huérfano local de columnas de descuentos que no existían en PRD. Local fue revertido a la versión canónica y segura de Producción, solucionando radicalmente la aparición persistente de totales matemáticos ficticios.

### BUG-03: Auth deshabilitado en `/api/caja/*`
- **Prioridad:** 🔴 CRÍTICO (seguridad)
- **Archivo:** `routes/api.php` — grupo `/api/caja/`
- **Causa:** Middleware `auth:sanctum` removido durante desarrollo
- **Fix:** Reactivar antes de producción

### BUG-04: Origen Fragmentado de Descuentos (Heredado de Floreant POS)
- **Prioridad:** 🔴 CRÍTICO (Pendiente de arquitectura de solución)
- **Contexto Operativo:** El sistema transaccional legacy (Floreant POS) no posee un registro atomizado, centralizado y unificado para el procesamiento de descuentos, dificultando la migración del dato exacto.
- **Análisis de Origen (Floreant POS):**
  - `ticket`: Expone el campo `total_discount`, teóricamente cubriendo el nivel cabecera.
  - `ticket_item`: Almacena transacciones a nivel artículo, que pueden tener inyecciones de descuento individuales.
  - `transactions`: Entidad financiera final que registra pagos y anulaciones, pero cuyo monto cobrado ya viene mutado sin especificar qué remanente fue descuento.
- **Inconsistencias Posibles (Riesgo de Duplicación):**
  - Combinaciones asimétricas de `ticket_discount` y `ticket_item_discount` originan que, si se suman ambos arbitrariamente, el descuento total reportado dobletee o triplique matemáticamente al descuento real percibido.
- **Mapeo a TerrenaLaravel:**
  - El ecosistema de base de datos (`selemti.precorte` / `postcorte`) confía ciegamente en funciones totalizadoras para obtener ventas netas. No hay actualmente un pipeline oficial que desentramparice la herencia fragmentaria de Floreant.
- **Carencia de Fuente Única Confiable (Single Source of Truth):**
  - No hay pivote canónico de descuentos. El valor final depende empíricamente de si en la UI del POS de Java el cajero oprimió "Descuento al Ticket" vs "Descuento al Ítem". Toda agregación global en Postgres conlleva un riesgo de descarte o sobre-suma.
- **Impacto Sistémico:**
  - **Caja:** Genera incertidumbre sobre el cálculo neto al finalizar el turno operativo de la terminal.
  - **Postcorte:** Impide reportar montos brutos y descuentos tabulados sin romper la ecuación principal.
  - **Conciliación:** Induce severas variaciones al balancear el saldo final efectivo de base de datos contra el `drawer_pull_report` original sellado por la aplicación Java.
- **Memoria Técnica (Intento Previo):**
  - Hubo un intento de resolución artificial originado por implementaciones automatizadas e inconsistentes (IA). Intentó crear un pipeline de vistas complejas (`vw_descuentos_reales`) y alteró el DDL de `postcorte` inyectando 7 columnas ficticias (`total_ventas_brutas`, `calidad_reporte_descuentos`, etc). 
  - Fue un rótundo **experimento fallido**, operando como un parche fantasma *sin Interfaz de Usuario (UI)* y *sin contrato funcional canónico*. Terminó forzando un bug matemático de ceros absolutos por colisión de modelo y ha sido completamente revertido de los repositorios a su fuente pura.

---

## Funcionalidades Faltantes

### FEAT-01: [RESUELTO] UI del Módulo de Producción
- **Estado:** ✅ RESUELTO (Abril 2026)
- **Implementación:** Se completaron los 4 componentes Livewire (`OrdersIndex`, `OrderCreate`, `OrderDetail`, `OrderCapture`). El módulo es 100% operativo tanto en API como en Web UI.

### FEAT-02: UI de Kardex
- **Prioridad:** 🟡 ALTA
- **Estado:** API `GET /api/inventory/items/{id}/kardex` funciona, sin vista
- **Necesario:** Componente `app/Livewire/Inventory/KardexView.php` + vista blade

### FEAT-03: Dashboard Ejecutivo con KPIs diarios
- **Prioridad:** 🟡 MEDIA
- **Estado:** `DailyCloseService` existe, tablas resumen no creadas
- **Necesario:**
  - Migración para `daily_sales_summary` y `daily_kpi_summary`
  - Job que las pueble en cierre nocturno
  - Componente dashboard con gráficas (ventas vs costo vs margen)

### FEAT-04: Dashboard de Stock Visual
- **Prioridad:** 🟡 MEDIA
- **Estado:** API de stock funciona, sin vista consolidada
- **Necesario:** Vista con niveles de stock, alertas, brechas vs punto de reorden

---

## Deuda Técnica

### DEBT-01: Modelos Duplicados
- **Prioridad:** 🟢 BAJA
- `app/Models/Inv/Item.php` vs `app/Models/Inventory/Item.php`
- `app/Models/Caja/Postcorte.php` vs `app/Models/Core/PostCorte.php`
- `app/Models/Caja/SesionCajon.php` vs `app/Models/Core/SesionCaja.php`
- **Acción:** Consolidar en los namespaces nuevos, deprecar los de `Inv/` y `Core/`

### DEBT-02: [EN PROCESO] PosConsumptionService
- **Estado:** 🟠 REFACTORIZADO (v2.5)
- **Acción:** El núcleo lógico ha sido mudado a `selemti.fn_expandir_consumo_ticket` (v2.5) para recursividad. Falta consolidar los wrappers de PHP para apuntar exclusivamente a la nueva función de BD y eliminar el código legacy redundante.

### DEBT-03: Modelos de Compras en Raíz y Subcarpeta
- `app/Models/PurchaseOrder.php` (raíz) vs `app/Models/Purchasing/PurchaseRequest.php` (subcarpeta)
- **Acción:** Mover todos a `app/Models/Purchasing/`

### DEBT-04: Rutas Legacy
- `routes/api.php` contiene grupo `/api/legacy/*` con endpoints PHP-style
- **Acción:** Documentar dependientes y eliminar cuando no haya referencias

### DEBT-05: AuditLogService incompleto
- `app/Services/Audit/AuditLogService.php` — solo 39 líneas, scaffolding básico
- **Acción:** Implementar o usar el AuditLog model directamente

---

## Tests Faltantes

| Módulo | Estado |
|--------|--------|
| ReceivingService | ❌ sin tests |
| TransferService | ❌ sin tests |
| ProductionService | ❌ sin tests |
| ReturnService | ❌ sin tests |
| PrecorteService | ❌ sin tests |
| Reportes (parcial) | ⚠️ algunos tests |

---

## Orden de Trabajo Recomendado

| # | Tarea | Impacto | Esfuerzo |
|---|-------|---------|---------|
| 1 | BUG-01: Fix descuentos Java | Alto | Bajo (2 líneas) |
| 2 | BUG-02: Fix trigger postcorte | Alto | Medio (SQL) |
| 3 | BUG-03: Reactivar auth sanctum | Alto (seguridad) | Bajo (1 línea) |
| 4 | FEAT-01: UI Producción | Medio | Alto (4 componentes) |
| 5 | FEAT-02: UI Kardex | Medio | Bajo (1 componente) |
| 6 | FEAT-03: Dashboard KPIs | Medio | Medio |
| 7 | FEAT-04: Stock Dashboard | Medio | Medio |
| 8 | DEBT-01: Consolidar modelos | Bajo | Medio |
| 9 | DEBT-02: Consolidar PosConsumption | Bajo | Bajo |
