# 🔌 دليل ربط API لصفحة الموظف - Employee API Integration Guide

## 📋 نظرة عامة

هذا الدليل يوضح كيفية ربط صفحة الموظف مع API السيرفر، بما في ذلك:
- هيكل API Endpoints
- نماذج البيانات (Models)
- خدمة API (Service)
- معالجة الأخطاء
- التحديث التلقائي

---

## 🔗 Base URL

```dart
static const String baseUrl = 'https://d72f2aef-918c-4148-9723-15870f8c7cf6-00-2c1ygyxvqoldk.riker.replit.dev';
```

---

## 📡 API Endpoints

### **1. جلب بيانات الموظف**
```
GET /api/external/employee-profile
```

**Request:**
```json
{
  "api_key": "test_location_key_2025",
  "job_number": "12345"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "تم جلب البيانات بنجاح",
  "data": {
    "job_number": "12345",
    "name": "أحمد محمد علي",
    "name_en": "Ahmed Mohammed Ali",
    "department": "التسليم",
    "department_en": "Delivery",
    "position": "سائق",
    "position_en": "Driver",
    "phone": "0501234567",
    "email": "ahmed@example.com",
    "hire_date": "2020-01-15",
    "is_driver": true,
    "photos": {
      "personal": "https://example.com/photos/12345/personal.jpg",
      "id": "https://example.com/photos/12345/id.jpg",
      "license": "https://example.com/photos/12345/license.jpg"
    },
    "address": "الرياض، حي النخيل، شارع الملك فهد",
    "national_id": "1234567890"
  }
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "الموظف غير موجود",
  "error": "EMPLOYEE_NOT_FOUND"
}
```

---

### **2. جلب الحضور**
```
GET /api/external/employee-attendance
```

**Request:**
```json
{
  "api_key": "test_location_key_2025",
  "job_number": "12345",
  "start_date": "2025-01-01",  // optional
  "end_date": "2025-01-31"      // optional
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "تم جلب البيانات بنجاح",
  "data": [
    {
      "date": "2025-01-27",
      "check_in": "08:00:00",
      "check_out": "17:00:00",
      "status": "present",
      "hours_worked": 9.0,
      "late_minutes": 0,
      "early_leave_minutes": 0,
      "notes": ""
    },
    {
      "date": "2025-01-26",
      "check_in": "08:15:00",
      "check_out": "17:00:00",
      "status": "late",
      "hours_worked": 8.75,
      "late_minutes": 15,
      "early_leave_minutes": 0,
      "notes": "تأخر بسبب الزحام"
    },
    {
      "date": "2025-01-25",
      "check_in": null,
      "check_out": null,
      "status": "absent",
      "hours_worked": 0.0,
      "late_minutes": 0,
      "early_leave_minutes": 0,
      "notes": "إجازة مرضية"
    }
  ],
  "summary": {
    "total_days": 31,
    "present_days": 25,
    "absent_days": 3,
    "late_days": 2,
    "early_leave_days": 1,
    "total_hours": 225.5
  }
}
```

**Status Values:**
- `present`: حاضر
- `absent`: غائب
- `late`: متأخر
- `early_leave`: خروج مبكر
- `holiday`: إجازة

---

### **3. جلب السيارات المرتبطة**
```
GET /api/external/employee-cars
```

**Request:**
```json
{
  "api_key": "test_location_key_2025",
  "job_number": "12345"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "تم جلب البيانات بنجاح",
  "data": [
    {
      "car_id": "CAR001",
      "plate_number": "أ ب ج 1234",
      "plate_number_en": "ABC 1234",
      "model": "تويوتا كامري 2020",
      "model_en": "Toyota Camry 2020",
      "color": "أبيض",
      "color_en": "White",
      "status": "active",
      "assigned_date": "2024-01-01",
      "unassigned_date": null,
      "photo": "https://example.com/cars/CAR001.jpg",
      "notes": "سيارة رئيسية"
    },
    {
      "car_id": "CAR002",
      "plate_number": "د هـ و 5678",
      "plate_number_en": "DEF 5678",
      "model": "نيسان باترول 2019",
      "model_en": "Nissan Patrol 2019",
      "color": "أسود",
      "color_en": "Black",
      "status": "maintenance",
      "assigned_date": "2023-06-01",
      "unassigned_date": null,
      "photo": "https://example.com/cars/CAR002.jpg",
      "notes": "في الصيانة"
    }
  ]
}
```

