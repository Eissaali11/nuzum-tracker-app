# 📝 أمثلة عملية لطلبات API

## 🚀 أمثلة جاهزة للاستخدام

---

## 1️⃣ طلب غسيل سيارة - مثال كامل

### Flutter/Dart Code
```dart
import 'package:dio/dio.dart';
import 'dart:io';

Future<Map<String, dynamic>> createCarWashRequest({
  required String token,
  required int vehicleId,
  required String serviceType, // 'normal', 'polish', 'full_clean'
  required Map<String, File> photos, // plate, front, back, right_side, left_side
  String? requestedDate, // 'YYYY-MM-DD'
  String? manualCarInfo,
}) async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://eissahr.replit.app',
    headers: {
      'Authorization': 'Bearer $token',
    },
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  try {
    // إنشاء FormData
    final formData = FormData.fromMap({
      'vehicle_id': vehicleId.toString(),
      'service_type': serviceType,
      if (requestedDate != null) 'requested_date': requestedDate,
      if (manualCarInfo != null && manualCarInfo.isNotEmpty) 
        'manual_car_info': manualCarInfo,
      
      // الصور - أسماء الحقول الصحيحة
      'photo_plate': await MultipartFile.fromFile(
        photos['plate']!.path,
        filename: 'plate_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
      'photo_front': await MultipartFile.fromFile(
        photos['front']!.path,
        filename: 'front_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
      'photo_back': await MultipartFile.fromFile(
        photos['back']!.path,
        filename: 'back_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
      'photo_right_side': await MultipartFile.fromFile(
        photos['right_side']!.path,
        filename: 'right_side_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
      'photo_left_side': await MultipartFile.fromFile(
        photos['left_side']!.path,
        filename: 'left_side_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });

    print('🔄 إرسال طلب غسيل سيارة...');
    
    final response = await dio.post(
      '/api/v1/requests/create-car-wash',
      data: formData,
      onSendProgress: (sent, total) {
        final progress = (sent / total) * 100;
        print('📤 التقدم: ${progress.toStringAsFixed(1)}%');
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        print('✅ تم إنشاء الطلب بنجاح!');
        return {
          'success': true,
          'data': data['data'],
        };
      }
    }

    return {
      'success': false,
      'error': response.data['error'] ?? 'فشل إنشاء الطلب',
    };
  } on DioException catch (e) {
    print('❌ خطأ: ${e.message}');
    if (e.response != null) {
      print('📥 Response: ${e.response?.data}');
    }
    return {
      'success': false,
      'error': e.response?.data['error'] ?? e.message ?? 'حدث خطأ',
    };
  } catch (e) {
    print('❌ خطأ غير متوقع: $e');
    return {
      'success': false,
      'error': 'حدث خطأ غير متوقع',
    };
  }
}

// مثال الاستخدام:
void example() async {
  final result = await createCarWashRequest(
    token: 'YOUR_JWT_TOKEN',
    vehicleId: 456,
    serviceType: 'full_clean',
    photos: {
      'plate': File('/path/to/plate.jpg'),
      'front': File('/path/to/front.jpg'),
      'back': File('/path/to/back.jpg'),
      'right_side': File('/path/to/right.jpg'),
      'left_side': File('/path/to/left.jpg'),
    },
    requestedDate: '2025-01-20',
  );

  if (result['success'] == true) {
    print('✅ Request ID: ${result['data']['request_id']}');
  } else {
    print('❌ Error: ${result['error']}');
  }
}
```

### cURL Command
```bash
curl -X POST "https://eissahr.replit.app/api/v1/requests/create-car-wash" \
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

### Python Example
```python
import requests

def create_car_wash_request(token, vehicle_id, service_type, photos, requested_date=None):
    url = "https://eissahr.replit.app/api/v1/requests/create-car-wash"
    
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    files = {
        'photo_plate': open(photos['plate'], 'rb'),
        'photo_front': open(photos['front'], 'rb'),
        'photo_back': open(photos['back'], 'rb'),
        'photo_right_side': open(photos['right_side'], 'rb'),
        'photo_left_side': open(photos['left_side'], 'rb'),
    }
    
    data = {
        'vehicle_id': str(vehicle_id),
        'service_type': service_type,
    }
    
    if requested_date:
        data['requested_date'] = requested_date
    
    try:
        response = requests.post(url, headers=headers, files=files, data=data)
        response.raise_for_status()
        
        result = response.json()
        if result.get('success'):
            print(f"✅ تم إنشاء الطلب بنجاح! Request ID: {result['data']['request_id']}")
            return result
        else:
            print(f"❌ فشل: {result.get('error')}")
            return result
    except requests.exceptions.RequestException as e:
        print(f"❌ خطأ: {e}")
        return {'success': False, 'error': str(e)}
    finally:
        # إغلاق الملفات
        for file in files.values():
            file.close()

