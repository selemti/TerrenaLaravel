param(
    [string]$HostName = "127.0.0.1",
    [int]$Port = 5433,
    [string]$Database = "pos",
    [string]$User = "postgres", 
    [string]$Password = "T3rr3n4#p0s",
    [string]$SqlFile,
    [string]$LogFile,
    [string]$PsqlExe = "C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe"
)

function Resolve-Psql {
    param([string]$exe)
    
    # Verificar si la ruta existe directamente
    if (Test-Path $exe) {
        Write-Host "✓ psql encontrado: $exe" -ForegroundColor Green
        return $exe
    }
    
    # Si no existe, buscar alternativas
    Write-Host "Buscando psql en otras ubicaciones..." -ForegroundColor Yellow
    
    $candidates = @(
        "C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe",
        "C:\Program Files\PostgreSQL\9.5\bin\psql.exe",
        "C:\Program Files\PostgreSQL\9.6\bin\psql.exe",
        "C:\Program Files\PostgreSQL\10\bin\psql.exe",
        "C:\Program Files\PostgreSQL\11\bin\psql.exe"
    )
    
    foreach($path in $candidates) { 
        if (Test-Path $path) { 
            Write-Host "✓ Encontrado: $path" -ForegroundColor Green
            return $path 
        }
    }
    
    return $null
}

# Auto-detect SQL file if not specified
if (-not $SqlFile) {
    $SqlFile = (Get-ChildItem -Path "$PSScriptRoot" -Filter 'DEPLOY_CONSOLIDADO_FULL_PG95-v3-*.sql' | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1).FullName
}

# Auto-generate log file if not specified  
if (-not $LogFile) {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $LogFile = Join-Path $PSScriptRoot "deploy_v3-$timestamp.log"
}

# Validations
if (-not (Test-Path $SqlFile)) {
    Write-Error "No se encontró archivo SQL: $SqlFile"
    exit 1
}

$psqlPath = Resolve-Psql -exe $PsqlExe
if (-not $psqlPath) {
    Write-Error "No se encontró 'psql'. Verifica la instalación de PostgreSQL"
    exit 1
}

# Display execution info
Write-Host "=== DEPLOY AUTOMATICO PostgreSQL ===" -ForegroundColor Cyan
Write-Host "Servidor: $HostName`:$Port" -ForegroundColor Yellow
Write-Host "Base de datos: $Database" -ForegroundColor Yellow
Write-Host "Archivo SQL: $(Split-Path $SqlFile -Leaf)" -ForegroundColor Yellow
Write-Host "Log: $(Split-Path $LogFile -Leaf)" -ForegroundColor Yellow
Write-Host "Ejecutando..." -ForegroundColor Green

# Execute deployment
try {
    $env:PGPASSWORD = $Password
    $startTime = Get-Date
    
    & "$psqlPath" -h $HostName -p $Port -U $User -d $Database -v ON_ERROR_STOP=1 -f $SqlFile *>&1 | 
        Tee-Object -FilePath $LogFile
    
    if ($LASTEXITCODE -ne 0) {
        throw "psql retornó código de error: $LASTEXITCODE"
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host "✅ DEPLOY EXITOSO" -ForegroundColor Green
    Write-Host "⏱️  Duración: $($duration.ToString('mm\:ss'))" -ForegroundColor Cyan
    Write-Host "📋 Log completo: $LogFile" -ForegroundColor Cyan
    
} catch {
    Write-Error "❌ DEPLOY FALLADO: $($_.Exception.Message)"
    Write-Host "📋 Revisar log: $LogFile" -ForegroundColor Red
    exit 1
} finally {
    # Clean password from environment
    $env:PGPASSWORD = $null
}