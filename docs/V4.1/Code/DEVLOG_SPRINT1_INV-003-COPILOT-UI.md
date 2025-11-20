# DEVLOG Sprint 1 · INV-003 (UI Transferencias)

## Cambios realizados
- Nuevos componentes Livewire `TransferDispatch` y `TransferReceive` para despachar (EN_TRANSITO) y recibir transferencias, apoyados en `TransferService::markInTransit` y `receiveTransfer`.
- Vistas dedicadas con captura de guía, cantidades recibidas, observaciones y despliegue de varianzas devueltas por el servicio.
- Rutas web `/transfers/{id}/dispatch` y `/transfers/{id}/receive`; el listado de transferencias expone accesos rápidos y badges alineados a estados del servicio.
- Prueba `tests/Feature/TransferFlowTest.php` asegura que ambos componentes envían payloads correctos y actualizan estado/varianzas al usar servicios mockeados.

## Notas
- Los componentes cargan datos desde `transfer_cab/det` si existen; si no, operan con líneas vacías sin romper el flujo de pruebas.
