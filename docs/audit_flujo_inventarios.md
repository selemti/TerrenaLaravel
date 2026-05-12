# Auditoría: Flujo Completo de Inventarios (TerrenaLaravel V4.1)

Tras analizar los componentes clave del sistema (incluyendo la lógica de integración de `TEST_FLUJO_INVENTARIO_COMPLETO.php` y el motor de explosión de recetas `fn_expandir_consumo_ticket`), presento la auditoría del flujo logístico y financiero del inventario.

## 1. Módulo de Recepción (Entradas)
El flujo de entrada de mercancías (compras) funciona mediante un proceso estructurado de 3 estados para asegurar la validez antes de afectar existencias.

- **[BORRADOR]**: Se crea `recepcion_cab` y `recepcion_det`. En este punto no hay alteraciones al Kardex ni lotes creados.
- **[VALIDADA]**: El documento es bloqueado para edición y revisado, preparándolo para el posteo final.
- **[POSTEADA]**: 
  - Se genera un nuevo lote en `selemti.inventory_batch` rastreando fecha de caducidad, lote proveedor, costo unitario, cantidad original y actual.
  - Se inserta un movimiento positivo en `selemti.mov_inv` (Kardex) con la referencia `ref_tipo = 'recepcion'`.
  - El `batch_id` se asocia directamente a la línea de la recepción original.

## 2. Módulo de Transferencias (Movimiento Interno)
El manejo de traspasos entre almacenes requiere comprobación física en ambos extremos, utilizando 5 estados:

1. **[SOLICITADA/CREADA]**: El `TransferService` registra la intención de mover inventario de Almacén A al B.
2. **[APROBADA]**: Se autoriza la salida del inventario de origen.
3. **[EN TRÁNSITO]**: Se expide y asigna un número de guía. El inventario ya no está en origen, pero tampoco en el destino final.
4. **[RECIBIDA]**: La sucursal destino confirma las cantidades. **Importante:** Se genera cálculo de varianzas (faltantes/sobrantes) por línea.
5. **[POSTEADA]**: 
   - Genera movimiento `TRANSFER_OUT` (negativo) en el almacén origen.
   - Genera movimiento `TRANSFER_IN` (positivo) en el almacén destino.

> [!TIP]
> **Refactorización pendiente:** El script de test indica que algunas firmas de `TransferService` podrían requerir completarse o revisarse dependiendo de si el servicio ya fue migrado al 100%.

## 3. Consumo desde Punto de Venta (Explosión de Recetas)
La salida de inventario por ventas es el flujo más complejo debido a la naturaleza dinámica de los platillos. Se ejecuta a nivel base de datos mediante la función `fn_expandir_consumo_ticket (v2.5)`.

### Mecanismo de Recursividad Logística:
1. **Detección de Venta**: A partir del `ticket_item`, la función inserta un registro en `inv_consumo_pos` con estado `'PENDIENTE'`.
2. **Explosión Recursiva (CTE `bom_recursive`)**:
   - Lee el `codigo_plato_pos` y busca su correspondencia en `receta_cab` y `receta_version` (solo lee la `version_publicada = true`).
   - Analiza un nivel de profundidad máximo de 5 capas (`level < 5`).
3. **Modificadores POS**: Integra transparentemente cualquier extra (e.g. aderezo extra) si el modificador tiene vinculada su propia receta mediante `receta_modificador_id`.
4. **Stock-Aware (Inteligencia de Sub-recetas)**:
   > [!IMPORTANT]
   > La función evalúa la vista `v_stock_actual`. Si un platillo contiene una sub-receta (ej. Salsa Madre), verifica si *hay stock preparado* de esa salsa.
   > - Si **hay stock**: La función *no explota* la salsa; la descuenta como si fuera un insumo individual.
   > - Si **no hay stock**: Sigue bajando niveles y explota los ingredientes crudos de la salsa.

## 4. Kardex Central (`mov_inv`)
El corazón financiero del sistema. Todo flujo termina aquí.
Las estructuras críticas que garantizan la integridad son:
- **`tipo`**: Define la dirección contable y logística (Entrada/Salida).
- **`ref_tipo` & `ref_id`**: Trazo de auditoría exacto hacia la recepción, transferencia, ajuste o consumo de ticket.
- **`costo_unit`**: Obligatorio en entradas para valoración.
- **`lote_id`**: Control de la caducidad y costo FIFO/PEPS específico de la línea consumida.

---
**Conclusión de la Auditoría:**
El flujo está diseñado para una estricta protección de la integridad financiera. El mecanismo que delega la explosión de recetas a PostgreSQL (vía CTE) es un acierto de rendimiento tremendo para un ERP con un POS de alta concurrencia. No obstante, para mantener la precisión, es crucial asegurar que la vista `v_stock_actual` siempre devuelva información confiable en tiempo real.
