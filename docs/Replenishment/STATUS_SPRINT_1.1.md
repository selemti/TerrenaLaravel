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

**Siguiente paso inmediato (Etapa 6):**
- Crear modelos Eloquent (`PurchaseSuggestion`, `PurchaseSuggestionLine`, actualizar `PurchaseRequest`)
- Definir relaciones, scopes y atributos `fillable`
- Luego: servicios de negocio y endpoints API

**Responsable siguiente:** Claude / ChatGPT – Sprint 1.1 continuidad  

---

**Última actualización:** 2025-10-24  
**Responsable:** Gustavo Selem
