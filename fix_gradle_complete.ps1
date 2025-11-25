Write-Host "Completely fixing Gradle cache..." -ForegroundColor Red

# Stop all Gradle daemons first
Write-Host "Stopping Gradle daemons..." -ForegroundColor Yellow
$gradleHome = "$env:USERPROFILE\.gradle"
if (Test-Path "$gradleHome\daemon") {
    Remove-Item -Path "$gradleHome\daemon" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Stopped Gradle daemons" -ForegroundColor Green
}

# Delete entire Gradle cache directory
Write-Host "Deleting entire Gradle cache..." -ForegroundColor Yellow
if (Test-Path "$gradleHome\caches") {
    $size = (Get-ChildItem "$gradleHome\caches" -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "Cache size: $([math]::Round($size, 2)) GB" -ForegroundColor Gray
    Remove-Item -Path "$gradleHome\caches" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted Gradle caches" -ForegroundColor Green
}

# Delete wrapper cache
if (Test-Path "$gradleHome\wrapper") {
    Remove-Item -Path "$gradleHome\wrapper" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted Gradle wrapper cache" -ForegroundColor Green
}

# Delete local .gradle in project
Write-Host "Deleting local .gradle..." -ForegroundColor Yellow
if (Test-Path "android\.gradle") {
    Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted local .gradle" -ForegroundColor Green
}

# Delete build folders
Write-Host "Deleting build folders..." -ForegroundColor Yellow
$buildDirs = @("build", "android\app\build", "android\build")
foreach ($dir in $buildDirs) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted $dir" -ForegroundColor Green
    }
}

Write-Host "`nDone! Now run: flutter clean && flutter pub get" -ForegroundColor Green



