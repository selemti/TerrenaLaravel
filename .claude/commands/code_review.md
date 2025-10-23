# Checklist · Code Review TerrenaLaravel

1. **Seguridad y autenticación**
   - Verificar que endpoints nuevos tengan middleware (`auth:sanctum` o JWT) y rate limiting (`throttle`).
   - Revisar validaciones (`$request->validate` o Form Requests) para todo POST/PUT/DELETE; evita parámetros sin sanear.
   - Confirmar que tokens/credenciales no se expongan en logs (`\Log::debug`) ni en respuestas.

2. **Acceso a datos (dual DB)**
   - Asegura que modelos apunten al esquema correcto (`selemti.*` vs `public.*`) y que `DB_SCHEMA` se respete.
   - En SQL crudo (`DB::connection('pgsql')->select*`) usa parámetros enlazados; prohibido concatenar valores.
   - Cuando se agreguen tablas o vistas, valida contra `BD/DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148-safe.sql` y actualiza `docs/V2/02_Database/*.md`.

3. **Transacciones y consistencia**
   - Operaciones multi tabla (precortes, recepciones, movimientos) deben envolver cambios en `DB::transaction()`.
   - Revisar cálculos monetarios: usar tipos DECIMAL y helpers (`number_format`) para evitar errores de redondeo.
   - Confirmar idempotencia en endpoints reintentables (`createLegacy`, recepciones, movimientos) y manejar concurrencia (`SELECT ... FOR UPDATE` si aplica).

4. **Convenciones Laravel**
   - Cumplir PSR-12, nombres PascalCase/camelCase, sin lógica pesada en vistas.
   - Configurar `fillable/guarded` y `casts` para nuevos modelos; evita `->get()` sin paginación en listados grandes.
   - Para Livewire/Blade, sincronizar IDs y eventos con scripts `public/assets/js`.

5. **Respuesta y contratos**
   - Mantener formato `{ ok, data?, error?, message?, timestamp? }` y códigos HTTP correctos.
   - Documentar cambios de payload en `docs/V2/03_Backend/routes_api.md` y `.claude/context/04_api_workflow.md`.
   - Considerar pruebas automáticas (PHPUnit, Pest) u OpenAPI (`l5-swagger`) cuando se alteren contratos.

6. **Base de datos y despliegue**
   - Antes de aprobar, comprobar que objetos dependientes de v3 (funciones `fn_precorte_*`, vistas `vw_stock_*`) existan en la migración o script asociado.
   - Si se añaden scripts SQL, definir orden de ejecución y reflejarlo en `docs/V2/02_Database/schema_selemti.md`.
   - Ejecutar `composer test` y `php artisan catalogs:verify-tables --details` cuando cambie lógica de datos.
