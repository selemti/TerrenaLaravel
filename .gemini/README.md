# Configuración Gemini CLI - Proyecto Terrena

Esta carpeta contiene la configuración de **Gemini CLI** para el proyecto TerrenaLaravel.

## 📁 Archivos

### `GEMINI.md`
Documentación completa del proyecto y guía de trabajo para Gemini CLI.

**Contenido:**
- Visión general del proyecto (tech stack, arquitectura)
- Rol específico de Gemini (Database Engineer & Bug Fixer)
- Reglas críticas de trabajo (esquemas selemti vs public)
- Flujos de trabajo estándar (casos de uso comunes)
- Comandos útiles (PostgreSQL, Laravel, Git)
- Convenciones de código (modelos, migraciones, SQL)
- Troubleshooting común
- Comunicación con otros agentes (Claude, Codex)

**Actualizar cuando:**
- Se agregan nuevos módulos al proyecto
- Se cambian convenciones de código
- Se identifican nuevos problemas comunes

---

### `settings.json`
Configuración técnica de Gemini CLI.

**Configuración clave:**
```json
{
  "model": "gemini-2.5-pro",
  "confirmActions": true,
  "language": "es",
  "sandbox": false
}
```

**Permisos configurados:**

#### ✅ Auto-aprobados (sin confirmación):
- Migraciones Laravel (`php artisan migrate`, `db:seed`)
- Consultas SELECT en cualquier esquema
- Operaciones de escritura en esquema `selemti` (INSERT, UPDATE, DELETE, ALTER)
- Comandos git básicos (status, log, diff, add, commit)
- Limpiar cachés Laravel

#### ⚠️ Requieren confirmación:
- Operaciones destructivas en `selemti` (DROP, TRUNCATE)
- **CUALQUIER** operación de escritura en esquema `public` (Floreant POS)
- Rollback de migraciones
- Push a repositorio remoto

#### ❌ Bloqueados:
- Comandos destructivos del sistema (rm -rf, format)
- Git force push
- DROP DATABASE
- DROP SCHEMA public

**Actualizar cuando:**
- Se necesiten nuevos privilegios
- Se identifiquen comandos que deberían estar bloqueados
- Se cambien reglas de seguridad

---

### `WORK_ASSIGNMENTS.md`
Sistema de coordinación entre Claude, Codex y Gemini.

**Propósito:**
- Evitar conflictos y duplicación de trabajo
- Coordinar tareas entre agentes
- Documentar progreso del proyecto

**Secciones:**
- **Agentes Activos:** Roles y especializaciones
- **Trabajo Actual:** Tareas completadas y en progreso
- **Pendiente:** Backlog de tareas
- **Reglas de Coordinación:** Protocolo de comunicación
- **Flujo de Trabajo Típico:** Cómo colaborar en un módulo

**Actualizar cuando:**
- Se inicia una nueva tarea
- Se completa una tarea
- Se encuentra un blocker que requiere otro agente
- Se cambian prioridades

---

### `settings.json.orig`
Backup del archivo de configuración original.

**No modificar** - Solo para referencia histórica.

---

## 🚀 Cómo Usar Gemini CLI

### Iniciar Gemini
```bash
cd C:\xampp3\htdocs\TerrenaLaravel
gemini
```

### Comandos Típicos

**Analizar error de columna faltante:**
```
Analiza el error SQLSTATE[42703] en el módulo de recepciones.
La columna numero_recepcion no existe. Determina si debemos
agregar la columna o ajustar el código.
```

**Optimizar performance:**
```
El listado de recepciones en /inventory/receptions tarda >5 segundos.
Analiza el query y propón optimizaciones (índices, query rewrite).
```

**Verificar consistencia:**
```
Audita todas las tablas del esquema selemti relacionadas con inventario.
Compara con los modelos Eloquent y documenta inconsistencias.
```

**Ejecutar migraciones:**
```
Ejecuta todas las migraciones pendientes y verifica que no haya errores.
Si hay issues, documéntalos.
```

---

## 🔄 Flujo de Trabajo con Claude y Codex

### Ejemplo: Nuevo Módulo (Purchasing)

**1. Codex crea backend:**
```bash
# Codex hace:
- PurchasingService.php
- Modelos (PurchaseRequest, PurchaseOrder, etc.)
- Migraciones
# Commit:
git commit -m "feat(purchasing): backend completo

@gemini: Revisar y ejecutar migraciones en database/migrations/2025_10_24_*
"
```

