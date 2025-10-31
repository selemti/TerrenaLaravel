# ✅ CHECKLIST SATURDAY MORNING (1 NOV 2025)

**Hora de Inicio**: 09:00 AM
**Duración**: 6 horas (09:00-15:00)
**Objetivo**: Backend + Frontend listo para deployment a staging

---

## ⏰ 08:30-09:00 - PRE-START (30 min)

### Tech Lead

- [ ] Verificar todos los agentes disponibles (Qwen, Codex)
- [ ] Verificar servidor staging up and running
- [ ] Crear Slack thread: `#terrena-weekend-deployment`
- [ ] Post mensaje inicio:
  ```
  🚀 WEEKEND DEPLOYMENT - DAY 1
  Hora: 09:00-15:00
  Agentes: Qwen (Frontend), Codex (Backend)
  Goal: Code ready for staging deployment
  Thread para updates cada hora ⬇️
  ```

### Qwen

- [ ] Abrir proyecto en IDE
- [ ] Checkout nueva branch: `git checkout -b feature/weekend-frontend`
- [ ] Leer **COMPLETO**: `docs/UI-UX/MASTER/PROMPTS_SABADO/PROMPT_QWEN_FRONTEND_SABADO.md`
- [ ] Tener abiertos:
  - `app/Livewire/Catalogs/SucursalesIndex.php`
  - `app/Livewire/Catalogs/ProveedoresIndex.php`
  - `app/Livewire/Recipes/RecipesIndex.php`
  - `resources/views/livewire/catalogs/`
- [ ] Verificar npm dependencies: `npm install`
- [ ] Iniciar Vite: `npm run dev`

### Codex

- [ ] Abrir proyecto en IDE
- [ ] Checkout nueva branch: `git checkout -b feature/weekend-backend`
- [ ] Leer **COMPLETO**: `docs/UI-UX/MASTER/PROMPTS_SABADO/PROMPT_CODEX_BACKEND_SABADO.md`
- [ ] Tener abiertos:
  - `app/Http/Controllers/Api/Inventory/RecipeCostController.php`
  - `app/Models/Rec/`
  - `database/migrations/`
  - `tests/Feature/`
- [ ] Verificar composer dependencies: `composer install`
- [ ] Verificar tests pasan: `php artisan test`

---

## 🔥 09:00-11:00 - BLOQUE 1 (2 horas)

### Qwen: Validaciones Inline

**Meta**: Agregar `wire:model.live` + `validateOnly()` a todos los forms de Catálogos

**Archivos a modificar** (4):
- `app/Livewire/Catalogs/SucursalesIndex.php`
- `app/Livewire/Catalogs/AlmacenesIndex.php`
- `app/Livewire/Catalogs/ProveedoresIndex.php`
- `app/Livewire/Catalogs/UnidadesIndex.php`

**Checklist Interno**:
- [ ] Agregar método `updated($propertyName)` a cada componente
- [ ] Agregar método `messages()` con mensajes custom
- [ ] Cambiar `wire:model` a `wire:model.live` en todas las vistas
- [ ] Agregar divs `@error` debajo de cada input
- [ ] Probar validación RFC inválido (debe mostrar error en tiempo real)
- [ ] Probar validación nombre duplicado (debe mostrar error)

**Commit al terminar**:
```bash
git add app/Livewire/Catalogs/*.php resources/views/livewire/catalogs/*.blade.php
git commit -m "feat(frontend): Add inline validations to Catalogs

- Add wire:model.live to all catalog forms
- Add validateOnly() for real-time validation
- Add custom error messages
- Show errors inline below inputs

Qwen - Weekend Deployment Day 1"
```

**Update Slack (10:00)**:
```
✅ Qwen - Bloque 1 - 50% completado
Validaciones inline agregadas a:
- ✅ Sucursales
- ✅ Almacenes
- ⏳ Proveedores (en progreso)
- ⏳ Unidades (pending)
```

### Codex: Recipe Cost Snapshots

**Meta**: Implementar modelo + migration + service para snapshots de costos

**Archivos a crear** (4):
- `database/migrations/2025_11_01_090000_create_recipe_cost_snapshots.sql`
- `app/Models/Rec/RecipeCostSnapshot.php`
- `app/Services/Recipes/RecipeCostSnapshotService.php`
- `tests/Feature/RecipeCostSnapshotTest.php`

