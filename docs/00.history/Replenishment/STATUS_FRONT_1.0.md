# STATUS_FRONT_1.0 – Operación de Piso (Recepción, Transferencias, Dashboard)

## Objetivo
Exponer en UI (Livewire + Blade) los flujos operativos críticos ya cubiertos por el backend:
- Recepción de insumos vs Orden de Compra.
- Transferencias entre almacenes/sucursales.
- Panel operativo (urgencias, tolerancias, KPIs rápidos).

Los permisos son **delegables por usuario** (no por puesto fijo).  
Ejemplo: si el gerente está ausente, otro usuario con permiso temporal puede validar o postear.

---

## 1. Recepción de Compra (`ReceptionDetail`)
**Ruta web:** `/inventory/receptions/{id}`  
**Componente:** `App\Livewire\Inventory\ReceptionDetail`

### Métodos esperados
- `mount($id)` → carga estado actual y permisos del usuario.
- `validarRecepcion()` → `POST /api/purchasing/receptions/{id}/validate`
- `aprobarFueraTolerancia()` → `POST /api/purchasing/receptions/{id}/approve`
- `postearInventario()` → `POST /api/purchasing/receptions/{id}/post`

### Propiedades del componente
| Propiedad | Tipo | Descripción |
|------------|------|--------------|
| `estado` | string | EN_PROCESO / VALIDADA / CERRADA |
| `requiere_aprobacion` | bool | Indica si hay líneas fuera de tolerancia |
| `lineas` | array | Datos de los items recibidos |
| `permisos` | array | Lista de permisos activos del usuario |

### UI Blade
- Mostrar encabezado con folio, estado y aviso si `requiere_aprobacion === true`.
- Tabla de líneas (item, qty ordenada, qty recibida, diferencia%).
- Colorear líneas fuera de tolerancia.

### Botones y permisos
| Acción | Visible si | Endpoint | Permiso requerido |
|--------|-------------|-----------|-------------------|
| **Validar recepción** | estado = EN_PROCESO | `/validate` | `inventory.receptions.validate` |
| **Autorizar fuera de tolerancia** | estado = VALIDADA y requiere_aprobacion = true | `/approve` | `inventory.receptions.override_tolerance` |
| **Postear a inventario** | estado = VALIDADA y (no requiere_aprobación o ya autorizada) | `/post` | `inventory.receptions.post` |

Aunque el botón esté oculto, el backend **siempre valida el permiso** y puede devolver 403.

---

## 2. Transferencias Internas (`TransferDetail`)
**Ruta web:** `/transfers/{id}`  
**Componente:** `App\Livewire\Transfers\TransferDetail`

Métodos:
- `aprobar()`
- `ship()`
- `receive()`
- `post()`

Cada método llama a los endpoints `/api/inventory/transfers/...` según corresponda.  
Los botones se muestran sólo si el usuario tiene permisos como `inventory.transfers.ship`, etc.

---

## 3. Dashboard Operativo (`OpsDashboard`)
**Ruta web sugerida:** `/dashboard/inventario`  
**Componente:** `App\Livewire\Inventory\OpsDashboard`

Tarjetas principales:
- Recepciones pendientes de validación.
- Recepciones pendientes de autorización por tolerancia.
- Transferencias pendientes de recepción.
- Alertas críticas de stock.

Endpoints usados:
- `/api/reports/inventory/over-tolerance`
- `/api/inventory/stock/list`
- `/api/purchasing/receptions/.../status`

---

## 4. Permisos (Delegables)
El backend debe proveer permisos efectivos por usuario (no por rol fijo) vía:
```json
{
  "user_id": 12,
  "permisos": [
    "inventory.receptions.validate",
    "inventory.receptions.override_tolerance",
    "inventory.receptions.post"
  ]
}
El componente Livewire determina:

php
Copiar código
$this->canValidate = in_array('inventory.receptions.validate', $this->permisos);
$this->canOverride = in_array('inventory.receptions.override_tolerance', $this->permisos);
$this->canPost     = in_array('inventory.receptions.post', $this->permisos);
5. Estado actual
Backend completo salvo endpoint /approve (se define en Sprint 1.9).

Faltan componentes Livewire vacíos (scaffold).

Falta endpoint /api/me/permissions para exponer permisos (planeado siguiente sprint).

Con esto el front queda alineado con permisos delegables y flujo completo de recepción.

yaml
Copiar código

---