**Status Values:**
- `active`: نشط
- `maintenance`: صيانة
- `retired`: متقاعد

---

### **4. جلب الرواتب**
```
GET /api/external/employee-salaries
```

**Request:**
```json
{
  "api_key": "test_location_key_2025",
  "job_number": "12345",
  "start_date": "2025-01-01",  // optional
  "end_date": "2025-01-31"      // optional
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "تم جلب البيانات بنجاح",
  "data": [
    {
      "salary_id": "SAL001",
      "month": "2025-01",
      "amount": 5000.00,
      "currency": "SAR",
      "paid_date": "2025-01-05",
      "status": "paid",
      "details": {
        "base_salary": 4000.00,
        "allowances": 500.00,
        "deductions": 0.00,
        "bonuses": 500.00,
        "overtime": 0.00,
        "tax": 0.00
      },
      "notes": "راتب شهر يناير"
    },
    {
      "salary_id": "SAL002",
      "month": "2024-12",
      "amount": 5500.00,
      "currency": "SAR",
      "paid_date": "2024-12-05",
      "status": "paid",
      "details": {
        "base_salary": 4000.00,
        "allowances": 500.00,
        "deductions": 0.00,
        "bonuses": 1000.00,
        "overtime": 0.00,
        "tax": 0.00
      },
      "notes": "راتب شهر ديسمبر مع مكافأة"
    }
  ],
  "summary": {
    "total_salaries": 12,
    "total_amount": 60000.00,
    "average_amount": 5000.00,
    "last_salary": 5000.00,
    "last_paid_date": "2025-01-05"
  }
}
```

**Status Values:**
- `paid`: مدفوع
- `pending`: معلق
- `cancelled`: ملغي

---

### **5. جلب عمليات التسليم والاستلام**
```
GET /api/external/employee-operations
```

**Request:**
```json
{
  "api_key": "test_location_key_2025",
  "job_number": "12345",
  "start_date": "2025-01-01",  // optional
  "end_date": "2025-01-31",     // optional
  "type": "all"                 // all, delivery, pickup
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "تم جلب البيانات بنجاح",
  "data": [
    {
      "operation_id": "OP001",
      "type": "delivery",
      "date": "2025-01-27",
      "time": "10:30:00",
      "client_name": "شركة ABC للتجارة",
      "client_phone": "0501111111",
      "address": "الرياض، حي النخيل، شارع الملك فهد",
      "latitude": 24.7136,
      "longitude": 46.6753,
      "status": "completed",
      "items_count": 5,
      "total_amount": 1500.00,
      "currency": "SAR",
      "notes": "تم التسليم بنجاح",
      "signature": "https://example.com/signatures/OP001.jpg"
    },
    {
      "operation_id": "OP002",
      "type": "pickup",
      "date": "2025-01-27",
      "time": "14:00:00",
      "client_name": "شركة XYZ للخدمات",
      "client_phone": "0502222222",
      "address": "الرياض، حي العليا، شارع التحلية",
      "latitude": 24.7236,
      "longitude": 46.6853,
      "status": "pending",
      "items_count": 3,
      "total_amount": 800.00,
      "currency": "SAR",
      "notes": "في انتظار الاستلام",
      "signature": null
    }
  ],
  "summary": {
    "total_operations": 50,
    "delivery_count": 30,
    "pickup_count": 20,
    "completed_count": 45,
    "pending_count": 5,
    "total_amount": 75000.00
  }
}
```

**Type Values:**
- `delivery`: تسليم
- `pickup`: استلام

**Status Values:**
- `completed`: مكتمل
- `pending`: معلق
- `cancelled`: ملغي

