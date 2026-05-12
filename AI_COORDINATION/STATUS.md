# AI_COORDINATION — TerrenaLaravel
**Actualizado:** Abril 13, 2026

## Estado del proyecto

- **Avance general:** ~80%
- **Rama activa:** `work/inicio-limpio-abril-2026`
- **APIs:** 150+ endpoints implementados
- **Livewire:** 60+ componentes (mayoría con datos reales)
- **UOM pipeline:** Implementado y funcionando (KG/L/PZ base units)

## Roles por agente

| Agente | Herramienta | LLM | Responsabilidad |
|--------|-------------|-----|----------------|
| **Claude** | Claude Code | Claude Sonnet/Opus | UI/Livewire, arquitectura, orquestación |
| **Gemini** | Antigravity | Gemini 2.5 | SQL, migraciones PG, stored procedures |
| **Codex** | Codex CLI | GPT-4o | Backend services PHP (cuando disponible) |
| **Qwen** | OpenCode+Ollama | Qwen2.5-coder:7b | Tests, docs, scaffolding (gratis, local) |

## Prioridades actuales (hacer primero)

| # | Tarea | Agente | Estado |
|---|-------|--------|--------|
| 1 | Postcorte — Campos NULL / Esquema Expandido | Gemini | ✅ Resuelto (DDL Rollback) |
| 2 | UI Producción — 4 componentes Livewire | Claude | ✅ Completado (FASE 2) |
| 3 | Kardex UI — KardexView component | Claude | ⏳ Pendiente |
| 4 | Activar `auth:sanctum` en `/api/caja/*` | Claude/Codex | ⏳ Pendiente |
| 5 | Eliminar ReceivingService stub (duplicado de ReceptionService) | Codex | ⏳ Pendiente |

## En progreso

*(vacío — actualizar al iniciar tareas)*

---

## ✅ FASE 1 — Estabilización Backend Crítico (Claude Code, 2026-04-13)

### G-07 — selemti.transferencias: **NO EXISTE**

Consulta ejecutada:
```sql
SELECT tablename FROM pg_tables WHERE schemaname='selemti' AND tablename='transferencias';
```
Resultado: `[]` — tabla ausente. Tabla activa confirmada: `selemti.traspaso_cab`.

---

### G-03 — Fix DailyCloseService checkOperationalMoves()

**Archivo:** `app/Services/Operations/DailyCloseService.php`

ANTES (tabla inexistente + columnas incorrectas):
```php
DB::table('selemti.transferencias')
    ->where(fn ($q) => $q->where('origen_id', $branchId)->orWhere('destino_id', $branchId))
    ->whereDate('fecha_transferencia', ...)
    ->where('status', '!=', 'APPLIED')
```

DESPUÉS (tabla y columnas reales):
```php
DB::table('selemti.traspaso_cab')
    ->where(fn ($q) => $q->where('from_bodega_id', $branchId)->orWhere('to_bodega_id', $branchId))
    ->whereDate('created_at', ...)
    ->whereIn('estado', ['SOLICITADA', 'APROBADA', 'EN_TRANSITO'])
```

Fuente de verdad: `app/Models/Inventory/TransferHeader.php` (`$table = 'selemti.traspaso_cab'`)

---

### G-04 — Fix DailyCloseService: import + método faltante CRÍTICO

**Hallazgo crítico:** `processTheoreticalConsumption()` era invocado en línea 53 pero el método **no existía en el archivo**. PHP lanzaba `Error: Call to undefined method` en cada llamada a `run()`, bloqueando `OrquestadorPanel`.

**Cambio 1 — Import corregido:**
```php
// Añadido al inicio del archivo:
use App\Services\Inventory\PosConsumptionService;
```

**Cambio 2 — Método creado:**
- Query `public.tickets` LEFT JOIN `selemti.inv_consumo_pos` → tickets sin consumo del día
- Por ticket: `expandTicket(int)` → `confirmTicket(int)` (try/catch individual)
- Retorno: `['status' => true, 'tickets_processed' => $count]`

