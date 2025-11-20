CRUD Readiness — Score por Entidad

Fecha: 2025-10-17 03:00

Escala de evaluación
- BD lista (tabla + PK/FK + índices + tipos correctos) [40]
- Rutas/Controller/Requests esqueleto [20]
- Vistas (index/create/edit/show) presentes [20]
- Validaciones + mensajes + policies [20]

Entidades evaluadas

1) Productos / Artículos (Inventory Items)
- BD lista: 35/40 — Tablas y modelos presentes; revisar tipos monetarios y FK/índices en detalle.
- Rutas/Controller/Requests: 20/20 — API CRUD en Api\Inventory\ItemController.
- Vistas: 15/20 — Livewire items-index; create/edit posiblemente en Livewire (parcialmente cubierto).
- Validaciones/Policies: 10/20 — Falta FormRequest dedicado y policies explícitas.
- Score total: 80/100

2) UoM (Unidades de Medida y Conversiones)
- BD lista: 35/40 — selemti.unidades_medida y conversiones, llaves esperadas.
- Rutas/Controller/Requests: 20/20 — Api\Unidades\UnidadController y ConversionController.
- Vistas: 18/20 — Livewire catálogos (unidades, conversiones) con forms.
- Validaciones/Policies: 10/20 — Falta endurecer reglas y policies.
- Score total: 83/100

3) Familias (categorías de producto)
- BD lista: 20/40 — Existe public.menu_category (POS); backoffice propio no evidente.
- Rutas/Controller/Requests: 0/20 — No se detectan endpoints propios.
- Vistas: 0/20 — Sin vistas dedicadas.
- Validaciones/Policies: 0/20 — N/A.
- Score total: 20/100

4) Proveedores
- BD lista: 35/40 — selemti.proveedor presente.
- Rutas/Controller/Requests: 10/20 — Livewire UI; falta API REST si se requiere.
- Vistas: 18/20 — Livewire Catalogs\ProveedoresIndex operativo.
- Validaciones/Policies: 8/20 — Falta formalizar FormRequests/policies.
- Score total: 71/100

5) Cajas (Sesiones/Precortes/Postcortes)
- BD lista: 32/40 — Tablas correctas; falta índice en precorte_efectivo(precorte_id) y duplicado en precorte(sesion_id).
- Rutas/Controller/Requests: 20/20 — API completa (precorte/postcorte/conciliación), faltan FormRequests.
- Vistas: 18/20 — cortes.blade + wizard JS operativos.
- Validaciones/Policies: 6/20 — Sin auth/roles; sin FormRequests; autorizar cierre.
- Score total: 76/100

6) Sucursales
- BD lista: 35/40 — selemti.sucursal presente.
- Rutas/Controller/Requests: 10/20 — Livewire UI; falta API REST si se requiere.
- Vistas: 18/20 — Livewire Catalogs\SucursalesIndex.
- Validaciones/Policies: 8/20 — Falta formalizar.
- Score total: 71/100

Ranking (mayor a menor)
- UoM: 83/100
- Artículos: 80/100
- Cajas: 76/100
- Proveedores: 71/100
- Sucursales: 71/100
- Familias: 20/100

Gaps por entidad y dónde tocar
- UoM: endurecer validaciones y policies (Api\Unidades\*, FormRequests); pruebas Feature.
- Artículos: añadir FormRequests/policies; vistas de create/edit si faltan (Livewire o Blade); mensajes de validación.
- Cajas: agregar índice FK, eliminar duplicado (DB con DBA); añadir auth/roles; FormRequests; corregir wizard (IDs/store/guardias).
- Proveedores/Sucursales: exponer API REST si se requiere (o formalizar Livewire), validaciones y policies.
- Familias: definir modelo/tablas (si no usar POS), endpoints y UI.