**Checklist Interno**:
- [ ] Crear migration con JSONB para `cost_breakdown`
- [ ] Ejecutar migration: `php artisan migrate`
- [ ] Verificar tabla creada: `\d selemti.recipe_cost_snapshots`
- [ ] Crear modelo con casts y relaciones
- [ ] Crear service con métodos: `createSnapshot()`, `getCostAtDate()`, `checkAndCreateIfThresholdExceeded()`
- [ ] Crear 5 tests: manual snapshot, from snapshot, threshold exceeded, threshold not exceeded, mass snapshots
- [ ] Ejecutar tests: `php artisan test tests/Feature/RecipeCostSnapshotTest.php`
- [ ] Todos los tests pasan (5/5)

**Commit al terminar**:
```bash
git add database/migrations/*recipe_cost_snapshots* app/Models/Rec/RecipeCostSnapshot.php app/Services/Recipes/RecipeCostSnapshotService.php tests/Feature/RecipeCostSnapshotTest.php
git commit -m "feat(recipes): Add RecipeCostSnapshot model + service

- Add recipe_cost_snapshots table with JSONB
- Add RecipeCostSnapshot model with scopes
- Add RecipeCostSnapshotService with threshold detection (2%)
- Add feature tests (5/5 passing)

Codex - Weekend Deployment Day 1"
```

**Update Slack (10:00)**:
```
✅ Codex - Bloque 1 - 60% completado
RecipeCostSnapshot:
- ✅ Migration creada y ejecutada
- ✅ Model con relaciones
- ⏳ Service (en progreso)
- ⏳ Tests (pending)
```

---

## ⏰ 11:00 - CHECKPOINT 1 (15 min break)

### Tech Lead

- [ ] Revisar Slack updates de Qwen y Codex
- [ ] Verificar no hay blockers
- [ ] Si hay issues, decidir: continuar o pivotear

### Qwen + Codex

- [ ] Break 15 minutos ☕
- [ ] Pull cambios de `develop` (por si acaso): `git pull origin develop`
- [ ] Commit trabajo hasta ahora (work in progress OK)

**Update Slack (11:00)**:
```
📊 CHECKPOINT 1 (11:00)
Frontend: 50% Bloque 1 ✅
Backend: 60% Bloque 1 ✅
Status: ON TRACK 🟢
Bloqueadores: Ninguno
Next: Bloque 2 (11:15-13:00)
```

---

## 🔥 11:15-13:00 - BLOQUE 2 (1h 45min)

### Qwen: Loading States

**Meta**: Agregar spinners, skeleton loaders y toast notifications

**Archivos a modificar** (8):
- Todos los componentes de `app/Livewire/Catalogs/`
- Todos los componentes de `app/Livewire/Recipes/`
- Crear: `resources/views/components/loading-spinner.blade.php`
- Crear: `resources/views/components/toast-notification.blade.php`

**Checklist Interno**:
- [ ] Crear componente `<x-loading-spinner />`
- [ ] Agregar `wire:loading` targets a todos los botones
- [ ] Agregar skeleton loaders a tablas
- [ ] Crear componente `<x-toast-notification />`
- [ ] Disparar toast en save success: `$this->dispatch('notify', ...)`
- [ ] Disparar toast en delete success
- [ ] Probar: crear sucursal debe mostrar spinner + toast al terminar

**Commit al terminar**:
```bash
git add app/Livewire/ resources/views/
git commit -m "feat(frontend): Add loading states + toast notifications

- Add loading spinners to all action buttons
- Add skeleton loaders for tables
- Add toast notifications for success/error
- Create reusable components: loading-spinner, toast-notification

Qwen - Weekend Deployment Day 1"
```

**Update Slack (12:00)**:
```
✅ Qwen - Bloque 2 - 70% completado
Loading states:
- ✅ Spinners en botones
- ✅ Skeleton loaders
- ⏳ Toast notifications (en progreso)
```

### Codex: BOM Implosion

**Meta**: Implementar método recursivo para implodir BOM de recetas compuestas

**Archivos a modificar** (3):
- `app/Http/Controllers/Api/Inventory/RecipeCostController.php`
- `routes/api.php`
- `tests/Feature/RecipeBomImplosionTest.php`

**Archivos a actualizar** (1):
- `docs/UI-UX/MASTER/10_API_SPECS/API_RECETAS.md`

