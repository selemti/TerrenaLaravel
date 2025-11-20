# Servicios y Componentes Backend

## 1. Servicios registrados

| Clase | Ubicación | Responsabilidad | Notas |
|-------|-----------|-----------------|-------|
| `App\Services\Inventory\ReceptionService` | `app/Services/Inventory/ReceptionService.php` | Orquesta la creación de recepciones: inserta cabecera (`recepcion_cab`), detalle (`recepcion_det`), lotes (`inventory_batch`) y movimientos (`mov_inv`) dentro de una transacción. | Depende de tablas existentes en BD; actualmente se invoca desde Livewire `Inventory\ReceptionCreate`. |

## 2. Jobs / Queue

- No hay jobs personalizados aún. Las tablas `jobs`, `failed_jobs`, `job_batches` están preparadas.
- Revisión pendiente: procesar reconciliaciones o reportes con colas cuando se habilite.

## 3. Helpers y Facades

- `app/Helpers/CajaHelper.php` está autoloaded vía `composer.json`. Documentar sus funciones cuando se estabilice.

## 4. Pendientes

- [ ] Definir servicios para módulos de caja (precorte/postcorte) en lugar de lógica directa en controladores.
- [ ] Evaluar patrón Repository si se amplían las integraciones con POS.
- [ ] Agregar pruebas unitarias a `ReceptionService`.
- [ ] Centralizar validaciones y manejo de excepciones en capa de servicios.

Actualiza este archivo cuando se agreguen nuevos servicios o jobs.
