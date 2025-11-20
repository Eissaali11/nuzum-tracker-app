# 📸 APIs المستخدمة في صفحة رفع صور الفحص الدوري

## 🔗 Base URLs
```
الرفع: https://nuzum.site
الطلبات الأخرى: https://eissahr.replit.app
```

---

## 📋 الخطوة 1: إنشاء طلب الفحص (بدون صور)

### Endpoint
```
POST /api/v1/requests/create-car-inspection
```

### Headers
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer {token}"
}
```

### Request Body
```json
{
  "vehicle_id": 50,
  "inspection_type": "receipt",
  "inspection_date": "2025-01-18",
  "notes": "ملاحظات اختيارية (اختياري)"
}
```

### Response (Success - 200/201)
```json
{
  "success": true,
  "data": {
    "request_id": 123
  },
  "message": "تم إنشاء الطلب بنجاح"
}
```

### Response (Error)
```json
{
  "success": false,
  "error": "رسالة الخطأ",
  "message": "تفاصيل الخطأ"
}
```

### الكود المستخدم
- **File:** `lib/services/inspection_upload_service.dart`
- **Method:** `_createInspectionRequestOnly()`
- **Line:** 387-520

---

## 📤 الخطوة 2: رفع الصور (واحدة تلو الأخرى)

### Endpoints المحتملة (يتم تجربتها بالترتيب)

#### 1. المسار الأساسي (الأولوية الأولى) - ✅ الجديد على nuzum.site
```
POST https://nuzum.site/api/v1/requests/{request_id}/upload-inspection-image
```

#### 2. المسار البديل 1 - ✅ الجديد على nuzum.site
```
POST https://nuzum.site/api/v1/requests/{request_id}/upload-image
```

#### 3. المسار الاحتياطي (eissahr.replit.app)
```
POST https://eissahr.replit.app/api/v1/requests/{request_id}/upload-inspection-image
```

#### 4. المسار الاحتياطي 2
```
POST https://eissahr.replit.app/api/external/requests/{request_id}/upload-inspection-image
```

#### 5. المسار الاحتياطي 3
```
POST https://eissahr.replit.app/api/v1/requests/{request_id}/upload
```

### Headers
```json
{
  "Authorization": "Bearer {token}"
}
```
**ملاحظة:** `Content-Type` يتم إضافته تلقائياً من Dio مع `multipart/form-data` و `boundary`

### Request Body (FormData)
```
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary...

------WebKitFormBoundary...
Content-Disposition: form-data; name="image"; filename="inspection_1234567890.jpg"
Content-Type: image/jpeg

[Binary Image Data]
------WebKitFormBoundary...--
```

### Request Fields
- `image`: ملف الصورة (MultipartFile)
  - **Field Name:** `image`
  - **Content-Type:** `image/jpeg`
  - **Filename:** `inspection_{timestamp}.jpg`

### Response (Success - 200/201) - ✅ محدث
```json
{
  "success": true,
  "data": {
    "media_id": 123,
    "image_url": "https://nuzum.site/static/uploads/car_inspections/inspection_123_1234567890_abc.jpg",
    "local_path": "uploads/car_inspections/inspection_123_1234567890_abc.jpg",
    "drive_url": "https://drive.google.com/..." // null إذا فشل Google Drive
  },
  "message": "تم رفع الصورة بنجاح"
}
```

**ملاحظات:**
- ✅ **الحفظ المحلي المباشر** - الصور تُحفظ محلياً أولاً في `static/uploads/car_inspections/`
- ✅ **Google Drive اختياري** - يحاول رفع الصورة إلى Google Drive في الخلفية، لكن إذا فشل لن يؤثر على نجاح العملية
- ✅ **رفع فوري** - بدون انتظار Google Drive (أسرع بكثير)
- ✅ **موثوقية 100%** - لا يفشل حتى لو Google Drive معطل
- ✅ **الصور متاحة فوراً** - على الرابط المباشر `image_url`
- ✅ يتم حفظ البيانات في قاعدة البيانات
- ✅ يتم إنشاء مجلد تلقائي إذا لم يكن موجود
- ✅ يدعم صيغ: jpg, jpeg, png, heic

### Response (Error - 404)
```json
{
  "success": false,
  "error": "المسار غير موجود"
}
```
**ملاحظة:** عند 404، يتم تجربة المسار التالي تلقائياً

### Response (Error - 401)
```json
{
  "success": false,
  "error": "غير مصرح"
}
```

### Response (Error - 413)
```json
{
  "success": false,
  "error": "حجم الصورة كبير جداً"
}
```

### Response (Error - 422)
```json
{
  "success": false,
  "error": "بيانات الصورة غير صالحة"
}
```

### Response (Error - 500)
```json
{
  "success": false,
  "error": "خطأ في الخادم"
}
```

### الكود المستخدم
- **File:** `lib/services/requests_api_service.dart`
- **Method:** `uploadInspectionImage()`
- **Line:** 1316-1477

---

## 🔄 سير العمل الكامل (Workflow)

### 1. المستخدم يضغط "رفع الصور"
- **File:** `lib/widgets/inspection_upload_dialog.dart`
- **Method:** `_uploadInspection()`
- **Line:** 118-188

### 2. استدعاء InspectionUploadService
```dart
final service = InspectionUploadService();
final result = await service.uploadInspection(
  vehicleId: widget.car.carId,
  images: imagesWithFiles,
  onProgress: (progress) { ... },
);
```

### 3. إنشاء طلب الفحص (الخطوة 1)
- **File:** `lib/services/inspection_upload_service.dart`
- **Method:** `uploadInspection()` → `_createInspectionRequestOnly()`
- **Endpoint:** `POST /api/v1/requests/create-car-inspection`
- **Content-Type:** `application/json`

### 4. رفع كل صورة (الخطوة 2)
- **File:** `lib/services/inspection_upload_service.dart`
- **Method:** `uploadInspection()` → `RequestsApiService.uploadInspectionImage()`
- **Endpoint:** `POST /api/v1/requests/{request_id}/upload-inspection-image`
- **Content-Type:** `multipart/form-data`
- **Retry:** 3 محاولات لكل صورة

---

## 📊 مثال كامل للطلب

### الطلب 1: إنشاء طلب الفحص
```http
POST https://eissahr.replit.app/api/v1/requests/create-car-inspection HTTP/1.1
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