**2. Gemini prepara DB:**
```bash
# Gemini hace:
- Ejecuta: php artisan migrate
- Verifica: consistencia de columnas vs modelos
- Optimiza: agrega índices necesarios
# Commit:
git commit -m "chore(db): ejecutar migraciones de purchasing

@codex: OK. Agregué índice en purchase_orders.vendor_id
@claude: DB lista para trabajar UI
"
```

**3. Claude crea UI:**
```bash
# Claude hace:
- Componentes Livewire
- Vistas Blade
- Integración con PurchasingService
- Documentación
# Commit:
git commit -m "feat(purchasing): UI completa

@gemini: Probar performance del listado, avisar si necesita optimización
"
```

---

## 📊 Métricas de Responsabilidad

### Gemini es responsable de:
- ✅ Esquema `selemti` consistente con código
- ✅ Migraciones ejecutadas correctamente
- ✅ Índices optimizados para queries frecuentes
- ✅ Detección temprana de errores SQL
- ✅ Datos normalizados y sin duplicados

### Gemini NO hace:
- ❌ Componentes Livewire (es tarea de Claude)
- ❌ Services con lógica de negocio (es tarea de Codex)
- ❌ Vistas Blade (es tarea de Claude)
- ❌ Código JavaScript/Alpine (es tarea de Claude)

---

## 🛡️ Reglas de Seguridad Críticas

### ⚠️ NUNCA sin Autorización:
1. Modificar esquema `public` (Floreant POS en producción)
2. DROP/TRUNCATE de tablas con datos históricos
3. Cambiar credenciales en `.env`
4. Push force a ramas principales

### ✅ SIEMPRE Hacer:
1. Revisar WORK_ASSIGNMENTS.md antes de empezar
2. Actualizar WORK_ASSIGNMENTS.md con tu tarea
3. Explicar riesgo antes de operaciones destructivas
4. Documentar cambios en mensajes de commit
5. Notificar a Claude/Codex si les afecta el cambio

---

## 📖 Recursos Adicionales

### Documentación del Proyecto
- **CLAUDE.md** - Guía para Claude (desarrollo UI)
- **docs/CajaChica/FondoCaja/** - Documentación Caja Chica (~170 páginas)
- **docs/InventoryCounts/** - Documentación Conteos de Inventario

### Documentación Externa
- [Laravel 12 Migrations](https://laravel.com/docs/12.x/migrations)
- [PostgreSQL 9.5 Docs](https://www.postgresql.org/docs/9.5/)
- [Eloquent ORM](https://laravel.com/docs/12.x/eloquent)

### Herramientas
- **psql:** `C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe`
- **php artisan:** CLI de Laravel
- **git:** Control de versiones

---

## 🐛 Troubleshooting Gemini CLI

### "Permission denied" al ejecutar psql
**Causa:** Ruta incorrecta o falta de comillas en Windows

**Fix:**
```bash
# ❌ MAL
psql -c "SELECT ..."

# ✅ BIEN
"C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe" -h localhost -p 5433 -U postgres -d pos -c "SELECT ..."
```

### "Action requires confirmation"
**Causa:** El comando está en la lista `requireConfirmation`

**Acción:** Gemini debe explicar QUÉ va a hacer, POR QUÉ, y el RIESGO. Luego el usuario aprueba o rechaza.

### "Command blocked"
**Causa:** El comando está en la lista `blockedCommands`

**Acción:** Revisar si hay una alternativa más segura. Si realmente es necesario, pedir al usuario que lo ejecute manualmente.

### Gemini no lee archivos de contexto
**Causa:** `contextFiles` en settings.json puede no ser soportado por tu versión de Gemini CLI

**Fix:** Menciona explícitamente en el prompt:
```
Lee .gemini/GEMINI.md y .gemini/WORK_ASSIGNMENTS.md antes de continuar
```

---

## 📝 Changelog

### 2025-10-24 - Configuración Inicial (Claude)
- ✅ Creado GEMINI.md (720 líneas)
- ✅ Actualizado settings.json con permisos granulares
- ✅ Creado WORK_ASSIGNMENTS.md para coordinación
- ✅ Creado este README.md
- ✅ Aclarado que `public` es Floreant POS en producción

### Futuras Actualizaciones
- [ ] Agregar ejemplos de uso avanzado
- [ ] Documentar casos edge (rollback, conflicts, etc.)
- [ ] Crear guía de onboarding para nuevos devs
- [ ] Agregar scripts de validación pre-commit

---

**Última actualización:** 2025-10-24
**Configurado por:** Claude Code
**Versión Gemini CLI:** 2.5-pro
**Estado:** ✅ Producción