---

## 📦 نماذج البيانات (Models)

### **1. Employee Model**
```dart
class Employee {
  final String jobNumber;
  final String name;
  final String? nameEn;
  final String department;
  final String? departmentEn;
  final String position;
  final String? positionEn;
  final String? phone;
  final String? email;
  final DateTime hireDate;
  final bool isDriver;
  final EmployeePhotos? photos;
  final String? address;
  final String? nationalId;

  Employee({
    required this.jobNumber,
    required this.name,
    this.nameEn,
    required this.department,
    this.departmentEn,
    required this.position,
    this.positionEn,
    this.phone,
    this.email,
    required this.hireDate,
    required this.isDriver,
    this.photos,
    this.address,
    this.nationalId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      jobNumber: json['job_number'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      department: json['department'] ?? '',
      departmentEn: json['department_en'],
      position: json['position'] ?? '',
      positionEn: json['position_en'],
      phone: json['phone'],
      email: json['email'],
      hireDate: DateTime.parse(json['hire_date'] ?? DateTime.now().toIso8601String()),
      isDriver: json['is_driver'] ?? false,
      photos: json['photos'] != null ? EmployeePhotos.fromJson(json['photos']) : null,
      address: json['address'],
      nationalId: json['national_id'],
    );
  }
}

class EmployeePhotos {
  final String? personal;
  final String? id;
  final String? license;

  EmployeePhotos({
    this.personal,
    this.id,
    this.license,
  });

  factory EmployeePhotos.fromJson(Map<String, dynamic> json) {
    return EmployeePhotos(
      personal: json['personal'],
      id: json['id'],
      license: json['license'],
    );
  }
}
```

### **2. Attendance Model**
```dart
class Attendance {
  final DateTime date;
  final String? checkIn;
  final String? checkOut;
  final AttendanceStatus status;
  final double hoursWorked;
  final int lateMinutes;
  final int earlyLeaveMinutes;
  final String? notes;

  Attendance({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.hoursWorked,
    this.lateMinutes = 0,
    this.earlyLeaveMinutes = 0,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      date: DateTime.parse(json['date']),
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      status: AttendanceStatus.fromString(json['status'] ?? 'absent'),
      hoursWorked: (json['hours_worked'] ?? 0.0).toDouble(),
      lateMinutes: json['late_minutes'] ?? 0,
      earlyLeaveMinutes: json['early_leave_minutes'] ?? 0,
      notes: json['notes'],
    );
  }
}

enum AttendanceStatus {
  present,
  absent,
  late,
  earlyLeave,
  holiday;

  static AttendanceStatus fromString(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      case 'early_leave':
        return AttendanceStatus.earlyLeave;
      case 'holiday':
        return AttendanceStatus.holiday;
      default:
        return AttendanceStatus.absent;
    }
  }
}
```

### **3. Car Model**
```dart
class Car {
  final String carId;
  final String plateNumber;
  final String? plateNumberEn;
  final String model;
  final String? modelEn;
  final String color;
  final String? colorEn;
  final CarStatus status;
  final DateTime assignedDate;
  final DateTime? unassignedDate;
  final String? photo;
  final String? notes;

  Car({
    required this.carId,
    required this.plateNumber,
    this.plateNumberEn,
    required this.model,
    this.modelEn,
    required this.color,
    this.colorEn,
    required this.status,
    required this.assignedDate,
    this.unassignedDate,
    this.photo,
    this.notes,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      carId: json['car_id'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      plateNumberEn: json['plate_number_en'],
      model: json['model'] ?? '',
      modelEn: json['model_en'],
      color: json['color'] ?? '',
      colorEn: json['color_en'],
      status: CarStatus.fromString(json['status'] ?? 'active'),
      assignedDate: DateTime.parse(json['assigned_date']),
      unassignedDate: json['unassigned_date'] != null ? DateTime.parse(json['unassigned_date']) : null,
      photo: json['photo'],
      notes: json['notes'],
    );
  }
}

enum CarStatus {
  active,
  maintenance,
  retired;

  static CarStatus fromString(String value) {
    switch (value) {
      case 'active':
        return CarStatus.active;
      case 'maintenance':
        return CarStatus.maintenance;
      case 'retired':
        return CarStatus.retired;
      default:
        return CarStatus.active;
    }
  }
}
```

