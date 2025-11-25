# سكريبت تنظيف شامل لتحرير مساحة القرص
Write-Host "🧹 بدء تنظيف القرص..." -ForegroundColor Cyan

# 1. تنظيف ملفات Flutter
Write-Host "`n📦 تنظيف ملفات Flutter..." -ForegroundColor Yellow
flutter clean 2>$null
Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "✅ تم تنظيف ملفات Flutter" -ForegroundColor Green

# 2. تنظيف ملفات Gradle المؤقتة
Write-Host "`n📦 تنظيف ملفات Gradle..." -ForegroundColor Yellow
$gradleCache = "$env:USERPROFILE\.gradle\caches"
if (Test-Path $gradleCache) {
    Get-ChildItem -Path $gradleCache -Recurse -ErrorAction SilentlyContinue | 
        Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | 
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ تم تنظيف ملفات Gradle القديمة" -ForegroundColor Green
}

# 3. تنظيف ملفات Pub Cache القديمة
Write-Host "`n📦 تنظيف ملفات Pub Cache..." -ForegroundColor Yellow
$pubCache = "$env:USERPROFILE\.pub-cache"
if (Test-Path $pubCache) {
    Get-ChildItem -Path $pubCache -Recurse -ErrorAction SilentlyContinue | 
        Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-60)} | 
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ تم تنظيف ملفات Pub Cache القديمة" -ForegroundColor Green
}

# 4. تنظيف ملفات Windows Temp
Write-Host "`n📦 تنظيف ملفات Windows Temp..." -ForegroundColor Yellow
$tempDirs = @(
    "$env:LOCALAPPDATA\Temp",
    "$env:TEMP",
    "$env:WINDIR\Temp"
)
foreach ($tempDir in $tempDirs) {
    if (Test-Path $tempDir) {
        Get-ChildItem -Path $tempDir -Recurse -ErrorAction SilentlyContinue | 
            Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | 
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "✅ تم تنظيف ملفات Temp" -ForegroundColor Green

# 5. تنظيف ملفات Recycle Bin
Write-Host "`n📦 تنظيف سلة المحذوفات..." -ForegroundColor Yellow
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Host "✅ تم تنظيف سلة المحذوفات" -ForegroundColor Green

# 6. عرض المساحة المتاحة
Write-Host "`n💾 المساحة المتاحة على القرص:" -ForegroundColor Cyan
Get-PSDrive -PSProvider FileSystem | 
    Where-Object {$_.Name -eq "C"} | 
    Select-Object Name, 
        @{Name="Used(GB)";Expression={[math]::Round($_.Used/1GB,2)}}, 
        @{Name="Free(GB)";Expression={[math]::Round($_.Free/1GB,2)}} | 
    Format-Table -AutoSize

Write-Host "`n✅ اكتمل التنظيف!" -ForegroundColor Green
Write-Host "💡 نصيحة: إذا كانت المساحة لا تزال قليلة، قم بحذف:" -ForegroundColor Yellow
Write-Host "   - ملفات التطبيقات غير المستخدمة" -ForegroundColor Yellow
Write-Host "   - ملفات الفيديو والصور الكبيرة" -ForegroundColor Yellow
Write-Host "   - ملفات التحميلات القديمة" -ForegroundColor Yellow
