# Safe Cleanup Script - لا يؤثر على بيانات Flutter الافتراضية
# Safe Cleanup - Does not affect Flutter default data

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Safe Cleanup - تنظيف آمن" -ForegroundColor Cyan
Write-Host "  لا يؤثر على Flutter SDK" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check space before cleanup
Write-Host "Space before cleanup:" -ForegroundColor Yellow
$before = Get-PSDrive C
Write-Host "  Free: $([math]::Round($before.Free / 1GB, 2)) GB" -ForegroundColor Yellow
Write-Host ""

$totalFreed = 0

# 1. Clean ONLY project build files (safe)
Write-Host "[1/5] Cleaning project build files..." -ForegroundColor Green
if (Test-Path "build") {
    $buildSize = (Get-ChildItem "build" -Recurse -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if ($buildSize) {
        Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue
        $totalFreed += $buildSize
        Write-Host "  Deleted: $([math]::Round($buildSize / 1MB, 2)) MB" -ForegroundColor Green
    } else {
        Write-Host "  Build folder is empty" -ForegroundColor Gray
    }
} else {
    Write-Host "  No build folder found" -ForegroundColor Gray
}

# 2. Clean .dart_tool in project only (safe)
Write-Host "[2/5] Cleaning project .dart_tool..." -ForegroundColor Green
if (Test-Path ".dart_tool") {
    $dartToolSize = (Get-ChildItem ".dart_tool" -Recurse -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if ($dartToolSize) {
        Remove-Item ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
        $totalFreed += $dartToolSize
        Write-Host "  Deleted: $([math]::Round($dartToolSize / 1MB, 2)) MB" -ForegroundColor Green
    } else {
        Write-Host "  .dart_tool folder is empty" -ForegroundColor Gray
    }
} else {
    Write-Host "  No .dart_tool folder found" -ForegroundColor Gray
}

# 3. Clean ONLY Flutter temp build files (NOT Flutter SDK)
Write-Host "[3/5] Cleaning Flutter temp build files..." -ForegroundColor Green
$flutterTempBuild = Get-ChildItem "$env:LOCALAPPDATA\Temp\flutter_tools*" -Recurse -ErrorAction SilentlyContinue | 
    Where-Object {$_.FullName -like "*flutter_tools*" -and $_.FullName -like "*build*" -or $_.FullName -like "*app.dill*"}
if ($flutterTempBuild) {
    $flutterTempSize = ($flutterTempBuild | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if ($flutterTempSize) {
        $flutterTempBuild | Remove-Item -Force -ErrorAction SilentlyContinue
        $totalFreed += $flutterTempSize
        Write-Host "  Deleted: $([math]::Round($flutterTempSize / 1MB, 2)) MB" -ForegroundColor Green
    }
} else {
    Write-Host "  No Flutter temp build files found" -ForegroundColor Gray
}

# 4. Clean Android build cache in project only (safe)
Write-Host "[4/5] Cleaning Android build cache..." -ForegroundColor Green
if (Test-Path "android\.gradle") {
    $androidGradleSize = (Get-ChildItem "android\.gradle" -Recurse -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if ($androidGradleSize) {
        Remove-Item "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
        $totalFreed += $androidGradleSize
        Write-Host "  Deleted: $([math]::Round($androidGradleSize / 1MB, 2)) MB" -ForegroundColor Green
    } else {
        Write-Host "  No Android gradle cache found" -ForegroundColor Gray
    }
} else {
    Write-Host "  No Android gradle cache found" -ForegroundColor Gray
}

# 5. Clean ONLY very old temp files (older than 30 days) - safe
Write-Host "[5/5] Cleaning very old temp files (30+ days)..." -ForegroundColor Green
$veryOldTemp = Get-ChildItem "$env:LOCALAPPDATA\Temp" -ErrorAction SilentlyContinue | 
    Where-Object {
        $_.LastWriteTime -lt (Get-Date).AddDays(-30) -and 
        $_.PSIsContainer -eq $false -and
        $_.Name -notlike "*flutter*" -and
        $_.Name -notlike "*dart*"
    }
if ($veryOldTemp) {
    $veryOldTempSize = ($veryOldTemp | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    if ($veryOldTempSize) {
        $veryOldTemp | Remove-Item -Force -ErrorAction SilentlyContinue
        $totalFreed += $veryOldTempSize
        Write-Host "  Deleted: $([math]::Round($veryOldTempSize / 1MB, 2)) MB" -ForegroundColor Green
    }
} else {
    Write-Host "  No very old temp files found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Results:" -ForegroundColor Yellow
$after = Get-PSDrive C
Write-Host "  Free space: $([math]::Round($after.Free / 1GB, 2)) GB" -ForegroundColor Green
Write-Host "  Total freed: $([math]::Round($totalFreed / 1MB, 2)) MB" -ForegroundColor Green
Write-Host ""
Write-Host "  Flutter SDK: Protected (not touched)" -ForegroundColor Green
Write-Host "  Flutter settings: Protected (not touched)" -ForegroundColor Green
Write-Host "  Project data: Protected (not touched)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Safe cleanup completed!" -ForegroundColor Green
Write-Host ""
