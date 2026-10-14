# ============================================================
#  Windows Update Pause Tool
$Version = "v1.3.0"
$Author = "Roy-Jin (GitHub)"
# ============================================================

$RegPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
$PauseStart = (Get-Date).AddDays(-1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$PauseEnd = "9999-01-01T00:00:00Z"
$StringItems = @{
    "PauseFeatureUpdatesEndTime"   = $PauseEnd
    "PauseFeatureUpdatesStartTime" = $PauseStart
    "PauseQualityUpdatesEndTime"   = $PauseEnd
    "PauseQualityUpdatesStartTime" = $PauseStart
    "PauseUpdatesExpiryTime"       = $PauseEnd
    "PauseUpdatesStartTime"        = $PauseStart
}
$DWordItems = @{
    "FlightSettingsMaxPauseDays" = 3650
}

$CurrentUser = [Environment]::UserName
$ComputerName = [Environment]::MachineName

function Set-WUUX {
    if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

    Write-Host "  [+] Pausing Windows Update..." -ForegroundColor Yellow
    Write-Host "  ============================================" -ForegroundColor Cyan
    
    foreach ($key in $StringItems.Keys) {
        try {
            New-ItemProperty -Path $RegPath -Name $key -Value $StringItems[$key] -PropertyType String -Force | Out-Null
            Write-Host "    [OK] Written: $key" -ForegroundColor Green
        } catch {
            Write-Host "    [ERR] Failed: $key" -ForegroundColor Red
        }
    }

    foreach ($key in $DWordItems.Keys) {
        try {
            New-ItemProperty -Path $RegPath -Name $key -Value $DWordItems[$key] -PropertyType DWord -Force | Out-Null
            Write-Host "    [OK] Written: $key" -ForegroundColor Green
        } catch {
            Write-Host "    [ERR] Failed: $key" -ForegroundColor Red
        }
    }
    
    Write-Host "`n  Done! Windows Update has been paused." -ForegroundColor Green
    Write-Host "  System updates are now disabled." -ForegroundColor Gray
}

function Remove-WUUX {
    if (-not (Test-Path $RegPath)) {
        Write-Host "  [INFO] Registry path not found. Nothing to remove." -ForegroundColor Yellow
        return
    }
    
    Write-Host "  [+] Resuming Windows Update..." -ForegroundColor Yellow
    Write-Host "  ============================================" -ForegroundColor Cyan
    
    foreach ($key in $StringItems.Keys) {
        Remove-ItemProperty -Path $RegPath -Name $key -Force -ErrorAction SilentlyContinue
        Write-Host "    [OK] Removed: $key" -ForegroundColor Green
    }
    foreach ($key in $DWordItems.Keys) {
        Remove-ItemProperty -Path $RegPath -Name $key -Force -ErrorAction SilentlyContinue
        Write-Host "    [OK] Removed: $key" -ForegroundColor Green
    }
    
    Write-Host "`n  Done! Windows Update has been resumed." -ForegroundColor Green
    Write-Host "  System will now check for updates normally." -ForegroundColor Gray
}

function Get-WUUXStatus {
    Write-Host "  [?] Querying Windows Update registry status..." -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    
    if (-not (Test-Path $RegPath)) {
        Write-Host "    [INFO] Registry path does not exist. No values set." -ForegroundColor Yellow
        Write-Host "    Windows Update is in normal state." -ForegroundColor Gray
        return
    }
    
    $prop = Get-ItemProperty -Path $RegPath -ErrorAction SilentlyContinue
    
    Write-Host "  Pause-related keys:" -ForegroundColor Cyan
    foreach ($key in $StringItems.Keys) {
        if ($prop.$key) {
            Write-Host "    $key : $($prop.$key)" -ForegroundColor Green
        } else {
            Write-Host "    $key : Not set" -ForegroundColor Gray
        }
    }
    foreach ($key in $DWordItems.Keys) {
        if ($prop.$key) {
            Write-Host "    $key : $($prop.$key)" -ForegroundColor Green
        } else {
            Write-Host "    $key : Not set" -ForegroundColor Gray
        }
    }
    
    $allProperties = $prop.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
    $otherProps = $allProperties | Where-Object { 
        $name = $_.Name
        -not ($StringItems.ContainsKey($name) -or $DWordItems.ContainsKey($name))
    }
    
    if ($otherProps.Count -gt 0) {
        Write-Host "`n  Other registry keys:" -ForegroundColor Cyan
        foreach ($item in $otherProps) {
            Write-Host "    $($item.Name) : $($item.Value)" -ForegroundColor Gray
        }
    }
    
    Write-Host "  -----------------------------------------------" -ForegroundColor DarkGray
    Write-Host "`n  Registry path: $RegPath" -ForegroundColor Gray
}

function Show-TUI {
    Clear-Host
    $line = "  ============================================================"
    Write-Host $line -ForegroundColor Cyan
    Write-Host "   Windows Update Pause Tool" -ForegroundColor White
    Write-Host "   Version: $Version    Author: $Author" -ForegroundColor DarkGray
    Write-Host "   Issues & Feedback: https://github.com/Roy-Jin/WUPause/issues" -ForegroundColor DarkGray
    Write-Host "   Current User: $CurrentUser    Computer: $ComputerName" -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
    
    $prop = if (Test-Path $RegPath) { Get-ItemProperty -Path $RegPath -ErrorAction SilentlyContinue }
    if ($prop.PauseUpdatesExpiryTime) {
        Write-Host "   Status: PAUSED" -ForegroundColor Red
    } else {
        Write-Host "   Status: NORMAL (Not paused)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "   -----------------------------------------------" -ForegroundColor DarkGray
    Write-Host "   [1] Pause Windows Update (Write registry)" -ForegroundColor Green
    Write-Host "   [2] Resume Windows Update (Remove registry)" -ForegroundColor Yellow
    Write-Host "   [3] View registry status (List all values)" -ForegroundColor Cyan
    Write-Host "   [0] Exit" -ForegroundColor Gray
    Write-Host "   -----------------------------------------------" -ForegroundColor DarkGray
}

$again = $true
Show-TUI
while ($again) {
    $choice = Read-Host "`n  Enter option (1/2/3/0)"
    switch ($choice) {
        '1' { Clear-Host; Set-WUUX; Read-Host "`n  Press Enter to return to menu" }
        '2' { Clear-Host; Remove-WUUX; Read-Host "`n  Press Enter to return to menu" }
        '3' { Clear-Host; Get-WUUXStatus; Read-Host "`n  Press Enter to return to menu" }
        '0' { $again = $false; Write-Host "`n  Thank you for using. Goodbye!" -ForegroundColor Cyan }
        default { Write-Host "  [ERR] Invalid option. Please try again." -ForegroundColor Red }
    }
    if ($again) { Show-TUI }
}