# 📊 ملخص البيانات التي يتم جلبها من API
## Summary of Fetched Data from API

---

## 📦 نظرة عامة - Overview

يتم جلب جميع البيانات في **طلب واحد** من API الشامل:
```
POST /api/external/employee-complete-profile
```

---

## 1️⃣ بيانات الموظف الأساسية - Employee Basic Data

### ✅ المعلومات الشخصية:
- **`job_number`** - الرقم الوظيفي (مطلوب)
- **`name`** - الاسم بالعربية (مطلوب)
- **`name_en`** - الاسم بالإنجليزية (اختياري)
- **`national_id`** - رقم الهوية الوطنية (اختياري)
- **`birth_date`** - تاريخ الميلاد (اختياري) - Format: YYYY-MM-DD
- **`hire_date`** - تاريخ التوظيف (اختياري) - Format: YYYY-MM-DD
- **`nationality`** - الجنسية (اختياري)
- **`residence_expiry_date`** - تاريخ انتهاء الإقامة (اختياري) - Format: YYYY-MM-DD
- **`sponsor_name`** - اسم الكفيل (اختياري)
- **`absher_phone`** - رقم جوال أبشر الشخصي (اختياري)

### ✅ المعلومات الوظيفية:
- **`department`** - الدائرة (مطلوب) - بالعربية
- **`department_en`** - الدائرة بالإنجليزية (اختياري)
- **`section`** - القسم (مطلوب) - بالعربية
- **`section_en`** - القسم بالإنجليزية (اختياري)
- **`position`** - المسمى الوظيفي (مطلوب) - بالعربية
- **`position_en`** - المسمى الوظيفي بالإنجليزية (اختياري)
- **`is_driver`** - هل هو سائق؟ (مطلوب) - boolean

### ✅ معلومات الاتصال:
- **`phone`** - رقم الجوال (اختياري)
- **`email`** - البريد الإلكتروني (اختياري)
- **`address`** - العنوان (اختياري)

### ✅ الصور - Photos:
- **`photos.personal`** - رابط الصورة الشخصية (URL) - (اختياري)
- **`photos.id`** - رابط صورة الهوية (URL) - (اختياري)
- **`photos.license`** - رابط صورة الرخصة (URL) - (اختياري - فقط إذا كان سائق)

---

## 2️⃣ بيانات السيارة - Car Data

### ✅ السيارة الحالية - Current Car:
- **`current_car.car_id`** - معرف السيارة
- **`current_car.plate_number`** - رقم اللوحة (عربي)
- **`current_car.plate_number_en`** - رقم اللوحة (إنجليزي) - (اختياري)
- **`current_car.model`** - الموديل
- **`current_car.model_en`** - الموديل (إنجليزي) - (اختياري)
- **`current_car.color`** - اللون
- **`current_car.color_en`** - اللون (إنجليزي) - (اختياري)
- **`current_car.status`** - الحالة: `active` | `maintenance` | `retired`
- **`current_car.assigned_date`** - تاريخ الربط - Format: YYYY-MM-DDTHH:mm:ss
- **`current_car.photo`** - صورة السيارة (URL) - (اختياري)
- **`current_car.notes`** - ملاحظات - (اختياري)

### ✅ السيارات السابقة - Previous Cars:
نفس الحقول أعلاه مع إضافة:
- **`previous_cars[].unassigned_date`** - تاريخ إلغاء الربط - Format: YYYY-MM-DDTHH:mm:ss

---

## 3️⃣ سجل الحضور - Attendance Records

### ✅ لكل سجل حضور - For Each Attendance Record:
- **`attendance[].date`** - التاريخ - Format: YYYY-MM-DD
- **`attendance[].check_in`** - وقت الدخول - Format: HH:mm (اختياري)
- **`attendance[].check_out`** - وقت الخروج - Format: HH:mm (اختياري)
- **`attendance[].status`** - الحالة:
  - `present` - حاضر
  - `absent` - غائب
  - `late` - متأخر
  - `early_leave` - خروج مبكر
  - `holiday` - إجازة
