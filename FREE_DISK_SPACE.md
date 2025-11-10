# تحرير مساحة على القرص

## المشكلة
خطأ: "There is not enough space on the disk"

## الحلول

### 1. حذف Gradle Cache (يوفر عدة GB)
```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches"
```

### 2. حذف Android Build Cache
```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Android\Sdk\.temp" -ErrorAction SilentlyContinue
```

### 3. حذف Flutter Build Cache
```powershell
flutter clean
```

### 4. التحقق من المساحة المتاحة
```powershell
Get-PSDrive C | Select-Object Used,Free
```

### 5. تنظيف Windows Temp Files
```powershell
Remove-Item -Recurse -Force "$env:TEMP\*" -ErrorAction SilentlyContinue
```

## ملاحظات
- يُنصح بتحرير **5-10 GB على الأقل** قبل محاولة البناء
- بعد تحرير المساحة، حاول البناء مرة أخرى:
  ```powershell
  flutter build apk --release
  ```

## التحذيرات حول Linux/Windows
التحذيرات حول `shared_preferences:linux` و `geolocator:windows` ليست مشكلة حقيقية لأن التطبيق يستهدف Android فقط. يمكن تجاهلها بأمان.