### **4. Salary Model**
```dart
class Salary {
  final String salaryId;
  final String month;
  final double amount;
  final String currency;
  final DateTime? paidDate;
  final SalaryStatus status;
  final SalaryDetails details;
  final String? notes;

  Salary({
    required this.salaryId,
    required this.month,
    required this.amount,
    required this.currency,
    this.paidDate,
    required this.status,
    required this.details,
    this.notes,
  });

  factory Salary.fromJson(Map<String, dynamic> json) {
    return Salary(
      salaryId: json['salary_id'] ?? '',
      month: json['month'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'SAR',
      paidDate: json['paid_date'] != null ? DateTime.parse(json['paid_date']) : null,
      status: SalaryStatus.fromString(json['status'] ?? 'pending'),
      details: SalaryDetails.fromJson(json['details'] ?? {}),
      notes: json['notes'],
    );
  }
}

class SalaryDetails {
  final double baseSalary;
  final double allowances;
  final double deductions;
  final double bonuses;
  final double overtime;
  final double tax;

  SalaryDetails({
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    required this.bonuses,
    required this.overtime,
    required this.tax,
  });

  factory SalaryDetails.fromJson(Map<String, dynamic> json) {
    return SalaryDetails(
      baseSalary: (json['base_salary'] ?? 0.0).toDouble(),
      allowances: (json['allowances'] ?? 0.0).toDouble(),
      deductions: (json['deductions'] ?? 0.0).toDouble(),
      bonuses: (json['bonuses'] ?? 0.0).toDouble(),
      overtime: (json['overtime'] ?? 0.0).toDouble(),
      tax: (json['tax'] ?? 0.0).toDouble(),
    );
  }
}

enum SalaryStatus {
  paid,
  pending,
  cancelled;

  static SalaryStatus fromString(String value) {
    switch (value) {
      case 'paid':
        return SalaryStatus.paid;
      case 'pending':
        return SalaryStatus.pending;
      case 'cancelled':
        return SalaryStatus.cancelled;
      default:
        return SalaryStatus.pending;
    }
  }
}
```

### **5. Operation Model**
```dart
class Operation {
  final String operationId;
  final OperationType type;
  final DateTime date;
  final String time;
  final String clientName;
  final String? clientPhone;
  final String address;
  final double? latitude;
  final double? longitude;
  final OperationStatus status;
  final int itemsCount;
  final double totalAmount;
  final String currency;
  final String? notes;
  final String? signature;

  Operation({
    required this.operationId,
    required this.type,
    required this.date,
    required this.time,
    required this.clientName,
    this.clientPhone,
    required this.address,
    this.latitude,
    this.longitude,
    required this.status,
    required this.itemsCount,
    required this.totalAmount,
    required this.currency,
    this.notes,
    this.signature,
  });

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      operationId: json['operation_id'] ?? '',
      type: OperationType.fromString(json['type'] ?? 'delivery'),
      date: DateTime.parse(json['date']),
      time: json['time'] ?? '',
      clientName: json['client_name'] ?? '',
      clientPhone: json['client_phone'],
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: OperationStatus.fromString(json['status'] ?? 'pending'),
      itemsCount: json['items_count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'SAR',
      notes: json['notes'],
      signature: json['signature'],
    );
  }
}

enum OperationType {
  delivery,
  pickup;

  static OperationType fromString(String value) {
    switch (value) {
      case 'delivery':
        return OperationType.delivery;
      case 'pickup':
        return OperationType.pickup;
      default:
        return OperationType.delivery;
    }
  }
}

enum OperationStatus {
  completed,
  pending,
  cancelled;

  static OperationStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return OperationStatus.completed;
      case 'pending':
        return OperationStatus.pending;
      case 'cancelled':
        return OperationStatus.cancelled;
      default:
        return OperationStatus.pending;
    }
  }
}
```