**Checklist Interno**:
- [ ] Agregar método público `implodeRecipeBom(string $id)`
- [ ] Agregar método privado recursivo `implodeRecipeBomRecursive(...)`
- [ ] Protección contra loops infinitos (max depth 10)
- [ ] Agrupar ingredientes duplicados sumando cantidades
- [ ] Agregar route: `Route::get('/recipes/{id}/bom/implode', ...)`
- [ ] Crear 3 tests: simple recipe, complex with subrecipes, duplicate aggregation
- [ ] Ejecutar tests: `php artisan test tests/Feature/RecipeBomImplosionTest.php`
- [ ] Actualizar docs API con nuevo endpoint

**Commit al terminar**:
```bash
git add app/Http/Controllers/Api/Inventory/RecipeCostController.php routes/api.php tests/Feature/RecipeBomImplosionTest.php docs/UI-UX/MASTER/10_API_SPECS/API_RECETAS.md
git commit -m "feat(recipes): Add BOM implosion endpoint

- Add GET /api/recipes/{id}/bom/implode endpoint
- Recursive implosion to get only base ingredients
- Aggregate duplicate ingredients
- Add feature tests (3/3 passing)
- Update API docs

Codex - Weekend Deployment Day 1"
```

**Update Slack (12:00)**:
```
✅ Codex - Bloque 2 - 75% completado
BOM Implosion:
- ✅ Método recursivo implementado
- ✅ Protección loops infinitos
- ⏳ Tests (2/3 passing)
- ⏳ Docs update (pending)
```

---

## ⏰ 13:00 - CHECKPOINT 2 (30 min lunch break)

### Todos

- [ ] Lunch break 30 min 🍔
- [ ] Push trabajo hasta ahora:
  ```bash
  git push origin feature/weekend-frontend  # Qwen
  git push origin feature/weekend-backend   # Codex
  ```

**Update Slack (13:00)**:
```
🍔 LUNCH BREAK (13:00-13:30)
Frontend: 75% completo ✅
Backend: 80% completo ✅
Status: AHEAD OF SCHEDULE 🟢
Retomamos 13:30
```

---

## 🔥 13:30-15:00 - BLOQUE 3 (1h 30min)

### Qwen: Responsive Design

**Meta**: Optimizar para mobile (tablets y phones)

**Archivos a modificar**:
- Todas las vistas `resources/views/livewire/catalogs/*.blade.php`
- Todas las vistas `resources/views/livewire/recipes/*.blade.php`
- `resources/css/app.css` (si necesario)

**Checklist Interno**:
- [ ] Reemplazar tablas con cards en mobile (`d-none d-md-table` + cards)
- [ ] Hacer modales full-screen en mobile
- [ ] Agregar `viewport` meta tag si falta
- [ ] Probar en Chrome DevTools (iPhone 12, iPad)
- [ ] Verificar botones tienen buen tamaño (min 44x44px)
- [ ] Verificar formularios son usables en touch

**Commit al terminar**:
```bash
git add resources/views/ resources/css/
git commit -m "feat(frontend): Optimize for mobile (responsive design)

- Replace tables with cards on mobile
- Make modals full-screen on small screens
- Improve touch targets (min 44x44px)
- Test on iPhone 12 and iPad viewports

Qwen - Weekend Deployment Day 1"
```

**Update Slack (14:00)**:
```
✅ Qwen - Bloque 3 - 90% completado
Responsive design:
- ✅ Cards para mobile
- ✅ Modales full-screen
- ✅ Touch targets
- ⏳ Final testing
```

### Codex: Seeders + Final Tests

**Meta**: Crear seeders production-ready y ejecutar test suite completo

**Archivos a crear** (3):
- `database/seeders/CatalogosProductionSeeder.php`
- `database/seeders/RecipesProductionSeeder.php`
- `tests/Feature/WeekendDeploymentIntegrationTest.php`

**Archivos a modificar** (1):
- `database/seeders/DatabaseSeeder.php`

**Checklist Interno**:
- [ ] Crear `CatalogosProductionSeeder` (unidades, sucursales, almacenes, categorías, proveedores)
- [ ] Crear `RecipesProductionSeeder` (1 receta demo)
- [ ] Agregar llamadas a `DatabaseSeeder`
- [ ] Ejecutar seeders localmente: `php artisan db:seed --class=CatalogosProductionSeeder`
- [ ] Verificar no duplica registros (updateOrInsert)
- [ ] Crear integration test (3 test cases: catalogs API, recipe cost + snapshot, BOM implosion)
- [ ] Ejecutar **TODOS** los tests: `php artisan test`
- [ ] Verificar **100% passing**