- **`attendance[].hours_worked`** - عدد ساعات العمل (number)
- **`attendance[].late_minutes`** - دقائق التأخير (number)
- **`attendance[].early_leave_minutes`** - دقائق الخروج المبكر (number)
- **`attendance[].notes`** - ملاحظات (اختياري)

---

## 4️⃣ سجل الرواتب - Salary Records

### ✅ لكل راتب - For Each Salary:
- **`salaries[].salary_id`** - معرف الراتب
- **`salaries[].month`** - الشهر - Format: YYYY-MM
- **`salaries[].amount`** - المبلغ الإجمالي (number)
- **`salaries[].currency`** - العملة (افتراضي: SAR)
- **`salaries[].paid_date`** - تاريخ الدفع - Format: YYYY-MM-DDTHH:mm:ss (اختياري)
- **`salaries[].status`** - الحالة:
  - `paid` - مدفوع
  - `pending` - معلق
  - `cancelled` - ملغي
- **`salaries[].details.base_salary`** - الراتب الأساسي (number)
- **`salaries[].details.allowances`** - البدلات (number)
- **`salaries[].details.deductions`** - الخصومات (number)
- **`salaries[].details.bonuses`** - المكافآت (number)
- **`salaries[].details.overtime`** - ساعات إضافية (number)
- **`salaries[].details.tax`** - الضرائب (number)
- **`salaries[].notes`** - ملاحظات (اختياري)

---

## 5️⃣ عمليات التسليم والاستلام - Operations

### ✅ لكل عملية - For Each Operation:
- **`operations[].operation_id`** - معرف العملية
- **`operations[].type`** - النوع:
  - `delivery` - تسليم
  - `pickup` - استلام
- **`operations[].date`** - التاريخ والوقت - Format: YYYY-MM-DDTHH:mm:ss
- **`operations[].car_id`** - معرف السيارة
- **`operations[].car_plate_number`** - رقم لوحة السيارة
- **`operations[].client_name`** - اسم العميل
- **`operations[].client_phone`** - رقم جوال العميل (اختياري)
- **`operations[].address`** - العنوان
- **`operations[].latitude`** - خط العرض (اختياري)
- **`operations[].longitude`** - خط الطول (اختياري)
- **`operations[].status`** - الحالة:
  - `completed` - مكتمل
  - `pending` - معلق
  - `cancelled` - ملغي
- **`operations[].items_count`** - عدد العناصر (number)
- **`operations[].total_amount`** - المبلغ الإجمالي (number)
- **`operations[].currency`** - العملة (افتراضي: SAR)
- **`operations[].notes`** - ملاحظات (اختياري)
- **`operations[].signature`** - التوقيع (URL) - (اختياري)

---

## 6️⃣ الإحصائيات الشاملة - Complete Statistics

### ✅ إحصائيات الحضور - Attendance Statistics:
- **`statistics.attendance.total_days`** - إجمالي الأيام (number)
- **`statistics.attendance.present_days`** - أيام الحضور (number)
- **`statistics.attendance.absent_days`** - أيام الغياب (number)
- **`statistics.attendance.late_days`** - أيام التأخير (number)
- **`statistics.attendance.early_leave_days`** - أيام الخروج المبكر (number)
- **`statistics.attendance.total_hours`** - إجمالي الساعات (number)
- **`statistics.attendance.attendance_rate`** - نسبة الحضور (%) (number)

### ✅ إحصائيات الرواتب - Salary Statistics:
- **`statistics.salaries.total_salaries`** - عدد الرواتب (number)
- **`statistics.salaries.total_amount`** - إجمالي المبلغ (number)
- **`statistics.salaries.average_amount`** - متوسط الراتب (number)
- **`statistics.salaries.last_salary`** - آخر راتب (number)
- **`statistics.salaries.last_paid_date`** - تاريخ آخر دفع - Format: YYYY-MM-DDTHH:mm:ss (اختياري)

