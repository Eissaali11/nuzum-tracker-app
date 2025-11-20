# Comprehensive Safe Cleanup - تنظيف شامل آمن
# لا يحذف أي بيانات Flutter الافتراضية

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Comprehensive Safe Cleanup" -ForegroundColor Cyan
Write-Host "  (No Flutter Data Loss)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$before = Get-PSDrive C
Write-Host "Space before: $([math]::Round($before.Free / 1GB, 2)) GB" -ForegroundColor Yellow
Write-Host ""

$totalFreed = 0

# 1. Project build files (100% safe)
Write-Host "[1/8] Cleaning project build files..." -ForegroundColor Green
if (Test-Path "build") {
    $size = (Get-ChildItem "build" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $size
    Write-Host "  Freed: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Green
}

# 2. .dart_tool (100% safe)
Write-Host "[2/8] Cleaning .dart_tool..." -ForegroundColor Green
if (Test-Path ".dart_tool") {
    $size = (Get-ChildItem ".dart_tool" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $size
    Write-Host "  Freed: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Green
}

# 3. Android build folders in project (safe)
Write-Host "[3/8] Cleaning Android build folders..." -ForegroundColor Green
if (Test-Path "android\.gradle") {
    $size = (Get-ChildItem "android\.gradle" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $size
    Write-Host "  Freed: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Green
}
if (Test-Path "android\app\build") {
    $size = (Get-ChildItem "android\app\build" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item "android\app\build" -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $size
    Write-Host "  Freed: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Green
}

# 4. Old Flutter temp files (7+ days - safe)
Write-Host "[4/8] Cleaning old Flutter temp files (7+ days)..." -ForegroundColor Green
$oldFlutter = Get-ChildItem "$env:LOCALAPPDATA\Temp\flutter_tools*" -Recurse -ErrorAction SilentlyContinue | 
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)}
if ($oldFlutter) {
    $size = ($oldFlutter | Measure-Object -Property Length -Sum).Sum
    $oldFlutter | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $totalFreed += $size
    Write-Host "  Freed: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Green
}

# 5. Old Gradle transforms (60+ days - safe, will re-download)
Write-Host "[5/8] Cleaning old Gradle transforms (60+ days)..." -ForegroundColor Green
if (Test-Path "$env:USERPROFILE\.gradle\caches\transforms-*") {
    $oldGradle = Get-ChildItem "$env:USERPROFILE\.gradle\caches\transforms-*" -Recurse -ErrorAction SilentlyContinue | 
        Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-60)}
    if ($oldGradle) {
        $size = ($oldGradle | Measure-Object -Property Length -Sum).Sum
        $oldGradle | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        $totalFreed += $size
        Write-Host "  Freed: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Green
    }
}

# 6. Old Windows temp files (30+ days - safe)
Write-Host "[6/8] Cleaning old Windows temp files (30+ days)..." -ForegroundColor Green
$oldTemp = Get-ChildItem "$env:LOCALAPPDATA\Temp" -ErrorAction SilentlyContinue | 
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30) -and $_.PSIsContainer -eq $false}
if ($oldTemp) {
    $size = ($oldTemp | Measure-Object -Property Length -Sum).Sum
    $oldTemp | Remove-Item -Force -ErrorAction SilentlyContinue
    $totalFreed += $size
    Write-Host "  Freed: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Green
}

# 7. Empty Recycle Bin (safe)
Write-Host "[7/8] Emptying Recycle Bin..." -ForegroundColor Green
try {
    $shell = New-Object -ComObject Shell.Application
    $recycleBin = $shell.NameSpace(0xA)
    $items = $recycleBin.Items()
    if ($items.Count -gt 0) {
        $recycleBin.InvokeVerb("delete")
        Write-Host "  Recycle Bin emptied" -ForegroundColor Green
    } else {
        Write-Host "  Recycle Bin already empty" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Could not empty Recycle Bin (may require admin)" -ForegroundColor Yellow
}

# 8. Windows Update cleanup (safe - old update files)
Write-Host "[8/8] Checking Windows Update cache..." -ForegroundColor Green
if (Test-Path "$env:SystemRoot\SoftwareDistribution\Download") {
    $updateFiles = Get-ChildItem "$env:SystemRoot\SoftwareDistribution\Download" -Recurse -ErrorAction SilentlyContinue | 
        Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-90)}
    if ($updateFiles) {
        $size = ($updateFiles | Measure-Object -Property Length -Sum).Sum
        Write-Host "  Found old update files: $([math]::Round($size / 1MB, 2)) MB" -ForegroundColor Yellow
        Write-Host "  (Use Windows Disk Cleanup to remove safely)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
$after = Get-PSDrive C
Write-Host "Space after: $([math]::Round($after.Free / 1GB, 2)) GB" -ForegroundColor Green
Write-Host "Total freed: $([math]::Round($totalFreed / 1MB, 2)) MB" -ForegroundColor Green
Write-Host ""
Write-Host "Protected (NOT deleted):" -ForegroundColor Yellow
Write-Host "  - Flutter SDK (C:\flutter)" -ForegroundColor Gray
Write-Host "  - Pub Cache" -ForegroundColor Gray
Write-Host "  - Android SDK" -ForegroundColor Gray
Write-Host "  - Recent files (< 7 days)" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Safe cleanup completed!" -ForegroundColor Green
Write-Host ""

