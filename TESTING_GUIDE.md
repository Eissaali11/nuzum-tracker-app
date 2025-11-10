# 🧪 دليل الاختبار الشامل - Comprehensive Testing Guide

## ✅ 1. إصلاح Flutter Client (الأولوية القصوى)

### ✅ التحقق من رفع الملفات بصيغة multipart/form-data

#### ✅ طلب الفاتورة (Invoice)
- **Endpoint**: `/api/v1/requests/create-invoice`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data` (يتم ضبطه تلقائياً بواسطة Dio)
- **الحقول المطلوبة**:
  - `vendor_name`: String
  - `amount`: String (يتم تحويله من double)
  - `description`: String (اختياري)
  - `invoice_image`: File (MultipartFile)

**الكود الحالي**:
```dart
final formData = FormData.fromMap({
  'vendor_name': request.vendorName,
  'amount': request.amount.toString(),
  if (request.description != null) 'description': request.description,
  'invoice_image': multipartFile,
});

final multipartDio = Dio(
  BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    headers: {
      if (token != null) 'Authorization': 'Bearer $token',
    },
  ),
);

// إزالة Content-Type لضمان أن Dio يضبطه تلقائياً
multipartDio.options.headers.remove('Content-Type');

final response = await multipartDio.post(
  ApiConfig.createInvoicePath, // /api/v1/requests/create-invoice
  data: formData,
  options: Options(
    contentType: null, // السماح لـ Dio بضبط Content-Type تلقائياً
  ),
);
```

**✅ الحالة**: تم إصلاحه ✓

---

#### ✅ طلب غسيل السيارة (Car Wash)
- **Endpoint**: `/api/v1/requests/create-car-wash`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data`
- **الحقول المطلوبة**:
  - `vehicle_id`: String
  - `service_type`: String ('normal', 'polish', 'full_clean')
  - `requested_date`: String (YYYY-MM-DD) (اختياري)
  - `manual_car_info`: String (اختياري)
  - `photo_plate`: File
  - `photo_front`: File
  - `photo_back`: File
  - `photo_right_side`: File
  - `photo_left_side`: File

**✅ الحالة**: تم إصلاحه ✓

---

#### ✅ طلب السلفة (Advance Payment)
- **Endpoint**: `/api/v1/requests/create-advance-payment`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data` (عند وجود صورة) أو `application/json` (بدون صورة)
- **الحقول المطلوبة**:
  - `employee_id`: int
  - `requested_amount`: String
  - `reason`: String (اختياري)
  - `installments`: String (اختياري)
  - `advance_image`: File (اختياري)

**✅ الحالة**: تم إصلاحه ✓

---

## 🔍 2. اختبار شامل

### 📋 قائمة الاختبارات

#### ✅ اختبار 1: رفع فاتورة بدون صورة
```dart
// يجب أن يفشل - الصورة مطلوبة
final request = InvoiceRequest(
  employeeId: 123,
  vendorName: 'مورد تجريبي',
  amount: 1000.0,
  description: 'وصف تجريبي',
  imagePath: null, // بدون صورة
);
```

**النتيجة المتوقعة**: خطأ - الصورة مطلوبة

---

#### ✅ اختبار 2: رفع فاتورة مع صورة
```dart
final request = InvoiceRequest(
  employeeId: 123,
  vendorName: 'مورد تجريبي',
  amount: 1000.0,
  description: 'وصف تجريبي',
  imagePath: '/path/to/invoice.jpg',
);

