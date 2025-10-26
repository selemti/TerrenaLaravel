# ======================================================================
# Registra (o remueve) una tarea programada para ejecutar el recÃ¡lculo
# Uso:
#   Registrar diaria 02:30:  -File BD/SCHEDULE_recalculo_costos.ps1 -Registrar -Hora "02:30" -Modo hoy
#   Remover:                 -File BD/SCHEDULE_recalculo_costos.ps1 -Remover
# ======================================================================

param(
  [switch]$Registrar,
  [switch]$Remover,
  [string]$Hora = '02:30',
  [ValidateSet('hoy','ayer')]
  [string]$Modo = 'hoy',
  [string]$Nombre = 'SelemtiRecalculoCostosDaily'
)

$ErrorActionPreference = 'Stop'

if(-not ($Registrar -xor $Remover)){
  Write-Host "Debe indicar -Registrar o -Remover" -ForegroundColor Yellow
  exit 1
}

$scriptPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'RUN_recalculo_costos.ps1'
if(-not (Test-Path $scriptPath)){
  Write-Host "No se encontrÃ³ RUN_recalculo_costos.ps1 en: $scriptPath" -ForegroundColor Red
  exit 1
}

if($Remover){
  if(Get-ScheduledTask -TaskName $Nombre -ErrorAction SilentlyContinue){
    Unregister-ScheduledTask -TaskName $Nombre -Confirm:$false
    Write-Host "Tarea '$Nombre' removida" -ForegroundColor Green
  } else {
    Write-Host "Tarea '$Nombre' no existe" -ForegroundColor Yellow
  }
  exit 0
}

# Registrar
$hh,$mm = $Hora.Split(':')
$time = [datetime]::Today.AddHours([int]$hh).AddMinutes([int]$mm)
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Modo $Modo"
$trigger = New-ScheduledTaskTrigger -Daily -At $time
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings (New-ScheduledTaskSettingsSet -Compatibility Win8 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries)

if(Get-ScheduledTask -TaskName $Nombre -ErrorAction SilentlyContinue){
  Unregister-ScheduledTask -TaskName $Nombre -Confirm:$false
}

Register-ScheduledTask -TaskName $Nombre -InputObject $task | Out-Null
Write-Host "Tarea '$Nombre' registrada diaria a las $Hora (Modo=$Modo)" -ForegroundColor Green


