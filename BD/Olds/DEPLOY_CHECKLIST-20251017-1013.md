# Deploy Checklist (PG 9.5)

Fecha: 2025-10-17 10:13

Entorno
- Host: 127.0.0.1
- Puerto: 5433
- DB: pos
- Usuario: postgres
- Password: T3rr3n4#p0s

Archivos
- DEPLOY_CONSOLIDADO_FULL_PG95-v3-*.sql (usar la versión más reciente)
- post_deploy_verify.sql
- run_deploy_v3.ps1 / run_deploy_v3.sh (plantillas)

Pasos (staging primero)
1) Backup de la base actual (si aplica)
   - pg_dump -h 127.0.0.1 -p 5433 -U postgres -Fc pos > backup-pos-before-<fecha>.dump
2) Verificar conectividad
   - psql -h 127.0.0.1 -p 5433 -U postgres -d pos -c "SELECT version();"
3) Ejecutar deploy
   - Windows (PowerShell): .\run_deploy_v3.ps1
   - Linux/Mac (bash): ./run_deploy_v3.sh
4) Revisar logs
   - BD/deploy_v3-<fecha>.log: buscar errores
5) Verificación post-deploy
   - psql -f post_deploy_verify.sql y validar que todas las pruebas pasen
6) (Prod) Repetir con ventana/backup y monitoreo

Notas
- Este deploy asume PG 9.5 y aplica parches de compat (reemplaza columnas GENERATED AS por triggers de subtotal).
- No usa transacción global; algunos CREATE/ALTER/DO requieren ejecución fuera de BEGIN/COMMIT.
- Evita duplicados: omite objetos ya vistos; puede dejar comentarios BEGIN/END por archivo.
