# ÍNDICE - AUDITORÍA BD NOVIEMBRE 2025

**Fecha**: 2 Noviembre 2025
**Ubicación**: `BD/Noviembre/`

---

## 📊 REPORTES DE AUDITORÍA

### 1. **REPORTE_AUDITORIA_DUPLICADOS_COMPLETO.md** ⭐ PRINCIPAL
- **Tamaño**: 30 KB
- **Contenido**: Análisis exhaustivo de 26 grupos de tablas duplicadas
- **Uso**: Leer primero este archivo para entender el problema completo

### 2. **REPORTE_AUDITORIA_DUPLICADOS.md**
- **Tamaño**: 17 KB
- **Contenido**: Reporte automático (9 grupos básicos)
- **Uso**: Versión resumida del análisis

### 3. **PLAN_LIMPIEZA_SAFE.md**
- **Tamaño**: 15 KB
- **Contenido**: Plan detallado paso a paso para limpieza segura
- **Uso**: Guía para ejecutar la limpieza de tablas legacy

### 4. **README_AUDITORIA.md**
- **Tamaño**: 9 KB
- **Contenido**: Índice general y comandos útiles
- **Uso**: Referencia rápida

---

## 🔧 SCRIPTS SQL

### 5. **drop_legacy_safe.sql**
- **Tamaño**: 12 KB
- **Contenido**: Script para eliminar ~50 tablas legacy
- **Configuración**: ROLLBACK activo (dry-run seguro)
- **Uso**:
  ```bash
  psql -h localhost -p 5433 -U postgres -d pos -f drop_legacy_safe.sql
  ```

### 6. **validate_cleanup.sql**
- **Tamaño**: 7.8 KB
- **Contenido**: Validaciones post-limpieza
- **Uso**: Ejecutar después de limpieza para verificar integridad

---

## 📋 DATOS DE REFERENCIA

### 7. **legacy_code_refs.txt**
- **Tamaño**: 47 KB
- **Contenido**: Output de grep - Referencias a tablas legacy en código PHP
- **Uso**: Verificar si código usa tablas legacy antes de eliminar

---

## 💾 DUMPS SQL

### 8. **00.SelemTI_Normalizada_29_10_25_10_40_v0.sql**
- **Tamaño**: 621 KB
- **Contenido**: Dump normalizado (solo estructura, sin datos)
- **Uso**: Referencia de schema "correcto"

### 9. **00.SelemTI_Full_02_03_2025_v1.sql**
- **Tamaño**: 100 MB
- **Contenido**: Dump completo con datos
- **Uso**: Backup de referencia

### 10. **UX_01_11_2025.sql**
- **Tamaño**: 42 MB
- **Contenido**: Dump de datos UX
- **Uso**: Datos del sistema POS

---

## 🎯 RESUMEN DE HALLAZGOS

### Problema Principal
La BD tiene **26 grupos de tablas duplicadas** porque:
1. Múltiples intentos de normalización incompletos
2. Nomenclaturas mezcladas (español, inglés, mixto)
3. Tablas legacy de sistemas anteriores sin eliminar

### Tablas Críticas Duplicadas
- **Usuarios**: `users`, `usuario` (legacy vacía)
- **Roles**: `roles`, `rol` (legacy vacía)
- **Sucursales**: `cat_sucursales`, `sucursal` (legacy vacía)
- **Almacenes**: `cat_almacenes`, `almacen`, `bodega` (legacy vacías)
- **Proveedores**: `cat_proveedores`, `proveedor` (legacy vacía)
- **Unidades**: `cat_unidades`, `unidad_medida_legacy`, `unidades_medida_legacy` (legacy vacías)
- **Producción**: `production_orders` vs 4 tablas legacy (todas vacías)

### Estado Actual
- **Total tablas**: 249 (142 selemti + 107 public)
- **Tablas legacy vacías**: ~70 tablas
- **Tablas con datos legacy**: 4 (requieren migración)
- **Impacto**: ALTO - Afecta claridad de schema y mantenibilidad

---

## 📝 NIVELES DE LIMPIEZA PROPUESTOS

### Nivel 1: MUY CONSERVADOR (100% seguro)
Eliminar 4 tablas con sufijo `_legacy`:
- `conversiones_unidad_legacy`
- `uom_conversion_legacy`
- `unidad_medida_legacy`
- `unidades_medida_legacy`

**Tiempo**: 10 segundos
**Riesgo**: NINGUNO

### Nivel 2: CONSERVADOR
Eliminar ~20 tablas legacy vacías más obvias:
- Usuarios/roles legacy
- Catálogos legacy (sucursal, almacen, bodega, proveedor)
- Las 4 del Nivel 1

**Tiempo**: 30 minutos
**Riesgo**: BAJO (requiere dry-run)

### Nivel 3: COMPLETO
Usar `drop_legacy_safe.sql` para eliminar ~70 tablas

**Tiempo**: 2 horas
**Riesgo**: MEDIO (requiere backup + validación)

---

## ✅ PASOS RECOMENDADOS

### Ahora Mismo (5 minutos)
1. Leer `REPORTE_AUDITORIA_DUPLICADOS_COMPLETO.md`
2. Decidir nivel de limpieza

### Antes de Limpieza (30 minutos)
1. Crear backup completo:
   ```bash
   pg_dump -h localhost -p 5433 -U postgres -d pos -F c \
     -f BD/Noviembre/backup_pre_limpieza_$(date +%Y%m%d_%H%M%S).dump
   ```
2. Ejecutar dry-run:
   ```bash
   psql -h localhost -p 5433 -U postgres -d pos \
     -f BD/Noviembre/drop_legacy_safe.sql
   ```

### Durante Limpieza (variable)
1. Cambiar `ROLLBACK` por `COMMIT` en script SQL
2. Ejecutar limpieza
3. Validar con `validate_cleanup.sql`

### Post Limpieza (15 minutos)
1. Ejecutar `php artisan test`
2. Verificar Livewire components
3. Probar API endpoints
4. Actualizar documentación

---

## 📞 SOPORTE

**Archivos generados por**: Claude Code (Task Agent)
**Fecha**: 2 Noviembre 2025
**Versión**: 1.0

Para preguntas o problemas:
1. Revisar README_AUDITORIA.md
2. Consultar PLAN_LIMPIEZA_SAFE.md
3. Verificar reportes de auditoría

---

**IMPORTANTE**: NO ejecutar ningún DROP sin antes:
1. Crear backup completo
2. Ejecutar dry-run exitoso
3. Revisar código (legacy_code_refs.txt)
4. Coordinarse con equipo
