# ================================================================
# DEPLOY SCRIPT FOR POSTGRESQL 9.5 - SAFE VERSION
# File: DEPLOY_v4_SAFE.ps1
# Date: 2025-10-17
# ================================================================

param(
    [string]$HostName = "localhost",
    [int]$Port = 5433,
    [string]$Database = "floreant",
    [string]$User = "postgres",
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"

# Colors
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green $args }
function Write-Warning2 { Write-ColorOutput Yellow $args }
function Write-Error2 { Write-ColorOutput Red $args }
function Write-Info { Write-ColorOutput Cyan $args }

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SqlFile = Join-Path $ScriptDir "DEPLOY_CONSOLIDADO_FULL_PG95-v4-FIXED.sql"
$LogFile = Join-Path $ScriptDir "deploy_v4_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$BackupFile = Join-Path $ScriptDir "backup_pre_deploy_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"

# Find psql.exe
$PsqlPaths = @(
    "C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe",
    "C:\xampp3\postgresql\bin\psql.exe",
    "C:\Program Files\PostgreSQL\9.5\bin\psql.exe",
    "C:\Program Files\PostgreSQL\10\bin\psql.exe",
    "C:\Program Files\PostgreSQL\11\bin\psql.exe",
    "psql.exe"
)

$PsqlPath = $null
foreach ($path in $PsqlPaths) {
    if (Test-Path $path -ErrorAction SilentlyContinue) {
        $PsqlPath = $path
        break
    }
}

if (-not $PsqlPath) {
    try {
        $PsqlPath = (Get-Command psql.exe -ErrorAction Stop).Source
    } catch {
        Write-Error2 "ERROR: No se encontro psql.exe en ninguna ubicacion conocida."
        Write-Error2 "Por favor, agregue la ruta de PostgreSQL al PATH o especifique la ruta completa."
        exit 1
    }
}

Write-Info "================================================================"
Write-Info "DEPLOY SCRIPT FOR POSTGRESQL 9.5 - SAFE VERSION"
Write-Info "================================================================"
Write-Info "Host: $HostName"
Write-Info "Port: $Port"
Write-Info "Database: $Database"
Write-Info "User: $User"
Write-Info "SQL File: $SqlFile"
Write-Info "Psql Path: $PsqlPath"
Write-Info "Log File: $LogFile"
if ($DryRun) {
    Write-Warning2 "DRY RUN MODE: No se ejecutaran cambios"
}
Write-Info "================================================================"

# Verify SQL file exists
if (-not (Test-Path $SqlFile)) {
    Write-Error2 "ERROR: Archivo SQL no encontrado: $SqlFile"
    exit 1
}

$FileSizeMB = [math]::Round((Get-Item $SqlFile).Length / 1048576, 2)
Write-Success "`n[OK] Archivo SQL encontrado ($FileSizeMB MB)"

# Test connection
Write-Info "`nProbando conexion a PostgreSQL..."
# Si ya viene PGPASSWORD del entorno, no pedirlo
if (-not $env:PGPASSWORD -or $env:PGPASSWORD.Length -eq 0) {
    $PlainPassword = Read-Host -Prompt "Ingrese la contrasena para el usuario '$User'" -AsSecureString
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PlainPassword))
} else {
    Write-Info "PGPASSWORD provisto por entorno; no se solicita interactivamente."
}

$testQuery = "SELECT version();"
try {
    $testResult = & "$PsqlPath" -h $HostName -p $Port -U $User -d $Database -t -c $testQuery 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Error2 "`n[ERROR] No se pudo conectar a PostgreSQL"
        Write-Error2 $testResult
        exit 1
    }

    Write-Success "[OK] Conexion exitosa"
    Write-Info "PostgreSQL Version: $($testResult.Trim())"

    # Check if PostgreSQL 9.5
    if ($testResult -match "PostgreSQL 9\.5") {
        Write-Success "[OK] PostgreSQL 9.5 detectado - compatible"
    } else {
        Write-Warning2 "[WARN] Este script esta optimizado para PostgreSQL 9.5"
        Write-Warning2 "Version detectada: $($testResult.Trim())"
        $continue = Read-Host "Desea continuar de todos modos? (s/n)"
        if ($continue -ne 's' -and $continue -ne 'S') {
            Write-Info "Operacion cancelada por el usuario"
            exit 0
        }
    }
} catch {
    Write-Error2 "[ERROR] Error al conectar: $_"
    exit 1
}

# Create backup
Write-Info "`nCreando respaldo de esquema selemti..."
try {
    $PgBinDir = Split-Path -Parent $PsqlPath
    $PgDumpPath = Join-Path $PgBinDir "pg_dump.exe"
    if (Test-Path $PgDumpPath) {
        & "$PgDumpPath" -h $HostName -p $Port -U $User -d $Database -n selemti -n public --schema-only -F p -f "$BackupFile" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "[OK] Respaldo creado: $BackupFile"
        } else {
            Write-Warning2 "[WARN] No se pudo crear respaldo (puede ser que el esquema no exista aun)"
        }
    } else {
        Write-Warning2 "[WARN] pg_dump no encontrado en: $PgDumpPath; se omite respaldo."
    }
} catch {
    Write-Warning2 "[WARN] No se pudo crear respaldo: $_"
}

if ($DryRun) {
    Write-Warning2 "`n[DRY RUN] Se ejecutaria el siguiente comando:"
    Write-Info "psql -h $HostName -p $Port -U $User -d $Database -v ON_ERROR_STOP=0 -f `"$SqlFile`""
    Write-Info "`nPara ejecutar realmente, omita el parametro -DryRun"
    exit 0
}

