Write-Host "Cleaning disk space..." -ForegroundColor Cyan

# Clean build directories
$dirs = @("build", ".dart_tool", "android\app\build", "android\.gradle", "android\build")
foreach ($dir in $dirs) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Deleted: $dir" -ForegroundColor Green
    }
}

# Check free space
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
Write-Host "Free space: $freeGB GB" -ForegroundColor $(if ($freeGB -lt 5) { "Red" } else { "Green" })

if ($freeGB -lt 5) {
    Write-Host "WARNING: Low disk space! Please free more space." -ForegroundColor Red
}

Write-Host "Done!" -ForegroundColor Green



