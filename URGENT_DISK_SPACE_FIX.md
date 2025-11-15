# 🚨 حل عاجل: مساحة القرص ممتلئة 99.75%

**المشكلة:** القرص C: ممتلئ بنسبة **99.75%** - تبقى فقط **0.59 GB**!

**الحل:** يجب تحرير **على الأقل 5-10 GB** لبناء التطبيق.

---

## ⚡ حلول فورية (سريعة)

### 1. حذف ملفات كبيرة يدوياً:

#### أ. ابحث عن ملفات كبيرة:
```powershell
# ابحث عن ملفات أكبر من 500 MB
Get-ChildItem -Path C:\Users\$env:USERNAME -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object {$_.Length -gt 500MB} | 
    Sort-Object Length -Descending | 
    Select-Object FullName, @{Name="SizeGB";Expression={[math]::Round($_.Length/1GB,2)}} | 
    Format-Table -AutoSize
```

#### ب. ابحث عن مجلدات كبيرة:
```powershell
# ابحث عن مجلدات كبيرة
Get-ChildItem -Path C:\Users\$env:USERNAME -Directory -ErrorAction SilentlyContinue | 
    ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | 
            Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            Folder = $_.FullName
            SizeGB = [math]::Round($size/1GB,2)
        }
    } | 
    Where-Object {$_.SizeGB -gt 1} | 
    Sort-Object SizeGB -Descending | 
    Format-Table -AutoSize
```

### 2. تنظيف Downloads:
```powershell
# احذف ملفات التحميل القديمة (أكبر من 30 يوم)
Get-ChildItem -Path "$env:USERPROFILE\Downloads" -File | 
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-30)} | 
    Remove-Item -Force
```

### 3. تنظيف Desktop:
```powershell
# احذف ملفات Desktop القديمة
Get-ChildItem -Path "$env:USERPROFILE\Desktop" -File | 
    Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-90)} | 
    Remove-Item -Force
```

### 4. تنظيف Android SDK (إذا كان موجود):
```powershell
# Android SDK قد يشغل 5-10 GB
# احذف إصدارات Android القديمة من:
# C:\Users\$env:USERNAME\AppData\Local\Android\Sdk
```

### 5. تنظيف Node.js (إذا كان موجود):
```powershell
# Node.js cache
Remove-Item -Path "$env:APPDATA\npm-cache" -Recurse -Force -ErrorAction SilentlyContinue
```

---

## 🧹 تنظيف شامل (يحتاج وقت)

### 1. Windows Disk Cleanup:
1. اضغط `Win + R`
2. اكتب `cleanmgr`
3. اختر القرص C:
4. اختر جميع الخيارات
5. اضغط "OK"

### 2. تنظيف Windows Update:
```powershell
# كمسؤول (Run as Administrator)
Stop-Service -Name wuauserv -Force
Remove-Item -Path "$env:WINDOWS\SoftwareDistribution\Download\*" -Recurse -Force
Start-Service -Name wuauserv
```

### 3. تنظيف Windows Logs:
```powershell
# كمسؤول
wevtutil el | ForEach-Object {wevtutil cl "$_"}
```

### 4. تنظيف System Restore Points:
```powershell
# كمسؤول
vssadmin delete shadows /all
```

---

## 📦 نقل ملفات كبيرة

### 1. نقل المشروع إلى قرص آخر:
```powershell
# إذا كان لديك قرص D: أو E:
# انقل المشروع إلى هناك
Move-Item -Path "C:\Users\user\nuzum-tracker-app" -Destination "D:\Projects\" -Force
```

### 2. نقل ملفات Downloads:
```powershell
# انقل ملفات التحميل الكبيرة إلى قرص آخر
Get-ChildItem -Path "$env:USERPROFILE\Downloads" -File | 
    Where-Object {$_.Length -gt 100MB} | 
    Move-Item -Destination "D:\Downloads\" -Force
```

---

## 🎯 أولويات التنظيف

### 1. **فوري (يحرر 1-5 GB):**
- ✅ Recycle Bin
- ✅ Temp Files
- ✅ Flutter Temp Files
- ✅ Downloads القديمة

### 2. **متوسط (يحرر 5-10 GB):**
- ✅ Windows Update Cache
- ✅ System Logs
- ✅ Prefetch
- ✅ Desktop Files

### 3. **كبير (يحرر 10+ GB):**
- ✅ Android SDK (إصدارات قديمة)
- ✅ Node.js Cache
- ✅ ملفات فيديو/صور كبيرة
- ✅ System Restore Points

---

## ✅ بعد تحرير المساحة

### 1. تحقق من المساحة:
```powershell
Get-PSDrive C | Select-Object @{Name="FreeGB";Expression={[math]::Round($_.Free/1GB,2)}}
```

### 2. يجب أن يكون لديك على الأقل:
- **5 GB** للبناء الأساسي
- **10 GB** للبناء المريح
- **20 GB** للتطوير المستمر

### 3. أعد بناء المشروع:
```bash
flutter clean
flutter pub get
flutter build apk
```

---

## 🚨 إذا لم تستطع تحرير مساحة كافية

### الحل البديل: استخدم قرص آخر

1. **انقل المشروع:**
   ```powershell
   Move-Item -Path "C:\Users\user\nuzum-tracker-app" -Destination "D:\" -Force
   ```

2. **أو استخدم SSD خارجي**

3. **أو استخدم Cloud Storage** (OneDrive, Google Drive)

---

## 📊 المساحة المطلوبة لـ Flutter

| المكون | المساحة |
|--------|---------|
| Flutter SDK | ~2 GB |
| Android SDK | ~5-10 GB |
| Build Cache | ~1-5 GB |
| Pub Cache | ~500 MB - 2 GB |
| **المجموع** | **~10-20 GB** |

---

## ✅ Checklist

- [ ] تنظيف Recycle Bin
- [ ] تنظيف Temp Files
- [ ] تنظيف Downloads القديمة
- [ ] تنظيف Desktop
- [ ] تنظيف Windows Update Cache
- [ ] فحص المساحة (يجب أن تكون > 5 GB)
- [ ] إعادة بناء المشروع

---

**⚠️ مهم:** يجب أن تحرر **على الأقل 5 GB** قبل محاولة بناء التطبيق مرة أخرى!

---

**تم إعداد الدليل بواسطة:** AI Assistant  
**التاريخ:** 2025-01-20

