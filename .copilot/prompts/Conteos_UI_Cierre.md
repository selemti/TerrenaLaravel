<!-- ⚠️ INVARIANTE CRÍTICO: DB_SCHEMA en phpunit.xml debe ser SOLO `selemti`. Nunca incluir `public`. Si se agrega `public`, RefreshDatabase borra las 108 tablas FloreantPOS. Ocurrió 2026-05-13. public es READ ONLY. Test guardián: tests/Unit/GuardRailsTest -->

Rol: Dev Laravel Livewire. No tocar esquema.

Objetivo: Pantalla de “Conteos físicos”:
- Listado `selemti.inventory_counts` por `sucursal_id`, con chips de estado.
- Vista detalle: `inventory_count_lines` + totales de variación.
- Acción “Cerrar conteo” (cambia `estado` a CERRADO/CLOSED sin nuevas columnas).

Validación: tras cerrar, ejecutar bloque **8** de `verification_queries_psql_v5.sql` ⇒ **0 abiertos**.

Entrega:
- Ramas: `feat/ui-conteos-<fecha>`.
- Archivos: Livewire (app/Livewire/Orquestador/ConteosIndex.php, ConteoShow.php), blades y rutas.
- Evidencias: `docs/Orquestador/Conteos_Evidencia_<fecha>.md` (capturas + salida de SQL).
