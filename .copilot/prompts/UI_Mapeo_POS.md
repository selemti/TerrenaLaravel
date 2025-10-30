Rol: Dev Laravel (Livewire 3 + Tailwind). No cambies el esquema.

Objetivo: Vista “Mapeos POS” con:
- Tabla filtrable por `tipo` (MENU/MODIFIER), `plu`, vigencia (valid_from/valid_to, vigente_desde).
- CRUD básico (create/update/soft disable vía `valid_to` o bandera `meta.activo` si aplica).
- Validación: que los **bloques 1 y 1.b** de `docs/Orquestador/sql/verification_queries_psql_v5.sql` queden en cero tras mapear.

Contexto:
- Usar `selemti.pos_map` (campos reales).
- Relación POS: `public.menu_item` y `public.ticket_item(_modifier)` solo lectura.
- **Sucursal** se infiere por `public.terminal.location` en auditorías SQL; UI no debe acoplarse a eso.

Entrega:
- Ramas: `feat/ui-pos-map-<fecha>`.
- Archivos: Livewire Component (app/Livewire/Orquestador/PosMap.php), Blade (resources/views/orquestador/pos-map.blade.php), Route (routes/web.php).
- README corto: `docs/Orquestador/UI_Mapping_README.md` con pasos de prueba + query v5.