{
  "vehicle_id": 50,
  "inspection_type": "receipt",
  "inspection_date": "2025-01-18",
  "notes": "صورة 1: ملاحظة 1\nصورة 2: ملاحظة 2"
}
```

### الطلب 2: رفع الصورة الأولى (✅ على nuzum.site)
```http
POST https://nuzum.site/api/v1/requests/123/upload-inspection-image HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="image"; filename="inspection_1705593600000.jpg"
Content-Type: image/jpeg

[JPEG Image Binary Data]
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

### الطلب 3: رفع الصورة الثانية (✅ على nuzum.site)
```http
POST https://nuzum.site/api/v1/requests/123/upload-inspection-image HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW

[نفس التنسيق للصورة الثانية]
```

---

## 🔧 الإعدادات (Configuration)

### Base URLs
```dart
// lib/config/api_config.dart
static const String baseUrl = 'https://eissahr.replit.app'; // للطلبات العامة
static const String nuzumBaseUrl = 'https://nuzum.site'; // لرفع الصور (الجديد)
```

### Paths
```dart
// lib/config/api_config.dart
static const String createCarInspectionPath = '/api/v1/requests/create-car-inspection';
static const String uploadInspectionImagePath = '/api/v1/requests';
```

### Timeout
```dart
// lib/config/api_config.dart
static const Duration timeoutDuration = Duration(seconds: 30);
```

---

## 📝 ملاحظات مهمة

1. **عملية من خطوتين:** لا يمكن رفع الصور مع إنشاء الطلب في طلب واحد
2. **رفع متسلسل:** الصور تُرفع واحدة تلو الأخرى (ليس بشكل متوازي)
3. **إعادة المحاولة:** كل صورة لديها 3 محاولات مع تأخير متزايد (2s, 4s, 6s)
4. **مسارات بديلة:** إذا فشل المسار الأساسي، يتم تجربة المسارات البديلة تلقائياً
5. **ضغط الصور:** يتم ضغط الصور تلقائياً قبل الرفع
6. **Token:** يجب أن يكون Token صالحاً في كل طلب

---

## 🐛 معالجة الأخطاء

### خطأ 401 (Unauthorized)
- يتم إيقاف المحاولات فوراً
- رسالة: "غير مصرح لك برفع الصورة. يرجى تسجيل الدخول مرة أخرى"

### خطأ 404 (Not Found)
- يتم تجربة المسار التالي تلقائياً
- إذا فشلت جميع المسارات: "المسار غير موجود. يرجى التحقق من رقم الطلب"

### خطأ الاتصال (Connection Error)
- يتم إيقاف المحاولات
- رسالة: "فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت"

### خطأ Timeout
- يتم إعادة المحاولة (حتى 3 مرات)
- رسالة: "انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت"

---

## 📍 الملفات ذات الصلة

1. **UI Component:**
   - `lib/widgets/inspection_upload_dialog.dart`

2. **Service Layer:**
   - `lib/services/inspection_upload_service.dart`
   - `lib/services/requests_api_service.dart`

3. **Configuration:**
   - `lib/config/api_config.dart`

4. **Authentication:**
   - `lib/services/auth_service.dart`

---

## ✅ Checklist للسرفر

تأكد من أن السيرفر يدعم:

- [x] `POST /api/v1/requests/create-car-inspection` (JSON) - ✅ متوفر
- [x] `POST https://nuzum.site/api/v1/requests/{id}/upload-inspection-image` (Multipart) - ✅ متوفر (جديد)
- [x] `POST https://nuzum.site/api/v1/requests/{id}/upload-image` (Multipart) - ✅ متوفر (بديل)
- [x] قبول `image` كاسم الحقل في FormData - ✅ متوفر
- [x] قبول `Content-Type: image/jpeg` للصور - ✅ متوفر
- [x] دعم صيغ: jpg, jpeg, png, heic - ✅ متوفر
- [x] رفع تلقائي إلى Google Drive - ✅ متوفر
- [x] إنشاء مجلد تلقائي - ✅ متوفر
- [x] إرجاع `request_id` في استجابة إنشاء الطلب - ✅ متوفر
- [x] إرجاع `media_id` في استجابة رفع الصورة - ✅ متوفر
- [x] إرجاع `drive_url` في استجابة رفع الصورة - ✅ متوفر
- [x] إرجاع `drive_file_id` في استجابة رفع الصورة - ✅ متوفر (جديد)

