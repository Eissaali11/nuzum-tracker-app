# 💾 حل مشكلة مساحة القرص - Disk Space Solution

**المشكلة:** `There is not enough space on the disk`

---

## 🔍 المشكلة

Flutter يحتاج مساحة كافية على القرص لبناء التطبيق. الخطأ يحدث عندما:
- القرص C: ممتلئ
- ملفات Flutter المؤقتة تشغل مساحة كبيرة
- Build cache كبير

---

## ✅ الحلول السريعة

### 1. تنظيف Flutter Build Cache

```bash
flutter clean
```

### 2. تنظيف ملفات Flutter المؤقتة

```powershell
# Windows PowerShell
Remove-Item -Path "$env:LOCALAPPDATA\Temp\flutter_tools.*" -Recurse -Force
```

### 3. تنظيف Flutter Pub Cache

```bash
flutter pub cache repair
```

### 4. تنظيف Build Folder

```bash
# في مجلد المشروع
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
```

---

## 🧹 تنظيف شامل

### Windows Disk Cleanup:

1. **افتح Disk Cleanup:**
   - اضغط `Win + R`
   - اكتب `cleanmgr`
   - اضغط Enter

2. **اختر القرص C:**
   - اختر "Temporary files"
   - اختر "Recycle Bin"
   - اختر "Thumbnails"
   - اضغط "OK"

### تنظيف Flutter Cache يدوياً:

```powershell
# تنظيف Flutter cache
Remove-Item -Path "$env:LOCALAPPDATA\Pub\Cache" -Recurse -Force -ErrorAction SilentlyContinue

# تنظيف Android build cache
Remove-Item -Path "$env:USERPROFILE\.gradle\caches" -Recurse -Force -ErrorAction SilentlyContinue

# تنظيف Android build folders
Remove-Item -Path "$env:USERPROFILE\.android\build-cache" -Recurse -Force -ErrorAction SilentlyContinue
```

---

## 📊 فحص مساحة القرص

### Windows PowerShell:

```powershell
# فحص مساحة القرص C:
Get-PSDrive C | Select-Object Used,Free,@{Name="UsedPercent";Expression={[math]::Round(($_.Used/($_.Used+$_.Free))*100,2)}}
```

### Windows Command Prompt:

```cmd
dir C:\ | find "bytes free"
```

---

## 🎯 نصائح لتحرير مساحة

### 1. حذف ملفات غير ضرورية:
- ملفات التحميل القديمة
- ملفات الصور المكررة
- ملفات الفيديو الكبيرة
- ملفات ZIP القديمة

### 2. نقل ملفات كبيرة:
- نقل ملفات كبيرة إلى قرص آخر (D:, E:, etc.)
- استخدام Cloud Storage (OneDrive, Google Drive)

### 3. تنظيف البرامج غير المستخدمة:
- Settings > Apps > Uninstall
- احذف البرامج التي لا تستخدمها

### 4. تنظيف Recycle Bin:
```powershell
Clear-RecycleBin -Force
```

---

## 🚀 بعد تحرير المساحة

### 1. أعد بناء المشروع:

```bash
flutter clean
flutter pub get
flutter build apk
```

### 2. إذا استمرت المشكلة:

- **استخدم قرص آخر:** انقل المشروع إلى قرص D: أو E:
- **استخدم SSD خارجي:** إذا كان متوفراً
- **احذف ملفات كبيرة:** ابحث عن ملفات كبيرة واحذفها

---

## 📝 مساحة القرص المطلوبة

### لبناء تطبيق Flutter:
- **الحد الأدنى:** 5 GB
- **الموصى به:** 10 GB
- **للتطوير المريح:** 20 GB

### مساحة Flutter Cache:
- **Pub Cache:** ~500 MB - 2 GB
- **Build Cache:** ~1 GB - 5 GB
- **Android SDK:** ~5 GB - 10 GB

---

## ✅ Checklist

- [ ] تنظيف Flutter build cache (`flutter clean`)
- [ ] تنظيف ملفات Temp
- [ ] تنظيف Flutter pub cache
- [ ] فحص مساحة القرص
- [ ] تحرير مساحة إضافية (حذف ملفات غير ضرورية)
- [ ] إعادة بناء المشروع

---

## 🔗 روابط مفيدة

- [Flutter Clean Command](https://docs.flutter.dev/reference/flutter-cli#clean)
- [Windows Disk Cleanup](https://support.microsoft.com/en-us/windows/disk-cleanup-in-windows-10-8a96ff42-5751-39ad-23d6-434b4d5b9a68)

---

**تم إعداد الدليل بواسطة:** AI Assistant  
**التاريخ:** 2025-01-20

