# 📋 متطلبات API لربط التطبيق مع Replit

> **تاريخ التقرير:** 2025-01-15  
> **الإصدار:** 2.0  
> **الحالة:** جاهز للمراجعة والتطوير

---

## 📊 تقرير حالة API - نظرة عامة

> **Base URL:** `https://eissahr.replit.app`

### ✅ Endpoints الموجودة والعاملة (10 endpoints)

| القسم | Method | Endpoint | الحالة | الملاحظات |
|------|--------|----------|--------|-----------|
| **🔐 المصادقة** | POST | `/api/v1/auth/login` | ✅ موجود | تسجيل دخول الموظف |
| **📋 الطلبات** | GET | `/api/v1/requests` | ✅ موجود | جلب قائمة الطلبات مع filters |
| **📋 الطلبات** | GET | `/api/v1/requests/{id}` | ✅ موجود | جلب تفاصيل طلب معين |
| **📋 الطلبات** | POST | `/api/v1/requests` | ✅ موجود | إنشاء طلب عام (جميع الأنواع) |
| **📋 الطلبات** | POST | `/api/v1/requests/{id}/upload` | ✅ موجود | رفع ملفات (صور/فيديوهات) |
| **📋 الطلبات** | GET | `/api/v1/requests/statistics` | ✅ موجود | إحصائيات الطلبات |
| **📋 الطلبات** | GET | `/api/v1/requests/types` | ✅ موجود | أنواع الطلبات المتاحة |
| **🚗 المركبات** | GET | `/api/v1/vehicles` | ✅ موجود | قائمة السيارات المخصصة للموظف |
| **🔔 الإشعارات** | GET | `/api/v1/notifications` | ✅ موجود | جلب إشعارات الموظف |
| **🔔 الإشعارات** | PUT | `/api/v1/notifications/{id}/read` | ✅ موجود | تحديد إشعار كمقروء |
| **📊 بيانات الموظف** | POST | `/api/external/employee-complete-profile` | ✅ موجود | الملف الشامل للموظف |
| **📊 بيانات الموظف** | POST | `/api/external/employee-location` | ✅ موجود | حفظ موقع GPS |
| **🧪 اختبار** | GET | `/api/external/test` | ✅ موجود | اختبار الاتصال |

### ⚠️ Endpoints المطلوبة والمفقودة (8 endpoints)

| Method | Endpoint المطلوب | الحالة | الأولوية | ملاحظات |
|--------|-----------------|--------|----------|---------|
| GET | `/api/v1/employee/liabilities` | ❌ مفقود | 🔴 عالية | **مطلوب بشدة - الالتزامات المالية** |
| GET | `/api/v1/employee/financial-summary` | ❌ مفقود | 🔴 عالية | **مطلوب بشدة - الملخص المالي** |
| POST | `/api/v1/requests/create-advance-payment` | ❌ مفقود | 🟡 متوسطة | يمكن استخدام `POST /api/v1/requests` |
| POST | `/api/v1/requests/create-invoice` | ❌ مفقود | 🟡 متوسطة | يمكن استخدام `POST /api/v1/requests` |
| POST | `/api/v1/requests/create-car-wash` | ❌ مفقود | 🟡 متوسطة | يمكن استخدام `POST /api/v1/requests` |
| POST | `/api/v1/requests/create-car-inspection` | ❌ مفقود | 🟡 متوسطة | يمكن استخدام `POST /api/v1/requests` |
| PUT | `/api/v1/notifications/mark-all-read` | ❌ مفقود | 🟢 منخفضة | nice to have - يمكن استخدام حل بديل |

---

## 🔄 الحلول البديلة الحالية (Workarounds)

### 1. إنشاء الطلبات المتخصصة

**الحل الحالي:** يمكن استخدام endpoint موحد:

```
POST /api/v1/requests
```

**Request Body:**
```json
{
  "type": "advance_payment",  // أو "invoice", "car_wash", "car_inspection"
  "data": {
    // بيانات الطلب حسب النوع
  }
}
```

**ملاحظة:** الـ endpoints المتخصصة توفر:
- ✅ Validation محسّن لكل نوع
- ✅ رسائل خطأ أوضح
- ✅ تجربة أفضل للمطورين

### 2. رفع الملفات

**الحل الحالي:** يمكن استخدام:

```
POST /api/v1/requests/{id}/upload
```

**Request Body (Form Data):**
```
file: [file]
file_type: "image" | "video"
description: "optional"
```

---

## 🎯 خطة التنفيذ المقترحة

### المرحلة 1: الالتزامات المالية (أولوية عالية) - يوم واحد

#### 1.1 إنشاء Database Schema

```sql
-- جدول الالتزامات المالية
CREATE TABLE employee_liabilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    liability_type VARCHAR(50) NOT NULL,  -- 'advance_payment', 'loan', 'penalty'
    total_amount DECIMAL(10,2) NOT NULL,
    remaining_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    start_date DATE NOT NULL,
    due_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employee(id)
);

-- جدول الأقساط
CREATE TABLE liability_installments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    liability_id INTEGER NOT NULL,
    installment_number INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    paid_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (liability_id) REFERENCES employee_liabilities(id)
);
```

#### 1.2 إنشاء Models

