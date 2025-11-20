# DEVLOG Sprint 1 · INV-002 (UI Recepciones)

## Cambios realizados
- `ReceptionCreate` ahora genera recepciones en BORRADOR vía `ReceptionService::createDraftReception`, normaliza `costo_unit` y soporta evidencias en `public/evidencias`; reglas dinámicas toleran ausencia de catálogos en ambientes de prueba.
- `ReceptionDetail` deja de depender de endpoints mock: consulta BD cuando está disponible y se apoya en `ReceivingService` como fallback. Acciones de validar/postear invocan `ReceptionService`; aprobación de tolerancia usa `ReceivingService::approveReception`.
- Índice de recepciones muestra badges por estado y enlaces al detalle.
- Prueba `tests/Feature/ReceptionStateTest.php` valida payload hacia `createDraftReception` (incluye doc_url) y flujos de validación/posteo con servicios mockeados.

## Notas
- Las vistas muestran mensajes de éxito/error y evidencias por línea cuando existe `doc_url`.
- Las consultas a catálogos están envueltas en `try/catch` para no bloquear UI en entornos sin tablas.