**Servicio canónico:** `App\Services\Inventory\PosConsumptionService`
- `expandTicket(int $ticketId): void` ✅ → llama `fn_expandir_consumo_ticket`
- `confirmTicket(int $ticketId): void` ✅ → llama `fn_confirmar_consumo_ticket`
- Sin dependencias rotas en IoC

---

### Estado FASE 1

| Tarea | Estado |
|-------|--------|
| G-07 selemti.transferencias verificada | ✅ DONE |
| G-03 tabla transfers corregida | ✅ DONE |
| G-04 import + método faltante creado | ✅ DONE |

---

### Estado consolidado de tareas del plan de orquestación

| Tarea | Agente | Estado | Fecha |
|-------|--------|--------|-------|
| G-07 Verificar selemti.transferencias | Claude | ✅ DONE — no existe | 2026-04-13 |
| G-03 Fix DailyCloseService tabla transfers | Claude | ✅ DONE | 2026-04-13 |
| G-04 Fix DailyCloseService import + método | Claude | ✅ DONE | 2026-04-13 |
| G-05 Eliminar Operations\PosConsumptionService | Gemini | ✅ DONE | 2026-04-13 |
| G-06 Fix PosReprocess.php import | Claude | ✅ DONE (excepcional, ver nota) | 2026-04-13 |
| G-08 Validación SQL v5 bloques 2,3,7 | Gemini | ✅ DONE — 0 rows (dataset vacío) | 2026-04-13 |
| G-01 Migración fix_postcorte_trigger | Gemini | 🚫 CANCELADA (Revertida - falso culpable) | 2026-04-13 |
| G-02 php artisan migrate | Gemini | 🚫 CANCELADA | 2026-04-13 |
| C-01 4 componentes Livewire Production | Claude | ✅ DONE | 2026-04-13 |
| C-02 4 vistas Blade Production | Claude | ✅ DONE | 2026-04-13 |
| C-03 Rutas production en web.php | Claude | ✅ DONE | 2026-04-13 |
| C-04 Documentación STATUS/WORK_ASSIGNMENTS | Claude | ✅ DONE | 2026-04-13 |

---

## ✅ FASE 1 — Estabilización Backend Crítico (COMPLETADA)

Detalle de G-07, G-03, G-04 documentado arriba. G-05 ejecutado por Gemini, G-08 validado sobre dataset vacío.

**Nota G-06 (ejecución excepcional):** Estaba congelado en el plan, pero G-05 eliminó `Operations\PosConsumptionService.php` sin corregir el import en `PosReprocess.php`. Esto rompió el autoloader completo (`BindingResolutionException` en todo `artisan`). Se aplicó G-06 de emergencia para restaurar la operación. Ver lección operativa abajo.

---

## ✅ FASE 2 — UI Producción (COMPLETADA — 2026-04-13)

### C-01 — 4 componentes Livewire PHP ✅
- `app/Livewire/Production/OrdersIndex.php` — listado paginado, filtros, resumen por estado
- `app/Livewire/Production/OrderCreate.php` — formulario nueva orden con folio auto
- `app/Livewire/Production/OrderDetail.php` — detalle con inputs/outputs/movimientos, acciones iniciar/cancelar
- `app/Livewire/Production/OrderCapture.php` — captura producción con BOM y verificación stock

### C-02 — 4 vistas Blade (Bootstrap 5) ✅
- `resources/views/livewire/production/orders-index.blade.php`
- `resources/views/livewire/production/order-create.blade.php`
- `resources/views/livewire/production/order-detail.blade.php`
- `resources/views/livewire/production/order-capture.blade.php`

### C-03 — Rutas en routes/web.php ✅
```
GET /production              → production.index   (OrdersIndex)
GET /production/create       → production.create  (OrderCreate)
GET /production/{orderId}    → production.show     (OrderDetail)
GET /production/{orderId}/capture → production.capture (OrderCapture)
+ Route::view('/produccion', 'produccion') mantenida por compatibilidad
```