### ✅ إحصائيات السيارات - Car Statistics:
- **`statistics.cars.current_car`** - هل يوجد سيارة حالية؟ (boolean)
- **`statistics.cars.total_cars`** - إجمالي السيارات (number)
- **`statistics.cars.active_cars`** - السيارات النشطة (number)
- **`statistics.cars.maintenance_cars`** - السيارات في الصيانة (number)
- **`statistics.cars.retired_cars`** - السيارات المتقاعدة (number)

### ✅ إحصائيات العمليات - Operation Statistics:
- **`statistics.operations.total_operations`** - إجمالي العمليات (number)
- **`statistics.operations.delivery_count`** - عدد عمليات التسليم (number)
- **`statistics.operations.pickup_count`** - عدد عمليات الاستلام (number)
- **`statistics.operations.completed_count`** - عدد العمليات المكتملة (number)

---

## 📋 مثال على البيانات الكاملة - Complete Data Example

```json
{
  "success": true,
  "message": "تم جلب البيانات بنجاح",
  "data": {
    "employee": {
      "job_number": "5216",
      "name": "أحمد محمد العلي",
      "name_en": "Ahmed Mohammed Al-Ali",
      "national_id": "1234567890",
      "birth_date": "1990-05-15",
      "hire_date": "2020-01-10",
      "nationality": "سعودي",
      "residence_expiry_date": "2026-12-31",
      "sponsor_name": "شركة نزوم للتجارة",
      "absher_phone": "0501234567",
      "department": "الدائرة التقنية",
      "department_en": "Technical Department",
      "section": "قسم التطوير",
      "section_en": "Development Section",
      "position": "مطور تطبيقات",
      "position_en": "Application Developer",
      "phone": "0501234567",
      "email": "ahmed@example.com",
      "address": "الرياض، حي النخيل",
      "is_driver": true,
      "photos": {
        "personal": "https://example.com/photos/personal/5216.jpg",
        "id": "https://example.com/photos/id/5216.jpg",
        "license": "https://example.com/photos/license/5216.jpg"
      }
    },
    "current_car": {
      "car_id": "CAR001",
      "plate_number": "أ ب ج 1234",
      "plate_number_en": "ABC 1234",
      "model": "تويوتا كامري",
      "model_en": "Toyota Camry",
      "color": "أبيض",
      "color_en": "White",
      "status": "active",
      "assigned_date": "2024-01-15T08:00:00",
      "photo": "https://example.com/cars/CAR001.jpg",
      "notes": "سيارة جديدة"
    },
    "previous_cars": [
      {
        "car_id": "CAR002",
        "plate_number": "د هـ و 5678",
        "plate_number_en": "DEF 5678",
        "model": "هوندا أكورد",
        "model_en": "Honda Accord",
        "color": "أسود",
        "color_en": "Black",
        "status": "retired",
        "assigned_date": "2022-01-01T08:00:00",
        "unassigned_date": "2024-01-14T17:00:00",
        "photo": null,
        "notes": "تم استبدالها"
      }
    ],
    "attendance": [
      {
        "date": "2025-01-15",
        "check_in": "08:00",
        "check_out": "17:00",
        "status": "present",
        "hours_worked": 8.0,
        "late_minutes": 0,
        "early_leave_minutes": 0,
        "notes": null
      }
    ],
    "salaries": [
      {
        "salary_id": "SAL001",
        "month": "2025-01",
        "amount": 15000.00,
        "currency": "SAR",
        "paid_date": "2025-01-05T10:00:00",
        "status": "paid",
        "details": {
          "base_salary": 12000.00,
          "allowances": 2000.00,
          "deductions": 500.00,
          "bonuses": 1000.00,
          "overtime": 500.00,
          "tax": 0.00
        },
        "notes": null
      }
    ],
    "operations": [
      {
        "operation_id": "OP001",
        "type": "delivery",
        "date": "2025-01-15T10:30:00",
        "car_id": "CAR001",
        "car_plate_number": "أ ب ج 1234",
        "client_name": "محمد أحمد",
        "client_phone": "0509876543",
        "address": "الرياض، حي العليا",
        "status": "completed",
        "items_count": 5,
        "total_amount": 500.00,
        "currency": "SAR",
        "notes": "تم التسليم بنجاح"
      }
    ],
    "statistics": {
      "attendance": {
        "total_days": 22,
        "present_days": 20,
        "absent_days": 1,
        "late_days": 1,
        "early_leave_days": 0,
        "total_hours": 158.5,
        "attendance_rate": 90.91
      },
      "salaries": {
        "total_salaries": 12,
        "total_amount": 180000.00,
        "average_amount": 15000.00,
        "last_salary": 15000.00,
        "last_paid_date": "2025-01-05T10:00:00"
      },
      "cars": {
        "current_car": true,
        "total_cars": 2,
        "active_cars": 1,
        "maintenance_cars": 0,
        "retired_cars": 1
      },
      "operations": {
        "total_operations": 45,
        "delivery_count": 25,
        "pickup_count": 20,
        "completed_count": 43
      }
    }
  }
}
```

