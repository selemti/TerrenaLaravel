# Producción - UI Semana 5 (Noviembre 2025)

## Componentes Implementados
| Componente | Ruta | Funcionalidad |
|------------|------|---------------|
| `Production/Index` | `/production` | Listado con filtros (estado, sucursal, rango de fechas) y acciones contextuales |
| `Production/Create` | `/production/create` | Formulario con selección de receta, versión, cantidades y destino |
| `Production/Execute` | `/production/{id}/execute` | Wizard 3 pasos: consumo de ingredientes → producción → cierre |
| `Production/Detail` | `/production/{id}/detail` | Vista de solo lectura con inputs, outputs y bitácora |

## Integraciones Backend
- API `GET /api/production/orders` para el listado.
- API `POST /api/production/orders` al crear órdenes.
- API `POST /api/production/orders/{id}/consume` para registrar consumos.
- API `POST /api/production/orders/{id}/complete` para marcar como completada.
- API `POST /api/production/orders/{id}/post` para postear al inventario.

## UX Destacada
- Stepper visual con estados completados/presentes.
- Validaciones `validateOnly` y mensajes en español.
- Loading states (spinners en botones, skeletons en tarjetas).
- Toast notifications centralizadas.
- Diseño responsive: tablas → cards en mobile, modales full-height.

## Datos Precargados
- Catálogo de recetas (`Receta::where('activo', true)`), versiones (`RecetaVersion`), almacenes y sucursales.
- Prefill de `programado_para` con `now()`.

## Pendientes / Backlog
1. Soporte para adjuntar fotos de producción.
2. Reporte de eficiencia en tiempo real (ligado a dashboard semana 6).
3. Validaciones de disponibilidad de ingredientes en almacén origen.
4. Historial de eventos (timeline) por orden.