```python
# models/liability.py
class EmployeeLiability(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    employee_id = db.Column(db.Integer, db.ForeignKey('employee.id'), nullable=False)
    liability_type = db.Column(db.String(50), nullable=False)
    total_amount = db.Column(db.Numeric(10, 2), nullable=False)
    remaining_amount = db.Column(db.Numeric(10, 2), nullable=False)
    status = db.Column(db.String(20), default='active')
    start_date = db.Column(db.Date, nullable=False)
    due_date = db.Column(db.Date)
    notes = db.Column(db.Text)
    
    employee = db.relationship('Employee', backref='liabilities')
    installments = db.relationship('LiabilityInstallment', backref='liability', lazy='dynamic')

class LiabilityInstallment(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    liability_id = db.Column(db.Integer, db.ForeignKey('employee_liabilities.id'), nullable=False)
    installment_number = db.Column(db.Integer, nullable=False)
    amount = db.Column(db.Numeric(10, 2), nullable=False)
    due_date = db.Column(db.Date, nullable=False)
    paid_amount = db.Column(db.Numeric(10, 2), default=0)
    status = db.Column(db.String(20), default='pending')
    paid_date = db.Column(db.DateTime)
```

#### 1.3 إنشاء Endpoints

```python
# routes/api_employee_finance.py
@api_employee_requests.route('/employee/liabilities', methods=['GET'])
@token_required
def get_employee_liabilities(current_employee):
    """جلب الالتزامات المالية للموظف"""
    status_filter = request.args.get('status', 'all')
    
    liabilities = EmployeeFinanceService.get_employee_liabilities(
        current_employee.id,
        status_filter
    )
    
    return jsonify({
        'success': True,
        'data': liabilities
    }), 200

@api_employee_requests.route('/employee/financial-summary', methods=['GET'])
@token_required
def get_financial_summary(current_employee):
    """جلب الملخص المالي الشامل"""
    summary = EmployeeFinanceService.get_financial_summary(current_employee.id)
    
    return jsonify({
        'success': True,
        'data': summary
    }), 200
```

### المرحلة 2: Endpoints الطلبات المتخصصة (أولوية عالية) - يومان

#### 2.1 إنشاء Validation Functions

```python
# services/request_validation.py
def validate_advance_payment(employee_id, requested_amount, installments):
    """التحقق من صحة طلب السلفة"""
    employee = Employee.query.get(employee_id)
    
    # التحقق من الحد الأقصى
    max_advance = employee.salary * 3
    if requested_amount > max_advance:
        return False, f"الحد الأقصى للسلفة هو {max_advance} ريال"
    
    # التحقق من عدم وجود سلف نشطة
    active_advances = EmployeeLiability.query.filter_by(
        employee_id=employee_id,
        liability_type='advance_payment',
        status='active'
    ).count()
    
    if active_advances > 0:
        return False, "لديك سلفة نشطة بالفعل"
    
    # التحقق من عدد الأقساط
    if installments < 1 or installments > 12:
        return False, "عدد الأقساط يجب أن يكون بين 1 و 12"
    
    return True, "صحيح"
```

#### 2.2 إنشاء Endpoints المتخصصة

```python
@api_employee_requests.route('/requests/create-advance-payment', methods=['POST'])
@token_required
def create_advance_payment(current_employee):
    """إنشاء طلب سلفة متخصص"""
    data = request.get_json()
    
    # Validation
    is_valid, message = validate_advance_payment(
        current_employee.id,
        data.get('requested_amount'),
        data.get('installments')
    )
    
    if not is_valid:
        return jsonify({'success': False, 'error': message}), 400
    
    # إنشاء الطلب
    new_request = EmployeeRequest(
        employee_id=current_employee.id,
        request_type='advance_payment',
        title=f"طلب سلفة - {data.get('requested_amount')} ريال",
        status='pending',
        amount=data.get('requested_amount')
    )
    
    db.session.add(new_request)
    db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'تم إنشاء طلب السلفة بنجاح',
        'data': {
            'request_id': new_request.id,
            'type': 'advance_payment',
            'status': 'pending'
        }
    }), 201
```

### المرحلة 3: تحسينات رفع الملفات (أولوية متوسطة) - يوم واحد

```python
@api_employee_requests.route('/requests/<int:request_id>/upload-image', methods=['POST'])
@token_required
def upload_inspection_image(current_employee, request_id):
    """رفع صورة لطلب فحص السيارة"""
    # التحقق من الطلب
    request_obj = EmployeeRequest.query.get_or_404(request_id)
    
    if request_obj.employee_id != current_employee.id:
        return jsonify({'success': False, 'error': 'غير مصرح'}), 403
    
    if 'image' not in request.files:
        return jsonify({'success': False, 'error': 'لم يتم رفع صورة'}), 400
    
    # معالجة الصورة
    file = request.files['image']
    # حفظ الملف
    # إرجاع URL
    
    return jsonify({
        'success': True,
        'message': 'تم رفع الصورة بنجاح',
        'data': {
            'image_url': image_url,
            'image_id': image_id
        }
    }), 200
```

### المرحلة 4: الإشعارات (أولوية منخفضة) - نصف يوم

```python
@api_employee_requests.route('/notifications/mark-all-read', methods=['PUT'])
@token_required
def mark_all_notifications_read(current_employee):
    """تحديد جميع الإشعارات كمقروءة"""
    updated = Notification.query.filter_by(
        employee_id=current_employee.id,
        is_read=False
    ).update({'is_read': True})
    
    db.session.commit()
    
    return jsonify({
        'success': True,
        'message': 'تم تحديد جميع الإشعارات كمقروءة',
        'data': {
            'updated_count': updated
        }
    }), 200
```

---

## 🔐 المصادقة (Authentication)

### 1. تسجيل الدخول
**Endpoint:** `POST /api/v1/auth/login`

**Base URL:** `https://eissahr.replit.app`

**Request Body:**
```json
{
  "employee_id": "string",
  "password": "string"
}
```

**Response (Success 200):**
```json
{
  "success": true,
  "message": "تم تسجيل الدخول بنجاح",
  "data": {
    "token": "jwt_token_string",
    "refresh_token": "refresh_token_string",
    "expires_in": 3600
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "error": "رسالة الخطأ"
}
```

