<#
============================================================================
Ejecuta selemti.recalcular_costos_periodo y registra el resultado
Usos:
  - Rango: powershell -NoProfile -ExecutionPolicy Bypass -File BD/RUN_recalculo_costos.ps1 -Modo rango -Desde 2025-09-01 -Hasta 2025-10-17
  - Hoy:   powershell -NoProfile -ExecutionPolicy Bypass -File BD/RUN_recalculo_costos.ps1 -Modo hoy
  - Ayer:  powershell -NoProfile -ExecutionPolicy Bypass -File BD/RUN_recalculo_costos.ps1 -Modo ayer
Si no se especifica -Modo, por defecto usa 'hoy'.
============================================================================
#>

param(
  [ValidateSet('hoy','ayer','rango')]
  [string]$Modo = 'hoy',
  [string]$Desde,
  [string]$Hasta
)

$ErrorActionPreference = 'Stop'

function Get-EnvValue([string]$key) {
  $line = Get-Content -Path '.env' -ErrorAction Stop | Where-Object { $_ -match "^\s*$key\s*=" } | Select-Object -First 1
  if (-not $line) { throw "Clave $key no encontrada en .env" }
  $val = $line.Split('=',2)[1].Trim('"')
  return $val
}

function Parse-Date([string]$s) {
  $dt = [datetime]::MinValue
  if([string]::IsNullOrWhiteSpace($s)) { throw "Fecha vacia" }
  if([datetime]::TryParseExact($s, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$dt)) { return $dt }
  if([datetime]::TryParseExact($s, 'yyyy/MM/dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$dt)) { return $dt }
  if([datetime]::TryParseExact($s, 'dd-MM-yyyy', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$dt)) { return $dt }
  if([datetime]::TryParseExact($s, 'dd/MM/yyyy', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$dt)) { return $dt }
  throw "Fecha invalida: $s. Formatos validos: yyyy-MM-dd, dd/MM/yyyy"
}

try {
  $today = (Get-Date).Date
  switch ($Modo) {
    'hoy'  { $Desde = $today.ToString('yyyy-MM-dd'); $Hasta = $Desde }
    'ayer' { $Desde = $today.AddDays(-1).ToString('yyyy-MM-dd'); $Hasta = $Desde }
    'rango' {
      if([string]::IsNullOrWhiteSpace($Desde)) { throw "Debe especificar -Desde en modo rango" }
      if([string]::IsNullOrWhiteSpace($Hasta)) { $Hasta = $today.ToString('yyyy-MM-dd') }
    }
  }

  $dtDesde = Parse-Date $Desde
  $dtHasta = Parse-Date $Hasta
  if ($dtHasta -lt $dtDesde) { throw "Hasta ($Hasta) no puede ser menor que Desde ($Desde)" }

  $dbhost = Get-EnvValue 'DB_HOST'
  $dbport = Get-EnvValue 'DB_PORT'
  $dbname = Get-EnvValue 'DB_DATABASE'
  $dbuser = Get-EnvValue 'DB_USERNAME'
  $dbpass = Get-EnvValue 'DB_PASSWORD'
  $env:PGPASSWORD = $dbpass

  $psqlPaths = @(
    'C:\\Program Files (x86)\\PostgreSQL\\9.5\\bin\\psql.exe',
    'C:\\Program Files\\PostgreSQL\\9.5\\bin\\psql.exe',
    'psql.exe'
  )
  $psql = $null
  foreach($p in $psqlPaths){ if(Test-Path $p){ $psql = $p; break } }
  if (-not $psql) { $psql = (Get-Command psql.exe -ErrorAction Stop).Source }

  $desdeSql = $dtDesde.ToString('yyyy-MM-dd')
  $hastaSql = $dtHasta.ToString('yyyy-MM-dd')

  $logDir = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath 'logs'
  if(-not (Test-Path $logDir)){ New-Item -ItemType Directory -Path $logDir | Out-Null }
  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $logFile = Join-Path $logDir ("recalculo_costos_${stamp}.log")

  Write-Host "Ejecutando recalcular_costos_periodo ($desdeSql -> $hastaSql)" -ForegroundColor Cyan
  $sql = "SELECT selemti.recalcular_costos_periodo(DATE '$desdeSql', DATE '$hastaSql');"
  $result = & "$psql" -h $dbhost -p $dbport -U $dbuser -d $dbname -t -A -c $sql 2>&1
  $exit = $LASTEXITCODE

  Set-Content -Path $logFile -Value ("[{0}] Host={1}:{2} DB={3}`nModo={4} Rango={5}..{6}`nSQL: {7}`nSalidas:`n{8}" -f $stamp,$dbhost,$dbport,$dbname,$Modo,$desdeSql,$hastaSql,$sql,($result -join "`n")) -Encoding UTF8

  if ($exit -ne 0) { throw "psql terminó con código $exit. Ver log: $logFile" }

  $count = 0
  foreach($line in $result){ if([int]::TryParse($line.Trim(), [ref]$count)){ break } }
  Write-Host ("Inserciones/actualizaciones registradas: {0}" -f $count) -ForegroundColor Green
  Write-Host ("Log: {0}" -f $logFile)

} catch {
  Write-Host ("[ERROR] $_") -ForegroundColor Red
  exit 1
}

