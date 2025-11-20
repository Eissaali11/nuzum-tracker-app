# إصلاح مشكلة رفع صور الفحص الدوري
## Inspection Upload 415 Error Fix

---

## المشكلة

عند محاولة رفع صور الفحص الدوري، كان التطبيق يفشل بخطأ:
```
415 Unsupported Media Type
Did not attempt to load JSON data because the request Content-Type was not 'application/json'.
```

### السبب:
- الكود القديم كان يحاول إرسال الملفات مع طلب إنشاء الفحص في طلب واحد (multipart/form-data)
- السيرفر يتوقع `Content-Type: application/json` فقط في endpoint إنشاء الطلب
- السيرفر لا يقبل `multipart/form-data` في `/api/v1/requests/create-car-inspection`

---

## الحل

تم تقسيم عملية رفع صور الفحص إلى خطوتين:

### الخطوة 1: إنشاء طلب الفحص (JSON)
```dart
POST /api/v1/requests/create-car-inspection
Content-Type: application/json

{
  "vehicle_id": 50,
  "inspection_type": "periodic",
  "inspection_date": "2025-11-18",
  "notes": "ملاحظات اختيارية"
}
```

### الخطوة 2: رفع الصور واحدة تلو الأخرى (Multipart)
```dart
POST /api/v1/requests/{request_id}/upload-inspection-image
Content-Type: multipart/form-data

{
  "image": <file>
}
```

---

## التغييرات المُنفذة

### 1. ملف: `lib/services/inspection_upload_service.dart`

#### تم تعديل `uploadInspection`:
- الآن تستخدم عملية من خطوتين
- تقوم بإنشاء الطلب أولاً (JSON)
- ثم ترفع الصور واحدة تلو الأخرى

#### تم إضافة `_createInspectionRequestOnly`:
- دالة خاصة لإنشاء طلب الفحص بدون ملفات
- تستخدم `Content-Type: application/json`
- ترجع `request_id` للاستخدام في رفع الصور

---

## كيفية الاستخدام

الاستخدام لم يتغير في التطبيق:

```dart
final service = InspectionUploadService();
final result = await service.uploadInspection(
  vehicleId: car.carId,
  images: imagesWithFiles,
  onProgress: (progress) {
    setState(() {
      _uploadProgress = progress;
    });
  },
);
```

---

## المزايا

1. **توافق مع السيرفر**: يستخدم النهج الصحيح الذي يتوقعه السيرفر
2. **تتبع التقدم**: يحسب التقدم الإجمالي لرفع جميع الصور
3. **معالجة الأخطاء**: يستمر في رفع الصور حتى لو فشلت إحداها
4. **رسائل واضحة**: يُظهر عدد الصور المرفوعة بنجاح

---

## إصلاح إضافي: نوع الفحص

### المشكلة الثانية:
```
نوع الفحص غير صحيح. الأنواع المتاحة: delivery, receipt
```

### الحل:
تم تغيير نوع الفحص من `"periodic"` إلى `"delivery"`:

```dart
inspectionType: 'delivery', // delivery أو receipt
```

### أنواع الفحص المقبولة:
- `delivery`: فحص تسليم السيارة
- `receipt`: فحص استلام السيارة

---

## الاختبار

تم اختبار الحل على:
- ✅ إنشاء طلب فحص بنجاح
- ✅ رفع صور متعددة
- ✅ تتبع التقدم
- ✅ معالجة الأخطاء
- ✅ استخدام نوع الفحص الصحيح

---

## ملاحظات

- الملفات القديمة (`uploadInspectionOldMethod`) محفوظة للرجوع إليها
- الكود محسّن لتقليل استهلاك الذاكرة
- تم إضافة سجلات تفصيلية (debug logs) للمتابعة
- نوع الفحص الافتراضي: `delivery` (يمكن تغييره إلى `receipt` عند الحاجة)

---

**تاريخ الإصلاح**: 2025-11-18
**الحالة**: ✅ تم الإصلاح والاختبار

