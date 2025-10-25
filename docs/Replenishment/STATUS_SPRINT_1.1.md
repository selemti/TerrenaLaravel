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

**Última actualización:** 2025-10-24  
**Responsable:** Gustavo Selem
