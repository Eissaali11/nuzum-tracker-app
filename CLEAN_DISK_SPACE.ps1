# ============================================
# 🧹 تنظيف مساحة القرص - Clean Disk Space
# ============================================

Write-Host "🧹 بدء تنظيف مساحة القرص..." -ForegroundColor Cyan

# 1. تنظيف مجلدات البناء في المشروع
Write-Host "`n📁 تنظيف مجلدات البناء..." -ForegroundColor Yellow
$buildDirs = @(
    "build",
    ".dart_tool",
    "android\app\build",
    "android\.gradle",
    "android\build",
    "ios\build",
    "ios\Flutter\Flutter.framework",
    "ios\Flutter\Flutter.podspec"
)

foreach ($dir in $buildDirs) {
    if (Test-Path $dir) {
        $size = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB
        Write-Host "  حذف: $dir ($([math]::Round($size, 2)) MB)" -ForegroundColor Gray
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 2. تنظيف Gradle Cache
Write-Host "`n📦 تنظيف Gradle Cache..." -ForegroundColor Yellow
$gradleCache = "$env:USERPROFILE\.gradle\caches"
if (Test-Path $gradleCache) {
    $size = (Get-ChildItem $gradleCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "  حجم Gradle Cache: $([math]::Round($size, 2)) GB" -ForegroundColor Gray
    Remove-Item -Path "$gradleCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✅ تم تنظيف Gradle Cache" -ForegroundColor Green
}

# 3. تنظيف Flutter Build Cache
Write-Host "`n📱 تنظيف Flutter Build Cache..." -ForegroundColor Yellow
$flutterBuildCache = "$env:LOCALAPPDATA\Pub\Cache"
if (Test-Path $flutterBuildCache) {
    $size = (Get-ChildItem $flutterBuildCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "  حجم Flutter Cache: $([math]::Round($size, 2)) GB" -ForegroundColor Gray
    # لا نحذف كل شيء، فقط الملفات القديمة
    Write-Host "  ⚠️  Flutter Cache كبير جداً، يرجى حذفه يدوياً إذا لزم الأمر" -ForegroundColor Yellow
}

# 4. تنظيف ملفات Windows المؤقتة
Write-Host "`n🗑️  تنظيف ملفات Windows المؤقتة..." -ForegroundColor Yellow
$tempDirs = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp"
)

foreach ($tempDir in $tempDirs) {
    if (Test-Path $tempDir) {
        $files = Get-ChildItem $tempDir -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
        $size = ($files | Measure-Object -Property Length -Sum).Sum / 1MB
        if ($size -gt 0) {
            Write-Host "  حذف ملفات قديمة من $tempDir ($([math]::Round($size, 2)) MB)" -ForegroundColor Gray
            $files | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}

# 5. عرض المساحة المتاحة
Write-Host "`n💾 المساحة المتاحة على القرص:" -ForegroundColor Cyan
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
$usedGB = [math]::Round($drive.Used / 1GB, 2)
$totalGB = [math]::Round(($drive.Free + $drive.Used) / 1GB, 2)

Write-Host "  المساحة الحرة: $freeGB GB" -ForegroundColor $(if ($freeGB -lt 5) { "Red" } elseif ($freeGB -lt 10) { "Yellow" } else { "Green" })
Write-Host "  المساحة المستخدمة: $usedGB GB" -ForegroundColor Gray
Write-Host "  المساحة الإجمالية: $totalGB GB" -ForegroundColor Gray

if ($freeGB -lt 5) {
    Write-Host "`n⚠️  تحذير: المساحة الحرة قليلة جداً! يرجى تحرير مساحة إضافية." -ForegroundColor Red
    Write-Host "   اقتراحات:" -ForegroundColor Yellow
    Write-Host "   1. حذف الملفات غير المستخدمة" -ForegroundColor White
    Write-Host "   2. تفريغ سلة المحذوفات" -ForegroundColor White
    Write-Host "   3. استخدام أداة تنظيف القرص (Disk Cleanup)" -ForegroundColor White
    Write-Host "   4. حذف البرامج غير المستخدمة" -ForegroundColor White
}

Write-Host "`n✅ اكتمل التنظيف!" -ForegroundColor Green



