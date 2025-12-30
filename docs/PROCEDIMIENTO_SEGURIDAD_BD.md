# Script de seguridad para prevención de pérdida de base de datos

## 1. Identificación de la causa raíz
- Se encontraron múltiples archivos SQL con comandos `DROP DATABASE pos;`
- Estos archivos están en las carpetas BD, BD\Olds, BD\Noviembre
- Algunos scripts de instalación y despliegue son completamente destructivos

## 2. Archivos de riesgo identificados
Los siguientes son algunos de los archivos que contienen comandos destructivos:

- `BD\SelemTI_Estrucutra_Pedido_29_10_25_10_40_v3.sql`
- `BD\Olds\DEPLOY_CONSOLIDADO_FULL_PG95-v3-20251017-180148.sql`
- `BD\Noviembre\00.SelemTI_Full_03_11_2025_v4_Antes_Qwen.sql`
- Y muchos otros archivos similares

## 3. Recomendaciones de seguridad implementadas
- Archivo `proteger_db.sh` creado para aislar scripts destructivos
- Archivo `verificar_integridad_db.php` creado para monitoreo de integridad
- Documentación `CAUSA_RAIZ_PERDIDA_BD.md` creada con el análisis completo

## 4. Procedimientos de seguridad recomendados

### A. Antes de ejecutar cualquier script SQL
1. Verificar si contiene comandos destructivos (`DROP`, `DELETE`, `TRUNCATE`)
2. Hacer un backup antes de ejecutar scripts desconocidos
3. Ejecutar en ambiente de prueba primero

### B. Implementar el sistema de monitoreo
1. Ejecutar `php verificar_integridad_db.php` periódicamente
2. Automatizar backups regulares
3. Monitorear archivos de logs de PostgreSQL

### C. Control de acceso
1. Aislar scripts destructivos en directorios separados
2. Implementar confirmaciones antes de ejecutar operaciones críticas
3. Documentar claramente qué scripts son seguros y cuáles no

## 5. Comando para crear backup antes de operaciones críticas

Para crear un backup de seguridad antes de cualquier operación crítica:

```bash
pg_dump -h localhost -p 5433 -U postgres -d pos -f "backup_pre_$(date +%Y%m%d_%H%M%S).sql" --schema=public --schema=selemti
```

## 6. Prevención futura

- Establecer un proceso de despliegue controlado
- Implementar un sistema de versionado de base de datos (migraciones) en lugar de reinstalaciones completas
- Separar claramente ambientes de desarrollo, pruebas y producción
- Documentar adecuadamente los procesos de instalación y despliegue

## Conclusión

La pérdida repetida de la base de datos no es aleatoria sino causada por la ejecución de scripts que contienen comandos `DROP DATABASE`. Con los controles implementados (scripts de verificación, aislamiento de scripts destructivos y documentación), se minimiza significativamente el riesgo de pérdida futura de datos.