# مثال الاستخدام:
result = create_car_wash_request(
    token="YOUR_JWT_TOKEN",
    vehicle_id=456,
    service_type="full_clean",
    photos={
        'plate': '/path/to/plate.jpg',
        'front': '/path/to/front.jpg',
        'back': '/path/to/back.jpg',
        'right_side': '/path/to/right.jpg',
        'left_side': '/path/to/left.jpg',
    },
    requested_date='2025-01-20'
)
```

---

## 2️⃣ طلب فاتورة - مثال كامل

### Flutter/Dart Code
```dart
import 'package:dio/dio.dart';
import 'dart:io';

Future<Map<String, dynamic>> createInvoiceRequest({
  required String token,
  required int employeeId,
  required String vendorName,
  required double amount,
  required File invoiceImage,
  String? description,
}) async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://eissahr.replit.app',
    headers: {
      'Authorization': 'Bearer $token',
    },
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  try {
    // إنشاء FormData
    final formData = FormData.fromMap({
      'employee_id': employeeId.toString(),
      'vendor_name': vendorName,
      'amount': amount.toString(), // مهم: تحويل إلى String
      if (description != null && description.isNotEmpty) 
        'description': description,
      
      // الصورة - اسم الحقل الصحيح: invoice_image
      'invoice_image': await MultipartFile.fromFile(
        invoiceImage.path,
        filename: 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });

    print('🔄 إرسال طلب فاتورة...');
    
    final response = await dio.post(
      '/api/v1/requests/create-invoice',
      data: formData,
      onSendProgress: (sent, total) {
        final progress = (sent / total) * 100;
        print('📤 التقدم: ${progress.toStringAsFixed(1)}%');
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        print('✅ تم رفع الفاتورة بنجاح!');
        return {
          'success': true,
          'data': data['data'],
        };
      }
    }

    return {
      'success': false,
      'error': response.data['error'] ?? 'فشل رفع الفاتورة',
    };
  } on DioException catch (e) {
    print('❌ خطأ: ${e.message}');
    if (e.response != null) {
      print('📥 Response: ${e.response?.data}');
    }
    return {
      'success': false,
      'error': e.response?.data['error'] ?? e.message ?? 'حدث خطأ',
    };
  } catch (e) {
    print('❌ خطأ غير متوقع: $e');
    return {
      'success': false,
      'error': 'حدث خطأ غير متوقع',
    };
  }
}

// مثال الاستخدام:
void example() async {
  final result = await createInvoiceRequest(
    token: 'YOUR_JWT_TOKEN',
    employeeId: 123,
    vendorName: 'اسم المورد',
    amount: 1000.00,
    invoiceImage: File('/path/to/invoice.jpg'),
    description: 'وصف الفاتورة',
  );

  if (result['success'] == true) {
    print('✅ Request ID: ${result['data']['request_id']}');
  } else {
    print('❌ Error: ${result['error']}');
  }
}
```

### cURL Command
```bash
curl -X POST "https://eissahr.replit.app/api/v1/requests/create-invoice" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "employee_id=123" \
  -F "vendor_name=اسم المورد" \
  -F "amount=1000.00" \
  -F "description=وصف الفاتورة" \
  -F "invoice_image=@/path/to/invoice.jpg"
```

### Python Example
```python
import requests

def create_invoice_request(token, employee_id, vendor_name, amount, invoice_image_path, description=None):
    url = "https://eissahr.replit.app/api/v1/requests/create-invoice"
    
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    files = {
        'invoice_image': open(invoice_image_path, 'rb'),
    }
    
    data = {
        'employee_id': str(employee_id),
        'vendor_name': vendor_name,
        'amount': str(amount),  # مهم: تحويل إلى String
    }
    
    if description:
        data['description'] = description
    
    try:
        response = requests.post(url, headers=headers, files=files, data=data)
        response.raise_for_status()
        
        result = response.json()
        if result.get('success'):
            print(f"✅ تم رفع الفاتورة بنجاح! Request ID: {result['data']['request_id']}")
            return result
        else:
            print(f"❌ فشل: {result.get('error')}")
            return result
    except requests.exceptions.RequestException as e:
        print(f"❌ خطأ: {e}")
        return {'success': False, 'error': str(e)}
    finally:
        files['invoice_image'].close()

# مثال الاستخدام:
result = create_invoice_request(
    token="YOUR_JWT_TOKEN",
    employee_id=123,
    vendor_name="اسم المورد",
    amount=1000.00,
    invoice_image_path="/path/to/invoice.jpg",
    description="وصف الفاتورة"
)
```

---

## 3️⃣ رفع ملف إضافي لطلب موجود

### Flutter/Dart Code
```dart
import 'package:dio/dio.dart';
import 'dart:io';

