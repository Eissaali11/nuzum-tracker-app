# سكريبت إصلاح مشاكل المشروع الشامل
# تاريخ الإنشاء: $(Get-Date -Format "yyyy-MM-dd")

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  سكريبت إصلاح مشاكل المشروع" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# التحقق من المساحة الحالية
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
$usedPercent = [math]::Round(($drive.Used / ($drive.Used + $drive.Free)) * 100, 2)
Write-Host "المساحة الحالية:" -ForegroundColor Yellow
Write-Host "  - المتاحة: $freeGB GB" -ForegroundColor $(if ($freeGB -lt 15) { "Red" } else { "Green" })
Write-Host "  - المستخدمة: $usedPercent%" -ForegroundColor $(if ($usedPercent -gt 90) { "Red" } else { "Green" })
Write-Host ""

# المرحلة 1: تنظيف Gradle
Write-Host "[1/5] تنظيف Gradle Cache..." -ForegroundColor Yellow
try {
    $gradleCache = "$env:USERPROFILE\.gradle\caches"
    if (Test-Path $gradleCache) {
        $sizeBefore = (Get-ChildItem $gradleCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        Remove-Item $gradleCache -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ تم حذف $([math]::Round($sizeBefore, 2)) GB من Gradle Cache" -ForegroundColor Green
    } else {
        Write-Host "  ℹ لا يوجد Gradle Cache" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ✗ خطأ في تنظيف Gradle: $_" -ForegroundColor Red
}

# المرحلة 2: تنظيف Flutter
Write-Host "[2/5] تنظيف Flutter Cache..." -ForegroundColor Yellow
try {
    # Flutter tools temp
    $flutterTemp = Get-ChildItem "$env:LOCALAPPDATA\Temp\flutter_tools*" -Recurse -ErrorAction SilentlyContinue
    if ($flutterTemp) {
        $sizeBefore = ($flutterTemp | Measure-Object -Property Length -Sum).Sum / 1GB
        $flutterTemp | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ تم حذف $([math]::Round($sizeBefore, 2)) GB من Flutter Temp" -ForegroundColor Green
    }
    
    # Pub cache (اختياري - يحذف الحزم المثبتة)
    Write-Host "  ⚠ تخطي Pub Cache (لحماية الحزم المثبتة)" -ForegroundColor Yellow
} catch {
    Write-Host "  ✗ خطأ في تنظيف Flutter: $_" -ForegroundColor Red
}

# المرحلة 3: تنظيف Android
Write-Host "[3/5] تنظيف Android Cache..." -ForegroundColor Yellow
try {
    $androidTemp = "$env:LOCALAPPDATA\Android\Sdk\.temp"
    if (Test-Path $androidTemp) {
        $sizeBefore = (Get-ChildItem $androidTemp -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        Remove-Item $androidTemp -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ تم حذف $([math]::Round($sizeBefore, 2)) GB من Android Temp" -ForegroundColor Green
    } else {
        Write-Host "  ℹ لا يوجد Android Temp" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ✗ خطأ في تنظيف Android: $_" -ForegroundColor Red
}

# المرحلة 4: تنظيف Windows Temp
Write-Host "[4/5] تنظيف Windows Temp (الملفات الأقدم من 7 أيام)..." -ForegroundColor Yellow
try {
    $oldFiles = Get-ChildItem "$env:TEMP" -ErrorAction SilentlyContinue | 
        Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)}
    if ($oldFiles) {
        $sizeBefore = ($oldFiles | Measure-Object -Property Length -Sum).Sum / 1GB
        $oldFiles | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ تم حذف $([math]::Round($sizeBefore, 2)) GB من Temp القديمة" -ForegroundColor Green
    } else {
        Write-Host "  ℹ لا توجد ملفات قديمة في Temp" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ✗ خطأ في تنظيف Temp: $_" -ForegroundColor Red
}

# المرحلة 5: تنظيف المشروع
Write-Host "[5/5] تنظيف ملفات البناء في المشروع..." -ForegroundColor Yellow
try {
    $projectPath = "C:\Users\user\nuzum-tracker-app"
    if (Test-Path $projectPath) {
        Set-Location $projectPath
        
        # flutter clean
        Write-Host "  - تشغيل flutter clean..." -ForegroundColor Gray
        flutter clean 2>&1 | Out-Null
        
        # حذف build و .dart_tool
        if (Test-Path "build") {
            Remove-Item "build" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ تم حذف مجلد build" -ForegroundColor Green
        }
        
        Write-Host "  ✓ تم تنظيف المشروع" -ForegroundColor Green
    } else {
        Write-Host "  ✗ مسار المشروع غير موجود: $projectPath" -ForegroundColor Red
    }
} catch {
    Write-Host "  ✗ خطأ في تنظيف المشروع: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  النتيجة النهائية" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# عرض المساحة بعد التنظيف
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
$usedPercent = [math]::Round(($drive.Used / ($drive.Used + $drive.Free)) * 100, 2)

Write-Host "المساحة بعد التنظيف:" -ForegroundColor Yellow
Write-Host "  - المتاحة: $freeGB GB" -ForegroundColor $(if ($freeGB -lt 15) { "Red" } else { "Green" })
Write-Host "  - المستخدمة: $usedPercent%" -ForegroundColor $(if ($usedPercent -gt 90) { "Red" } else { "Green" })
Write-Host ""

if ($freeGB -lt 15) {
    Write-Host "⚠ تحذير: المساحة المتاحة لا تزال أقل من 15 GB" -ForegroundColor Red
    Write-Host "  يُنصح بتحرير مساحة إضافية يدوياً:" -ForegroundColor Yellow
    Write-Host "  1. استخدام 'تنظيف القرص' في Windows" -ForegroundColor White
    Write-Host "  2. حذف التطبيقات غير المستخدمة" -ForegroundColor White
    Write-Host "  3. نقل الملفات الكبيرة إلى قرص آخر" -ForegroundColor White
} else {
    Write-Host "✓ المساحة كافية للبناء!" -ForegroundColor Green
}

Write-Host ""
Write-Host "الخطوات التالية:" -ForegroundColor Cyan
Write-Host "  1. تشغيل: flutter pub get" -ForegroundColor White
Write-Host "  2. تشغيل: flutter build apk --debug" -ForegroundColor White
Write-Host ""

