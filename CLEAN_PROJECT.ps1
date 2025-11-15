# PowerShell Script لتنظيف المشروع بالكامل
# Clean Project Script

Write-Host "🧹 تنظيف المشروع لتحرير المساحة..." -ForegroundColor Green
Write-Host ""

$projectPath = Get-Location
$totalFreed = 0

# 1. تنظيف Flutter Build
Write-Host "1. تنظيف Flutter Build..." -ForegroundColor Yellow
$folders = @(
    "build",
    ".dart_tool",
    ".flutter-plugins",
    ".flutter-plugins-dependencies",
    ".packages",
    "pubspec.lock"
)

foreach ($folder in $folders) {
    $path = Join-Path $projectPath $folder
    if (Test-Path $path) {
        $size = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum
        if ($size) {
            $sizeMB = [math]::Round($size / 1MB, 2)
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   ✅ تم حذف $folder ($sizeMB MB)" -ForegroundColor Green
            $totalFreed += $size
        } else {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   ✅ تم حذف $folder" -ForegroundColor Green
        }
    }
}

# 2. تنظيف Android Build
Write-Host "2. تنظيف Android Build..." -ForegroundColor Yellow
$androidFolders = @(
    "android\app\build",
    "android\build",
    "android\.gradle",
    "android\app\.cxx",
    "android\.idea"
)

foreach ($folder in $androidFolders) {
    $path = Join-Path $projectPath $folder
    if (Test-Path $path) {
        $size = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum
        if ($size) {
            $sizeMB = [math]::Round($size / 1MB, 2)
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   ✅ تم حذف $folder ($sizeMB MB)" -ForegroundColor Green
            $totalFreed += $size
        } else {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   ✅ تم حذف $folder" -ForegroundColor Green
        }
    }
}

# 3. تنظيف iOS Build (إن وجد)
Write-Host "3. تنظيف iOS Build..." -ForegroundColor Yellow
$iosFolders = @(
    "ios\build",
    "ios\.symlinks",
    "ios\Pods",
    "ios\.flutter-plugins"
)

foreach ($folder in $iosFolders) {
    $path = Join-Path $projectPath $folder
    if (Test-Path $path) {
        $size = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum
        if ($size) {
            $sizeMB = [math]::Round($size / 1MB, 2)
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   ✅ تم حذف $folder ($sizeMB MB)" -ForegroundColor Green
            $totalFreed += $size
        }
    }
}

# 4. تنظيف ملفات IDE
Write-Host "4. تنظيف ملفات IDE..." -ForegroundColor Yellow
$ideFiles = @(
    ".idea",
    ".vscode",
    "*.iml",
    ".DS_Store"
)

foreach ($item in $ideFiles) {
    $path = Join-Path $projectPath $item
    if (Test-Path $path) {
        $size = (Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum
        if ($size) {
            $sizeMB = [math]::Round($size / 1MB, 2)
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   ✅ تم حذف $item ($sizeMB MB)" -ForegroundColor Green
            $totalFreed += $size
        }
    }
}

# 5. تنظيف ملفات Log
Write-Host "5. تنظيف ملفات Log..." -ForegroundColor Yellow
Get-ChildItem -Path $projectPath -Recurse -Include "*.log" -ErrorAction SilentlyContinue | 
    Remove-Item -Force -ErrorAction SilentlyContinue
Write-Host "   ✅ تم حذف ملفات Log" -ForegroundColor Green

# 6. تنظيف ملفات Temp
Write-Host "6. تنظيف ملفات Temp..." -ForegroundColor Yellow
Get-ChildItem -Path $projectPath -Recurse -Include "*.tmp", "*.temp" -ErrorAction SilentlyContinue | 
    Remove-Item -Force -ErrorAction SilentlyContinue
Write-Host "   ✅ تم حذف ملفات Temp" -ForegroundColor Green

# 7. تنظيف Coverage Reports
Write-Host "7. تنظيف Coverage Reports..." -ForegroundColor Yellow
$coveragePath = Join-Path $projectPath "coverage"
if (Test-Path $coveragePath) {
    Remove-Item -Path $coveragePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "   ✅ تم حذف Coverage Reports" -ForegroundColor Green
}

# النتيجة
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($totalFreed -gt 0) {
    $totalFreedMB = [math]::Round($totalFreed / 1MB, 2)
    $totalFreedGB = [math]::Round($totalFreed / 1GB, 2)
    Write-Host "✅ تم تحرير: $totalFreedMB MB ($totalFreedGB GB)" -ForegroundColor Green
} else {
    Write-Host "✅ تم تنظيف المشروع" -ForegroundColor Green
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

