# PowerShell Script لتحرير مساحة القرص
# Run as Administrator

Write-Host "🧹 بدء تنظيف القرص..." -ForegroundColor Green

# 1. تنظيف Recycle Bin
Write-Host "`n1. تنظيف Recycle Bin..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "✅ تم تنظيف Recycle Bin" -ForegroundColor Green

# 2. تنظيف ملفات Temp
Write-Host "`n2. تنظيف ملفات Temp..." -ForegroundColor Yellow
$tempFolders = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "$env:WINDOWS\Temp"
)

foreach ($folder in $tempFolders) {
    if (Test-Path $folder) {
        Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue | 
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "✅ تم تنظيف: $folder" -ForegroundColor Green
    }
}

# 3. تنظيف Flutter Temp Files
Write-Host "`n3. تنظيف Flutter Temp Files..." -ForegroundColor Yellow
$flutterTemp = "$env:LOCALAPPDATA\Temp\flutter_tools.*"
Get-ChildItem -Path "$env:LOCALAPPDATA\Temp" -Filter "flutter_tools.*" -ErrorAction SilentlyContinue | 
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ تم تنظيف Flutter Temp Files" -ForegroundColor Green

# 4. تنظيف Windows Update Cache
Write-Host "`n4. تنظيف Windows Update Cache..." -ForegroundColor Yellow
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:WINDOWS\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Start-Service -Name wuauserv -ErrorAction SilentlyContinue
Write-Host "✅ تم تنظيف Windows Update Cache" -ForegroundColor Green

# 5. تنظيف Prefetch
Write-Host "`n5. تنظيف Prefetch..." -ForegroundColor Yellow
Remove-Item -Path "$env:WINDOWS\Prefetch\*" -Force -ErrorAction SilentlyContinue
Write-Host "✅ تم تنظيف Prefetch" -ForegroundColor Green

# 6. فحص المساحة بعد التنظيف
Write-Host "`n📊 المساحة بعد التنظيف:" -ForegroundColor Cyan
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
$usedPercent = [math]::Round(($drive.Used / ($drive.Used + $drive.Free)) * 100, 2)
Write-Host "المساحة الحرة: $freeGB GB" -ForegroundColor $(if ($freeGB -gt 5) { "Green" } else { "Red" })
Write-Host "النسبة المستخدمة: $usedPercent%" -ForegroundColor $(if ($usedPercent -lt 90) { "Green" } else { "Red" })

Write-Host "`n✅ اكتمل التنظيف!" -ForegroundColor Green