---

## 📋 الطلبات (Requests) - دليل الاستخدام الكامل

### 📌 نظرة عامة

التطبيق يستخدم **endpoint موحد** لإنشاء جميع أنواع الطلبات:
- `POST /api/external/requests` - لإنشاء جميع أنواع الطلبات
- `GET /api/external/requests` - لجلب قائمة الطلبات مع filters
- `GET /api/external/requests/<id>` - لجلب تفاصيل طلب معين
- `POST /api/external/requests/<id>/upload` - لرفع الملفات

---

### 1. جلب قائمة الطلبات ومتابعتها
**Endpoint:** `GET /api/v1/requests`

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Query Parameters (Optional):**
- `type`: 'advance' | 'invoice' | 'car_wash' | 'car_inspection'
- `status`: 'pending' | 'approved' | 'rejected' | 'completed'
- `date_from`: 'YYYY-MM-DD'
- `date_to`: 'YYYY-MM-DD'

**Response (Success 200):**
```json
{
  "success": true,
  "message": "تم جلب الطلبات بنجاح",
  "requests": [
    {
      "id": 1,
      "type": "advance",
      "title": "طلب سلفة",
      "status": "pending",
      "amount": 5000.00,
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-01-15T10:30:00Z",
      "admin_notes": null,
      "advance_data": {
        "requested_amount": 5000.00,
        "installments": 3,
        "reason": "سبب الطلب"
      }
    }
  ],
  "statistics": {
    "active_requests": 5,
    "approved_requests": 10,
    "rejected_requests": 2,
    "total_requests": 17
  }
}
```

### 2. جلب تفاصيل طلب معين (متابعة الطلب)
**Endpoint:** `GET /api/v1/requests/{id}`

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Response (Success 200):**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "type": "advance",
    "title": "طلب سلفة",
    "status": "pending",
    "status_ar": "قيد الانتظار",
    "amount": 5000.00,
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z",
    "admin_notes": "ملاحظات الإدارة",
    "advance_data": {
      "requested_amount": 5000.00,
      "installments": 3,
      "monthly_installment": 1666.67,
      "reason": "سبب الطلب"
    },
    "timeline": [
      {
        "status": "pending",
        "date": "2025-01-15T10:30:00Z",
        "note": "تم إنشاء الطلب"
      }
    ]
  }
}
```

**استخدام في Flutter:**
```dart
// متابعة حالة الطلب
Future<void> checkRequestStatus(int requestId) async {
  final result = await RequestsApiService.getRequestDetails(requestId);
  
  if (result['success'] == true) {
    final request = result['data'];
    print('حالة الطلب: ${request['status']}');
    print('ملاحظات الإدارة: ${request['admin_notes']}');
  }
}
```

---

### 3. إنشاء الطلبات - استخدام Endpoint موحد

> **ملاحظة:** يمكن استخدام endpoint موحد `POST /api/v1/requests` لإنشاء جميع أنواع الطلبات، أو استخدام endpoints متخصصة (إن كانت متوفرة).

#### 3.1 إنشاء طلب سلفة (باستخدام Endpoint موحد)
**Endpoint:** `POST /api/v1/requests` (موحد) أو `POST /api/v1/requests/create-advance-payment` (متخصص - مفقود حالياً)

**Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "employee_id": 123,
  "requested_amount": 5000.00,
  "installments": 3,
  "reason": "سبب الطلب (اختياري)"
}
```

**Response (Success 200/201):**
```json
{
  "success": true,
  "message": "تم إنشاء الطلب بنجاح",
  "data": {
    "request_id": 1,
    "status": "pending",
    "pdf_url": "https://example.com/pdf/request_1.pdf"
  }
}
```

### 4. رفع فاتورة
**Endpoint:** `POST /api/external/requests/create-invoice`

**Endpoint:** `POST /api/external/requests` (موحد) أو `POST /api/external/requests/create-invoice` (متخصص)

**Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: multipart/form-data
```

**Request Body (Form Data - Endpoint موحد):**
```
type: "invoice"
employee_id: 123
vendor_name: "اسم المورد"
amount: 1000.00
description: "وصف الفاتورة (اختياري)"
invoice_image: [file]
```

**Request Body (Form Data - Endpoint متخصص):**
```
employee_id: 123
vendor_name: "اسم المورد"
amount: 1000.00
description: "وصف الفاتورة (اختياري)"
invoice_image: [file]
```

**Response (Success 200/201):**
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

**استخدام في Flutter:**
```dart
// رفع فاتورة مع تتبع التقدم
Future<void> uploadInvoice(File imageFile) async {
  final request = InvoiceRequest(
    employeeId: 123,
    vendorName: 'اسم المورد',
    amount: 1000.00,
    description: 'وصف الفاتورة',
    imagePath: imageFile.path,
  );
  
  final result = await RequestsApiService.createInvoice(
    request,
    onProgress: (sent, total) {
      final progress = (sent / total) * 100;
      print('تم رفع: ${progress.toStringAsFixed(1)}%');
    },
  );
  
  if (result['success'] == true) {
    print('تم رفع الفاتورة بنجاح');
  }
}
```

---

#### 3.3 إنشاء طلب غسيل سيارة
**Endpoint:** `POST /api/v1/requests` (موحد) أو `POST /api/v1/requests/create-car-wash` (متخصص - مفقود حالياً)

**Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: multipart/form-data
```

**Request Body (Form Data - Endpoint موحد):**
```
type: "car_wash"
employee_id: 123
vehicle_id: 456
service_type: "full_clean"
requested_date: "2025-01-20" (optional)
photo_plate: [file]
photo_front: [file]
photo_back: [file]
photo_right_side: [file]
photo_left_side: [file]
```