**Commit al terminar**:
```bash
git add database/seeders/ tests/Feature/
git commit -m "feat(seeders): Add production-ready seeders

- Add CatalogosProductionSeeder (7 UOMs, 1 branch, 2 warehouses, etc)
- Add RecipesProductionSeeder (1 demo recipe)
- Add WeekendDeploymentIntegrationTest (3 tests)
- All tests passing (14/14) ✅

Codex - Weekend Deployment Day 1"
```

**Update Slack (14:00)**:
```
✅ Codex - Bloque 3 - 95% completado
Seeders + Tests:
- ✅ CatalogosProductionSeeder
- ✅ RecipesProductionSeeder
- ✅ Integration tests
- ⏳ Full test suite running...
```

---

## 🎯 15:00 - FINAL CHECKPOINT (Deliverables)

### Tech Lead - Code Review

**Checklist Rápido**:
- [ ] Qwen: Pull request de `feature/weekend-frontend` a `develop`
- [ ] Codex: Pull request de `feature/weekend-backend` a `develop`
- [ ] Revisar commits (mensajes claros, código limpio)
- [ ] Revisar tests (todos pasan)
- [ ] Verificar no hay console.log() olvidados
- [ ] Verificar no hay dd() olvidados

### Qwen - Final Deliverable

**Checklist Final**:
- [ ] Commit final y push:
  ```bash
  git add .
  git commit -m "feat(frontend): Weekend deployment frontend complete

  BLOQUE 1: Validaciones Inline ✅
  - wire:model.live en todos los forms
  - validateOnly() real-time
  - Custom error messages

  BLOQUE 2: Loading States ✅
  - Spinners en botones
  - Skeleton loaders
  - Toast notifications

  BLOQUE 3: Responsive Design ✅
  - Mobile-optimized (cards)
  - Full-screen modals
  - Touch-friendly

  Qwen - Weekend Deployment Day 1 COMPLETE"

  git push origin feature/weekend-frontend
  ```

- [ ] Crear Pull Request en GitHub:
  ```
  Title: [Weekend Deployment] Frontend Improvements - Qwen

  Description:
  Frontend improvements for weekend deployment (Catalogs + Recipes).

  Changes:
  - ✅ Inline validations (wire:model.live)
  - ✅ Loading states (spinners, skeletons, toasts)
  - ✅ Responsive design (mobile-optimized)
  - ✅ 5 reusable components created

  Testing:
  - Manual testing on Chrome (desktop + mobile)
  - All forms validate correctly
  - All loading states work
  - Mobile UI looks good

  Ready for: Code Review → Merge to develop → Deploy to staging
  ```

- [ ] Post en Slack:
  ```
  ✅ QWEN - FRONTEND COMPLETE (15:00)

  Deliverables:
  - ✅ Validaciones inline (4 componentes)
  - ✅ Loading states (spinners + toasts)
  - ✅ Responsive design (mobile-optimized)
  - ✅ 5 componentes reutilizables

  PR: https://github.com/org/TerrenaLaravel/pull/XXX
  Status: READY FOR REVIEW 🟢
  ```

### Codex - Final Deliverable

**Checklist Final**:
- [ ] Ejecutar Laravel Pint (code formatting):
  ```bash
  ./vendor/bin/pint
  ```

- [ ] Ejecutar test suite completo:
  ```bash
  php artisan test
  # Expected: XX/XX passing ✅
  ```

- [ ] Commit final y push:
  ```bash
  git add .
  git commit -m "feat(backend): Weekend deployment backend complete

  BLOQUE 1: Recipe Cost Snapshots ✅
  - RecipeCostSnapshot model + migration
  - RecipeCostSnapshotService with threshold (2%)
  - Feature tests (5/5 passing)

  BLOQUE 2: BOM Implosion ✅
  - Recursive BOM implosion method
  - Duplicate aggregation
  - Feature tests (3/3 passing)

  BLOQUE 3: Seeders + Tests ✅
  - CatalogosProductionSeeder
  - RecipesProductionSeeder
  - Integration tests (3/3 passing)

  Total tests: 11/11 passing ✅
  Code coverage: >80%

  Codex - Weekend Deployment Day 1 COMPLETE"

  git push origin feature/weekend-backend
  ```

- [ ] Crear Pull Request en GitHub:
  ```
  Title: [Weekend Deployment] Backend Services - Codex

  Description:
  Backend services for weekend deployment (Catalogs + Recipes).

  Changes:
  - ✅ Recipe Cost Snapshots (model + service + tests)
  - ✅ BOM Implosion (recursive explosion to base ingredients)
  - ✅ Production Seeders (Catalogs + Recipes)
  - ✅ Integration tests (end-to-end flows)

  Testing:
  - ✅ Feature tests: 11/11 passing
  - ✅ Code coverage: >80%
  - ✅ Manual testing: snapshots work, BOM implosion works
  - ✅ Seeders tested locally (no duplicates)

  Migrations:
  - recipe_cost_snapshots table (new)

  Ready for: Code Review → Merge to develop → Deploy to staging
  ```

