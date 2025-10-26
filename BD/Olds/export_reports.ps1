# ======================================================================
# Exporta a Excel varios reportes estándar apoyados en las vistas creadas
# Uso:
#   powershell -NoProfile -ExecutionPolicy Bypass -File BD/export_reports.ps1 -Desde 2025-09-01 -Hasta 2025-10-17 -OutDir .\exports
#   powershell -NoProfile -ExecutionPolicy Bypass -File BD/export_reports.ps1 -Hoy -OutDir .\exports
# ======================================================================

param(
  [string]$Desde,
  [string]$Hasta,
  [switch]$Hoy,
  [string]$OutDir = '.\\exports'
)

$ErrorActionPreference = 'Stop'

function Run-Export($Sql, $OutPath, $Sheet='Hoja1'){
  $script = Join-Path $PSScriptRoot 'export_to_excel.ps1'
  & powershell -NoProfile -ExecutionPolicy Bypass -File $script -Sql $Sql -Out $OutPath -Sheet $Sheet
}

# Rango por defecto
if($Hoy){
  $Desde = (Get-Date).ToString('yyyy-MM-dd')
  $Hasta = $Desde
} else {
  if([string]::IsNullOrWhiteSpace($Desde)){ throw "Debe indicar -Desde o -Hoy" }
  if([string]::IsNullOrWhiteSpace($Hasta)){ $Hasta = (Get-Date).ToString('yyyy-MM-dd') }
}

if(-not (Test-Path $OutDir)){ New-Item -ItemType Directory -Path $OutDir | Out-Null }

$tag = (Get-Date).ToString('yyyyMMdd_HHmmss')

Run-Export "SELECT * FROM selemti.vw_kpis_sucursal_dia WHERE fecha BETWEEN DATE '$Desde' AND DATE '$Hasta' ORDER BY fecha, sucursal_id" (Join-Path $OutDir ("kpis_sucursal_"+$tag+".xlsx")) 'KPIs'
Run-Export "SELECT * FROM selemti.vw_kpis_terminal_dia WHERE fecha BETWEEN DATE '$Desde' AND DATE '$Hasta' ORDER BY fecha, terminal_id" (Join-Path $OutDir ("kpis_terminal_"+$tag+".xlsx")) 'KPIs'
Run-Export "SELECT * FROM selemti.vw_ventas_por_familia WHERE fecha BETWEEN DATE '$Desde' AND DATE '$Hasta' ORDER BY fecha, familia" (Join-Path $OutDir ("ventas_familia_"+$tag+".xlsx")) 'Ventas'
Run-Export "SELECT * FROM selemti.vw_ventas_por_item WHERE fecha BETWEEN DATE '$Desde' AND DATE '$Hasta' ORDER BY fecha, sucursal_id, plu" (Join-Path $OutDir ("ventas_plu_"+$tag+".xlsx")) 'Ventas'
Run-Export "SELECT * FROM selemti.vw_ventas_por_hora WHERE hora::date BETWEEN DATE '$Desde' AND DATE '$Hasta' ORDER BY hora DESC" (Join-Path $OutDir ("ventas_hora_"+$tag+".xlsx")) 'VentasHora'
Run-Export "SELECT * FROM selemti.vw_stock_valorizado ORDER BY valor DESC" (Join-Path $OutDir ("stock_valorizado_"+$tag+".xlsx")) 'StockVal'
Run-Export "SELECT * FROM selemti.vw_consumo_vs_movimientos WHERE fecha BETWEEN DATE '$Desde' AND DATE '$Hasta' ORDER BY fecha DESC, sucursal_id" (Join-Path $OutDir ("consumo_vs_real_"+$tag+".xlsx")) 'Consumo'
Run-Export "SELECT * FROM selemti.vw_movimientos_anomalos ORDER BY ts DESC LIMIT 1000" (Join-Path $OutDir ("mov_anomalos_"+$tag+".xlsx")) 'Anomalias'

Write-Host "[OK] Exportes generados en: $OutDir" -ForegroundColor Green