**Request Body (Form Data - Endpoint متخصص):**
```
employee_id: 123
vehicle_id: 456
service_type: "normal" | "polish" | "full_clean"
requested_date: "2025-01-20" (optional)
photo_plate: [file]
photo_front: [file]
photo_back: [file]
photo_right_side: [file]
photo_left_side: [file]
```

**Response (Success 200/201):**
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

---

#### 3.4 إنشاء طلب فحص وتوثيق سيارة
**Endpoint:** `POST /api/v1/requests` (موحد) أو `POST /api/v1/requests/create-car-inspection` (متخصص - مفقود حالياً)

**Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

**Request Body (Endpoint موحد):**
```json
{
  "type": "car_inspection",
  "data": {
    "employee_id": 123,
    "vehicle_id": 456,
    "inspection_type": "delivery",
    "description": "وصف الفحص (اختياري)"
  }
}
```

**Request Body (Endpoint متخصص):**
```json
{
  "employee_id": 123,
  "vehicle_id": 456,
  "inspection_type": "delivery" | "receipt",
  "description": "وصف الفحص (اختياري)"
}
```

**Response (Success 200/201):**
```json
{
  "success": true,
  "message": "تم إنشاء طلب الفحص بنجاح",
  "data": {
    "request_id": 4,
    "type": "car_inspection",
    "status": "pending",
    "inspection_type": "delivery",
    "inspection_type_ar": "فحص تسليم",
    "vehicle_plate": "ABC 123",
    "upload_instructions": {
      "max_images": 20,
      "max_videos": 3,
      "max_image_size_mb": 10,
      "max_video_size_mb": 500
    }
  }
}
```

**استخدام في Flutter:**
```dart
// إنشاء طلب فحص ثم رفع الملفات
Future<void> createInspectionRequest() async {
  // 1. إنشاء الطلب
  final request = CarInspectionRequest(
    employeeId: 123,
    vehicleId: 456,
    inspectionType: 'delivery',
    description: 'وصف الفحص',
  );
  
  final result = await RequestsApiService.createCarInspection(request);
  
  if (result['success'] == true) {
    final requestId = result['data']['request_id'];
    
    // 2. رفع الصور
    for (var imageFile in imageFiles) {
      await RequestsApiService.uploadInspectionImage(
        requestId,
        imageFile,
        onProgress: (sent, total) {
          print('تم رفع: ${(sent / total * 100).toStringAsFixed(1)}%');
        },
      );
    }
    
    // 3. رفع الفيديوهات
    for (var videoFile in videoFiles) {
      await RequestsApiService.uploadInspectionVideo(
        requestId,
        videoFile,
        onProgress: (sent, total) {
          print('تم رفع: ${(sent / total * 100).toStringAsFixed(1)}%');
        },
      );
    }
  }
}
```

---

### 4. رفع الملفات (صور وفيديوهات)

#### 4.1 رفع ملفات (Endpoint موحد)
**Endpoint:** `POST /api/v1/requests/{id}/upload`

**Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: multipart/form-data
```

**Request Body (Form Data):**
```
file: [file]
file_type: "image" | "video"
description: "وصف الملف (اختياري)"
```

**Response (Success 200):**
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

#### 4.2 رفع صورة متخصصة (إن كانت متوفرة)
**Endpoint:** `POST /api/external/requests/{request_id}/upload-inspection-image`

**Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: multipart/form-data
```

**Request Body (Form Data):**
```
image: [file] (JPEG/PNG/HEIC, max 10MB)
description: "وصف الصورة (اختياري)"
```

**Response (Success 200):**
```json
{
  "success": true,
  "message": "تم رفع الصورة بنجاح",
  "data": {
    "image_url": "https://example.com/uploads/inspection_4_1.jpg",
    "image_id": "img_001",
    "total_images": 5,
    "remaining_slots": 15
  }
}
```

#### 4.3 رفع فيديو متخصص (إن كان متوفراً)
**Endpoint:** `POST /api/external/requests/{request_id}/upload-inspection-video`

**Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: multipart/form-data
```

**Request Body (Form Data):**
```
video: [file] (MP4/MOV, max 500MB)
description: "وصف الفيديو (اختياري)"
```

**Response (Success 200):**
```json
{
  "success": true,
  "message": "تم رفع الفيديو بنجاح",
  "data": {
    "video_url": "https://example.com/uploads/inspection_4_video1.mp4",
    "video_id": "vid_001",
    "file_size_mb": 45.2,
    "duration_seconds": 30,
    "total_videos": 2,
    "remaining_slots": 1
  }
}
```

**استخدام في Flutter:**
```dart
// رفع ملفات مع تتبع التقدم
Future<void> uploadFiles(int requestId, List<File> files) async {
  for (var file in files) {
    final isVideo = file.path.endsWith('.mp4') || file.path.endsWith('.mov');
    
    final result = await RequestsApiService.uploadFile(
      requestId,
      file,
      fileType: isVideo ? 'video' : 'image',
      onProgress: (sent, total) {
        final progress = (sent / total) * 100;
        print('تم رفع: ${progress.toStringAsFixed(1)}%');
      },
    );
    
    if (result['success'] == true) {
      print('تم رفع الملف: ${result['data']['file_url']}');
    }
  }
}
```

---

### 5. متابعة حالة الطلبات

#### 5.1 جلب قائمة الطلبات مع Filters
**Endpoint:** `GET /api/external/requests` أو `GET /api/external/requests/my-requests`

**Query Parameters:**
```
?type=advance_payment          // فلترة حسب النوع
?status=pending                // فلترة حسب الحالة
?date_from=2025-01-01          // من تاريخ
?date_to=2025-01-31            // إلى تاريخ
?page=1                        // رقم الصفحة
?per_page=20                   // عدد النتائج في الصفحة
```

**استخدام في Flutter:**
```dart
// جلب الطلبات مع filters
Future<void> loadRequests() async {
  final result = await RequestsApiService.getMyRequests(
    type: 'advance_payment',      // فقط طلبات السلفة
    status: 'pending',            // فقط الطلبات قيد الانتظار
    dateFrom: DateTime(2025, 1, 1),
    dateTo: DateTime(2025, 1, 31),
  );
  
  if (result['success'] == true) {
    final requests = result['data'] as List<Request>;
    final statistics = result['statistics'] as RequestStatistics;
    
    print('إجمالي الطلبات: ${statistics.totalRequests}');
    print('الطلبات النشطة: ${statistics.activeRequests}');
    
    for (var request in requests) {
      print('طلب #${request.id}: ${request.status}');
    }
  }
}
```

#### 5.2 جلب إحصائيات الطلبات
**Endpoint:** `GET /api/external/requests/statistics`

**Response (Success 200):**
```json
{
  "success": true,
  "data": {
    "active_requests": 5,
    "approved_requests": 10,
    "rejected_requests": 2,
    "completed_requests": 3,
    "total_requests": 20,
    "by_type": {
      "advance_payment": 8,
      "invoice": 5,
      "car_wash": 4,
      "car_inspection": 3
    }
  }
}
```

---

## 💳 الالتزامات المالية (Liabilities) - ⚠️ يحتاج تطوير

> **⚠️ مهم:** هذا القسم **غير موجود حالياً** في API ويحتاج تطوير فوري.

### 📌 نظرة عامة

قسم الالتزامات المالية يعرض:
- التزامات الموظف المالية (سلف، أقساط، غرامات)
- تفاصيل الأقساط الشهرية
- الملخص المالي الشامل
- القسط القادم المستحق

---

### 1. جلب الالتزامات المالية
**Endpoint:** `GET /api/external/employee/liabilities` ⚠️ **مفقود - يحتاج تطوير**

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Query Parameters (Optional):**
- `status`: 'active' | 'paid' | 'all'
- `type`: 'advance_payment' | 'loan' | 'penalty'

**Response (Success 200):**
```json
{
  "success": true,
  "data": {
    "total_liabilities": 15000.00,
    "active_liabilities": 10000.00,
    "paid_liabilities": 5000.00,
    "liabilities": [
      {
        "id": 1,
        "type": "advance_payment",
        "type_ar": "سلفة",
        "total_amount": 5000.00,
        "remaining_amount": 3333.33,
        "paid_amount": 1666.67,
        "status": "active",
        "status_ar": "نشط",
        "start_date": "2025-01-01",
        "due_date": "2025-04-01",
        "installments_total": 3,
        "installments_paid": 1,
        "installments": [
          {
            "id": 1,
            "installment_number": 1,
            "amount": 1666.67,
            "due_date": "2025-02-01",
            "status": "paid",
            "status_ar": "مدفوع",
            "paid_date": "2025-01-28",
            "paid_amount": 1666.67
          },
          {
            "id": 2,
            "installment_number": 2,
            "amount": 1666.67,
            "due_date": "2025-03-01",
            "status": "pending",
            "status_ar": "قيد الانتظار",
            "paid_date": null,
            "paid_amount": 0
          },
          {
            "id": 3,
            "installment_number": 3,
            "amount": 1666.66,
            "due_date": "2025-04-01",
            "status": "pending",
            "status_ar": "قيد الانتظار",
            "paid_date": null,
            "paid_amount": 0
          }
        ],
        "next_due_date": "2025-03-01",
        "next_due_amount": 1666.67
      }
    ]
  }
}
```

**استخدام في Flutter:**
```dart
// جلب الالتزامات المالية
Future<void> loadLiabilities() async {
  final result = await LiabilitiesApiService.getLiabilities(
    status: 'active',  // فقط الالتزامات النشطة
  );
  
  if (result['success'] == true) {
    final summary = result['data'] as LiabilitiesSummary;
    
    print('إجمالي الالتزامات: ${summary.totalLiabilities} ر.س');
    print('الالتزامات النشطة: ${summary.activeLiabilities} ر.س');
    print('الالتزامات المسددة: ${summary.paidLiabilities} ر.س');
    
    for (var liability in summary.liabilities) {
      print('التزام #${liability.id}: ${liability.typeLabel}');
      print('المبلغ المتبقي: ${liability.remaining} ر.س');
      
      // عرض الأقساط
      for (var installment in liability.installments) {
        print('  القسط ${installment.installmentNumber}: ${installment.status}');
      }
    }
  }
}
```

---

### 2. جلب الملخص المالي
**Endpoint:** `GET /api/external/employee/financial-summary` ⚠️ **مفقود - يحتاج تطوير**

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Response (Success 200):**
```json
{
  "success": true,
  "data": {
    "current_balance": 5000.00,
    "total_earnings": 50000.00,
    "total_deductions": 45000.00,
    "active_liabilities": 10000.00,
    "paid_liabilities": 5000.00,
    "pending_requests": 3,
    "approved_requests": 10,
    "rejected_requests": 2,
    "last_salary": {
      "amount": 8500.00,
      "month": "2025-01",
      "paid_date": "2025-01-25"
    },
    "upcoming_installment": {
      "amount": 1666.67,
      "due_date": "2025-03-01",
      "liability_type": "advance_payment",
      "liability_id": 1
    },
    "monthly_summary": {
      "total_income": 8500.00,
      "total_deductions": 2000.00,
      "installments": 1666.67,
      "net_income": 4833.33
    }
  }
}
```

**استخدام في Flutter:**
```dart
// جلب الملخص المالي
Future<void> loadFinancialSummary() async {
  final result = await LiabilitiesApiService.getFinancialSummary();
  
  if (result['success'] == true) {
    final summary = result['data'] as FinancialSummary;
    
    print('الرصيد الحالي: ${summary.currentBalance} ر.س');
    print('إجمالي المكتسبات: ${summary.totalEarnings} ر.س');
    print('إجمالي الخصومات: ${summary.totalDeductions} ر.س');
    
    if (summary.upcomingInstallment != null) {
      print('القسط القادم: ${summary.upcomingInstallment!.amount} ر.س');
      print('تاريخ الاستحقاق: ${summary.upcomingInstallment!.dueDate}');
    }
  }
}
```

---

### 📋 متطلبات Database للالتزامات المالية

يجب إنشاء الجداول التالية في Replit:

```sql
-- جدول الالتزامات المالية
CREATE TABLE employee_liabilities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    liability_type VARCHAR(50) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    remaining_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    start_date DATE NOT NULL,
    due_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employee(id)
);

