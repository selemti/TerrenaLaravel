param(
  [string] $HostName = '""'+"127.0.0.1"+'""',
  [int]    $Port     = 5433,
  [string] $Database = '""'+"pos"+'""',
  [string] $User     = '""'+"postgres"+'""',
  [string] $Password = '""'+"T3rr3n4#p0s"+'""',
  [string] $SqlFile  = (Get-ChildItem -Path "$PSScriptRoot" -Filter 'DEPLOY_CONSOLIDADO_FULL_PG95-v3-*.sql' | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName,
  [string] $LogFile  = (Join-Path $PSScriptRoot ("deploy_v3-" + (Get-Date -Format 'yyyyMMdd-HHmm') + ".log")),
  [string] $PsqlExe  = '""'+"psql"+'""'
)

function Resolve-Psql {
  param([string]$exe)
  try {
    $cmd = Get-Command $exe -ErrorAction Stop
    return $cmd.Source
  } catch {
    $cands = @(
      'C:\Program Files\PostgreSQL\9.5\bin\psql.exe',
      'C:\Program Files\PostgreSQL\9.6\bin\psql.exe',
      'C:\Program Files\PostgreSQL\10\bin\psql.exe',
      'C:\Program Files\PostgreSQL\11\bin\psql.exe',
      'C:\Program Files\PostgreSQL\12\bin\psql.exe',
      'C:\Program Files\PostgreSQL\13\bin\psql.exe',
      'C:\Program Files\PostgreSQL\14\bin\psql.exe',
      'C:\Program Files (x86)\PostgreSQL\9.5\bin\psql.exe'
    )
    foreach($p in $cands){ if (Test-Path $p) { return $p } }
    return $null
  }
}

if (-not (Test-Path $SqlFile)) { Write-Error "No se encontró SQL de deploy v3"; exit 1 }

$psqlPath = Resolve-Psql -exe $PsqlExe
if (-not $psqlPath) {
  Write-Error "No se encontró 'psql'. Usa -PsqlExe con ruta completa o agrega PostgreSQL bin a PATH"
  exit 1
}

Write-Host "Usando archivo SQL: $SqlFile"
Write-Host "Usando psql: $psqlPath"
$env:PGPASSWORD = $Password
& "$psqlPath" -h $HostName -p $Port -U $User -d $Database -v ON_ERROR_STOP=1 -f $SqlFile *>&1 | Tee-Object -FilePath $LogFile
if ($LASTEXITCODE -ne 0) { Write-Error "Deploy falló. Ver $LogFile"; exit 1 }
Write-Host "Deploy OK. Log: $LogFile"