---

## 🔧 خدمة API (Service)

```dart
class EmployeeApiService {
  static const String baseUrl = 'https://d72f2aef-918c-4148-9723-15870f8c7cf6-00-2c1ygyxvqoldk.riker.replit.dev';
  static const Duration timeoutDuration = Duration(seconds: 30);

  // جلب بيانات الموظف
  static Future<EmployeeResponse> getEmployeeProfile({
    required String jobNumber,
    required String apiKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/external/employee-profile'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'api_key': apiKey,
          'job_number': jobNumber,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return EmployeeResponse.success(Employee.fromJson(data['data']));
        } else {
          return EmployeeResponse.error(data['message'] ?? 'فشل جلب البيانات');
        }
      } else {
        return EmployeeResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return EmployeeResponse.error('حدث خطأ: $e');
    }
  }

  // جلب الحضور
  static Future<AttendanceResponse> getAttendance({
    required String jobNumber,
    required String apiKey,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = {
        'api_key': apiKey,
        'job_number': jobNumber,
      };
      
      if (startDate != null) {
        body['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        body['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/external/employee-attendance'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final attendanceList = (data['data'] as List)
              .map((json) => Attendance.fromJson(json))
              .toList();
          return AttendanceResponse.success(attendanceList);
        } else {
          return AttendanceResponse.error(data['message'] ?? 'فشل جلب البيانات');
        }
      } else {
        return AttendanceResponse.error('خطأ في الاتصال: ${response.statusCode}');
      }
    } catch (e) {
      return AttendanceResponse.error('حدث خطأ: $e');
    }
  }

  // جلب السيارات
  static Future<CarsResponse> getCars({
    required String jobNumber,
    required String apiKey,
  }) async {
    // Similar implementation...
  }

  // جلب الرواتب
  static Future<SalariesResponse> getSalaries({
    required String jobNumber,
    required String apiKey,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Similar implementation...
  }

  // جلب العمليات
  static Future<OperationsResponse> getOperations({
    required String jobNumber,
    required String apiKey,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    // Similar implementation...
  }
}
```

---

## 🎨 مثال على استخدام الخدمة في الصفحة

```dart
class EmployeeProfileScreen extends StatefulWidget {
  @override
  _EmployeeProfileScreenState createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  Employee? employee;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jobNumber = prefs.getString('jobNumber');
      final apiKey = prefs.getString('apiKey');

      if (jobNumber == null || apiKey == null) {
        setState(() {
          error = 'الرجاء إدخال الرقم الوظيفي والمفتاح';
          isLoading = false;
        });
        return;
      }

      final response = await EmployeeApiService.getEmployeeProfile(
        jobNumber: jobNumber,
        apiKey: apiKey,
      );

      if (response.success && response.data != null) {
        setState(() {
          employee = response.data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = response.error ?? 'فشل جلب البيانات';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'حدث خطأ: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('صفحة الموظف')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('صفحة الموظف')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(error!),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEmployeeData,
                child: Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (employee == null) {
      return Scaffold(
        appBar: AppBar(title: Text('صفحة الموظف')),
        body: Center(child: Text('لا توجد بيانات')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('صفحة الموظف'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEmployeeData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // بطاقة المعلومات الشخصية
            _buildProfileCard(employee!),
            // باقي البطاقات...
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(Employee employee) {
    return Container(
      // التصميم...
    );
  }
}
```

---

## ✅ الخلاصة

هذا الدليل يوضح:
1. ✅ هيكل API Endpoints
2. ✅ نماذج البيانات (Models)
3. ✅ خدمة API (Service)
4. ✅ معالجة الأخطاء
5. ✅ مثال على الاستخدام

**الخطوة التالية:** تنفيذ الكود بناءً على هذا التصميم.

---

**تاريخ الإنشاء:** 2025-01-27  
**آخر تحديث:** 2025-01-27

