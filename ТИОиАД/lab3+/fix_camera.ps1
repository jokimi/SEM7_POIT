# Скрипт для исправления проблем с камерой
# Запустите в PowerShell от имени администратора

# 1. Перезагрузка служб камеры
Write-Host "Перезагрузка служб камеры..." -ForegroundColor Yellow
Get-Service | Where-Object {$_.Name -like "*camera*"} | Restart-Service -Force

# 2. Сброс настроек приватности (требуется перезагрузка)
Write-Host "Сброс настроек приватности..." -ForegroundColor Yellow
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam"
if (Test-Path $regPath) {
    Remove-Item $regPath -Recurse -Force
}

# 3. Перезагрузка устройства
Write-Host "Вы хотите перезагрузить компьютер? (y/n)" -ForegroundColor Red
$reboot = Read-Host "Введите 'y' для перезагрузки, 'n' для выхода"
if ($reboot -eq 'y') {
    Restart-Computer -Force
}