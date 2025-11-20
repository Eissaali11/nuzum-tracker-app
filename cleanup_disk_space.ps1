# Comprehensive Disk Space Cleanup Script
# سكريبت شامل لتحرير المساحة على القرص

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Disk Space Cleanup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check space before cleanup
Write-Host "Space before cleanup:" -ForegroundColor Yellow
$before = Get-PSDrive C
Write-Host "  Free: $([math]::Round($before.Free / 1GB, 2)) GB" -ForegroundColor Yellow
Write-Host ""

# 1. Clean Flutter temp files
Write-Host "[1/6] Cleaning Flutter temp files..." -ForegroundColor Green
$flutterTemp = Get-ChildItem "$env:LOCALAPPDATA\Temp\flutter_tools*" -Recurse -ErrorAction SilentlyContinue
if ($flutterTemp) {
    $flutterSize = ($flutterTemp | Measure-Object -Property Length -Sum).Sum
    Remove-Item "$env:LOCALAPPDATA\Temp\flutter_tools*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Deleted: $([math]::Round($flutterSize / 1MB, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "  No Flutter temp files found" -ForegroundColor Gray
}

# 2. Clean old Temp files (older than 1 day)
Write-Host "[2/6] Cleaning old Temp files..." -ForegroundColor Green
$oldTemp = Get-ChildItem "$env:LOCALAPPDATA\Temp" -ErrorAction SilentlyContinue | 
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-1) -and $_.PSIsContainer -eq $false}
if ($oldTemp) {
    $oldTempSize = ($oldTemp | Measure-Object -Property Length -Sum).Sum
    $oldTemp | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  Deleted: $([math]::Round($oldTempSize / 1MB, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "  No old files found" -ForegroundColor Gray
}

# 3. Clean Gradle Cache (partial - only old files)
Write-Host "[3/6] Cleaning Gradle Cache..." -ForegroundColor Green
$gradleCache = "$env:USERPROFILE\.gradle\caches"
if (Test-Path $gradleCache) {
    $gradleOld = Get-ChildItem "$gradleCache\transforms-*" -Recurse -ErrorAction SilentlyContinue | 
        Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)}
    if ($gradleOld) {
        $gradleSize = ($gradleOld | Measure-Object -Property Length -Sum).Sum
        $gradleOld | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Deleted: $([math]::Round($gradleSize / 1MB, 2)) MB from Gradle Cache" -ForegroundColor Green
    } else {
        Write-Host "  No old Gradle files found" -ForegroundColor Gray
    }
} else {
    Write-Host "  Gradle folder not found" -ForegroundColor Gray
}

# 4. Clean Flutter Build Files
Write-Host "[4/6] Cleaning Flutter Build files..." -ForegroundColor Green
if (Test-Path "build") {
    $buildSize = (Get-ChildItem "build" -Recurse -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum).Sum
    Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Deleted: $([math]::Round($buildSize / 1MB, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "  No build folder found" -ForegroundColor Gray
}

# 5. Clean .dart_tool
Write-Host "[5/6] Cleaning .dart_tool..." -ForegroundColor Green
if (Test-Path ".dart_tool") {
    $dartToolSize = (Get-ChildItem ".dart_tool" -Recurse -ErrorAction SilentlyContinue | 
        Measure-Object -Property Length -Sum).Sum
    Remove-Item ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Deleted: $([math]::Round($dartToolSize / 1MB, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "  No .dart_tool folder found" -ForegroundColor Gray
}

# 6. Clean additional Windows temp files
Write-Host "[6/6] Cleaning Windows temp files..." -ForegroundColor Green
$winTemp = Get-ChildItem "$env:TEMP" -ErrorAction SilentlyContinue | 
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7) -and $_.PSIsContainer -eq $false}
if ($winTemp) {
    $winTempSize = ($winTemp | Measure-Object -Property Length -Sum).Sum
    $winTemp | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  Deleted: $([math]::Round($winTempSize / 1MB, 2)) MB" -ForegroundColor Green
} else {
    Write-Host "  No old files found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Space after cleanup:" -ForegroundColor Yellow
$after = Get-PSDrive C
$freed = $after.Free - $before.Free
Write-Host "  Free: $([math]::Round($after.Free / 1GB, 2)) GB" -ForegroundColor Green
if ($freed -gt 0) {
    Write-Host "  Freed: $([math]::Round($freed / 1GB, 2)) GB" -ForegroundColor Green
} else {
    Write-Host "  Freed: 0 GB (files may have been deleted already)" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host ""
