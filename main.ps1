[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================
#  Windows 更新暂停工具
$Version = "v1.0.0"
$Author  = "Roy-Jin (GitHub)"
# ============================================================

# 注册表路径与要写入的键值（均为 String 类型）
$RegPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
$ItemsToManage = @{
    "PauseFeatureUpdatesEndTime"   = "9999-01-01T00:00:00Z"
    "PauseFeatureUpdatesStartTime" = "2026-01-01T00:00:00Z"
    "PauseQualityUpdatesEndTime"   = "9999-01-01T00:00:00Z"
    "PauseQualityUpdatesStartTime" = "2026-01-01T00:00:00Z"
    "PauseUpdatesExpiryTime"       = "9999-01-01T00:00:00Z"
    "PauseUpdatesStartTime"        = "2026-01-01T00:00:00Z"
}

$CurrentUser  = [Environment]::UserName
$ComputerName = [Environment]::MachineName

# 写入暂停键值
function Set-WUUX {
    if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
    foreach ($key in $ItemsToManage.Keys) {
        try {
            New-ItemProperty -Path $RegPath -Name $key -Value $ItemsToManage[$key] -PropertyType String -Force | Out-Null
            Write-Host "    [OK] 写入成功: $key" -ForegroundColor Green
        } catch {
            Write-Host "    [ERR] 写入失败: $key" -ForegroundColor Red
        }
    }
}

# 删除暂停键值，恢复更新
function Remove-WUUX {
    if (-not (Test-Path $RegPath)) {
        Write-Host "    [INFO] 未发现注册表路径，无需删除。" -ForegroundColor Yellow
        return
    }
    foreach ($key in $ItemsToManage.Keys) {
        Remove-ItemProperty -Path $RegPath -Name $key -Force -ErrorAction SilentlyContinue
        Write-Host "    [OK] 已删除: $key" -ForegroundColor Green
    }
}

# 查询当前状态
function Get-WUUXStatus {
    Write-Host "  当前 Windows 更新状态：" -ForegroundColor Cyan
    $prop = if (Test-Path $RegPath) { Get-ItemProperty -Path $RegPath -ErrorAction SilentlyContinue }
    if ($prop.PauseUpdatesExpiryTime) {
        Write-Host "    状态: 已暂停" -ForegroundColor Red
    } else {
        Write-Host "    状态: 正常（未暂停）" -ForegroundColor Green
    }
}

# 显示主界面
function Show-TUI {
    Clear-Host
    $line = "  ============================================================"
    Write-Host $line -ForegroundColor Cyan
    Write-Host "   Windows 更新暂停工具" -ForegroundColor White
    Write-Host "   版本: $Version    作者: $Author" -ForegroundColor DarkGray
    Write-Host "   本脚本仅作演示用例使用，请勿用于生产环境。" -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   当前用户: $CurrentUser    计算机: $ComputerName" -ForegroundColor Gray
    Write-Host ""
    Get-WUUXStatus
    Write-Host ""
    Write-Host "   -----------------------------------------------" -ForegroundColor DarkGray
    Write-Host "   [1] 暂停 Windows 更新 (写入注册表)" -ForegroundColor Green
    Write-Host "   [2] 恢复 Windows 更新 (删除注册表)" -ForegroundColor Yellow
    Write-Host "   [3] 查看当前状态" -ForegroundColor Cyan
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
            Write-Host "`n  [+] 正在暂停 Windows 更新..." -ForegroundColor Yellow
            Set-WUUX
            Write-Host "`n  完成！Windows 更新已被暂停。" -ForegroundColor Green
            Read-Host "`n  按 Enter 返回菜单"
        }
        '2' {
            Write-Host "`n  [+] 正在恢复 Windows 更新..." -ForegroundColor Yellow
            Remove-WUUX
            Write-Host "`n  完成！Windows 更新已恢复。" -ForegroundColor Green
            Read-Host "`n  按 Enter 返回菜单"
        }
        '3' {
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
Read-Host "`n  按 Enter 退出窗口"