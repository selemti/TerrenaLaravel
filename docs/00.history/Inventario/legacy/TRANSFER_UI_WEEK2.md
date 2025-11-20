# Transferencias - UI Semana 2 (Noviembre 2025)

## Objetivos
- Completar flujo visual: crear → aprobar/despachar → recibir → postear.
- Unificar experiencia responsive para backoffice y móviles.

## Componentes Livewire
| Componente | Ruta | Descripción |
|------------|------|-------------|
| `Transfers/Index` | `/transfers` | Tabla con filtros (estado, almacén, fechas) y acciones contextuales |
| `Transfers/Create` | `/transfers/create` | Wizard 3 pasos (general → ítems → resumen) |
| `Transfers/Dispatch` | `/transfers/{id}/dispatch` | Registro de guía y cantidades despachadas |
| `Transfers/Receive` | `/transfers/{id}/receive` | Captura de cantidades recibidas, diferencias y observaciones |

## Patrón UX
- Barra de progreso (Stepper) en creación y ejecución.
- Botones con `wire:loading` y skeleton loaders para tablas.
- Modales de confirmación antes de aprobar, despachar y recibir.
- Cards en móvil (`d-md-none`) con badges según estado (`bg-info`, `bg-warning`, `bg-success`, etc.).
- Toast notifications reutilizando `<x-toast-notification />`.

## Integraciones API
- `Transfers/Index`: consume `/api/inventory/transfers` (paginación 20).
- `Dispatch`: `POST /api/inventory/transfers/{id}/ship` con `guia` opcional.
- `Receive`: `POST /api/inventory/transfers/{id}/receive` (envía arreglo `lineas` con `line_id`, `cantidad_recibida`, `observaciones`).
- Botón “Postear” (pendiente UI) delega a `POST /api/inventory/transfers/{id}/post`.

## Validaciones
- Campos requeridos por paso en wizard (`validateOnly`).
- Cantidades > 0 y origen ≠ destino.
- Diferencias >5 % resaltadas en amarillo, >10 % en rojo.
- Confirmación para cancelar transferencias (futura iteración).

## Recursos Visuales
- Componentes Blade reutilizables (`search-input`, `status-badge`, `action-buttons`).
- CSS: modales full-screen en móvil, skeletons animados para listas.

## Pendientes UI
1. Integrar botones de aprobar/despachar directamente en tabla (cuando backend exponga permisos).
2. Diseñar vista de historial de actividades por transferencia.
3. Agregar exportación CSV desde index.
4. Validar multi-idioma (labels en inglés/español).

