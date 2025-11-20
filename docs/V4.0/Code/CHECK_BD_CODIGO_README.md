# CHECK AUTOMÁTICO BD ↔ CÓDIGO

Comando Artisan para verificar que el mapeo documentado en `docs/V4.0/Code/BD_CODIGO_MAPA_CAMPOS_ALL_VERIFICADO.md` coincida con la realidad de la base de datos PostgreSQL.

## 🎯 Objetivo

Detectar automáticamente:
- **Columnas FANTASMA**: Documentadas como existentes pero que no están en la BD real
- **Columnas NUEVAS**: Existen en BD pero no están en el mapeo
- **MISMATCH de estado**: Marcadas como CONFIABLE pero con inconsistencias

## 📋 Uso

### Ejecución básica
```bash
php artisan check:db-code-consistency
```

### Con todas las verificaciones (verbose)
```bash
php artisan check:db-code-consistency --verbose
```

### Solo mostrar errores (sin warnings)
```bash
php artisan check:db-code-consistency --only-errors
```

## 📊 Salida

El comando genera un reporte en consola con:

1. **Resumen**: Total de filas verificadas, errores y warnings
2. **Errores críticos**: 
   - `BD_FALTANTE`: Columna documentada como existente pero ausente en BD
3. **Advertencias**:
   - `BD_NUEVA`: Columna existe en BD pero no está en mapeo
   - `INCONSISTENCIA_ESTADO`: Estados contradictorios en el mapeo

## ✅ Código de salida

- `0`: Todo OK, sin inconsistencias
- `1`: Se encontraron errores

## 🔧 Integración en CI/CD

Puedes agregar este check en tu pipeline para detectar divergencias automáticamente:

```yaml
# .github/workflows/check-bd.yml
- name: Check BD consistency
  run: php artisan check:db-code-consistency --only-errors
```

## 📝 Notas

- El comando lee el archivo: `docs/V4.0/Code/BD_CODIGO_MAPA_CAMPOS_ALL_VERIFICADO.md`
- Verifica contra ambos esquemas: `public` y `selemti`
- Si encuentras errores, actualiza el mapeo o corrige la BD según corresponda
