# ✅ CHECKLIST DE VALIDACIÓN - Trabajo de IA

**Propósito**: Validar sistemáticamente el trabajo generado por IAs antes de integrarlo  
**Versión**: 1.0  
**Fecha**: 31 de octubre de 2025

---

## 🎯 PRINCIPIOS DE VALIDACIÓN

### ⚡ Validación Rápida vs Profunda

**Validación Rápida** (5-10 minutos):
- Usarla para: Tareas pequeñas (XS, S)
- Verificar: Funciona, no rompe nada, código limpio básico

**Validación Profunda** (20-30 minutos):
- Usarla para: Tareas medianas/grandes (M, L, XL)
- Verificar: Todo lo de rápida + tests, performance, edge cases

---

## ⚡ VALIDACIÓN RÁPIDA (Para Tareas XS/S)

### 1️⃣ Verificación Básica (2 min)

```bash
# ¿Los archivos existen?
ls -la {archivos_esperados}

# ¿El código compila?
php artisan optimize && php artisan cache:clear
```

**Checklist**:
- [ ] Todos los archivos prometidos fueron creados/modificados
- [ ] No hay errores de sintaxis PHP
- [ ] Laravel carga sin errores

---

### 2️⃣ Funcionalidad Core (3 min)

**Para Backend (Controller/Service)**:
```bash
# Probar endpoint manualmente
curl -X GET http://localhost:8000/api/{endpoint}
# O usar Postman/Insomnia
```

**Para Frontend (Livewire/Blade)**:
```bash
php artisan serve
# Visitar en navegador la ruta correspondiente
```

**Checklist**:
- [ ] La funcionalidad principal funciona (happy path)
- [ ] No hay errores 500
- [ ] UI renderiza correctamente (si aplica)

---

### 3️⃣ Code Quality Básico (2 min)

```bash
# Linter
./vendor/bin/pint --test

# Verificar imports y namespaces
grep -n "use App\\" {archivo} | head -20
```

**Checklist**:
- [ ] PSR-12 compliance (Pint pasa)
- [ ] Imports correctos y ordenados
- [ ] No hay `dd()`, `var_dump()` olvidados

---

### 4️⃣ No Rompe Nada (3 min)

```bash
# Rutas siguen funcionando
php artisan route:list | grep {modulo}

# Tests existentes pasan (si los hay)
php artisan test --testsuite=Feature --filter={modulo} --stop-on-failure
```

**Checklist**:
- [ ] Rutas relacionadas funcionan
- [ ] Tests existentes no se rompieron
- [ ] Navegación de la app sigue funcionando

---

**✅ Si todo lo anterior pasa → APROBAR para integración**

---

## 🔍 VALIDACIÓN PROFUNDA (Para Tareas M/L/XL)

### Todo lo de Validación Rápida +

---

### 5️⃣ Tests y Cobertura (5 min)

```bash
# Correr tests del módulo
php artisan test --filter={modulo}

# Ver cobertura (si está configurada)
php artisan test --coverage --min=80
```

**Checklist**:
- [ ] Tests nuevos fueron creados (si la tarea lo requería)
- [ ] Tests pasan consistentemente (correr 3 veces)
- [ ] Cobertura >80% para código crítico
- [ ] Edge cases están testeados

---

### 6️⃣ Performance y Queries (5 min)

```bash
# Instalar Debugbar si no está
composer require barryvdh/laravel-debugbar --dev

# Probar con datos reales
php artisan tinker
>>> {Model}::factory(100)->create();
```

**Checklist Backend**:
- [ ] Queries optimizadas (sin N+1)
- [ ] Tiempo de respuesta <200ms para endpoints
- [ ] Índices DB usados correctamente
- [ ] Eager loading donde sea necesario

**Checklist Frontend**:
- [ ] Página carga en <2 segundos
- [ ] Livewire no hace polling innecesario
- [ ] Assets optimizados (Vite build OK)

---

### 7️⃣ Seguridad y Validaciones (5 min)

**Checklist**:
- [ ] Validaciones en FormRequests (no en controllers)
- [ ] Permisos chequeados (`@can()`, `authorize()`)
- [ ] No hay SQL injection (usar Eloquent/QueryBuilder)
- [ ] No hay XSS (Blade escapa automático, verificar `{!! !!}`)
- [ ] CSRF protection en formularios (token incluido)
- [ ] Inputs sanitizados correctamente

**Tests Manuales**:
```bash
# Intentar acceder sin permisos
# Intentar enviar datos inválidos
# Intentar SQL injection en búsquedas
```

---

### 8️⃣ UX y Responsive (5 min)

**Checklist**:
- [ ] Diseño consistente con el resto de la app
- [ ] Funciona en móviles (ancho <768px)
- [ ] Funciona en tablets (768-1024px)
- [ ] Loading states implementados
- [ ] Mensajes de error claros y útiles
- [ ] Feedback visual en acciones (success, error)

**Probar en**:
- Chrome Desktop (1920x1080)
- Chrome Mobile (iPhone SE 375px)
- Chrome Tablet (iPad 768px)

---

### 9️⃣ Documentación y Mantenibilidad (3 min)

