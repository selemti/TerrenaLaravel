# ✅ CHECKLIST DE VALIDACIÓN - TRANSFERENCIAS

**Módulo**: Transferencias entre Almacenes
**Versión**: 1.0
**Fecha**: Noviembre 2025
**Objetivo**: Validar implementación completa antes de deployment

---

## 📋 ÍNDICE

1. [Backend Validation](#backend-validation)
2. [Frontend Validation](#frontend-validation)
3. [Database Validation](#database-validation)
4. [API Validation](#api-validation)
5. [UI/UX Validation](#uiux-validation)
6. [Testing Validation](#testing-validation)
7. [Security Validation](#security-validation)
8. [Performance Validation](#performance-validation)
9. [Documentation Validation](#documentation-validation)
10. [Deployment Readiness](#deployment-readiness)

---

## 1️⃣ BACKEND VALIDATION

### Models

- [ ] **TransferHeader** (`app/Models/Inv/TransferHeader.php`)
  - [ ] Conexión PostgreSQL configurada: `protected $connection = 'pgsql'`
  - [ ] Tabla correcta: `protected $table = 'selemti.transfer_cab'`
  - [ ] Relaciones definidas: `lines()`, `almacenOrigen()`, `almacenDestino()`, `solicitadoPor()`, `aprobadoPor()`, `despachoPor()`, `recibidoPor()`, `posteadoPor()`
  - [ ] Casts correctos: fechas como `datetime`, estados como `string`
  - [ ] Constantes de estado definidas: `STATUS_SOLICITADA`, `STATUS_APROBADA`, `STATUS_EN_TRANSITO`, `STATUS_RECIBIDA`, `STATUS_POSTEADA`
  - [ ] Fillable/Guarded configurado correctamente

- [ ] **TransferLine** (`app/Models/Inv/TransferLine.php`)
  - [ ] Conexión PostgreSQL configurada
  - [ ] Tabla correcta: `protected $table = 'selemti.transfer_det'`
  - [ ] Relaciones definidas: `header()`, `item()`, `uom()`
  - [ ] Casts correctos: cantidades como `decimal:4`
  - [ ] Fillable/Guarded configurado correctamente

### Service Layer

- [ ] **TransferService** (`app/Services/Inventory/TransferService.php`)
  - [ ] Método `createTransfer()` implementado
    - [ ] Validación de almacén origen ≠ destino
    - [ ] Creación de header y lines en transacción
    - [ ] Retorna transfer_id
  - [ ] Método `approveTransfer()` implementado
    - [ ] Validación de stock en almacén origen
    - [ ] Actualiza estado a `APROBADA`
    - [ ] Registra `aprobada_por` y `fecha_aprobada`
  - [ ] Método `shipTransfer()` implementado
    - [ ] Actualiza estado a `EN_TRANSITO`
    - [ ] Registra `despacho_por`, `fecha_despachada`, `numero_guia`
    - [ ] Actualiza `cantidad_despachada` en lines
  - [ ] Método `receiveTransfer()` implementado
    - [ ] Actualiza estado a `RECIBIDA`
    - [ ] Registra `recibido_por`, `fecha_recibida`
    - [ ] Actualiza `cantidad_recibida` y `observaciones_recepcion` en lines
    - [ ] Calcula varianzas automáticamente
  - [ ] Método `postTransfer()` implementado
    - [ ] Crea 2 movimientos en `mov_inv` por cada línea:
      - Salida: tipo `TRASPASO_OUT`, qty negativo, almacén origen
      - Entrada: tipo `TRASPASO_IN`, qty positivo, almacén destino
    - [ ] Actualiza estado a `POSTEADA`
    - [ ] Registra `posteada_por` y `fecha_posteada`
    - [ ] Todo en transacción atómica

### Controllers

- [ ] **TransferController** (`app/Http/Controllers/Api/Inventory/TransferController.php`)
  - [ ] `index()` - Lista transferencias con filtros
  - [ ] `store()` - Crea transferencia (llama `TransferService::createTransfer`)
  - [ ] `show()` - Detalle de transferencia con líneas
  - [ ] `approve()` - Aprueba transferencia (llama `TransferService::approveTransfer`)
  - [ ] `ship()` - Despacha transferencia (llama `TransferService::shipTransfer`)
  - [ ] `receive()` - Recibe transferencia (llama `TransferService::receiveTransfer`)
  - [ ] `post()` - Postea a inventario (llama `TransferService::postTransfer`)
  - [ ] Validaciones en cada endpoint
  - [ ] Responses con estructura estándar: `{ok, data, message, timestamp}`
  - [ ] Manejo de errores con try/catch

### Factory

- [ ] **TransferHeaderFactory** (`database/factories/TransferHeaderFactory.php`)
  - [ ] Genera datos realistas para testing
  - [ ] Incluye estados válidos
  - [ ] Referencias a almacenes y usuarios válidos

---

## 2️⃣ FRONTEND VALIDATION

### Componentes Livewire

- [ ] **Transfers/Index** (`app/Livewire/Transfers/Index.php`)
  - [ ] Filtros implementados: estado, almacén origen/destino, fecha
  - [ ] Tabla con paginación
  - [ ] Badges de estado con colores correctos
  - [ ] Acciones contextuales por estado:
    - SOLICITADA: Aprobar / Editar / Cancelar
    - APROBADA: Despachar
    - EN_TRANSITO: Recibir
    - RECIBIDA: Postear
  - [ ] Loading states en botones
  - [ ] Toast notifications en acciones

- [ ] **Transfers/Create** (`app/Livewire/Transfers/Create.php`)
  - [ ] Wizard de 3 pasos implementado
  - [ ] Paso 1: Información General (origen, destino, fecha, observaciones)
  - [ ] Paso 2: Agregar Ítems (tabla dinámica con add/remove)
  - [ ] Paso 3: Revisión y Confirmación
  - [ ] Progress bar visual (1/3, 2/3, 3/3)
  - [ ] Validación por paso (no avanza si falta data)
  - [ ] Botones Anterior/Siguiente/Finalizar
  - [ ] Loading spinner en "Finalizar"
  - [ ] Validaciones inline con `wire:model.live`
  - [ ] Mensajes de error en español

- [ ] **Transfers/Dispatch** (`app/Livewire/Transfers/Dispatch.php`)
  - [ ] Muestra info de transferencia
  - [ ] Tabla de ítems con cantidad solicitada
  - [ ] Input "Número de guía"
  - [ ] Input "Cantidad despachada" (editable, default = solicitada)
  - [ ] Botón "Marcar en Tránsito" con loading state
  - [ ] Llama API `POST /api/inventory/transfers/{id}/ship`
  - [ ] Toast success/error

- [ ] **Transfers/Receive** (`app/Livewire/Transfers/Receive.php`)
  - [ ] Muestra info de transferencia (guía, fecha despachada)
  - [ ] Tabla comparativa:
    - Cantidad despachada
    - Cantidad recibida (input editable)
    - Diferencia (calculada)
    - Varianza % (calculada)
    - Observaciones por línea
  - [ ] Highlight diferencias >5% (amarillo), >10% (rojo)
  - [ ] Resumen de diferencias totales
  - [ ] Modal de confirmación antes de guardar
  - [ ] Botón "Registrar Recepción" con loading state
  - [ ] Llama API `POST /api/inventory/transfers/{id}/receive`

### Vistas Blade

- [ ] **index.blade.php** (`resources/views/livewire/transfers/index.blade.php`)
  - [ ] Tabla responsive (cards en mobile)
  - [ ] Badges de estado con colores Bootstrap 5
  - [ ] Dropdowns de acciones con iconos
  - [ ] Skeleton loaders mientras carga

- [ ] **create.blade.php** (`resources/views/livewire/transfers/create.blade.php`)
  - [ ] Wizard responsive
  - [ ] Progress stepper visible
  - [ ] Validaciones inline visibles
  - [ ] Tabla de ítems dinámica

- [ ] **dispatch.blade.php** (`resources/views/livewire/transfers/dispatch.blade.php`)
  - [ ] Layout limpio
  - [ ] Inputs accesibles
  - [ ] Botones claramente etiquetados

- [ ] **receive.blade.php** (`resources/views/livewire/transfers/receive.blade.php`)
  - [ ] Tabla comparativa clara
  - [ ] Highlights de varianza funcionales
  - [ ] Resumen visual de diferencias

### Componentes Reutilizables

- [ ] **transfer-status-badge.blade.php** (`resources/views/components/transfer-status-badge.blade.php`)
  - [ ] Recibe `$estado` como parámetro
  - [ ] Retorna badge con color correcto:
    - SOLICITADA: `bg-info`
    - APROBADA: `bg-primary`
    - EN_TRANSITO: `bg-warning`
    - RECIBIDA: `bg-success`
    - POSTEADA: `bg-secondary`

- [ ] **progress-stepper.blade.php** (`resources/views/components/progress-stepper.blade.php`)
  - [ ] Recibe `$currentStep` y `$totalSteps`
  - [ ] Muestra progreso visual
  - [ ] Responsive

---

## 3️⃣ DATABASE VALIDATION

### Estructura de BD

- [ ] **Tabla `selemti.transfer_cab` existe**
  ```bash
  psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.transfer_cab"
  ```
  - [ ] Columnas base presentes: `id`, `origen_almacen_id`, `destino_almacen_id`, `estado`
  - [ ] Columnas agregadas por migration:
    - `aprobada_por`, `despacho_por`, `recibido_por`, `posteada_por`
    - `fecha_solicitada`, `fecha_aprobada`, `fecha_despachada`, `fecha_recibida`, `fecha_posteada`
    - `observaciones`, `observaciones_recepcion`, `numero_guia`
  - [ ] Foreign keys correctas: `origen_almacen_id`, `destino_almacen_id` → `cat_almacenes`
  - [ ] User references: `solicitada_por`, `aprobada_por`, etc. → `users`

- [ ] **Tabla `selemti.transfer_det` existe**
  ```bash
  psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.transfer_det"
  ```
  - [ ] Columnas presentes: `id`, `transfer_cab_id`, `item_id`, `uom_id`
  - [ ] Columnas de cantidades: `cantidad_solicitada`, `cantidad_despachada`, `cantidad_recibida`
  - [ ] Foreign keys correctas

- [ ] **Tabla `selemti.mov_inv` existe** (para posteo)
  ```bash
  psql -h localhost -p 5433 -U postgres -d pos -c "\d selemti.mov_inv"
  ```
  - [ ] Columna `tipo` es ENUM con valores: `'TRASPASO_IN'`, `'TRASPASO_OUT'`
  - [ ] Columnas: `item_id`, `batch_id`, `tipo`, `qty`, `uom`, `ref_tipo`, `ref_id`, `ts`

### Migration

- [ ] **Migration `2025_11_01_090000_complete_transfer_tables.php` existe**
  - [ ] Agrega columnas faltantes a `transfer_cab`
  - [ ] Agrega columnas faltantes a `transfer_det`
  - [ ] Crea índices para foreign keys
  - [ ] Método `down()` implementado (rollback)

- [ ] **Migration ejecutada correctamente**
  ```bash
  php artisan migrate:status
  ```
  - [ ] Aparece en estado "Ran"

### Datos de Prueba

- [ ] **Almacenes de prueba existen**
  ```sql
  SELECT id, clave, nombre FROM selemti.cat_almacenes ORDER BY id LIMIT 5;
  ```
  - [ ] Al menos 2 almacenes disponibles para transferencias

- [ ] **Ítems de prueba existen**
  ```sql
  SELECT id, nombre FROM selemti.items WHERE activo = true LIMIT 5;
  ```
  - [ ] Al menos 5 ítems activos disponibles

---

## 4️⃣ API VALIDATION

### Endpoints

- [ ] **GET `/api/inventory/transfers`**
  - [ ] Retorna lista de transferencias
  - [ ] Acepta filtros: `?estado=SOLICITADA&origen_id=57&fecha_desde=2025-11-01`
  - [ ] Paginación funcional
  - [ ] Response structure: `{ok: true, data: [...], timestamp: "..."}`

- [ ] **POST `/api/inventory/transfers`**
  - [ ] Crea nueva transferencia
  - [ ] Valida payload:
    ```json
    {
      "origen_almacen_id": 57,
      "destino_almacen_id": 58,
      "lineas": [
        {
          "item_id": "ITEM-001",
          "cantidad": 10,
          "uom_id": 1
        }
      ]
    }
    ```
  - [ ] Retorna `transfer_id` y estado `SOLICITADA`
  - [ ] Error si origen = destino
  - [ ] Error si líneas vacías

- [ ] **GET `/api/inventory/transfers/{id}`**
  - [ ] Retorna detalle de transferencia con líneas
  - [ ] Incluye relaciones: almacenes, ítems, usuarios
  - [ ] Error 404 si no existe

- [ ] **POST `/api/inventory/transfers/{id}/approve`**
  - [ ] Cambia estado a `APROBADA`
  - [ ] Valida stock suficiente en almacén origen
  - [ ] Error si estado no es `SOLICITADA`
  - [ ] Error si stock insuficiente

- [ ] **POST `/api/inventory/transfers/{id}/ship`**
  - [ ] Cambia estado a `EN_TRANSITO`
  - [ ] Acepta payload:
    ```json
    {
      "numero_guia": "GUIA-12345",
      "lineas": [
        {
          "linea_id": 1,
          "cantidad_despachada": 10
        }
      ]
    }
    ```
  - [ ] Error si estado no es `APROBADA`

- [ ] **POST `/api/inventory/transfers/{id}/receive`**
  - [ ] Cambia estado a `RECIBIDA`
  - [ ] Acepta payload:
    ```json
    {
      "lineas": [
        {
          "linea_id": 1,
          "cantidad_recibida": 9.5,
          "observaciones_recepcion": "Merma en tránsito"
        }
      ]
    }
    ```
  - [ ] Calcula varianzas automáticamente
  - [ ] Error si estado no es `EN_TRANSITO`

- [ ] **POST `/api/inventory/transfers/{id}/post`**
  - [ ] Cambia estado a `POSTEADA`
  - [ ] Crea movimientos en `mov_inv`:
    - Salida (TRASPASO_OUT) en almacén origen
    - Entrada (TRASPASO_IN) en almacén destino
  - [ ] Error si estado no es `RECIBIDA`
  - [ ] Error si ya fue posteada

### Authentication

- [ ] **API requiere autenticación** (Sanctum token)
  - [ ] Endpoints protegidos con middleware `auth:sanctum`
  - [ ] Error 401 sin token
  - [ ] Error 403 sin permisos

### Error Handling

- [ ] **Errores retornan JSON estructurado**
  ```json
  {
    "ok": false,
    "error": "error_code",
    "message": "Human readable message",
    "timestamp": "2025-11-01T10:30:00Z"
  }
  ```
- [ ] Códigos HTTP correctos: 200, 201, 400, 401, 403, 404, 500

---

## 5️⃣ UI/UX VALIDATION

### Responsive Design

- [ ] **Desktop (1920x1080)**
  - [ ] Tabla de transferencias visible completa
  - [ ] Wizard de creación en 3 columnas
  - [ ] Modales centrados
  - [ ] Sidebar navegable

- [ ] **Tablet (768px)**
  - [ ] Tabla responsive (scroll horizontal si es necesario)
  - [ ] Wizard en 2 columnas
  - [ ] Sidebar colapsable

- [ ] **Mobile (375px)**
  - [ ] Tabla se convierte en cards
  - [ ] Wizard en 1 columna (vertical)
  - [ ] Modales full-screen
  - [ ] Touch targets >44px
  - [ ] Botones de acción accesibles

### Badges y Estados

- [ ] **Colores correctos según estado**
  - [ ] SOLICITADA: Azul claro (`bg-info`)
  - [ ] APROBADA: Azul (`bg-primary`)
  - [ ] EN_TRANSITO: Amarillo (`bg-warning`)
  - [ ] RECIBIDA: Verde (`bg-success`)
  - [ ] POSTEADA: Gris (`bg-secondary`)

### Loading States

- [ ] **Spinners visibles durante operaciones**
  - [ ] Botón "Crear Transferencia" muestra spinner
  - [ ] Botón "Aprobar" muestra spinner
  - [ ] Botón "Despachar" muestra spinner
  - [ ] Botón "Recibir" muestra spinner
  - [ ] Botón "Postear" muestra spinner

### Toast Notifications

- [ ] **Mensajes de éxito**
  - [ ] "Transferencia creada exitosamente"
  - [ ] "Transferencia aprobada"
  - [ ] "Transferencia despachada"
  - [ ] "Recepción registrada"
  - [ ] "Transferencia posteada a inventario"

- [ ] **Mensajes de error**
  - [ ] "Stock insuficiente en almacén origen"
  - [ ] "No se puede aprobar transferencia en este estado"
  - [ ] "Error al guardar: [detalle]"

### Validaciones Inline

- [ ] **Validaciones en tiempo real**
  - [ ] Almacén origen no puede ser igual a destino
  - [ ] Cantidad debe ser >0
  - [ ] Fecha solicitada no puede ser pasada
  - [ ] Al menos 1 línea requerida

- [ ] **Mensajes de error claros**
  - [ ] Aparecen debajo del campo
  - [ ] Color rojo
  - [ ] Icono de error

---

## 6️⃣ TESTING VALIDATION

### Feature Tests

- [ ] **Test `TransferCreationTest.php`**
  - [ ] `test_can_create_transfer_with_valid_data()`
  - [ ] `test_cannot_create_transfer_with_same_warehouse()`
  - [ ] `test_cannot_create_transfer_without_lines()`

- [ ] **Test `TransferApprovalTest.php`**
  - [ ] `test_can_approve_transfer_with_sufficient_stock()`
  - [ ] `test_cannot_approve_transfer_with_insufficient_stock()`
  - [ ] `test_cannot_approve_transfer_in_wrong_state()`

- [ ] **Test `TransferShipmentTest.php`**
  - [ ] `test_can_ship_approved_transfer()`
  - [ ] `test_cannot_ship_transfer_in_wrong_state()`
  - [ ] `test_updates_shipped_quantities_correctly()`

- [ ] **Test `TransferReceiptTest.php`**
  - [ ] `test_can_receive_shipped_transfer()`
  - [ ] `test_calculates_variance_correctly()`
  - [ ] `test_cannot_receive_transfer_in_wrong_state()`

- [ ] **Test `TransferPostingTest.php`**
  - [ ] `test_can_post_received_transfer()`
  - [ ] `test_creates_movement_records_correctly()`
  - [ ] `test_cannot_post_transfer_twice()`

- [ ] **Test `TransferWorkflowTest.php`** (end-to-end)
  - [ ] `test_complete_transfer_workflow()`
    - Crear → Aprobar → Despachar → Recibir → Postear
    - Verificar movimientos en `mov_inv`
    - Verificar estados en cada paso

### Test Coverage

- [ ] **Coverage >80% en Service Layer**
  ```bash
  php artisan test --coverage --min=80
  ```

- [ ] **Todos los tests pasan**
  ```bash
  php artisan test
  ```
  - [ ] 0 failures
  - [ ] 0 errors
  - [ ] Tiempo <30 segundos

---

## 7️⃣ SECURITY VALIDATION

### Permissions

- [ ] **Permiso `can_manage_transfers` existe**
  ```sql
  SELECT name FROM selemti.permissions WHERE name = 'can_manage_transfers';
  ```

- [ ] **Middleware de permisos aplicado**
  - [ ] Endpoints requieren permiso `can_manage_transfers`
  - [ ] Error 403 si usuario no tiene permiso

### Input Validation

- [ ] **Validación de datos en controller**
  - [ ] IDs de almacenes existen
  - [ ] IDs de ítems existen
  - [ ] Cantidades son numéricas >0
  - [ ] Estados son válidos

### SQL Injection Prevention

- [ ] **Uso de Eloquent/Query Builder** (no SQL raw)
- [ ] **Prepared statements** en queries custom

### Authorization

- [ ] **Usuario solo ve transferencias de sus sucursales** (si aplica scope)
- [ ] **Usuario solo puede aprobar si tiene rol adecuado**

---

## 8️⃣ PERFORMANCE VALIDATION

### Query Optimization

- [ ] **Eager loading en relaciones**
  ```php
  TransferHeader::with(['lines.item', 'almacenOrigen', 'almacenDestino'])->get();
  ```
  - [ ] No hay N+1 queries

- [ ] **Índices en columnas de búsqueda**
  ```sql
  -- Verificar índices
  SELECT indexname, indexdef
  FROM pg_indexes
  WHERE tablename = 'transfer_cab' AND schemaname = 'selemti';
  ```
  - [ ] Índice en `estado`
  - [ ] Índice en `origen_almacen_id`
  - [ ] Índice en `destino_almacen_id`
  - [ ] Índice en `fecha_solicitada`

### Response Time

- [ ] **API endpoints <500ms**
  ```bash
  curl -w "@curl-format.txt" https://staging.terrena.com/api/inventory/transfers
  ```
  - [ ] GET `/api/inventory/transfers` <300ms
  - [ ] POST `/api/inventory/transfers` <500ms
  - [ ] POST `/api/inventory/transfers/{id}/post` <1000ms (más complejo)

### Paginación

- [ ] **Index endpoint paginado**
  - [ ] Default: 25 registros por página
  - [ ] Acepta parámetro `?per_page=50`
  - [ ] Retorna metadata: `total`, `current_page`, `last_page`

---

## 9️⃣ DOCUMENTATION VALIDATION

### Code Documentation

- [ ] **PHPDoc en todos los métodos**
  - [ ] Service methods tienen `@param` y `@return`
  - [ ] Complex logic tiene comentarios inline

### API Documentation

- [ ] **Swagger/OpenAPI spec actualizada**
  ```bash
  php artisan l5-swagger:generate
  ```
  - [ ] Endpoints `/api/inventory/transfers/*` documentados
  - [ ] Ejemplos de request/response incluidos

### User Documentation

- [ ] **README actualizado** (si aplica)
  - [ ] Instrucciones de uso del módulo
  - [ ] Screenshots de UI
  - [ ] Flujo de trabajo explicado

### Deployment Guide

- [ ] **DEPLOYMENT_GUIDE_TRANSFERENCIAS.md completo**
  - [ ] Pre-requisitos listados
  - [ ] Steps de staging deployment
  - [ ] Steps de production deployment
  - [ ] Rollback plan incluido
  - [ ] Smoke tests documentados

---

## 🔟 DEPLOYMENT READINESS

### Pre-Deployment

- [ ] **Branch listo para merge**
  ```bash
  git status
  git log --oneline -5
  ```
  - [ ] Commits limpios
  - [ ] No hay archivos sin versionar
  - [ ] Branch actualizado con `main`/`develop`

- [ ] **Migrations testeadas en local**
  ```bash
  php artisan migrate:fresh
  php artisan migrate:rollback
  php artisan migrate
  ```
  - [ ] Up funciona
  - [ ] Down funciona
  - [ ] Datos de prueba persisten

- [ ] **Backup de BD producción realizado**
  ```bash
  pg_dump -h localhost -U postgres -d pos -F c -f backup_pre_transfers.backup
  ```

### Staging Deployment

- [ ] **Deploy a staging exitoso**
  - [ ] Código pulled correctamente
  - [ ] Dependencies instaladas
  - [ ] Migrations ejecutadas
  - [ ] Cache cleared
  - [ ] Smoke tests pasan

### Production Deployment

- [ ] **Go/No-Go Decision aprobada**
  - [ ] QA team aprobó staging
  - [ ] Stakeholders notificados
  - [ ] Downtime window comunicado

### Post-Deployment

- [ ] **Monitoring activo primeras 4 horas**
  - [ ] No errores 500 en logs
  - [ ] API response time normal
  - [ ] No bugs P0 reportados

- [ ] **Smoke tests en producción pasan**
  - [ ] Crear transferencia de prueba
  - [ ] Aprobar
  - [ ] Despachar
  - [ ] Recibir
  - [ ] Postear
  - [ ] Verificar movimientos en `mov_inv`

---

## 📊 RESUMEN DE VALIDACIÓN

### Checklist General

| Categoría | Items | Completados | % |
|-----------|-------|-------------|---|
| Backend | 20 | [ ] | 0% |
| Frontend | 25 | [ ] | 0% |
| Database | 15 | [ ] | 0% |
| API | 12 | [ ] | 0% |
| UI/UX | 18 | [ ] | 0% |
| Testing | 10 | [ ] | 0% |
| Security | 8 | [ ] | 0% |
| Performance | 6 | [ ] | 0% |
| Documentation | 6 | [ ] | 0% |
| Deployment | 10 | [ ] | 0% |
| **TOTAL** | **130** | **0** | **0%** |

### Criterios de Éxito

- ✅ **Mínimo 95% de items completados**
- ✅ **Todos los tests pasan (100%)**
- ✅ **No bugs P0 o P1 sin resolver**
- ✅ **API response time <500ms**
- ✅ **UI funciona en desktop y mobile**
- ✅ **Deployment guide completo**

---

## 🚨 BLOCKERS

Si alguno de estos items falla, **NO PROCEDER** con deployment:

1. ❌ Tests no pasan (cualquier falla)
2. ❌ Migration falla en staging
3. ❌ API retorna errores 500
4. ❌ UI completamente rota en mobile
5. ❌ Stock no se actualiza correctamente al postear
6. ❌ Movimientos en `mov_inv` no se crean
7. ❌ Usuario sin permisos puede acceder a endpoints
8. ❌ Backup de BD producción no existe

---

## 📞 ESCALATION

- **P0 (Blocker)**: Detener deployment, llamar Tech Lead
- **P1 (Critical)**: Crear hotfix, deployment continúa con precaución
- **P2 (Minor)**: Documentar issue, fix en próximo sprint
- **P3 (Enhancement)**: Agregar a backlog

---

**Versión**: 1.0
**Fecha de Creación**: 31 de Octubre 2025
**Última Actualización**: 31 de Octubre 2025

✅ **Validación completa antes de deployment a producción**
