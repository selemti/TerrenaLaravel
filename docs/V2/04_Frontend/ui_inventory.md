# UI · Inventario y Recepciones

Componentes Livewire bajo `app/Livewire/Inventory/` y vistas relacionadas.

## 1. Componentes

| Componente | Descripción | Dependencias | Estado |
|------------|-------------|--------------|--------|
| `ItemsIndex` | Tablero de inventario con filtros, KPIs, modales de kardex y movimientos rápidos. | Vistas SQL `v_stock_resumen`, `v_kardex_item`; tabla `mov_inv`. | ⚠ Interfaces listas, falta respaldo de datos reales. |
| `ReceptionsIndex` | Listado de recepciones (en construcción). | Tablas `recepcion_cab`, `recepcion_det`. | ⚠ Estructura mínima. |
| `ReceptionCreate` | Formulario para crear recepciones (adjunta evidencias). | `ReceptionService`, storage público, catálogos de proveedores/items. | ⚠ Usa datos mock; requiere catálogos reales y validaciones extra. |
| `LotsIndex` | Gestión de lotes/caducidades. | Vista/tablas de lotes (`inventory_batch`). | ⚠ Placeholder. |

## 2. Flujo de Recepciones

1. Usuario selecciona proveedor, sucursal, almacén.
2. Captura líneas (ítem, cantidades, lote, caducidad, evidencia).
3. `ReceptionService` inserta cabecera, detalle, lote y movimiento de inventario.
4. Mensaje flash `Recepción #ID guardada` → redirige a índice.

> Validar que las tablas `recepcion_*` y `inventory_batch` existan y tengan PK/FK correctas. Migraciones pendientes.

## 3. Requisitos de Base de Datos

- Postgres 9.5 (con `DB_SCHEMA = selemti,public`).
- Vistas para KPIs y kardex (ver `docs/V2/02_Database/schema_public.md`).
- Scripts de inventario en `D:\Tavo\2025\UX\Inventarios\selemti_deploy_inventarios*.sql`.

## 4. Pendientes UX

- Incorporar diseños más recientes (ver `D:\Tavo\2025\UX\Inventarios\v3/`).
- Definir mensajes de error amigables cuando faltan vistas/tablas (actualmente se atrapan excepciones silenciosas).
- Implementar buscador asistido de ítems (autocomplete).
- Agregar exportación/impresión de inventario.

## 5. Próximos Pasos Técnicos

- Crear migraciones para tablas `recepcion_cab`, `recepcion_det`, `inventory_batch`, `mov_inv`.
- Implementar autorización (roles) para movimientos rápidos.
- Escribir pruebas para `ReceptionService` y componentes (Livewire Testing).
- Integrar cálculos de costo y monitoreo de temperatura en `mov_inv.meta`.

Actualiza este documento cuando se completen migraciones o se añadan nuevas pantallas.
