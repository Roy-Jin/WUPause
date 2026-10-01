[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
#  Windows 更新暂停工具
$Version = "v1.2.0"
$Author = "Roy-Jin (GitHub)"
# ============================================================

# 注册表路径与要写入的键值
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

# 写入暂停键值
function Set-WUUX {
    if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

    Write-Host "  [+] 正在暂停 Windows 更新..." -ForegroundColor Yellow
    Write-Host "  ============================================" -ForegroundColor Cyan
    
    foreach ($key in $StringItems.Keys) {
        try {
            New-ItemProperty -Path $RegPath -Name $key -Value $StringItems[$key] -PropertyType String -Force | Out-Null
            Write-Host "    [OK] 写入成功: $key" -ForegroundColor Green
        }
        catch {
            Write-Host "    [ERR] 写入失败: $key" -ForegroundColor Red
        }
    }

    foreach ($key in $DWordItems.Keys) {
        try {
            New-ItemProperty -Path $RegPath -Name $key -Value $DWordItems[$key] -PropertyType DWord -Force | Out-Null
            Write-Host "    [OK] 写入成功: $key" -ForegroundColor Green
        }
        catch {
            Write-Host "    [ERR] 写入失败: $key" -ForegroundColor Red
        }
    }
    
    Write-Host "`n  完成！Windows 更新已被暂停。" -ForegroundColor Green
    Write-Host "  系统更新已被禁用" -ForegroundColor Gray
}

# 删除暂停键值，恢复更新
function Remove-WUUX {
    if (-not (Test-Path $RegPath)) {
        Write-Host "  [INFO] 未发现注册表路径，无需删除。" -ForegroundColor Yellow
        return
    }
    
    Write-Host "  [+] 正在恢复 Windows 更新..." -ForegroundColor Yellow
    Write-Host "  ============================================" -ForegroundColor Cyan
    
    foreach ($key in $StringItems.Keys) {
        Remove-ItemProperty -Path $RegPath -Name $key -Force -ErrorAction SilentlyContinue
        Write-Host "    [OK] 已删除: $key" -ForegroundColor Green
    }
    foreach ($key in $DWordItems.Keys) {
        Remove-ItemProperty -Path $RegPath -Name $key -Force -ErrorAction SilentlyContinue
        Write-Host "    [OK] 已删除: $key" -ForegroundColor Green
    }
    
    Write-Host "`n  完成！Windows 更新已恢复。" -ForegroundColor Green
    Write-Host "  系统将恢复检查更新状态" -ForegroundColor Gray
}

# 查看注册表状态及所有值
function Get-WUUXStatus {
    Write-Host "  [?] 正在查询 Windows 更新注册表状态..." -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor Cyan
    
    # 检查注册表路径是否存在
    if (-not (Test-Path $RegPath)) {
        Write-Host "    [INFO] 注册表路径不存在，未设置任何值。" -ForegroundColor Yellow
        Write-Host "    Windows 更新处于正常状态" -ForegroundColor Gray
        return
    }
    
    # 获取注册表所有属性
    $prop = Get-ItemProperty -Path $RegPath -ErrorAction SilentlyContinue
    
    # 显示暂停相关键值
    Write-Host "  暂停相关键值:" -ForegroundColor Cyan
    foreach ($key in $StringItems.Keys) {
        if ($prop.$key) {
            Write-Host "    $key : $($prop.$key)" -ForegroundColor Green
        }
        else {
            Write-Host "    $key : 未设置" -ForegroundColor Gray
        }
    }
    foreach ($key in $DWordItems.Keys) {
        if ($prop.$key) {
            Write-Host "    $key : $($prop.$key)" -ForegroundColor Green
        }
        else {
            Write-Host "    $key : 未设置" -ForegroundColor Gray
        }
    }
    
    # 显示所有非暂停相关的键值（如果存在）
    $allProperties = $prop.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
    $otherProps = $allProperties | Where-Object { 
        $name = $_.Name
        -not ($StringItems.ContainsKey($name) -or $DWordItems.ContainsKey($name))
    }
    
    if ($otherProps.Count -gt 0) {
        Write-Host "`n  其他注册表键值:" -ForegroundColor Cyan
        foreach ($item in $otherProps) {
            Write-Host "    $($item.Name) : $($item.Value)" -ForegroundColor Gray
        }
    }
    
    Write-Host "  -----------------------------------------------" -ForegroundColor DarkGray
    Write-Host "`n  注册表路径: $RegPath" -ForegroundColor Gray
}

# 显示主界面
function Show-TUI {
    Clear-Host
    $line = "  ============================================================"
    Write-Host $line -ForegroundColor Cyan
    Write-Host "   Windows 更新暂停工具" -ForegroundColor White
    Write-Host "   版本: $Version    作者: $Author" -ForegroundColor DarkGray
    Write-Host "   需要帮助或反馈: https://github.com/Roy-Jin/WUPause/issues" -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   当前用户: $CurrentUser    计算机: $ComputerName" -ForegroundColor Gray
    Write-Host ""
    
    # 查询并显示当前状态
    $prop = if (Test-Path $RegPath) { Get-ItemProperty -Path $RegPath -ErrorAction SilentlyContinue }
    if ($prop.PauseUpdatesExpiryTime) {
        Write-Host "   当前状态: 已暂停" -ForegroundColor Red
    }
    else {
        Write-Host "   当前状态: 正常（未暂停）" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "   -----------------------------------------------" -ForegroundColor DarkGray
    Write-Host "   [1] 暂停 Windows 更新 (写入注册表)" -ForegroundColor Green
    Write-Host "   [2] 恢复 Windows 更新 (删除注册表)" -ForegroundColor Yellow
    Write-Host "   [3] 查看注册表状态 (列出所有值)" -ForegroundColor Cyan
    Write-Host "   [0] 退出程序" -ForegroundColor Gray
    Write-Host "   -----------------------------------------------" -ForegroundColor DarkGray
}

# 主循环
$again = $true
Show-TUI
while ($again) {
    $choice = Read-Host "`n  请输入选项 (1/2/3/0)"
    switch ($choice) {
        '1' {
            Clear-Host
            Set-WUUX
            Read-Host "`n  按 Enter 返回菜单"
        }
        '2' {
            Clear-Host
            Remove-WUUX
            Read-Host "`n  按 Enter 返回菜单"
        }
        '3' {
            Clear-Host
            Get-WUUXStatus
            Read-Host "`n  按 Enter 返回菜单"
        }
        '0' {
            $again = $false
            Write-Host "`n  感谢使用，再见！" -ForegroundColor Cyan
        }
        default {
            Write-Host "  [ERR] 无效选项，请重新输入。" -ForegroundColor Red
        }
    }
    if ($again) { Show-TUI }
}