-- جدول الأقساط
CREATE TABLE liability_installments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    liability_id INTEGER NOT NULL,
    installment_number INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    paid_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (liability_id) REFERENCES employee_liabilities(id)
);
```

---

## 🔔 الإشعارات (Notifications) - ✅ موجود ويعمل

### 📌 نظرة عامة

نظام الإشعارات يعمل بشكل كامل ويوفر:
- جلب جميع الإشعارات أو غير المقروءة فقط
- تحديد إشعار كمقروء
- عداد الإشعارات غير المقروءة
- أنواع مختلفة من الإشعارات

---

### 1. جلب الإشعارات
**Endpoint:** `GET /api/external/notifications` ✅ **موجود**

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Query Parameters (Optional):**
- `status`: 'all' | 'unread' (افتراضي: 'all')

**Response (Success 200):**
```json
{
  "success": true,
  "notifications": [
    {
      "id": 1,
      "title": "تم اعتماد طلبك",
      "message": "تم اعتماد طلب السلفة رقم 123",
      "type": "request_approved",
      "is_read": false,
      "created_at": "2025-01-15T10:30:00Z",
      "data": {
        "request_id": 123,
        "request_type": "advance"
      }
    },
    {
      "id": 2,
      "title": "قسط مستحق",
      "message": "القسط الأول من السلفة مستحق بتاريخ 2025-02-01",
      "type": "liability_due",
      "is_read": false,
      "created_at": "2025-01-20T08:00:00Z",
      "data": {
        "liability_id": 1,
        "installment_number": 1,
        "due_date": "2025-02-01"
      }
    }
  ],
  "unread_count": 5
}
```

**استخدام في Flutter:**
```dart
// جلب الإشعارات
Future<void> loadNotifications() async {
  // جلب جميع الإشعارات
  final allResult = await NotificationsApiService.getNotifications(
    status: 'all',
  );
  
  // جلب الإشعارات غير المقروءة فقط
  final unreadResult = await NotificationsApiService.getNotifications(
    status: 'unread',
  );
  
  if (allResult['success'] == true) {
    final notifications = allResult['data'] as List<Notification>;
    final unreadCount = allResult['unread_count'] as int;
    
    print('إجمالي الإشعارات: ${notifications.length}');
    print('الإشعارات غير المقروءة: $unreadCount');
    
    for (var notification in notifications) {
      if (!notification.isRead) {
        print('إشعار جديد: ${notification.title}');
      }
    }
  }
}
```

---

### 2. تحديد إشعار كمقروء
**Endpoint:** `PUT /api/external/notifications/{notification_id}/mark-read` ✅ **موجود**

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Response (Success 200):**
```json
{
  "success": true,
  "message": "تم تحديد الإشعار كمقروء",
  "data": {
    "notification_id": 1,
    "is_read": true
  }
}
```

**استخدام في Flutter:**
```dart
// تحديد إشعار كمقروء
Future<void> markNotificationAsRead(int notificationId) async {
  final result = await NotificationsApiService.markAsRead(notificationId);
  
  if (result['success'] == true) {
    print('تم تحديد الإشعار كمقروء');
    // تحديث عداد الإشعارات غير المقروءة
    await loadNotificationsCount();
  }
}

// عند فتح الإشعار
void onNotificationTap(Notification notification) {
  // فتح تفاصيل الإشعار
  if (notification.data?['request_id'] != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetailsScreen(
          requestId: notification.data!['request_id'],
        ),
      ),
    );
  }
  
  // تحديد كمقروء
  if (!notification.isRead) {
    markNotificationAsRead(notification.id);
  }
}
```

---

### 3. تحديد جميع الإشعارات كمقروءة
**Endpoint:** `PUT /api/external/notifications/mark-all-read` ⚠️ **مفقود - nice to have**

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Response (Success 200):**
```json
{
  "success": true,
  "message": "تم تحديد جميع الإشعارات كمقروءة",
  "data": {
    "updated_count": 15,
    "unread_count": 0
  }
}
```

**استخدام في Flutter (Workaround حالياً):**
```dart
// تحديد جميع الإشعارات كمقروءة (حل بديل)
Future<void> markAllNotificationsAsRead() async {
  // جلب جميع الإشعارات غير المقروءة
  final result = await NotificationsApiService.getNotifications(
    status: 'unread',
  );
  
  if (result['success'] == true) {
    final notifications = result['data'] as List<Notification>;
    
    // تحديد كل إشعار كمقروء
    for (var notification in notifications) {
      await NotificationsApiService.markAsRead(notification.id);
    }
    
    print('تم تحديد ${notifications.length} إشعار كمقروء');
  }
}
```

---

### 4. عداد الإشعارات غير المقروءة

**استخدام في Flutter:**
```dart
// جلب عدد الإشعارات غير المقروءة
Future<int> getUnreadNotificationsCount() async {
  final result = await NotificationsApiService.getNotifications(
    status: 'unread',
  );
  
  if (result['success'] == true) {
    return result['unread_count'] as int;
  }
  
  return 0;
}

