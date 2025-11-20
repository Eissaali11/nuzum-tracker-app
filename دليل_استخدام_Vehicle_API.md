# 🚗 دليل استخدام Vehicle API

## 📋 الفهرس

1. [المعلومات الأساسية](#المعلومات-الأساسية)
2. [شرح البيانات المُرجعة](#شرح-البيانات-المُرجعة)
3. [أكواد Flutter جاهزة](#أكواد-flutter-جاهزة)
4. [معالجة الأخطاء](#معالجة-الأخطاء)
5. [Dependencies المطلوبة](#dependencies-المطلوبة)
6. [نصائح وأفضل الممارسات](#نصائح-وأفضل-الممارسات)
7. [الأمان](#الأمان)

---

## 1️⃣ المعلومات الأساسية

### الرابط الأساسي (Base URL)

```
http://nuzum.site
```

### نقاط الوصول (API Endpoints)

#### 1. جلب سيارة موظف معين
```
GET /api/employees/{employee_id}/vehicle
```

**مثال:**
```
GET http://nuzum.site/api/employees/180/vehicle
```

#### 2. جلب تفاصيل سيارة معينة
```
GET /api/vehicles/{vehicle_id}/details
```

**مثال:**
```
GET http://nuzum.site/api/vehicles/10/details
```

### كيفية الاستدعاء

**Headers:**
```
Content-Type: application/json
```

**ملاحظة:** هذه الـ API لا تحتاج إلى Token للمصادقة حالياً.

---

## 2️⃣ شرح البيانات المُرجعة

### 📦 هيكل الاستجابة الكاملة

```json
{
  "success": true,
  "employee": { ... },
  "vehicle": { ... },
  "handover_records": [ ... ],
  "handover_count": 4
}
```

---

### 👤 معلومات الموظف (Employee)

| الحقل | النوع | الوصف | مثال |
|------|------|-------|------|
| `id` | `int` | معرف الموظف | `180` |
| `employee_id` | `string` | الرقم الوظيفي | `"1910"` |
| `name` | `string` | اسم الموظف الكامل | `"HUSSAM AL DAIN"` |
| `mobile` | `string` | رقم الجوال | `"966591014696"` |
| `mobile_personal` | `string?` | رقم الجوال الشخصي | `"966563960177"` |
| `job_title` | `string` | المسمى الوظيفي | `"courier"` |
| `department` | `string` | القسم | `"Aramex Courier"` |

---

### 🚗 معلومات السيارة (Vehicle)

#### المعلومات الأساسية

| الحقل | النوع | الوصف | مثال |
|------|------|-------|------|
| `id` | `int` | معرف السيارة | `10` |
| `plate_number` | `string` | رقم اللوحة | `"3189-ب س ن"` |
| `make` | `string` | الشركة المصنعة | `"نيسان"` |
| `model` | `string` | الموديل | `"ارفان"` |
| `year` | `int` | سنة الصنع | `2021` |
| `color` | `string` | اللون | `"برند ارامكس"` |
| `type_of_car` | `string` | نوع السيارة | `"باص"` |
| `status` | `string` | الحالة | `"in_project"` |
| `status_arabic` | `string` | الحالة بالعربية | `"نشطة مع سائق"` |
| `driver_name` | `string` | اسم السائق | `"HUSSAM AL DAIN"` |
| `project` | `string` | المشروع | `"Aramex Coruer"` |
| `notes` | `string?` | الملاحظات | `"تم استلام السيارة..."` |

#### التواريخ المهمة

| الحقل | النوع | الوصف | مثال |
|------|------|-------|------|
| `authorization_expiry_date` | `string` | تاريخ انتهاء التفويض | `"2026-02-16"` |
| `registration_expiry_date` | `string` | تاريخ انتهاء الاستمارة | `"2026-10-07"` |
| `inspection_expiry_date` | `string` | تاريخ انتهاء الفحص الدوري | `"2026-07-10"` |

#### الصور والمستندات

| الحقل | النوع | الوصف | مثال |
|------|------|-------|------|
| `registration_form_image` | `string?` | صورة الاستمارة | `"http://nuzum.site/static/uploads/vehicles/registration_form.jpg"` |
| `insurance_file` | `string?` | ملف التأمين | `"http://nuzum.site/static/uploads/vehicles/insurance.pdf"` |
| `license_image` | `string?` | صورة الرخصة | `"http://nuzum.site/static/uploads/vehicles/license.jpg"` |
| `plate_image` | `string?` | صورة اللوحة | `"http://nuzum.site/static/uploads/vehicles/plate.jpg"` |
| `drive_folder_link` | `string?` | رابط مجلد Google Drive | `"https://drive.google.com/drive/folders/xxxxx"` |

#### معلومات إضافية

| الحقل | النوع | الوصف | مثال |
|------|------|-------|------|
| `created_at` | `string` | تاريخ الإنشاء | `"2025-04-23 15:29:28"` |
| `updated_at` | `string` | تاريخ التحديث | `"2025-11-06 10:15:16"` |

---

### 📋 سجلات التسليم/الاستلام (Handover Records)

#### معلومات السجل الأساسية

| الحقل | النوع | الوصف | مثال |
|------|------|-------|------|
| `id` | `int` | معرف السجل | `196` |
| `handover_type` | `string` | نوع العملية | `"delivery"` أو `"receipt"` |
| `handover_type_arabic` | `string` | نوع العملية بالعربية | `"تسليم"` أو `"استلام"` |
| `handover_date` | `string` | تاريخ العملية | `"2025-10-15"` |
| `handover_time` | `string` | وقت العملية | `"14:02"` |
| `mileage` | `int` | الكيلومترات | `150000` |
| `vehicle_plate_number` | `string` | رقم لوحة السيارة | `"3189-ب س ن"` |
| `vehicle_type` | `string` | نوع السيارة | `"نيسان ارفان 2021"` |
| `project_name` | `string` | اسم المشروع | `"Aramex"` |
| `city` | `string` | المدينة | `"المجمعه"` |
| `person_name` | `string` | اسم الشخص | `"HUSSAM AL DAIN"` |
| `supervisor_name` | `string` | اسم المشرف | `"أحمد محمد"` |
| `fuel_level` | `string` | مستوى الوقود | `"1/2"` |
| `notes` | `string?` | الملاحظات | `"السيارة بحالة جيدة"` |

#### الروابط والتوقيعات

| الحقل | النوع | الوصف | مثال |
|------|------|-------|------|
| `form_link` | `string?` | رابط نموذج PDF | `"https://acrobat.adobe.com/id/urn:aaid:sc:AP:..."` |
| `form_link_2` | `string?` | رابط نموذج إضافي | `null` |
| `driver_signature` | `string?` | توقيع السائق | `"http://nuzum.site/static/signatures/..."` |
| `supervisor_signature` | `string?` | توقيع المشرف | `"http://nuzum.site/static/signatures/..."` |
| `damage_diagram` | `string?` | مخطط الأضرار | `"http://nuzum.site/static/diagrams/..."` |
| `vehicle_status_summary` | `string?` | ملخص حالة السيارة | `"حالة ممتازة"` |

---

### ✅ قائمة الفحص (Checklist)

| الحقل | النوع | الوصف | القيمة |
|------|------|-------|--------|
| `spare_tire` | `boolean` | إطار احتياطي | `true` |
| `fire_extinguisher` | `boolean` | طفاية حريق | `true` |
| `first_aid_kit` | `boolean` | صندوق إسعاف | `true` |
| `warning_triangle` | `boolean` | مثلث تحذير | `true` |
| `tools` | `boolean` | الأدوات | `true` |
| `oil_leaks` | `boolean` | تسرب زيت | `false` |
| `gear_issue` | `boolean` | مشكلة في الجير | `false` |
| `clutch_issue` | `boolean` | مشكلة في الدبرياج | `false` |
| `engine_issue` | `boolean` | مشكلة في المحرك | `false` |
| `windows_issue` | `boolean` | مشكلة في النوافذ | `false` |
| `tires_issue` | `boolean` | مشكلة في الإطارات | `false` |
| `body_issue` | `boolean` | مشكلة في الهيكل | `false` |
| `electricity_issue` | `boolean` | مشكلة في الكهرباء | `false` |
| `lights_issue` | `boolean` | مشكلة في الأضواء | `false` |
| `ac_issue` | `boolean` | مشكلة في التكييف | `false` |

---

### 📷 صور السيارة (Images)

| الحقل | النوع | الوصف | مثال |
|------|------|-------|------|
| `id` | `int` | معرف الصورة | `1768` |
| `url` | `string` | رابط الصورة | `"http://nuzum.site/static/uploads/handover/..."` |
| `uploaded_at` | `string` | تاريخ الرفع | `"2025-10-15 12:47:42"` |

---

## 3️⃣ أكواد Flutter جاهزة

### أ) Service Class

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleApiService {
  static const String baseUrl = 'http://nuzum.site';
  static const Duration timeout = Duration(seconds: 30);

  /// جلب سيارة موظف معين
  static Future<Map<String, dynamic>> getEmployeeVehicle(String employeeId) async {
    try {
      final url = '$baseUrl/api/employees/$employeeId/vehicle';
      debugPrint('🚀 [VehicleAPI] Fetching: $url');
      
      final response = await http
          .get(Uri.parse(url))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [VehicleAPI] Success: ${data['success']}');
        return data;
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VehicleAPI] Error: $e');
      rethrow;
    }
  }

  /// جلب تفاصيل سيارة معينة
  static Future<Map<String, dynamic>> getVehicleDetails(String vehicleId) async {
    try {
      final url = '$baseUrl/api/vehicles/$vehicleId/details';
      debugPrint('🚀 [VehicleAPI] Fetching: $url');
      
      final response = await http
          .get(Uri.parse(url))
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('✅ [VehicleAPI] Success: ${data['success']}');
        return data;
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VehicleAPI] Error: $e');
      rethrow;
    }
  }
}
```

---

### ب) Model Classes

#### Employee Model

```dart
class Employee {
  final int id;
  final String employeeId;
  final String name;
  final String mobile;
  final String? mobilePersonal;
  final String jobTitle;
  final String department;

  Employee({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.mobile,
    this.mobilePersonal,
    required this.jobTitle,
    required this.department,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      mobilePersonal: json['mobile_personal'],
      jobTitle: json['job_title'] ?? '',
      department: json['department'] ?? '',
    );
  }
}
```

#### Vehicle Model

```dart
class Vehicle {
  final int id;
  final String plateNumber;
  final String make;
  final String model;
  final int year;
  final String color;
  final String typeOfCar;
  final String status;
  final String statusArabic;
  final String driverName;
  final String project;
  final String? notes;
  final DateTime? authorizationExpiryDate;
  final DateTime? registrationExpiryDate;
  final DateTime? inspectionExpiryDate;
  final String? registrationFormImage;
  final String? insuranceFile;
  final String? licenseImage;
  final String? plateImage;
  final String? driveFolderLink;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.typeOfCar,
    required this.status,
    required this.statusArabic,
    required this.driverName,
    required this.project,
    this.notes,
    this.authorizationExpiryDate,
    this.registrationExpiryDate,
    this.inspectionExpiryDate,
    this.registrationFormImage,
    this.insuranceFile,
    this.licenseImage,
    this.plateImage,
    this.driveFolderLink,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      plateNumber: json['plate_number'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 0,
      color: json['color'] ?? '',
      typeOfCar: json['type_of_car'] ?? '',
      status: json['status'] ?? '',
      statusArabic: json['status_arabic'] ?? '',
      driverName: json['driver_name'] ?? '',
      project: json['project'] ?? '',
      notes: json['notes'],
      authorizationExpiryDate: _parseDate(json['authorization_expiry_date']),
      registrationExpiryDate: _parseDate(json['registration_expiry_date']),
      inspectionExpiryDate: _parseDate(json['inspection_expiry_date']),
      registrationFormImage: json['registration_form_image'],
      insuranceFile: json['insurance_file'],
      licenseImage: json['license_image'],
      plateImage: json['plate_image'],
      driveFolderLink: json['drive_folder_link'],
    );
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// حساب الأيام المتبقية حتى انتهاء التاريخ
  int? getDaysUntilExpiry(DateTime? expiryDate) {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    return difference.inDays;
  }

  /// الحصول على لون التحذير حسب الأيام المتبقية
  Color getExpiryColor(DateTime? expiryDate) {
    final days = getDaysUntilExpiry(expiryDate);
    if (days == null) return Colors.grey;
    if (days < 0) return Colors.red; // منتهي
    if (days < 30) return Colors.orange; // أقل من شهر
    if (days < 60) return Colors.yellow; // أقل من شهرين
    return Colors.green; // آمن
  }
}
```

#### HandoverRecord Model

```dart
enum HandoverType { delivery, receipt }

class HandoverRecord {
  final int id;
  final HandoverType handoverType;
  final String handoverTypeArabic;
  final DateTime handoverDate;
  final String handoverTime;
  final int mileage;
  final String vehiclePlateNumber;
  final String city;
  final String personName;
  final String supervisorName;
  final String fuelLevel;
  final String? notes;
  final String? formLink;
  final String? driverSignature;
  final String? supervisorSignature;
  final String? damageDiagram;
  final List<HandoverImage> images;

  HandoverRecord({
    required this.id,
    required this.handoverType,
    required this.handoverTypeArabic,
    required this.handoverDate,
    required this.handoverTime,
    required this.mileage,
    required this.vehiclePlateNumber,
    required this.city,
    required this.personName,
    required this.supervisorName,
    required this.fuelLevel,
    this.notes,
    this.formLink,
    this.driverSignature,
    this.supervisorSignature,
    this.damageDiagram,
    required this.images,
  });

  factory HandoverRecord.fromJson(Map<String, dynamic> json) {
    return HandoverRecord(
      id: json['id'] ?? 0,
      handoverType: json['handover_type'] == 'delivery' 
          ? HandoverType.delivery 
          : HandoverType.receipt,
      handoverTypeArabic: json['handover_type_arabic'] ?? '',
      handoverDate: DateTime.parse(json['handover_date']),
      handoverTime: json['handover_time'] ?? '',
      mileage: json['mileage'] ?? 0,
      vehiclePlateNumber: json['vehicle_plate_number'] ?? '',
      city: json['city'] ?? '',
      personName: json['person_name'] ?? '',
      supervisorName: json['supervisor_name'] ?? '',
      fuelLevel: json['fuel_level'] ?? '',
      notes: json['notes'],
      formLink: json['form_link'],
      driverSignature: json['driver_signature'],
      supervisorSignature: json['supervisor_signature'],
      damageDiagram: json['damage_diagram'],
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => HandoverImage.fromJson(img))
          .toList() ?? [],
    );
  }
}

class HandoverImage {
  final int id;
  final String url;
  final DateTime uploadedAt;

  HandoverImage({
    required this.id,
    required this.url,
    required this.uploadedAt,
  });

  factory HandoverImage.fromJson(Map<String, dynamic> json) {
    return HandoverImage(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }
}
```

---

### ج) صفحة العرض الكاملة

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class VehicleDetailsPage extends StatefulWidget {
  final String employeeId;

  const VehicleDetailsPage({Key? key, required this.employeeId}) : super(key: key);

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await VehicleApiService.getEmployeeVehicle(widget.employeeId);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل السيارة')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل السيارة')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('خطأ: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null || _data!['success'] != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل السيارة')),
        body: const Center(child: Text('لا توجد بيانات')),
      );
    }

    final employee = _data!['employee'] as Map<String, dynamic>;
    final vehicle = _data!['vehicle'] as Map<String, dynamic>;
    final handoverRecords = _data!['handover_records'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل السيارة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة معلومات الموظف
            _buildEmployeeCard(employee),
            const SizedBox(height: 16),
            
            // بطاقة معلومات السيارة
            _buildVehicleCard(vehicle),
            const SizedBox(height: 16),
            
            // بطاقة تواريخ الانتهاء
            _buildExpiryDatesCard(vehicle),
            const SizedBox(height: 16),
            
            // قائمة سجلات التسليم/الاستلام
            _buildHandoverRecordsSection(handoverRecords),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الموظف',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('الاسم', employee['name']),
            _buildInfoRow('الرقم الوظيفي', employee['employee_id']),
            _buildInfoRow('المسمى الوظيفي', employee['job_title']),
            _buildInfoRow('القسم', employee['department']),
            _buildInfoRow('الجوال', employee['mobile']),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات السيارة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('رقم اللوحة', vehicle['plate_number']),
            _buildInfoRow('الموديل', '${vehicle['make']} ${vehicle['model']}'),
            _buildInfoRow('السنة', vehicle['year'].toString()),
            _buildInfoRow('اللون', vehicle['color']),
            _buildInfoRow('نوع السيارة', vehicle['type_of_car']),
            _buildInfoRow('الحالة', vehicle['status_arabic']),
            _buildInfoRow('اسم السائق', vehicle['driver_name']),
            _buildInfoRow('المشروع', vehicle['project']),
            if (vehicle['notes'] != null)
              _buildInfoRow('الملاحظات', vehicle['notes']),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryDatesCard(Map<String, dynamic> vehicle) {
    final authExpiry = _parseDate(vehicle['authorization_expiry_date']);
    final regExpiry = _parseDate(vehicle['registration_expiry_date']);
    final inspExpiry = _parseDate(vehicle['inspection_expiry_date']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تواريخ الانتهاء',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildExpiryRow('انتهاء التفويض', authExpiry),
            _buildExpiryRow('انتهاء الاستمارة', regExpiry),
            _buildExpiryRow('انتهاء الفحص الدوري', inspExpiry),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryRow(String label, DateTime? date) {
    if (date == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            const Text('غير محدد', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final days = date.difference(DateTime.now()).inDays;
    Color color;
    String status;

    if (days < 0) {
      color = Colors.red;
      status = 'منتهي (${days.abs()} يوم)';
    } else if (days < 30) {
      color = Colors.orange;
      status = 'قريب ($days يوم)';
    } else if (days < 60) {
      color = Colors.yellow[700]!;
      status = 'تحذير ($days يوم)';
    } else {
      color = Colors.green;
      status = 'آمن ($days يوم)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('yyyy-MM-dd').format(date)} ($status)',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverRecordsSection(List<dynamic> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سجلات التسليم والاستلام',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...records.map((record) => _buildHandoverRecordCard(record)),
      ],
    );
  }

  Widget _buildHandoverRecordCard(Map<String, dynamic> record) {
    final isDelivery = record['handover_type'] == 'delivery';
    final typeColor = isDelivery ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDelivery ? Icons.send : Icons.call_received,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record['handover_type_arabic'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
                Text(
                  '${record['handover_date']} ${record['handover_time']}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('المدينة', record['city']),
            _buildInfoRow('الكيلومترات', record['mileage'].toString()),
            _buildInfoRow('مستوى الوقود', record['fuel_level']),
            _buildInfoRow('المشرف', record['supervisor_name']),
            if (record['notes'] != null)
              _buildInfoRow('الملاحظات', record['notes']),
            
            // رابط النموذج
            if (record['form_link'] != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openLink(record['form_link']),
                icon: const Icon(Icons.description),
                label: const Text('فتح نموذج PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            
            // عرض الصور
            if (record['images'] != null && (record['images'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('صور السيارة:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: (record['images'] as List).length,
                itemBuilder: (context, index) {
                  final image = record['images'][index];
                  return GestureDetector(
                    onTap: () => _showImageFullScreen(image['url']),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        image['url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      return DateTime.parse(dateValue);
    } catch (e) {
      return null;
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يمكن فتح الرابط')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  void _showImageFullScreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4️⃣ معالجة الأخطاء

### أكواد الأخطاء الشائعة

| الكود | الوصف | الحل |
|------|-------|-----|
| `200` | نجاح | ✅ البيانات موجودة |
| `404` | غير موجود | ⚠️ تحقق من `employee_id` أو `vehicle_id` |
| `500` | خطأ في الخادم | ⚠️ حاول مرة أخرى لاحقاً |
| `Timeout` | انتهت المهلة | ⚠️ تحقق من الاتصال بالإنترنت |

### مثال على معالجة الأخطاء

```dart
try {
  final data = await VehicleApiService.getEmployeeVehicle(employeeId);
  // معالجة البيانات
} on TimeoutException {
  // معالجة انتهاء المهلة
  showError('انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.');
} on SocketException {
  // معالجة مشكلة الاتصال
  showError('لا يوجد اتصال بالإنترنت.');
} catch (e) {
  // معالجة الأخطاء العامة
  showError('حدث خطأ: $e');
}
```

---

## 5️⃣ Dependencies المطلوبة

أضف هذه الحزم في `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # للطلبات HTTP
  http: ^1.1.0
  
  # لفتح الروابط والملفات
  url_launcher: ^6.2.1
  
  # لتنسيق التواريخ
  intl: ^0.20.2
```

ثم قم بتشغيل:
```bash
flutter pub get
```

---

## 6️⃣ نصائح وأفضل الممارسات

### التخزين المؤقت (Caching)

```dart
class VehicleCache {
  static Map<String, Map<String, dynamic>> _cache = {};
  static DateTime? _lastUpdate;
  static const Duration cacheDuration = Duration(minutes: 5);

  static bool isValid() {
    if (_lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!) < cacheDuration;
  }

  static Map<String, dynamic>? get(String key) {
    if (isValid()) {
      return _cache[key];
    }
    return null;
  }

  static void set(String key, Map<String, dynamic> data) {
    _cache[key] = data;
    _lastUpdate = DateTime.now();
  }
}
```

### Loading States

```dart
enum LoadingState { idle, loading, success, error }

class VehicleProvider extends ChangeNotifier {
  LoadingState _state = LoadingState.idle;
  Map<String, dynamic>? _data;
  String? _error;

  LoadingState get state => _state;
  Map<String, dynamic>? get data => _data;
  String? get error => _error;

  Future<void> loadVehicle(String employeeId) async {
    _state = LoadingState.loading;
    notifyListeners();

    try {
      _data = await VehicleApiService.getEmployeeVehicle(employeeId);
      _state = LoadingState.success;
    } catch (e) {
      _error = e.toString();
      _state = LoadingState.error;
    }
    notifyListeners();
  }
}
```

### معالجة الصور الكبيرة

```dart
Image.network(
  imageUrl,
  cacheWidth: 800, // تقليل حجم الصورة
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  },
  errorBuilder: (context, error, stackTrace) {
    return const Icon(Icons.broken_image);
  },
)
```

### التحقق من القيم الفارغة

```dart
String? getValueOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isEmpty) return null;
  return value.toString();
}

// استخدام
final name = getValueOrNull(json['name']) ?? 'غير محدد';
```

---

## 7️⃣ الأمان

### ✅ أفضل الممارسات

1. **عدم تخزين بيانات حساسة**
   ```dart
   // ❌ خطأ
   SharedPreferences.setString('api_key', 'secret');
   
   // ✅ صحيح
   // لا تخزن بيانات حساسة محلياً
   ```

2. **استخدام HTTPS** (عند التطوير للإنتاج)
   ```dart
   static const String baseUrl = 'https://nuzum.site'; // HTTPS
   ```

3. **المصادقة** (إذا أضيفت لاحقاً)
   ```dart
   static Future<Map<String, String>> _getHeaders() async {
     final token = await getAuthToken();
     return {
       'Content-Type': 'application/json',
       'Authorization': 'Bearer $token',
     };
   }
   ```

4. **الأذونات** (في AndroidManifest.xml)
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   ```

---

## 🎯 أمثلة استخدام سريعة

### مثال 1: جلب بيانات موظف

```dart
final data = await VehicleApiService.getEmployeeVehicle('180');
final employee = data['employee'];
print('الموظف: ${employee['name']}');
```

### مثال 2: عرض صورة الاستمارة

```dart
final vehicle = data['vehicle'];
if (vehicle['registration_form_image'] != null) {
  Image.network(vehicle['registration_form_image']);
}
```

### مثال 3: فتح نموذج PDF

```dart
final record = handoverRecords[0];
if (record['form_link'] != null) {
  await launchUrl(Uri.parse(record['form_link']));
}
```

---

## 📞 الدعم

للمساعدة أو الاستفسارات، يرجى التواصل مع فريق التطوير.

---

**آخر تحديث:** 2025-01-20  
**الإصدار:** 1.0.0

