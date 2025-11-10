# 📋 دليل طلبات API - إرسال الصور والفواتير

## 🔐 المصادقة (Authentication)
جميع الطلبات تتطلب JWT Token في الـ Header:
```
Authorization: Bearer {jwt_token}
```

---

## 🚗 1. إنشاء طلب غسيل سيارة مع الصور

### Endpoint
```
POST /api/v1/requests/create-car-wash
```
أو
```
POST /api/v1/requests
```

### Headers
```
Authorization: Bearer {jwt_token}
Content-Type: multipart/form-data
```

### Request Body (Form Data)

#### الطريقة الصحيحة - Endpoint المتخصص:
```
vehicle_id: 456
service_type: "normal" | "polish" | "full_clean"
requested_date: "2025-01-20" (اختياري - YYYY-MM-DD)
manual_car_info: "معلومات السيارة" (اختياري - للإدخال اليدوي)
photo_plate: [file] (مطلوب)
photo_front: [file] (مطلوب)
photo_back: [file] (مطلوب)
photo_right_side: [file] (مطلوب)
photo_left_side: [file] (مطلوب)
```

#### الطريقة البديلة - Endpoint الموحد:
```
type: "car_wash"
employee_id: 123
vehicle_id: 456
service_type: "normal" | "polish" | "full_clean"
requested_date: "2025-01-20" (اختياري)
photo_plate: [file]
photo_front: [file]
photo_back: [file]
photo_right_side: [file]
photo_left_side: [file]
```

### Response (Success 200/201)
```json
{
  "success": true,
  "message": "تم إنشاء طلب الغسيل بنجاح",
  "data": {
    "request_id": 3,
    "type": "car_wash",
    "status": "pending",
    "vehicle_plate": "ABC 123",
    "service_type": "full_clean",
    "service_type_ar": "تنظيف شامل",
    "images_count": 5
  }
}
```

### مثال cURL
```bash
curl -X POST "https://your-api.com/api/v1/requests/create-car-wash" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "vehicle_id=456" \
  -F "service_type=full_clean" \
  -F "requested_date=2025-01-20" \
  -F "photo_plate=@/path/to/plate.jpg" \
  -F "photo_front=@/path/to/front.jpg" \
  -F "photo_back=@/path/to/back.jpg" \
  -F "photo_right_side=@/path/to/right.jpg" \
  -F "photo_left_side=@/path/to/left.jpg"
```

### مثال Flutter/Dart
```dart
import 'package:dio/dio.dart';
import 'dart:io';

Future<void> createCarWashRequest() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://your-api.com',
    headers: {
      'Authorization': 'Bearer YOUR_JWT_TOKEN',
    },
  ));

  final formData = FormData.fromMap({
    'vehicle_id': '456',
    'service_type': 'full_clean',
    'requested_date': '2025-01-20',
    'photo_plate': await MultipartFile.fromFile(
      '/path/to/plate.jpg',
      filename: 'plate.jpg',
    ),
    'photo_front': await MultipartFile.fromFile(
      '/path/to/front.jpg',
      filename: 'front.jpg',
    ),
    'photo_back': await MultipartFile.fromFile(
      '/path/to/back.jpg',
      filename: 'back.jpg',
    ),
    'photo_right_side': await MultipartFile.fromFile(
      '/path/to/right.jpg',
      filename: 'right.jpg',
    ),
    'photo_left_side': await MultipartFile.fromFile(
      '/path/to/left.jpg',
      filename: 'left.jpg',
    ),
  });

  try {
    final response = await dio.post(
      '/api/v1/requests/create-car-wash',
      data: formData,
      onSendProgress: (sent, total) {
        final progress = (sent / total) * 100;
        print('تم رفع: ${progress.toStringAsFixed(1)}%');
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ تم إنشاء الطلب بنجاح: ${response.data}');
    }
  } catch (e) {
    print('❌ خطأ: $e');
  }
}
```

---

## 📄 2. إنشاء طلب فاتورة مع الصورة

### Endpoint
```
POST /api/v1/requests/create-invoice
```
أو
```
POST /api/v1/requests
```

### Headers
```
Authorization: Bearer {jwt_token}
Content-Type: multipart/form-data
```

### Request Body (Form Data)

#### الطريقة الصحيحة - Endpoint المتخصص:
```
employee_id: 123
vendor_name: "اسم المورد"
amount: 1000.00
description: "وصف الفاتورة" (اختياري)
invoice_image: [file] (مطلوب)
```

#### الطريقة البديلة - Endpoint الموحد:
```
type: "invoice"
employee_id: 123
vendor_name: "اسم المورد"
amount: 1000.00
description: "وصف الفاتورة" (اختياري)
invoice_image: [file]
```

### Response (Success 200/201)
```json
{
  "success": true,
  "message": "تم رفع الفاتورة بنجاح",
  "data": {
    "request_id": 2,
    "type": "invoice",
    "status": "pending",
    "vendor_name": "اسم المورد",
    "amount": 1000.00,
    "image_url": "https://example.com/uploads/invoice_2.jpg"
  }
}
```

### مثال cURL
```bash
curl -X POST "https://your-api.com/api/v1/requests/create-invoice" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "employee_id=123" \
  -F "vendor_name=اسم المورد" \
  -F "amount=1000.00" \
  -F "description=وصف الفاتورة" \
  -F "invoice_image=@/path/to/invoice.jpg"
```