# Execute SQL
Write-Info "`nEjecutando SQL deployment..."
Write-Info "Esto puede tomar varios minutos. Por favor espere..."
Write-Info "Los errores se registraran en: $LogFile"

try {
    & "$PsqlPath" -h $HostName -p $Port -U $User -d $Database -v ON_ERROR_STOP=0 -f "$SqlFile" 2>&1 | Tee-Object -FilePath "$LogFile"
} catch {
    Write-Error2 "[ERROR] Error durante la ejecucion: $_"
    exit 2
}

# Post-fix: asegurar vistas/funciones clave si hubo errores en el archivo grande
$FixViews = Join-Path $ScriptDir "fix_views.sql"
$FixFuncs = Join-Path $ScriptDir "fix_functions.sql"
if (Test-Path $FixViews) {
    Write-Info "\nAplicando fix_views.sql (post-fix de vistas clave)..."
    try {
        & "$PsqlPath" -h $HostName -p $Port -U $User -d $Database -f "$FixViews" 2>&1 | Out-Null
        Write-Success "[OK] Vistas clave forzadas"
    } catch {
        Write-Warning2 "[WARN] No se pudo aplicar fix_views.sql: $_"
    }
}
if (Test-Path $FixFuncs) {
    Write-Info "Aplicando fix_functions.sql (post-fix de funciones clave)..."
    try {
        & "$PsqlPath" -h $HostName -p $Port -U $User -d $Database -f "$FixFuncs" 2>&1 | Out-Null
        Write-Success "[OK] Funciones clave forzadas"
    } catch {
        Write-Warning2 "[WARN] No se pudo aplicar fix_functions.sql: $_"
    }
}

# Analyze results
Write-Info "`n================================================================"
Write-Info "ANALISIS DE RESULTADOS"
Write-Info "================================================================"

$logContent = Get-Content $LogFile -Raw

# Count errors and warnings
$errorCount = ([regex]::Matches($logContent, "ERROR:")).Count
$warningCount = ([regex]::Matches($logContent, "WARNING:")).Count
$noticeCount = ([regex]::Matches($logContent, "NOTICE:")).Count

Write-Info "Errores encontrados: $errorCount"
Write-Info "Advertencias: $warningCount"
Write-Info "Avisos (NOTICE): $noticeCount"

if ($errorCount -eq 0) {
    Write-Success "`n[OK] DEPLOY COMPLETADO EXITOSAMENTE"
    Write-Success "No se encontraron errores"
} elseif ($errorCount -lt 10) {
    Write-Warning2 "`n[WARN] DEPLOY COMPLETADO CON ERRORES MENORES"
    Write-Warning2 "Se encontraron $errorCount errores"
    Write-Info "Revise el log para mas detalles: $LogFile"
} else {
    Write-Error2 "`n[ERROR] DEPLOY COMPLETADO CON ERRORES CRITICOS"
    Write-Error2 "Se encontraron $errorCount errores"
    Write-Error2 "Revise el log para mas detalles: $LogFile"

    Write-Info "`nPrimeros 10 errores:"
    $errors = [regex]::Matches($logContent, "ERROR:.*") | Select-Object -First 10
    foreach ($err in $errors) {
        Write-Error2 "  - $($err.Value)"
    }
}

# Verify critical tables
Write-Info "`n================================================================"
Write-Info "VERIFICACION DE OBJETOS CRITICOS"
Write-Info "================================================================"

$verifyQueries = @(
    @{Name="Schema selemti"; Query="SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='selemti'"},
    @{Name="Tabla users"; Query="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='selemti' AND table_name='users'"},
    @{Name="Tabla sesion_cajon"; Query="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='selemti' AND table_name='sesion_cajon'"},
    @{Name="Tabla precorte"; Query="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='selemti' AND table_name='precorte'"},
    @{Name="Tabla postcorte"; Query="SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='selemti' AND table_name='postcorte'"},
    @{Name="Vista vw_conciliacion_sesion"; Query="SELECT COUNT(*) FROM information_schema.views WHERE table_schema='selemti' AND table_name='vw_conciliacion_sesion'"}
)

$allOk = $true
foreach ($check in $verifyQueries) {
    try {
        $result = & "$PsqlPath" -h $HostName -p $Port -U $User -d $Database -t -c $check.Query 2>&1
        if ($result.Trim() -eq "1") {
            Write-Success "[OK] $($check.Name): ENCONTRADO"
        } else {
            Write-Error2 "[ERROR] $($check.Name): NO ENCONTRADO"
            $allOk = $false
        }
    } catch {
        Write-Error2 "[ERROR] $($check.Name): ERROR AL VERIFICAR"
        $allOk = $false
    }
}

Write-Info "`n================================================================"
Write-Info "RESUMEN FINAL"
Write-Info "================================================================"
Write-Info "Archivo SQL: $SqlFile"
Write-Info "Log completo: $LogFile"
Write-Info "Backup: $BackupFile"
Write-Info "Errores: $errorCount"
Write-Info "Advertencias: $warningCount"

if ($allOk -and $errorCount -eq 0) {
    Write-Success "`n[OK] DEPLOY EXITOSO - SISTEMA LISTO PARA USO"
    exit 0
} elseif ($allOk -and $errorCount -lt 10) {
    Write-Warning2 "`n[WARN] DEPLOY COMPLETADO CON ERRORES MENORES - VERIFICAR LOG"
    exit 1
} else {
    Write-Error2 "`n[ERROR] DEPLOY CON ERRORES - REQUIERE REVISION"
    exit 2
}