---

## ✅ FASE 3 — Redefinición Postcorte: Cálculo Real (COMPLETADA)

El cálculo de totales de ventas y descuentos, que arrastró ceros absolutos en la base local, demostró no ser un bug de exclusión de rango en los tickets (falsa hipótesis extirpada). Fue catalogada oficialmente como una **Divergencia de Esquemas entre entornos**.

Un agente IA experimentó alterando el trigger y la función constructora sub-capa matemática inyectando 7 columnas ajenas (`total_ventas_brutas`, etc) que JAMÁS operaron en UI y rompieron la persistencia default.
**Solución Aplicada (Abril 2026):** Se amputó radicalmente todo rastro de la expansión truncada tanto en DDL (Base de datos), como en Funciones PL/PgSQL y el Modelo PHP, extirpándolo sin dejar huella y restituyendo exitosamente el estado original desde Producción en bruto. FASE COMPLETADA.

---

## ⚠️ Lección operativa — Eliminación de servicios (2026-04-13)

**Incidente:** G-05 eliminó `Operations\PosConsumptionService.php` pero dejó un consumidor activo (`PosReprocess.php`) con import al archivo eliminado. Esto rompió el autoloader de Laravel por completo — cualquier comando `artisan` fallaba.

**Regla para eliminaciones futuras:**
1. **Antes de eliminar** cualquier archivo de servicio, ejecutar:
   ```bash
   grep -r "NombreClase" app/ config/ routes/ --include="*.php"
   ```
2. **Corregir todos los consumidores** antes de eliminar el archivo, no después.
3. **Después de eliminar**, ejecutar sanity check:
   ```bash
   composer dump-autoload && php artisan route:list > /dev/null
   ```
4. Si la eliminación y la corrección de consumidores están en tareas separadas del plan, **deben ejecutarse juntas o en orden estricto**. Nunca eliminar sin el fix de imports en la misma operación.

---

## 📤 Handoff actualizado (estado real post-FASE 2)

```
Servicios PosConsumption:
  - Canónico: App\Services\Inventory\PosConsumptionService ✅
  - Operations\: ELIMINADO (G-05) ✅
  - Pos\: CONGELADO (broken por falta de repositorios)
  - PosReprocess.php: import corregido a Inventory\ (G-06) ✅

DailyCloseService: FUNCIONAL
  - Import correcto, processTheoreticalConsumption() creado, tabla transfers corregida
  - Validación G-08 pasó sobre dataset vacío — requiere validación con tickets reales

Pendiente para próxima fase (FASE 3):
  - FASE 3 redefinida: Auditoría completa de `selemti.fn_generar_postcorte`.
  - Investigar exclusión de tickets por la ventana de tiempos (`apertura_ts` vs `closing_date`).
  - G-01 y G-02 originales fueron revertidos correctamente tras diagnóstico.
```

---

## Completado recientemente (abril 2026)

- [x] UOM conversion pipeline — `resolveToBase()` en todos los servicios
- [x] Fix `App\Models\Inv\Item` — import `use App\Models\Catalogs\Unidad` faltante
- [x] TransferService — conversión UOM en `postTransferToInventory()`
- [x] Migración `add_uom_conversion_metadata` — columnas is_exact, scope, notes
- [x] Skills personalizados: terrena-context, terrena-simulate, terrena-agent-protocol, terrena-dev-environment
- [x] MCP servers: postgres, filesystem, git, ollama, github

## Instrucciones para nuevos agentes

1. Leer `CLAUDE.md` (reglas generales) y `.gemini/GEMINI.md` o equivalente para tu IA
2. Leer este archivo para ver qué se está haciendo
3. Elegir una tarea de "Prioridades" marcada como ⏳
4. Crear worktree: `git worktree add C:\terrena-<agente> work/<agente>-<tarea>`
5. Al terminar: PR a `develop`, actualizar este STATUS.md