### مثال Flutter/Dart
```dart
import 'package:dio/dio.dart';
import 'dart:io';

Future<void> createInvoiceRequest() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://your-api.com',
    headers: {
      'Authorization': 'Bearer YOUR_JWT_TOKEN',
    },
  ));

  final formData = FormData.fromMap({
    'employee_id': '123',
    'vendor_name': 'اسم المورد',
    'amount': '1000.00',
    'description': 'وصف الفاتورة',
    'invoice_image': await MultipartFile.fromFile(
      '/path/to/invoice.jpg',
      filename: 'invoice.jpg',
    ),
  });

  try {
    final response = await dio.post(
      '/api/v1/requests/create-invoice',
      data: formData,
      onSendProgress: (sent, total) {
        final progress = (sent / total) * 100;
        print('تم رفع: ${progress.toStringAsFixed(1)}%');
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ تم رفع الفاتورة بنجاح: ${response.data}');
    }
  } catch (e) {
    print('❌ خطأ: $e');
  }
}
```

---

## 📤 3. رفع صورة إضافية لطلب موجود

### Endpoint
```
POST /api/v1/requests/{request_id}/upload
```

### Headers
```
Authorization: Bearer {jwt_token}
Content-Type: multipart/form-data
```

### Request Body (Form Data)
```
file: [file] (مطلوب)
file_type: "image" | "video" (مطلوب)
description: "وصف الملف" (اختياري)
```

### Response (Success 200)
```json
{
  "success": true,
  "message": "تم رفع الملف بنجاح",
  "data": {
    "file_url": "https://example.com/uploads/file.jpg",
    "file_type": "image",
    "file_size": 1024000
  }
}
```

### مثال cURL
```bash
curl -X POST "https://your-api.com/api/v1/requests/123/upload" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "file=@/path/to/image.jpg" \
  -F "file_type=image" \
  -F "description=صورة إضافية"
```

### مثال Flutter/Dart
```dart
import 'package:dio/dio.dart';
import 'dart:io';

Future<void> uploadFileToRequest(int requestId, File file) async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://your-api.com',
    headers: {
      'Authorization': 'Bearer YOUR_JWT_TOKEN',
    },
  ));

  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(
      file.path,
      filename: 'image.jpg',
    ),
    'file_type': 'image',
    'description': 'صورة إضافية',
  });

  try {
    final response = await dio.post(
      '/api/v1/requests/$requestId/upload',
      data: formData,
      onSendProgress: (sent, total) {
        final progress = (sent / total) * 100;
        print('تم رفع: ${progress.toStringAsFixed(1)}%');
      },
    );

    if (response.statusCode == 200) {
      print('✅ تم رفع الملف بنجاح: ${response.data}');
    }
  } catch (e) {
    print('❌ خطأ: $e');
  }
}
```

---

## ⚠️ ملاحظات مهمة

### 1. أسماء الحقول
- **لطلب الغسيل**: استخدم `photo_plate`, `photo_front`, `photo_back`, `photo_right_side`, `photo_left_side`
- **للفاتورة**: استخدم `invoice_image` (وليس `image` أو `file`)
- **لرفع ملفات إضافية**: استخدم `file` مع `file_type`

### 2. أنواع الملفات المدعومة
- **الصور**: JPG, JPEG, PNG
- **الفيديوهات**: MP4, MOV (لطلبات الفحص فقط)

### 3. حجم الملفات
- **الصور**: يُفضل ضغطها قبل الإرسال (أقصى حجم: 5MB)
- **الفيديوهات**: أقصى حجم: 50MB

### 4. تنسيق التاريخ
- استخدم `YYYY-MM-DD` (مثال: `2025-01-20`)
- لا تستخدم الوقت في `requested_date`

### 5. معالجة الأخطاء
```dart
try {
  // ... إرسال الطلب
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    print('❌ خطأ في المصادقة - تحقق من Token');
  } else if (e.response?.statusCode == 400) {
    print('❌ بيانات غير صحيحة: ${e.response?.data}');
  } else if (e.response?.statusCode == 500) {
    print('❌ خطأ في السيرفر');
  } else {
    print('❌ خطأ غير معروف: $e');
  }
}
```

### 6. تتبع التقدم
```dart
onSendProgress: (sent, total) {
  final progress = (sent / total) * 100;
  print('تم رفع: ${progress.toStringAsFixed(1)}%');
  // تحديث UI مع التقدم
  setState(() {
    uploadProgress = progress;
  });
}
```

---

## 🔍 اختبار الطلبات

### استخدام Postman

1. **إعداد Request**:
   - Method: `POST`
   - URL: `https://your-api.com/api/v1/requests/create-car-wash`
   - Headers: `Authorization: Bearer YOUR_TOKEN`

2. **إعداد Body**:
   - اختر `form-data`
   - أضف الحقول النصية (vehicle_id, service_type, etc.)
   - أضف الملفات (photo_plate, photo_front, etc.) واختر `File` من القائمة

3. **إرسال الطلب**:
   - اضغط `Send`
   - تحقق من الـ Response

### استخدام cURL
راجع الأمثلة أعلاه في كل قسم.

---

## 📞 الدعم
إذا واجهت مشاكل:
1. تحقق من الـ JWT Token
2. تحقق من أسماء الحقول (case-sensitive)
3. تحقق من تنسيق الملفات
4. راجع الـ Response للتفاصيل

