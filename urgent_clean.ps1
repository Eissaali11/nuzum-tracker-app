# Urgent Disk Cleanup
Write-Host "Starting urgent cleanup..." -ForegroundColor Red

# Delete .dart_tool
if (Test-Path ".dart_tool") {
    Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted .dart_tool" -ForegroundColor Green
}

# Delete build folders
$buildFolders = @("build", "android\app\build", "android\build", "android\.gradle")
foreach ($folder in $buildFolders) {
    if (Test-Path $folder) {
        Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted $folder" -ForegroundColor Green
    }
}

# Clean Gradle cache
$gradleCache = "$env:USERPROFILE\.gradle\caches"
if (Test-Path $gradleCache) {
    Remove-Item -Path "$gradleCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned Gradle cache" -ForegroundColor Green
}

# Check free space
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
Write-Host "`nFree space: $freeGB GB" -ForegroundColor $(if ($freeGB -lt 2) { "Red" } else { "Green" })

if ($freeGB -lt 2) {
    Write-Host "`nWARNING: Still low on space! Please:" -ForegroundColor Red
    Write-Host "1. Empty Recycle Bin" -ForegroundColor Yellow
    Write-Host "2. Delete large files from Downloads" -ForegroundColor Yellow
    Write-Host "3. Run Windows Disk Cleanup (cleanmgr)" -ForegroundColor Yellow
    Write-Host "4. Uninstall unused programs" -ForegroundColor Yellow
}