---

## 📊 ملخص البيانات - Data Summary

### إجمالي البيانات:
- ✅ **1** موظف (مع 20+ حقل)
- ✅ **1** سيارة حالية (مع 10+ حقل)
- ✅ **N** سيارات سابقة (حسب التاريخ)
- ✅ **N** سجلات حضور (حسب الشهر أو النطاق الزمني)
- ✅ **N** سجلات رواتب (حسب الشهر أو النطاق الزمني)
- ✅ **N** عمليات (تسليم/استلام)
- ✅ **1** مجموعة إحصائيات شاملة (4 أنواع)

### إجمالي الحقول:
- **موظف:** ~25 حقل
- **سيارة:** ~10 حقول لكل سيارة
- **حضور:** ~8 حقول لكل سجل
- **راتب:** ~12 حقل لكل راتب
- **عملية:** ~15 حقل لكل عملية
- **إحصائيات:** ~20 حقل

---

## 🎯 كيفية الوصول للبيانات في الكود

```dart
// بعد جلب البيانات
final response = await EmployeeApiService.getCompleteProfile(
  jobNumber: '5216',
  apiKey: 'test_location_key_2025',
);

if (response.success && response.data != null) {
  final data = response.data!;
  
  // بيانات الموظف
  print('الاسم: ${data.employee.name}');
  print('الاسم بالإنجليزي: ${data.employee.nameEn}');
  print('رقم الهوية: ${data.employee.nationalId}');
  print('تاريخ الميلاد: ${data.employee.birthDate}');
  print('تاريخ التوظيف: ${data.employee.hireDate}');
  print('الجنسية: ${data.employee.nationality}');
  print('تاريخ انتهاء الإقامة: ${data.employee.residenceExpiryDate}');
  print('اسم الكفيل: ${data.employee.sponsorName}');
  print('رقم أبشر: ${data.employee.absherPhone}');
  print('الدائرة: ${data.employee.department}');
  print('القسم: ${data.employee.section}');
  
  // السيارة الحالية
  if (data.currentCar != null) {
    print('السيارة الحالية: ${data.currentCar!.plateNumber}');
  }
  
  // السيارات السابقة
  print('عدد السيارات السابقة: ${data.previousCars.length}');
  
  // الحضور
  print('عدد سجلات الحضور: ${data.attendance.length}');
  
  // الرواتب
  print('عدد الرواتب: ${data.salaries.length}');
  
  // العمليات
  print('عدد العمليات: ${data.operations.length}');
  
  // الإحصائيات
  print('نسبة الحضور: ${data.statistics.attendance.attendanceRate}%');
  print('إجمالي الرواتب: ${data.statistics.salaries.totalAmount}');
  print('عدد السيارات: ${data.statistics.cars.totalCars}');
  print('عدد العمليات: ${data.statistics.operations.totalOperations}');
}
```

---

**آخر تحديث:** 2025-01-XX  
**الحالة:** ✅ جميع البيانات متوفرة وجاهزة للاستخدام

