# 🧭 STATUS SPRINT 1.1 – Módulo de Compras

**Objetivo:** Implementar flujo de Sugerencias de Compra → Solicitud.  
**Esquema:** `selemti`  
**Estado general:** 🟨 En progreso  
**Fecha:** 2025-10-24  

---

## ✅ Progreso

| Etapa | Descripción | Estado |
|-------|--------------|:------:|
| 1 | Rediseño v2.1 aprobado (`REDISENO_TRES_FLUJOS.md`) | ✅ |
| 2 | Sistema de permisos dinámicos | ✅ |
| 3 | Validación de FKs y tipos | ✅ |
| 4 | Borradores de migrations validados | ✅ |
| 5 | Ejecución de migrations reales | ✅ |
| 6 | Creación de modelos Eloquent | ⏳ |
| 7 | Servicios de negocio | 🔲 |
| 8 | Endpoints API | 🔲 |
| 9 | Pruebas funcionales | 🔲 |

---

## 🔧 Reglas del proyecto
1. `public.*` es POS de solo lectura.  
2. Usuarios internos → `selemti.users`.  
3. Seguridad = permisos `{modulo}.{entidad}.{accion}`.  
4. Kardex (`mov_inv`) es inmutable.  
5. Diferencias de recepción controladas por `config('inventory.reception_tolerance_pct')`.  
6. No mezclar flujos: compras / producción / transferencias.

---

## 🚀 Próxima tarea
**Crear modelos Eloquent:**
- `PurchaseSuggestion`
- `PurchaseSuggestionLine`
- Actualizar `PurchaseRequest`  
Usar `namespace App\Models\Purchasing;`  
Schema `selemti`, definir relaciones y atributos `fillable`.

---

## 🧭 Handoff de Sesión

**Fecha de cierre:** 2025-10-24  
**Estado al cierre:** 🟨 En progreso – Migrations ejecutadas exitosamente  
**Completado:**
- Diseño v2.1 aprobado (COMPRAS → PRODUCCIÓN → TRANSFERENCIAS)
- Sistema de permisos dinámicos implementado (purchasing.*, inventory.*)
- Migrations creadas y ejecutadas: `purchase_suggestions`, `purchase_suggestion_lines`, `purchase_requests` alterada
- FKs formales a `selemti.users` (no `public.users`)
- Constraint UNIQUE en líneas para evitar duplicados por item
- Tablas selemti.purchase_suggestions y selemti.purchase_suggestion_lines ya existen.


**Siguiente paso inmediato (Etapa 6):**
- Crear modelos Eloquent (`PurchaseSuggestion`, `PurchaseSuggestionLine`, actualizar `PurchaseRequest`)
- Definir relaciones, scopes y atributos `fillable`
- Luego: servicios de negocio y endpoints API

**Responsable siguiente:** Claude / ChatGPT – Sprint 1.1 continuidad  

---

**Última actualización:** 2025-10-24  
**Responsable:** Gustavo Selem

Estado de validación (Sprint 1.1 - Compras)



Implementación:

API /api/purchasing/suggestions creada e integrada a Laravel.
Controlador PurchaseSuggestionController y PurchasingService actualizados.
Rutas index / approve / convert registradas y visibles en php artisan route:list.
Inserción exitosa en selemti.purchase_suggestions (registro ID=3) usando FKs reales (sucursal_id=22, almacen_id=58, sugerido_por_user_id=2).
Respuesta del endpoint GET /api/purchasing/suggestions válida (ok: true, sin error 500).



Pendiente para completar prueba funcional end-to-end:

Poblar catálogos operativos mínimos:
selemti.items (al menos 1 insumo comprable con UOM válida).
selemti.cat_proveedores (al menos 1 proveedor activo).
Crear línea en selemti.purchase_suggestion_lines ligada a la sugerencia ID=3.
Re-ejecutar:
POST /api/purchasing/suggestions/{id}/approve
POST /api/purchasing/suggestions/{id}/convert
Validar que se cree selemti.purchase_requests y selemti.purchase_request_lines.
Validar cambio de estado de la sugerencia a CONVERTIDA.



Decisión de operación:

No se ejecuta la prueba completa todavía porque aún se está alimentando inventario base (recetas, insumos, proveedores). No queremos probar con datos falsos en este momento.
Cuando existan insumos/proveedores reales cargados, se repite la prueba y se marca Sprint 1.1 como "VALIDADO EN OPERACIÓN".



Conclusión Sprint 1.1:

Código del flujo CORE de Compras está implementado y conectado a BD real.
Falta solo la carga de datos maestros para cerrar la prueba operativa.



### Control de versión / Handoff técnico

- Rama activa: integrate/web-prs-20251023-1922
- Último commit de control Sprint 1.1: 844c9ce
  Mensaje: "Sprint 1.1 (Compras): API /purchasing/suggestions + servicio PurchasingService actualizado, controlador PurchaseSuggestionController, modelos Purchasing*, migrations selemti.*, rutas API y documentación de flujo y permisos."

- Este commit marca:
  1. Que el flujo CORE de Compras (sugerencias → aprobación → conversión a solicitud) ya está implementado en código Laravel y expuesto vía API (`/api/purchasing/suggestions` + `/approve` + `/convert`).
  2. Que el servicio PurchasingService ya incorpora lógica para:
     - listar sugerencias con líneas
     - aprobar sugerencias
     - convertir sugerencia → purchase_request (+ líneas)
  3. Que quedó documentado el modelo de permisos dinámicos en lugar de roles fijos.
  4. Que la BD ya tiene al menos una sugerencia insertada manualmente (ID=3) dentro de `selemti.purchase_suggestions`, validando integridad de FKs reales (`sucursal_id`, `almacen_id`, `sugerido_por_user_id`).

- Pendiente post-commit:
  - Cargar datos maestros (items, proveedores, etc.) y `purchase_suggestion_lines` para poder probar `approve` y `convert`.
  - Confirmar en código local que existen físicamente:
    - database/migrations/2025_10_24_120000_create_purchase_suggestions_table.php
    - database/migrations/2025_10_24_120001_create_purchase_suggestion_lines_table.php
    - database/migrations/2025_10_24_120002_alter_purchase_requests_add_fields.php
    - app/Http/Controllers/Purchasing/PurchaseSuggestionController.php
    - app/Services/Purchasing/PurchasingService.php con los métodos list/approve/convert
    - app/Models/Purchasing/PurchaseRequestLine.php
    - docs/Replenishment/PERMISOS_RESPONSABILIDADES_FASE1.md

Este archivo (STATUS_SPRINT_1.1.md) es ahora la fuente oficial de en qué se quedó Compras y desde dónde arranca el siguiente sprint.