// تحديث العداد في Tab Bar
Future<void> updateNotificationsBadge() async {
  final count = await getUnreadNotificationsCount();
  setState(() {
    _unreadNotificationsCount = count;
  });
}

// استدعاء عند فتح صفحة الإشعارات
void onNotificationsTabTapped() {
  setState(() {
    _currentIndex = 7;  // index صفحة الإشعارات
  });
  // تحديث العداد
  updateNotificationsBadge();
}
```

---

## 📊 بيانات الموظف (Employee Data)

### 1. جلب الملف الشامل للموظف
**Endpoint:** `POST /api/external/employee-complete-profile`

**Headers:**
```
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "job_number": "string",
  "api_key": "string (optional if using JWT)"
}
```

**Response (Success 200):**
```json
{
  "success": true,
  "data": {
    "employee": {
      "id": 123,
      "name": "اسم الموظف",
      "job_number": "5216",
      "department": "القسم",
      "position": "المنصب"
    },
    "current_car": {
      "car_id": "456",
      "plate_number": "ABC 123",
      "model": "Toyota Camry",
      "year": 2020
    },
    "previous_cars": [],
    "attendance": [],
    "salaries": [],
    "operations": [],
    "statistics": {
      "salaries": {
        "last_salary": 10000.00
      }
    }
  }
}
```

---

## ⚠️ معالجة الأخطاء (Error Handling)

### رموز الحالة (Status Codes)
- `200`: نجاح العملية
- `201`: تم الإنشاء بنجاح
- `400`: خطأ في البيانات المرسلة
- `401`: غير مصرح (يجب تسجيل الدخول)
- `404`: غير موجود
- `500`: خطأ في الخادم
- `503`: الخادم غير متاح

### تنسيق رسالة الخطأ
```json
{
  "success": false,
  "error": "رسالة الخطأ بالعربية",
  "message": "تفاصيل إضافية (اختياري)"
}
```

---

## 📦 نماذج البيانات (Data Models)

### نموذج الطلب (Request)
```json
{
  "id": 1,
  "type": "advance" | "invoice" | "car_wash" | "car_inspection",
  "title": "عنوان الطلب",
  "status": "pending" | "approved" | "rejected" | "completed",
  "amount": 5000.00,
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z",
  "admin_notes": "ملاحظات الإدارة (اختياري)",
  "advance_data": { /* بيانات السلفة */ },
  "invoice_data": { /* بيانات الفاتورة */ },
  "car_wash_data": { /* بيانات غسيل السيارة */ },
  "inspection_data": { /* بيانات فحص السيارة */ }
}
```

### بيانات طلب السلفة (Advance Data)
```json
{
  "requested_amount": 5000.00,
  "installments": 3,
  "monthly_installment": 1666.67,
  "reason": "سبب الطلب (اختياري)"
}
```

### بيانات الفاتورة (Invoice Data)
```json
{
  "vendor_name": "اسم المورد",
  "amount": 1000.00,
  "description": "وصف الفاتورة (اختياري)",
  "image_url": "https://example.com/invoice.jpg"
}
```

### بيانات غسيل السيارة (Car Wash Data)
```json
{
  "vehicle_id": 456,
  "service_type": "normal" | "polish" | "full_clean",
  "requested_date": "2025-01-20",
  "photos": {
    "plate": "https://example.com/plate.jpg",
    "front": "https://example.com/front.jpg",
    "back": "https://example.com/back.jpg",
    "right_side": "https://example.com/right.jpg",
    "left_side": "https://example.com/left.jpg"
  }
}
```

### بيانات فحص السيارة (Inspection Data)
```json
{
  "vehicle_id": 456,
  "inspection_type": "delivery" | "receipt",
  "description": "وصف الفحص (اختياري)",
  "images": [
    "https://example.com/image1.jpg",
    "https://example.com/image2.jpg"
  ],
  "videos": [
    "https://example.com/video1.mp4"
  ]
}
```

### نموذج الالتزام المالي (Liability)
```json
{
  "id": 1,
  "type": "advance" | "damage" | "debt",
  "description": "وصف الالتزام",
  "amount": 5000.00,
  "paid": 1666.67,
  "remaining": 3333.33,
  "status": "active" | "completed" | "cancelled",
  "created_at": "2025-01-15T10:30:00Z",
  "due_date": "2025-02-15",
  "monthly_installment": 1666.67,
  "remaining_installments": 2,
  "installments": [
    {
      "installment_number": 1,
      "amount": 1666.67,
      "due_date": "2025-02-15",
      "status": "paid" | "pending",
      "paid_date": "2025-02-10"
    }
  ]
}
```

### نموذج الإشعار (Notification)
```json
{
  "id": 1,
  "title": "عنوان الإشعار",
  "message": "محتوى الإشعار",
  "type": "request_approved" | "request_rejected" | "request_pending" | "liability_due",
  "is_read": false,
  "created_at": "2025-01-15T10:30:00Z",
  "data": {
    "request_id": 123,
    "request_type": "advance"
  }
}
```

---

## 📝 ملاحظات مهمة

### 1. المصادقة
- جميع الـ endpoints (عدا تسجيل الدخول) تتطلب JWT token في header
- Token يجب أن يكون في الصيغة: `Authorization: Bearer {token}`
- عند انتهاء صلاحية Token، يجب استخدام refresh token أو إعادة تسجيل الدخول

### 2. رفع الملفات
- الحد الأقصى لحجم الصورة: 10MB
- الحد الأقصى لحجم الفيديو: 500MB
- الصور المدعومة: JPEG, PNG
- الفيديوهات المدعومة: MP4, MOV

### 3. التواريخ
- جميع التواريخ بصيغة ISO 8601: `YYYY-MM-DDTHH:mm:ssZ`
- أو بصيغة: `YYYY-MM-DD` للتواريخ فقط

### 4. الأرقام
- جميع المبالغ المالية بصيغة float/decimal
- الأرقام الصحيحة بصيغة integer

### 5. اللغة
- جميع الرسائل والبيانات بالعربية
- أسماء الحقول بالإنجليزية

---

## 🔄 Backup URLs

في حالة فشل الاتصال بالـ URL الأساسي، التطبيق سيحاول الاتصال بـ URL بديل:
- **Base URL:** `https://eissahr.replit.app`
- **Backup URL:** `https://d72f2aef-918c-4148-9723-15870f8c7cf6-00-2c1ygyxvqoldk.riker.replit.dev`

