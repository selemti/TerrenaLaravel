# Documentación: Orquestador de Cierre Diario

## 1. Visión General

El Orquestador de Cierre Diario es un proceso automatizado responsable de consolidar las operaciones de una sucursal al final de cada día. Su objetivo es asegurar la integridad de los datos de inventario, confirmar el consumo teórico basado en las ventas y generar una "foto" (snapshot) del estado del inventario para análisis y reportería.

El proceso está diseñado para ser **idempotente**, **robusto** y **trazable**.

## 2. Componentes Principales

| Componente | Ruta | Responsabilidad |
| :--- | :--- | :--- |
| **Artisan Command** | `app/Console/Commands/CloseDaily.php` | Punto de entrada para la ejecución manual y programada. Parsea los argumentos (`--date`, `--branch`) y delega la lógica al servicio. |
| **Service** | `app/Services/Operations/DailyCloseService.php` | Contiene toda la lógica de negocio del proceso de cierre. Orquesta los pasos, maneja la idempotencia y el logging. |
| **Scheduler** | `app/Console/Kernel.php` | Asegura la ejecución automática del comando `close:daily` todos los días a la hora definida. |

## 3. Flujo de Ejecución

El proceso se ejecuta para una **sucursal** y **fecha** específicas. Sigue estrictamente los siguientes pasos:

1.  **Adquirir Lock de Idempotencia**:
    *   Intenta establecer una llave en Redis (`close:lock:{branch_id}:{date}`) con un TTL de 23 horas.
    *   Si la llave ya existe, el proceso termina inmediatamente con estado `already_done`, previniendo duplicados.

2.  **Pre-chequeo de Sincronización POS**:
    *   Verifica la tabla `selemti.pos_sync_batches`.
    *   **Condición**: Debe existir un registro para la sucursal/fecha con `status = 'COMPLETED'`.
    *   Si no se cumple, el proceso se aborta limpiamente. **Es el único paso bloqueante.**

3.  **Procesar Consumo Teórico**:
    *   Identifica todos los tickets (`selemti.tickets`) del día que no tienen movimientos de inventario (`selemti.mov_inv`) asociados.
    *   Para cada ticket pendiente, invoca la función de PostgreSQL `selemti.fn_confirmar_consumo_ticket(?)`.
    *   Esta función es responsable de generar los movimientos de inventario correspondientes al consumo de la receta del ticket.

4.  **Verificar Movimientos Operativos**:
    *   Revisa si existen recepciones (`selemti.recepcion_cab`) o transferencias (`selemti.transferencias`) del día que no estén en un estado final (`POSTED`, `APPLIED`).
    *   **Acción**: Si encuentra pendientes, registra un `warning` en el log. **No detiene el cierre.**

5.  **Verificar Conteos de Inventario**:
    *   Revisa si existen conteos (`selemti.inventory_counts`) del día que no estén en estado `CLOSED`.
    *   **Acción**: Si encuentra conteos abiertos, registra un `warning`. **No detiene el cierre.**

6.  **Generar Snapshot Diario**:
    *   Calcula el stock teórico final para cada ítem con movimiento en la sucursal. El cálculo es la suma de todos los registros en `selemti.mov_inv` hasta el final del día.
    *   Obtiene el costo promedio actual del ítem desde `selemti.items`.
    *   Si hubo un conteo cerrado ese día, obtiene la cantidad física (`fisico_qty`).
    *   Realiza un `UPSERT` en la tabla `selemti.inventory_snapshot` utilizando la llave única `(snapshot_date, branch_id, item_id)`. Esto asegura que la información se inserte si no existe o se actualice si el proceso se re-ejecuta.

7.  **Resultado Final (Semáforo)**:
    *   El cierre se considera exitoso (`closed = true`) si los pasos de **Sincronización POS**, **Consumo** y **Snapshot** fueron exitosos.
    *   Los pasos de Movimientos y Conteos solo generan advertencias pero no impiden un cierre exitoso.

## 4. Ejecución

### 4.1. Ejecución Automática (Scheduler)

-   **Comando**: `php artisan close:daily`
-   **Frecuencia**: Todos los días.
-   **Hora**: `22:00` (10 PM).
-   **Zona Horaria**: `America/Mexico_City`.
-   **Lógica de Fecha**:
    -   Si se ejecuta a las 22:00 o después, procesa el día actual.
    -   Si se ejecuta antes de las 22:00, procesa el día anterior.

### 4.2. Ejecución Manual (Reprocesos)

Es posible re-ejecutar el cierre para una fecha o sucursal específica.

```bash
# Ejecutar para una fecha específica y todas las sucursales activas
php artisan close:daily --date="2025-10-30"

# Ejecutar para la fecha por defecto y una sucursal específica
php artisan close:daily --branch="BR01"

# Ejecutar para una fecha y múltiples sucursales
php artisan close:daily --date="2025-10-30" --branch="BR01" --branch="BR02"
```

## 5. Trazabilidad (Logging)

-   **Canal de Log**: `daily_close` (configurable en `config/logging.php`).
-   **Formato**: JSON estructurado.
-   **Campos Clave**:
    -   `trace_id`: Identificador único para toda la ejecución del proceso.
    -   `branch_id`: Sucursal que se está procesando.
    -   `date`: Fecha del cierre.
    -   `step`: Etapa del proceso (ej. `step_check_pos_sync`).
    -   `status`: `started`, `completed`, `completed_with_warnings`.
    -   Contexto adicional (ej. `tickets_processed`, `items_snapshotted`).

**Ejemplo de Log:**
```json
{"trace_id":"close_672a1b3c4d5e6","branch_id":"1","date":"2025-10-30","step":"step_process_consumption","status":"completed","tickets_processed":152}
```
