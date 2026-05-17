# Database Backups

Los archivos `.dump` se almacenan en `C:\TerrenaBackups\` (fuera del repo por tamaño).

Scripts de backup/restore en esa misma carpeta (`backup.sh`, `restore.sh`, `README.md`).

## Último backup conocido

| Archivo | Fecha | Tamaño | Contenido |
|---------|-------|--------|-----------|
| `terrena_20260517_094245_full.dump` | 2026-05-17 09:42 | 12.4 MB | Full dump (selemti + public) — E2E corrida + datos de venta actuales + 9 bug fixes |

## Binario pg_dump local

```
C:\Program Files (x86)\PostgreSQL\9.5\bin\pg_dump.exe
```

## Comando rápido (PowerShell)

```powershell
$env:PGPASSWORD = "T3rr3n4#p0s"
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
& "C:\Program Files (x86)\PostgreSQL\9.5\bin\pg_dump.exe" `
    -h localhost -p 5433 -U postgres -d pos `
    --format=custom --compress=9 `
    --file="C:\TerrenaBackups\terrena_${ts}_full.dump"
```