---

## ✅ قائمة التحقق (Checklist)

### ✅ Endpoints الموجودة (جاهزة للاستخدام)

- [x] تسجيل الدخول يعمل
- [x] جلب قائمة الطلبات يعمل (مع filters)
- [x] جلب تفاصيل طلب يعمل
- [x] إنشاء طلب عام يعمل (جميع الأنواع)
- [x] رفع ملفات يعمل
- [x] جلب إحصائيات الطلبات يعمل
- [x] جلب أنواع الطلبات يعمل
- [x] جلب قائمة السيارات يعمل
- [x] جلب الإشعارات يعمل
- [x] تحديد إشعار كمقروء يعمل
- [x] جلب الملف الشامل للموظف يعمل
- [x] حفظ موقع GPS يعمل

### ⚠️ Endpoints المطلوبة (تحتاج تطوير)

#### 🔴 أولوية عالية (يجب إضافتها أولاً)

- [ ] **جلب الالتزامات المالية** - `GET /api/external/employee/liabilities`
- [ ] **جلب الملخص المالي** - `GET /api/external/employee/financial-summary`
- [ ] **إنشاء طلب سلفة متخصص** - `POST /api/external/requests/create-advance-payment` (اختياري - يمكن استخدام endpoint موحد)
- [ ] **إنشاء طلب فاتورة متخصص** - `POST /api/external/requests/create-invoice` (اختياري)
- [ ] **إنشاء طلب غسيل متخصص** - `POST /api/external/requests/create-car-wash` (اختياري)
- [ ] **إنشاء طلب فحص متخصص** - `POST /api/external/requests/create-car-inspection` (اختياري)

#### 🟡 أولوية متوسطة

- [ ] **رفع صورة متخصص** - `POST /api/external/requests/<id>/upload-inspection-image` (اختياري - يمكن استخدام upload عام)
- [ ] **رفع فيديو متخصص** - `POST /api/external/requests/<id>/upload-inspection-video` (اختياري)

#### 🟢 أولوية منخفضة

- [ ] **تحديد جميع الإشعارات** - `PUT /api/external/notifications/mark-all-read` (nice to have)

---

## 📊 ملخص الحالة

### ✅ ما يعمل حالياً

التطبيق Flutter **جاهز للاستخدام** مع الـ endpoints الموجودة:

1. ✅ **تسجيل الدخول** - يعمل بشكل كامل
2. ✅ **الطلبات** - يمكن إنشاء وجلب جميع أنواع الطلبات باستخدام endpoint موحد
3. ✅ **رفع الملفات** - يعمل لجميع أنواع الملفات
4. ✅ **الإشعارات** - جلب وتحديد كمقروء يعمل
5. ✅ **بيانات الموظف** - جلب الملف الشامل يعمل

### ⚠️ ما يحتاج تطوير

1. 🔴 **الالتزامات المالية** - **مطلوب بشدة** (لا يوجد workaround)
2. 🔴 **الملخص المالي** - **مطلوب بشدة** (لا يوجد workaround)
3. 🟡 **Endpoints متخصصة** - اختيارية (يمكن استخدام endpoint موحد)
4. 🟢 **mark-all-read** - nice to have

---

## 🎯 توصيات فورية

### للتطبيق Flutter

**يمكن البدء في التطوير الآن** باستخدام:

1. ✅ Endpoint موحد لإنشاء الطلبات: `POST /api/external/requests`
2. ✅ Endpoint موحد لرفع الملفات: `POST /api/external/requests/<id>/upload`
3. ✅ جميع endpoints الجلب موجودة وتعمل

**يجب الانتظار لتطوير:**

1. ⏳ صفحة الالتزامات المالية (تحتاج endpoints جديدة)
2. ⏳ صفحة الملخص المالي (تحتاج endpoint جديد)

### لـ Replit Backend

**يجب تطوير فوراً:**

1. 🔴 Database schema للالتزامات المالية
2. 🔴 Endpoint الالتزامات المالية
3. 🔴 Endpoint الملخص المالي
4. 🔴 Business logic لحساب الأقساط

**يمكن تأجيلها:**

1. 🟡 Endpoints متخصصة للطلبات (يمكن استخدام endpoint موحد)
2. 🟢 mark-all-read للإشعارات

---

## 📞 للتواصل

في حالة وجود أي استفسارات أو مشاكل في التنفيذ، يرجى التواصل مع فريق التطوير.

**آخر تحديث:** 2025-01-15  
**الإصدار:** 2.0  
**الحالة:** جاهز للمراجعة والتطوير 🚀