Future<Map<String, dynamic>> uploadFileToRequest({
  required String token,
  required int requestId,
  required File file,
  required String fileType, // 'image' or 'video'
  String? description,
}) async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://eissahr.replit.app',
    headers: {
      'Authorization': 'Bearer $token',
    },
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  try {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: 'file_${DateTime.now().millisecondsSinceEpoch}.${fileType == 'image' ? 'jpg' : 'mp4'}',
      ),
      'file_type': fileType,
      if (description != null && description.isNotEmpty) 
        'description': description,
    });

    print('🔄 رفع ملف للطلب $requestId...');
    
    final response = await dio.post(
      '/api/v1/requests/$requestId/upload',
      data: formData,
      onSendProgress: (sent, total) {
        final progress = (sent / total) * 100;
        print('📤 التقدم: ${progress.toStringAsFixed(1)}%');
      },
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        print('✅ تم رفع الملف بنجاح!');
        return {
          'success': true,
          'data': data['data'],
        };
      }
    }

    return {
      'success': false,
      'error': response.data['error'] ?? 'فشل رفع الملف',
    };
  } on DioException catch (e) {
    print('❌ خطأ: ${e.message}');
    return {
      'success': false,
      'error': e.response?.data['error'] ?? e.message ?? 'حدث خطأ',
    };
  }
}
```

### cURL Command
```bash
curl -X POST "https://eissahr.replit.app/api/v1/requests/123/upload" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "file=@/path/to/file.jpg" \
  -F "file_type=image" \
  -F "description=صورة إضافية"
```

---

## ⚠️ نقاط مهمة

### 1. أسماء الحقول الصحيحة
- ✅ `photo_plate`, `photo_front`, `photo_back`, `photo_right_side`, `photo_left_side` (لطلب الغسيل)
- ✅ `invoice_image` (للفاتورة - ليس `image` أو `file`)
- ✅ `file` مع `file_type` (لرفع ملفات إضافية)

### 2. تنسيق البيانات
- ✅ `vehicle_id` و `employee_id` و `amount` يجب أن تكون **String** (ليس int أو double)
- ✅ `requested_date` يجب أن يكون `YYYY-MM-DD` (ليس مع الوقت)
- ✅ `service_type` يجب أن يكون: `'normal'`, `'polish'`, أو `'full_clean'`

### 3. معالجة الأخطاء
```dart
try {
  // ... إرسال الطلب
} on DioException catch (e) {
  switch (e.response?.statusCode) {
    case 401:
      print('❌ خطأ في المصادقة - تحقق من Token');
      break;
    case 400:
      print('❌ بيانات غير صحيحة: ${e.response?.data}');
      break;
    case 404:
      print('❌ المسار غير موجود');
      break;
    case 500:
      print('❌ خطأ في السيرفر');
      break;
    default:
      print('❌ خطأ غير معروف: ${e.message}');
  }
}
```

### 4. تتبع التقدم
```dart
onSendProgress: (sent, total) {
  final progress = (sent / total) * 100;
  print('📤 التقدم: ${progress.toStringAsFixed(1)}%');
  // تحديث UI
  setState(() {
    uploadProgress = progress;
  });
}
```

---

## 🔍 اختبار سريع

### Postman Collection
1. إنشاء Request جديد
2. Method: `POST`
3. URL: `https://eissahr.replit.app/api/v1/requests/create-car-wash`
4. Headers: `Authorization: Bearer YOUR_TOKEN`
5. Body → form-data:
   - `vehicle_id`: `456` (Text)
   - `service_type`: `full_clean` (Text)
   - `photo_plate`: [اختر File] (File)
   - `photo_front`: [اختر File] (File)
   - ... إلخ

### JavaScript/Node.js
```javascript
const FormData = require('form-data');
const fs = require('fs');
const axios = require('axios');

async function createCarWashRequest(token, vehicleId, serviceType, photos) {
  const formData = new FormData();
  
  formData.append('vehicle_id', vehicleId.toString());
  formData.append('service_type', serviceType);
  
  // إضافة الصور
  for (const [key, path] of Object.entries(photos)) {
    formData.append(`photo_${key}`, fs.createReadStream(path));
  }
  
  try {
    const response = await axios.post(
      'https://eissahr.replit.app/api/v1/requests/create-car-wash',
      formData,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          ...formData.getHeaders(),
        },
      }
    );
    
    if (response.data.success) {
      console.log('✅ تم إنشاء الطلب بنجاح!', response.data);
      return response.data;
    }
  } catch (error) {
    console.error('❌ خطأ:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}
```

---

## 📞 الدعم
إذا واجهت مشاكل:
1. ✅ تحقق من JWT Token
2. ✅ تحقق من أسماء الحقول (case-sensitive)
3. ✅ تحقق من تنسيق الملفات (JPG, PNG للصور)
4. ✅ راجع الـ Response للتفاصيل