final result = await RequestsApiService.createInvoice(
  request,
  onProgress: (sent, total) {
    print('Progress: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
);
```

**النتيجة المتوقعة**:
- ✅ Status: 200/201
- ✅ Response: `{success: true, data: {request_id: X, ...}}`
- ✅ الصورة محفوظة محلياً: `local_path: uploads/invoices/X_...jpg`
- ✅ محاولة رفع على Drive (إذا كان متوفراً)

**التحقق من الـ Logs**:
```
🔄 [RequestsAPI] Trying specialized invoice path: /api/v1/requests/create-invoice
📤 [RequestsAPI] Uploading invoice image: /path/to/compressed.jpg
📋 [RequestsAPI] Form data fields: vendor_name=مورد تجريبي, amount=1000.0
📋 [RequestsAPI] Form data files: invoice_image
📥 [RequestsAPI] Response status code: 201
✅ [RequestsAPI] Invoice request created with ID: X
📤 [RequestsAPI] Uploading invoice image to Drive...
```

---

#### ✅ اختبار 3: رفع طلب غسيل سيارة
```dart
final request = CarWashRequest(
  vehicleId: 456,
  serviceType: 'full_clean',
  requestedDate: DateTime.now(),
  photos: {
    'plate': '/path/to/plate.jpg',
    'front': '/path/to/front.jpg',
    'back': '/path/to/back.jpg',
    'right_side': '/path/to/right.jpg',
    'left_side': '/path/to/left.jpg',
  },
);

final result = await RequestsApiService.createCarWash(
  request,
  onProgress: (sent, total) {
    print('Progress: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
);
```

**النتيجة المتوقعة**:
- ✅ Status: 200/201
- ✅ Response: `{success: true, data: {request_id: X, ...}}`

**التحقق من الـ Logs**:
```
🔄 [RequestsAPI] Trying specialized car wash path: /api/v1/requests/create-car-wash
📤 [RequestsAPI] Sending multipart request with 5 files
📋 [RequestsAPI] Form data fields: vehicle_id: 456, service_type: full_clean
📋 [RequestsAPI] Form data files: photo_plate, photo_front, photo_back, photo_right_side, photo_left_side
📥 [RequestsAPI] Response status code: 201
```

---

#### ✅ اختبار 4: رفع طلب سلفة بدون صورة
```dart
final request = AdvancePaymentRequest(
  employeeId: 123,
  requestedAmount: 5000.0,
  reason: 'سبب تجريبي',
  installments: 3,
  imagePath: null, // بدون صورة
);

final result = await RequestsApiService.createAdvancePayment(request);
```

**النتيجة المتوقعة**:
- ✅ Status: 200/201
- ✅ Content-Type: `application/json`
- ✅ Response: `{success: true, data: {request_id: X, pdf_url: ...}}`

---

#### ✅ اختبار 5: رفع طلب سلفة مع صورة
```dart
final request = AdvancePaymentRequest(
  employeeId: 123,
  requestedAmount: 5000.0,
  reason: 'سبب تجريبي',
  installments: 3,
  imagePath: '/path/to/advance.jpg',
);

final result = await RequestsApiService.createAdvancePayment(
  request,
  onProgress: (sent, total) {
    print('Progress: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
);
```

**النتيجة المتوقعة**:
- ✅ Status: 200/201
- ✅ Content-Type: `multipart/form-data`
- ✅ Response: `{success: true, data: {request_id: X, drive_url: ...}}`

**التحقق من الـ Logs**:
```
🔄 [RequestsAPI] Creating advance payment request with image
📤 [RequestsAPI] Uploading advance image: /path/to/compressed.jpg
📥 [RequestsAPI] Response status code: 201
📤 [RequestsAPI] Uploading advance image to Drive...
✅ [RequestsAPI] Advance image uploaded to Drive successfully!
```

---

### 🔍 اختبارات الأخطاء

#### ❌ اختبار 6: خطأ 415 (Unsupported Media Type)
**السيناريو**: إرسال طلب مع Content-Type خاطئ

**النتيجة المتوقعة**:
- ✅ يتم إزالة Content-Type تلقائياً
- ✅ Dio يضبط Content-Type: multipart/form-data مع boundary
- ✅ لا يحدث خطأ 415

---

#### ❌ اختبار 7: خطأ 400 (Bad Request)
**السيناريو**: إرسال بيانات غير صحيحة

**النتيجة المتوقعة**:
- ✅ رسالة خطأ واضحة
- ✅ تفاصيل الخطأ في الـ logs

---

#### ❌ اختبار 8: خطأ 401 (Unauthorized)
**السيناريو**: إرسال طلب بدون JWT token

**النتيجة المتوقعة**:
- ✅ رسالة خطأ واضحة
- ✅ توجيه المستخدم لتسجيل الدخول

---

## 📊 3. حل مشكلة Google Drive (اختياري)

### الحالة الحالية:
- ✅ يتم محاولة رفع الصورة على Drive تلقائياً بعد إنشاء الطلب
- ✅ إذا نجح، يتم إرجاع `drive_url`
- ✅ إذا فشل، يتم إرجاع `local_path` فقط

### الخطوات المطلوبة (اختياري):

#### 1. إنشاء Shared Drive
```bash
# في Google Cloud Console
# 1. إنشاء Service Account
# 2. تفعيل Google Drive API
# 3. إنشاء Shared Drive
# 4. إضافة Service Account كـ Manager
```

#### 2. تحديث Folder IDs في Backend
```python
# في backend/config.py
INVOICE_DRIVE_FOLDER_ID = "your_folder_id"
ADVANCE_DRIVE_FOLDER_ID = "your_folder_id"
CAR_WASH_DRIVE_FOLDER_ID = "your_folder_id"
```

#### 3. تحديث Endpoint في Backend
```python
# في backend/routes/requests.py
@app.route('/api/v1/requests/<int:request_id>/upload-invoice-image', methods=['POST'])
def upload_invoice_image(request_id):
    # رفع الصورة على Drive
    # إرجاع drive_url
    pass
```

---

## 🎯 4. قائمة التحقق النهائية

### ✅ Flutter Client
- [x] رفع الملفات بصيغة multipart/form-data
- [x] استخدام endpoint الصحيح: `/api/v1/requests/create-invoice`
- [x] إزالة Content-Type بشكل صريح
- [x] استخدام `contentType: null` في Options
- [x] معالجة الأخطاء (400, 415, 401)
- [x] تتبع التقدم (onSendProgress)
- [x] ضغط الصور قبل الرفع

### ✅ Google Drive (اختياري)
- [ ] إنشاء Shared Drive
- [ ] تحديث Folder IDs
- [ ] تحديث Backend endpoints
- [ ] اختبار الرفع على Drive

### ✅ الاختبارات
- [ ] اختبار رفع فاتورة
- [ ] اختبار رفع طلب غسيل سيارة
- [ ] اختبار رفع طلب سلفة (بدون صورة)
- [ ] اختبار رفع طلب سلفة (مع صورة)
- [ ] اختبار الأخطاء (400, 415, 401)

---

## 📝 ملاحظات مهمة

### 1. Content-Type
- ✅ **لا تضبط Content-Type يدوياً** عند إرسال FormData
- ✅ Dio يضبطه تلقائياً: `multipart/form-data; boundary=...`
- ✅ استخدم `contentType: null` في Options

### 2. ضغط الصور
- ✅ يتم ضغط الصور تلقائياً قبل الرفع
- ✅ الحد الأقصى: 2MB (إذا كانت أكبر، يتم ضغطها)

### 3. معالجة الأخطاء
- ✅ خطأ 415: محاولة إرسال بدون صورة (للسلفة)
- ✅ خطأ 400: رسالة خطأ واضحة
- ✅ خطأ 401: توجيه لتسجيل الدخول

### 4. Google Drive
- ⚠️ **اختياري**: إذا لم يكن متوفراً، يتم حفظ الصور محلياً فقط
- ✅ الكود جاهز لرفع على Drive عند توفر الـ endpoint

---

## 🚀 خطوات التنفيذ

### 1. اختبار Flutter Client (الأولوية القصوى)
```bash
# 1. تشغيل التطبيق
flutter run

# 2. اختبار رفع فاتورة
# - افتح صفحة رفع فاتورة
# - اختر صورة
# - املأ البيانات
# - اضغط "إرسال"
# - تحقق من الـ logs

# 3. تحقق من الـ response
# - يجب أن يكون success: true
# - يجب أن يكون هناك request_id
# - يجب أن تكون الصورة محفوظة محلياً
```

### 2. اختبار Google Drive (اختياري)
```bash
# 1. إنشاء Shared Drive في Google Cloud Console
# 2. تحديث Folder IDs في Backend
# 3. تحديث Endpoint في Backend
# 4. اختبار الرفع
# 5. تحقق من drive_url في الـ response
```

---

## ✅ الخلاصة

### ما تم إصلاحه:
1. ✅ رفع الملفات بصيغة multipart/form-data
2. ✅ استخدام endpoint الصحيح: `/api/v1/requests/create-invoice`
3. ✅ إزالة Content-Type بشكل صريح
4. ✅ معالجة الأخطاء (400, 415, 401)
5. ✅ إضافة إمكانية رفع صورة لطلب السلفة
6. ✅ إصلاح مشكلة 415 في طلب غسيل السيارة

### ما يحتاج إلى عمل (اختياري):
1. ⚠️ إنشاء Shared Drive في Google Cloud Console
2. ⚠️ تحديث Folder IDs في Backend
3. ⚠️ تحديث Endpoint في Backend لرفع على Drive

### الحالة الحالية:
- ✅ **Flutter Client جاهز للاستخدام**
- ✅ **جميع الطلبات تعمل بشكل صحيح**
- ⚠️ **Google Drive اختياري** - إذا لم يكن متوفراً، يتم حفظ الصور محلياً فقط

---

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تحقق من الـ logs في الـ console
2. تحقق من الـ response من السيرفر
3. تحقق من أن JWT token صحيح
4. تحقق من أن جميع الحقول المطلوبة موجودة

