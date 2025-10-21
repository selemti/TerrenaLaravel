# ======================================================================
# Exporta el resultado de una consulta SQL a Excel (.xlsx) si hay Excel
# instalado; si no, deja un CSV junto a la ruta indicada.
#
# Uso ejemplos:
#   -File BD/export_to_excel.ps1 -Sql "SELECT * FROM selemti.vw_kpis_sucursal_dia" -Out "C:\tmp\kpis_sucursal.xlsx" -Sheet KPIs
#   -File BD/export_to_excel.ps1 -View selemti.vw_stock_valorizado -Out .\out\stock_valorizado.xlsx
#
# Requiere .env con DB_HOST, DB_PORT, DB_DATABASE, DB_USERNAME, DB_PASSWORD
# ======================================================================

param(
  [string]$Sql,
  [string]$View,
  [Parameter(Mandatory=$true)][string]$Out,
  [string]$Sheet = 'Hoja1'
)

$ErrorActionPreference = 'Stop'

function Get-EnvValue([string]$key) {
  $line = Get-Content -Path '.env' -ErrorAction Stop | Where-Object { $_ -match "^\s*$key\s*=" } | Select-Object -First 1
  if (-not $line) { throw "Clave $key no encontrada en .env" }
  $val = $line.Split('=',2)[1].Trim('"')
  return $val
}

# Preparar SQL final
if([string]::IsNullOrWhiteSpace($Sql)){
  if([string]::IsNullOrWhiteSpace($View)){
    throw "Debe especificar -Sql o -View"
  }
  $Sql = "SELECT * FROM $View"
}

# Credenciales
$dbhost = Get-EnvValue 'DB_HOST'
$dbport = Get-EnvValue 'DB_PORT'
$dbname = Get-EnvValue 'DB_DATABASE'
$dbuser = Get-EnvValue 'DB_USERNAME'
$dbpass = Get-EnvValue 'DB_PASSWORD'
$env:PGPASSWORD = $dbpass

# Encontrar psql
$psqlPaths = @(
  'C:\\Program Files (x86)\\PostgreSQL\\9.5\\bin\\psql.exe',
  'C:\\Program Files\\PostgreSQL\\9.5\\bin\\psql.exe',
  'psql.exe'
)
$psql = $null
foreach($p in $psqlPaths){ if(Test-Path $p){ $psql = $p; break } }
if (-not $psql) { $psql = (Get-Command psql.exe -ErrorAction Stop).Source }

# Asegurar carpeta de salida
$Out = (Resolve-Path -LiteralPath (New-Item -ItemType File -Path $Out -Force)).Path
Remove-Item -LiteralPath $Out -Force
$outDir = Split-Path -Parent $Out
if(-not (Test-Path $outDir)){ New-Item -ItemType Directory -Path $outDir | Out-Null }

# Exportar a CSV temporal (UTF8 con BOM)
$tmpCsv = Join-Path $outDir ("export_" + [IO.Path]::GetFileNameWithoutExtension($Out) + ".csv")
$copySql = "COPY (" + $Sql + ") TO STDOUT WITH CSV HEADER"
$csv = & "$psql" -h $dbhost -p $dbport -U $dbuser -d $dbname -t -A -c $copySql 2>&1
$exit = $LASTEXITCODE
if($exit -ne 0){
  Write-Host "[ERROR] psql falló exportando CSV:" -ForegroundColor Red
  $csv | ForEach-Object { Write-Host $_ }
  throw "psql terminó con código $exit"
}
# Escribir CSV con BOM
Set-Content -Path $tmpCsv -Value ($csv -join "`n") -Encoding UTF8

# Intentar Excel COM
$excel = $null
try { $excel = New-Object -ComObject Excel.Application } catch {}
if($null -ne $excel){
  try {
    $excel.Visible = $false
    $wb = $excel.Workbooks.Open($tmpCsv)
    $ws = $wb.Worksheets.Item(1)
    $ws.Name = $Sheet
    $ws.UsedRange.EntireColumn.AutoFit() | Out-Null
    $wb.SaveAs($Out, 51) # xlOpenXMLWorkbook
    $wb.Close($true)
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ws) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    Remove-Item -LiteralPath $tmpCsv -Force
    Write-Host ("[OK] Exportado a {0}" -f $Out) -ForegroundColor Green
  } catch {
    if($excel){ try { $excel.Quit() } catch {} }
    Write-Host "[WARN] No se pudo usar Excel COM. Se deja CSV." -ForegroundColor Yellow
    Write-Host ("CSV: {0}" -f $tmpCsv)
  }
} else {
  Write-Host "[WARN] Excel no disponible. Se deja CSV." -ForegroundColor Yellow
  Write-Host ("CSV: {0}" -f $tmpCsv)
}

