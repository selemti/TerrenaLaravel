# Gemini CLI - Quick Start Guide

Referencia rápida para trabajar con Gemini CLI en el proyecto Terrena.

## ⚡ Inicio Rápido

```bash
cd C:\xampp3\htdocs\TerrenaLaravel
gemini
```

Primero, pide a Gemini:
```
Lee .gemini/GEMINI.md y .gemini/WORK_ASSIGNMENTS.md
```

---

## 🎯 Tu Rol

Eres el **Database Engineer & Bug Fixer**.

**Puedes hacer libremente:**
- ✅ Modificar esquema `selemti` (CREATE, ALTER, INSERT, UPDATE, DELETE)
- ✅ Ejecutar migraciones (`php artisan migrate`)
- ✅ Optimizar índices
- ✅ Debuggear queries SQL
- ✅ Normalizar datos

**Requiere confirmación:**
- ⚠️ DROP/TRUNCATE en `selemti`
- ⚠️ **TODO en esquema `public`** (Floreant POS en producción)

---

## 📋 Tareas Comunes

### 1. Error de Columna Faltante
```
Error: SQLSTATE[42703]: no existe la columna "numero_recepcion"
```

**Prompt para Gemini:**
```
Analiza el error de columna faltante en el módulo de recepciones.
Verifica si la columna debe existir o si el código está mal.
Propón el fix y aplícalo si es seguro.
```

**Gemini hará:**
1. Buscar dónde se usa la columna en el código
2. Verificar estructura real de la tabla en BD
3. Proponer: agregar columna o ajustar código
4. Crear migration si es necesario
5. Ejecutar y verificar

---

### 2. Query Lenta
```
Síntoma: Listado tarda >5 segundos
```

**Prompt para Gemini:**
```
El listado de recepciones en /inventory/receptions es muy lento.
Analiza el query, identifica el problema (falta índice, etc.)
y optimízalo.
```

**Gemini hará:**
1. Ejecutar EXPLAIN ANALYZE en el query
2. Identificar Seq Scans (falta índice)
3. Proponer índices
4. Crear migration con índices
5. Verificar mejora

---

### 3. Inconsistencia BD vs Modelo
```
Síntoma: Código espera columnas que no existen
```

**Prompt para Gemini:**
```
Audita el módulo de inventario completo.
Compara modelos Eloquent con estructura real de BD.
Documenta inconsistencias y propón correcciones.
```

**Gemini hará:**
1. Listar tablas relacionadas
2. Para cada tabla: verificar columnas, índices, FKs
3. Leer modelos Eloquent correspondientes
4. Comparar $table, $fillable, $casts, relaciones
5. Documentar diferencias
6. Proponer migraciones de corrección

---

### 4. Ejecutar Migraciones Pendientes
```
Síntoma: Codex/Claude creó migraciones, necesitan ejecutarse
```

**Prompt para Gemini:**
```
Ejecuta todas las migraciones pendientes.
Verifica que no haya errores.
Si algo falla, analiza y documenta el problema.
```

**Gemini hará:**
1. `php artisan migrate:status` (ver pendientes)
2. `php artisan migrate` (ejecutar)
3. Verificar errores
4. Si falla: analizar causa y proponer fix
5. Actualizar WORK_ASSIGNMENTS.md con resultado

---

## 🔑 Comandos Clave

### PostgreSQL
```bash
# Conectar
"C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe" -h localhost -p 5433 -U postgres -d pos

# Dentro de psql:
\d selemti.tabla              # Describir tabla
\dt selemti.*                 # Listar tablas
\di selemti.*                 # Listar índices
SET search_path TO selemti;   # Usar esquema por defecto
```

### Laravel
```bash
php artisan migrate              # Ejecutar pendientes
php artisan migrate:status       # Ver estado
php artisan make:migration nombre # Crear nueva
```

### Git
```bash
git status
git add .gemini/WORK_ASSIGNMENTS.md database/migrations/...
git commit -m "fix(db): descripción"
```

---

## 🚨 Reglas de Oro

1. **SIEMPRE** revisar WORK_ASSIGNMENTS.md antes de empezar
2. **NUNCA** tocar esquema `public` sin autorización (es Floreant POS en producción)
3. **SIEMPRE** explicar riesgo antes de DROP/TRUNCATE
4. **SIEMPRE** usar ruta completa para psql en Windows
5. **SIEMPRE** PostgreSQL 9.5 syntax (nada de features modernas)

---

## 💬 Comunicación con Otros Agentes

**En commits:**
```bash
git commit -m "fix(db): agregar índice en recepcion_cab.sucursal_id

@claude: Índice agregado, mejora performance a <0.5s
"
```

**En WORK_ASSIGNMENTS.md:**
```markdown
### 🔄 EN PROGRESO

#### Gemini:
- [ ] Optimizar módulo de recepciones
  - **Para Claude:** Si encuentro más issues te aviso
```

---

## 📁 Archivos Importantes

- `.gemini/GEMINI.md` - Tu guía completa (720 líneas)
- `.gemini/WORK_ASSIGNMENTS.md` - Coordinación con Claude/Codex
- `.gemini/settings.json` - Tu configuración técnica
- `CLAUDE.md` - Guía de Claude (para entender el proyecto)

---

## 🆘 Ayuda Rápida

**¿No estás seguro si puedes hacer algo?**
→ Si es en `selemti`: ✅ adelante
→ Si es en `public`: ⚠️ pide confirmación
→ Si es DROP/TRUNCATE: ⚠️ explica riesgo primero

**¿Error de sintaxis PostgreSQL?**
→ Recuerda: estamos en 9.5, usa sintaxis clásica

**¿Conflicto con Claude/Codex?**
→ Revisa WORK_ASSIGNMENTS.md
→ Comunícate en commits con @claude o @codex

---

**Tip:** Lee GEMINI.md completo al menos una vez para entender todo el contexto del proyecto.

