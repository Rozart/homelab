# Install Glances system monitor on Windows
# Run as Administrator in PowerShell
#
# Target: PC (192.168.0.102)

$ErrorActionPreference = "Stop"

Write-Host "==> Installing Glances..." -ForegroundColor Cyan

pip install "glances[web]"

$glancesPath = (Get-Command glances).Source

Write-Host "==> Creating scheduled task to run Glances at startup..." -ForegroundColor Cyan

# Remove existing task if present
$existingTask = Get-ScheduledTask -TaskName "Glances" -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName "Glances" -Confirm:$false
}

$action = New-ScheduledTaskAction -Execute $glancesPath -Argument "-w --disable-webui"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0

Register-ScheduledTask -TaskName "Glances" -Action $action -Trigger $trigger -Principal $principal -Settings $settings

# Start it now
Start-ScheduledTask -TaskName "Glances"

Write-Host "==> Glances running on port 61208" -ForegroundColor Green
Write-Host "==> Verify: curl http://localhost:61208/api/4/quicklook" -ForegroundColor Green
