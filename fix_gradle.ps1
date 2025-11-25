Write-Host "Fixing Gradle cache issue..." -ForegroundColor Cyan

# Delete Gradle caches
$gradleHome = "$env:USERPROFILE\.gradle"
if (Test-Path "$gradleHome\caches") {
    Remove-Item -Path "$gradleHome\caches" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted Gradle caches" -ForegroundColor Green
}

if (Test-Path "$gradleHome\daemon") {
    Remove-Item -Path "$gradleHome\daemon" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted Gradle daemon" -ForegroundColor Green
}

# Delete local .gradle
if (Test-Path "android\.gradle") {
    Remove-Item -Path "android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted local .gradle" -ForegroundColor Green
}

Write-Host "Done! Now run: flutter clean && flutter pub get" -ForegroundColor Green