- [ ] Post en Slack:
  ```
  ✅ CODEX - BACKEND COMPLETE (15:00)

  Deliverables:
  - ✅ RecipeCostSnapshot (model + service)
  - ✅ BOM Implosion (recursive)
  - ✅ Production Seeders (2 seeders)
  - ✅ Tests: 11/11 passing ✅

  PR: https://github.com/org/TerrenaLaravel/pull/XXX
  Status: READY FOR REVIEW 🟢
  ```

### Tech Lead - Merge & Deploy Prep

**Checklist Final**:
- [ ] Review Qwen PR (approve/request changes)
- [ ] Review Codex PR (approve/request changes)
- [ ] Si ambos OK: Merge to `develop`
  ```bash
  git checkout develop
  git pull origin develop
  git merge feature/weekend-frontend --no-ff
  git merge feature/weekend-backend --no-ff
  git push origin develop
  ```

- [ ] Tag version:
  ```bash
  git tag -a v1.0-weekend -m "Weekend deployment - Catalogs + Recipes ready"
  git push origin v1.0-weekend
  ```

- [ ] Post en Slack:
  ```
  🎉 DAY 1 COMPLETE - CODE MERGED TO DEVELOP

  Summary:
  - ✅ Frontend: Validations + Loading + Responsive
  - ✅ Backend: Snapshots + BOM + Seeders
  - ✅ Tests: 11/11 passing
  - ✅ Code Review: Approved
  - ✅ Merged to develop

  Next Steps:
  - 17:00: Deploy to Staging
  - 19:00: Smoke tests
  - Tomorrow: QA + Production deployment

  Team: AMAZING WORK! 🚀
  ```

---

## 📊 SUCCESS CRITERIA (End of Day)

### Must Have (Critical)
- ✅ Qwen PR merged to develop
- ✅ Codex PR merged to develop
- ✅ All tests passing (100%)
- ✅ Code formatted (Pint)
- ✅ No console.log() or dd() in code
- ✅ Migrations executed successfully (local)

### Should Have (Important)
- ✅ Seeders tested locally
- ✅ API docs updated
- ✅ Integration tests passing
- ✅ Code coverage >80%

### Nice to Have (Optional)
- ⚪ Performance benchmarks
- ⚪ Postman collection updated
- ⚪ Screenshots of new UI

---

## 🚨 TROUBLESHOOTING

### "Tests failing"
1. Check error message
2. Fix locally
3. Re-run: `php artisan test`
4. Commit fix
5. Push

### "Merge conflicts"
1. `git pull origin develop`
2. Resolve conflicts manually
3. `git add .`
4. `git commit -m "fix: Resolve merge conflicts"`
5. `git push`

### "Can't push to branch"
1. Verify branch name: `git branch`
2. Verify remote: `git remote -v`
3. Force push if needed: `git push -f origin feature/weekend-xxx` (⚠️ only if solo branch)

### "Seeder duplicating records"
1. Use `updateOrInsert()` instead of `insert()`
2. Truncate table: `DB::table('xxx')->truncate();` (⚠️ only local)
3. Re-run seeder

---

## ✅ FINAL DELIVERABLE SUMMARY

**By 15:00, we should have**:

| Deliverable | Owner | Status |
|-------------|-------|--------|
| Inline Validations | Qwen | ✅ |
| Loading States | Qwen | ✅ |
| Responsive Design | Qwen | ✅ |
| RecipeCostSnapshot | Codex | ✅ |
| BOM Implosion | Codex | ✅ |
| Production Seeders | Codex | ✅ |
| Feature Tests (11) | Codex | ✅ |
| Integration Tests (3) | Codex | ✅ |
| API Docs Updated | Codex | ✅ |
| Code Review | Tech Lead | ✅ |
| Merge to develop | Tech Lead | ✅ |

**Next**: Staging Deployment (17:00-19:00)

---

🚀 **¡VAMOS CON TODO!** 🚀

---

**Creado**: 31 de Octubre 2025, 23:50
**Para**: Qwen, Codex, Tech Lead
**Ejecución**: Sábado 1 de Noviembre 2025, 09:00-15:00