**Checklist**:
- [ ] Comentarios PHPDoc en clases y métodos públicos
- [ ] README del módulo actualizado (si aplica)
- [ ] Variables de entorno documentadas (si hay nuevas)
- [ ] No hay TODOs o FIXMEs críticos sin resolver
- [ ] Código auto-explicativo (nombres descriptivos)

---

### 🔟 Integración y Dependencias (2 min)

**Checklist**:
- [ ] No rompe módulos relacionados
- [ ] Migraciones corren sin errores (fresh + seed)
- [ ] Seeders actualizados (si hay cambios de permisos)
- [ ] No conflictos de rutas con otros módulos
- [ ] Eventos/Listeners funcionan correctamente

```bash
# Migración limpia
php artisan migrate:fresh --seed

# Verificar seeders
php artisan db:seed --class={SeederClass}
```

---

## 🐛 PROBLEMAS COMUNES Y SOLUCIONES

### Problema: "Class not found"
**Solución**:
```bash
composer dump-autoload
php artisan optimize
```

### Problema: "View not found"
**Solución**:
```bash
php artisan view:clear
php artisan cache:clear
```

### Problema: "Livewire component not found"
**Solución**:
```bash
php artisan livewire:list
# Verificar namespace correcto
```

### Problema: Queries N+1
**Solución**:
```php
// Mal
$items = Item::all();
foreach ($items as $item) {
    echo $item->category->name; // N+1!
}

// Bien
$items = Item::with('category')->get();
foreach ($items as $item) {
    echo $item->category->name; // 1 query extra
}
```

### Problema: Performance lenta
**Checklist**:
- [ ] Verificar índices en BD
- [ ] Usar paginación (no `->all()` en tablas grandes)
- [ ] Cachear queries pesadas
- [ ] Usar Redis para sessions/cache

---

## 📊 MATRIZ DE DECISIÓN

| Criterio | ✅ Aprobar | 🟡 Revisar | ❌ Rechazar |
|----------|-----------|-----------|------------|
| **Funcionalidad** | 100% funcional | 90%+ funcional | <90% funcional |
| **Tests** | Todos pasan | 1-2 fallan | 3+ fallan |
| **Performance** | <200ms | 200-500ms | >500ms |
| **Code Quality** | Pint OK, DRY | Warnings menores | Muchos warnings |
| **Seguridad** | Sin issues | 1 issue menor | Issues críticos |
| **UX** | Responsive, claro | Funcional básico | Roto en móviles |

### Decisiones:
- **✅ Aprobar**: Integrar de inmediato, merge a main
- **🟡 Revisar**: Pedir correcciones menores a la IA
- **❌ Rechazar**: Rehace la tarea con specs más claras

---

## 🎯 PLANTILLA DE REPORTE DE VALIDACIÓN

Copia y completa después de validar:

```markdown
## ✅ VALIDACIÓN COMPLETADA

**Tarea**: {nombre_tarea}
**IA Utilizada**: {Claude/Qwen/ChatGPT}
**Validador**: {tu_nombre}
**Fecha**: {fecha}
**Tipo de Validación**: Rápida / Profunda

---

### Resultados

**Funcionalidad**: ✅ / 🟡 / ❌  
**Tests**: ✅ / 🟡 / ❌  
**Performance**: ✅ / 🟡 / ❌  
**Code Quality**: ✅ / 🟡 / ❌  
**Seguridad**: ✅ / 🟡 / ❌  
**UX**: ✅ / 🟡 / ❌  

---

### Notas

**Qué funciona bien**:
- {lista}

**Issues encontrados**:
- {lista}

**Correcciones aplicadas manualmente**:
- {lista}

---

### Decisión Final

[ ] ✅ APROBADO - Integrar
[ ] 🟡 APROBADO CON CORRECCIONES - Integrar después de fixes
[ ] ❌ RECHAZADO - Reintentar con specs mejoradas

---

### Próximos Pasos
- {acción_1}
- {acción_2}
```

---

## 🔄 MEJORA CONTINUA

### Si la IA falla repetidamente:

1. **Specs poco claras**: Mejorar el prompt con más ejemplos
2. **Tarea muy compleja**: Dividir en subtareas más pequeñas
3. **Falta contexto**: Adjuntar más documentación de MASTER/
4. **IA incorrecta**: Probar con otra IA (Claude vs Qwen vs ChatGPT)

### Métricas a Trackear:

| Métrica | Target |
|---------|--------|
| % Tareas Aprobadas (1er intento) | >80% |
| Tiempo promedio validación | <15 min |
| Issues críticos encontrados | <1 por tarea |
| Refactors necesarios | <20% del código |

---

## 📞 ESCALACIÓN

### Si encuentras problemas serios:

1. **Bug crítico**: Rollback inmediato, investigar
2. **Decisión arquitectónica incorrecta**: Pausar, discutir con equipo
3. **Performance inaceptable**: Profiling + optimización antes de integrar

---

**¡Mantengamos la calidad alta! 🎯**

---

**Mantenido por**: Equipo TerrenaLaravel  
**Última actualización**: 2025-10-31
