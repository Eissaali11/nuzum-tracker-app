# 📋 خطة تصميم صفحة الموظف - Employee Profile Design Plan

## 🎯 نظرة عامة

تصميم صفحة موظف شاملة تعرض:
- معلومات الموظف الشخصية
- الحضور والانصراف
- السيارات المرتبطة
- الرواتب المستلمة
- عمليات التسليم والاستلام

---

## 📐 هيكل الصفحات

### 1. **صفحة الموظف الرئيسية** (`EmployeeProfileScreen`)

```
┌─────────────────────────────────────┐
│  [←]  صفحة الموظف                   │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │   [صورة شخصية كبيرة]        │   │
│  │   اسم الموظف                │   │
│  │   الرقم الوظيفي              │   │
│  │   القسم / المنصب             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📸 الصور                     │   │
│  │  [صورة شخصية] [صورة هوية]   │   │
│  │  [صورة رخصة - إن وجدت]      │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📊 إحصائيات سريعة            │   │
│  │  [حضور اليوم] [راتب الشهر]  │   │
│  │  [عمليات] [سيارات]          │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📅 الحضور                    │   │
│  │  [عرض آخر 7 أيام]           │   │
│  │  [زر: عرض الكل]             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🚗 السيارات                  │   │
│  │  [قائمة السيارات]           │   │
│  │  [زر: عرض الكل]             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 💰 الرواتب                   │   │
│  │  [آخر راتب]                 │   │
│  │  [زر: عرض الكل]             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📦 العمليات                  │   │
│  │  [آخر عمليات]               │   │
│  │  [زر: عرض الكل]             │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## 🎨 تصميم الواجهة

### **الألوان المستخدمة:**
- **اللون الأساسي:** `#1A237E` (Deep Indigo)
- **اللون الثانوي:** `#0D47A1` (Deep Blue)
- **اللون النجاح:** `#4CAF50` (Green)
- **اللون التحذير:** `#FF9800` (Orange)
- **اللون الخطأ:** `#F44336` (Red)
- **الخلفية:** `#F5F5F5` (Light Gray)
- **النص:** `#212121` (Dark Gray)

### **الخطوط:**
- **العناوين:** `fontWeight: FontWeight.bold, fontSize: 20-24`
- **النصوص العادية:** `fontSize: 16`
- **النصوص الصغيرة:** `fontSize: 14`
- **الأرقام:** `fontWeight: FontWeight.w600`

---

## 📱 مكونات الصفحة

### **1. رأس الصفحة (Header)**
```dart
AppBar(
  title: Text('صفحة الموظف'),
  backgroundColor: Colors.white,
  elevation: 1,
  actions: [
    IconButton(icon: Icon(Icons.refresh), onPressed: refreshData),
  ],
)
```

### **2. بطاقة المعلومات الشخصية (Profile Card)**
```dart
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Column(
    children: [
      CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(employeePhoto),
      ),
      SizedBox(height: 16),
      Text(employeeName, style: TextStyle(color: Colors.white, fontSize: 24)),
      Text('الرقم الوظيفي: $jobNumber', style: TextStyle(color: Colors.white70)),
      Text(department, style: TextStyle(color: Colors.white70)),
    ],
  ),
)
```

### **3. بطاقة الصور (Photos Card)**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('الصور', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: 12),
      Row(
        children: [
          _buildPhotoCard('صورة شخصية', personalPhoto),
          SizedBox(width: 12),
          _buildPhotoCard('صورة الهوية', idPhoto),
          if (isDriver) ...[
            SizedBox(width: 12),
            _buildPhotoCard('رخصة القيادة', licensePhoto),
          ],
        ],
      ),
    ],
  ),
)
```

### **4. بطاقة الإحصائيات (Statistics Card)**
```dart
Row(
  children: [
    Expanded(child: _buildStatCard('حضور اليوم', todayAttendance, Icons.access_time, Colors.blue)),
    SizedBox(width: 12),
    Expanded(child: _buildStatCard('راتب الشهر', monthlySalary, Icons.account_balance_wallet, Colors.green)),
    SizedBox(width: 12),
    Expanded(child: _buildStatCard('العمليات', operationsCount, Icons.inventory, Colors.orange)),
    SizedBox(width: 12),
    Expanded(child: _buildStatCard('السيارات', carsCount, Icons.directions_car, Colors.purple)),
  ],
)
```

### **5. بطاقة الحضور (Attendance Card)**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الحضور', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceListScreen())),
            child: Text('عرض الكل'),
          ),
        ],
      ),
      SizedBox(height: 12),
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: min(7, attendanceList.length),
        itemBuilder: (context, index) => _buildAttendanceItem(attendanceList[index]),
      ),
    ],
  ),
)
```

### **6. بطاقة السيارات (Cars Card)**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('السيارات المرتبطة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CarsListScreen())),
            child: Text('عرض الكل'),
          ),
        ],
      ),
      SizedBox(height: 12),
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: carsList.length,
        itemBuilder: (context, index) => _buildCarItem(carsList[index]),
      ),
    ],
  ),
)
```

### **7. بطاقة الرواتب (Salaries Card)**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('الرواتب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SalariesListScreen())),
            child: Text('عرض الكل'),
          ),
        ],
      ),
      SizedBox(height: 12),
      _buildSalaryItem(lastSalary),
    ],
  ),
)
```

### **8. بطاقة العمليات (Operations Card)**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('عمليات التسليم والاستلام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OperationsListScreen())),
            child: Text('عرض الكل'),
          ),
        ],
      ),
      SizedBox(height: 12),
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: min(5, operationsList.length),
        itemBuilder: (context, index) => _buildOperationItem(operationsList[index]),
      ),
    ],
  ),
)
```

---

## 🔌 تصميم API Endpoints

### **1. جلب بيانات الموظف**
```
GET /api/external/employee-profile
Headers:
  Content-Type: application/json
Body:
{
  "api_key": "test_location_key_2025",
  "job_number": "12345"
}

Response:
{
  "success": true,
  "data": {
    "job_number": "12345",
    "name": "أحمد محمد",
    "name_en": "Ahmed Mohammed",
    "department": "التسليم",
    "position": "سائق",
    "phone": "0501234567",
    "email": "ahmed@example.com",
    "hire_date": "2020-01-15",
    "is_driver": true,
    "photos": {
      "personal": "https://example.com/photos/personal.jpg",
      "id": "https://example.com/photos/id.jpg",
      "license": "https://example.com/photos/license.jpg"
    }
  }
}
```

### **2. جلب الحضور**
```
GET /api/external/employee-attendance
Headers:
  Content-Type: application/json
Body:
{
  "api_key": "test_location_key_2025",
  "job_number": "12345",
  "start_date": "2025-01-01",  // optional
  "end_date": "2025-01-31"      // optional
}

Response:
{
  "success": true,
  "data": [
    {
      "date": "2025-01-27",
      "check_in": "08:00:00",
      "check_out": "17:00:00",
      "status": "present",  // present, absent, late, early_leave
      "hours_worked": 9.0
    },
    ...
  ]
}
```

### **3. جلب السيارات المرتبطة**
```
GET /api/external/employee-cars
Headers:
  Content-Type: application/json
Body:
{
  "api_key": "test_location_key_2025",
  "job_number": "12345"
}

Response:
{
  "success": true,
  "data": [
    {
      "car_id": "CAR001",
      "plate_number": "أ ب ج 1234",
      "model": "تويوتا كامري 2020",
      "color": "أبيض",
      "status": "active",  // active, maintenance, retired
      "assigned_date": "2024-01-01"
    },
    ...
  ]
}
```

### **4. جلب الرواتب**
```
GET /api/external/employee-salaries
Headers:
  Content-Type: application/json
Body:
{
  "api_key": "test_location_key_2025",
  "job_number": "12345",
  "start_date": "2025-01-01",  // optional
  "end_date": "2025-01-31"      // optional
}

Response:
{
  "success": true,
  "data": [
    {
      "salary_id": "SAL001",
      "month": "2025-01",
      "amount": 5000.00,
      "currency": "SAR",
      "paid_date": "2025-01-05",
      "status": "paid",  // paid, pending, cancelled
      "details": {
        "base_salary": 4000.00,
        "allowances": 500.00,
        "deductions": 0.00,
        "bonuses": 500.00
      }
    },
    ...
  ]
}
```

### **5. جلب عمليات التسليم والاستلام**
```
GET /api/external/employee-operations
Headers:
  Content-Type: application/json
Body:
{
  "api_key": "test_location_key_2025",
  "job_number": "12345",
  "start_date": "2025-01-01",  // optional
  "end_date": "2025-01-31",     // optional
  "type": "all"                 // all, delivery, pickup
}

Response:
{
  "success": true,
  "data": [
    {
      "operation_id": "OP001",
      "type": "delivery",  // delivery, pickup
      "date": "2025-01-27",
      "time": "10:30:00",
      "client_name": "شركة ABC",
      "address": "الرياض، حي النخيل",
      "status": "completed",  // completed, pending, cancelled
      "items_count": 5,
      "total_amount": 1500.00
    },
    ...
  ]
}
```

---

## 📂 هيكل الملفات المقترح

```
lib/
├── models/
│   ├── employee_model.dart          # نموذج بيانات الموظف
│   ├── attendance_model.dart        # نموذج الحضور
│   ├── car_model.dart               # نموذج السيارة
│   ├── salary_model.dart            # نموذج الراتب
│   └── operation_model.dart         # نموذج العملية
│
├── services/
│   └── employee_api_service.dart    # خدمة API للموظف
│
├── screens/
│   ├── employee_profile_screen.dart  # صفحة الموظف الرئيسية
│   ├── attendance_list_screen.dart  # قائمة الحضور
│   ├── cars_list_screen.dart        # قائمة السيارات
│   ├── salaries_list_screen.dart    # قائمة الرواتب
│   └── operations_list_screen.dart # قائمة العمليات
│
└── widgets/
    ├── employee_profile_card.dart   # بطاقة معلومات الموظف
    ├── attendance_item.dart         # عنصر الحضور
    ├── car_item.dart                # عنصر السيارة
    ├── salary_item.dart             # عنصر الراتب
    └── operation_item.dart          # عنصر العملية
```

---

## 🎨 تفاصيل التصميم

### **1. بطاقة الصورة الشخصية**
- **الحجم:** `CircleAvatar` بقطر 120px
- **الحدود:** بدون حدود
- **الظل:** `BoxShadow` خفيف
- **الخطأ:** أيقونة افتراضية `Icons.person`

### **2. بطاقة الصور (الشخصية، الهوية، الرخصة)**
- **الحجم:** `120x80` لكل صورة
- **الشكل:** `RoundedRectangleBorder` بزوايا 12px
- **التفاعل:** عند الضغط تفتح الصورة في نافذة كاملة
- **الحدود:** `Border.all(color: Colors.grey[300]!)`

### **3. بطاقة الإحصائيات**
- **الحجم:** `Expanded` لكل بطاقة
- **الخلفية:** `Colors.white`
- **الظل:** `BoxShadow` خفيف
- **الأيقونة:** في الأعلى، اللون حسب النوع
- **الرقم:** كبير وواضح
- **النص:** صغير أسفل الرقم

### **4. قائمة الحضور**
- **الشكل:** `ListTile` مع أيقونة في البداية
- **الألوان:**
  - ✅ حاضر: `Colors.green`
  - ❌ غائب: `Colors.red`
  - ⚠️ متأخر: `Colors.orange`
  - ⏰ خروج مبكر: `Colors.blue`
- **التنسيق:** التاريخ | وقت الدخول | وقت الخروج | الساعات

### **5. قائمة السيارات**
- **الشكل:** `Card` مع صورة السيارة (إن وجدت)
- **المعلومات:** رقم اللوحة، الموديل، اللون، الحالة
- **الحالة:**
  - 🟢 نشط: `Colors.green`
  - 🟡 صيانة: `Colors.orange`
  - 🔴 متقاعد: `Colors.red`

### **6. قائمة الرواتب**
- **الشكل:** `Card` مع أيقونة `Icons.account_balance_wallet`
- **المعلومات:** الشهر، المبلغ، تاريخ الدفع، الحالة
- **التنسيق:** الشهر في الأعلى، المبلغ كبير في الوسط، الحالة في الأسفل

### **7. قائمة العمليات**
- **الشكل:** `Card` مع أيقونة حسب النوع
- **الأيقونات:**
  - 📦 تسليم: `Icons.local_shipping`
  - 📥 استلام: `Icons.inventory`
- **المعلومات:** التاريخ، الوقت، العميل، العنوان، الحالة
- **الألوان:**
  - ✅ مكتمل: `Colors.green`
  - ⏳ معلق: `Colors.orange`
  - ❌ ملغي: `Colors.red`

---

## 🔄 حالات التحميل والأخطاء

### **حالة التحميل:**
```dart
Center(
  child: CircularProgressIndicator(),
)
```

### **حالة الخطأ:**
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.error_outline, size: 64, color: Colors.red),
      SizedBox(height: 16),
      Text('حدث خطأ في تحميل البيانات'),
      SizedBox(height: 8),
      ElevatedButton(
        onPressed: refreshData,
        child: Text('إعادة المحاولة'),
      ),
    ],
  ),
)
```

### **حالة فارغة:**
```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.inbox, size: 64, color: Colors.grey),
      SizedBox(height: 16),
      Text('لا توجد بيانات'),
    ],
  ),
)
```

---

## 📱 التنقل بين الصفحات

### **من صفحة التتبع إلى صفحة الموظف:**
```dart
// في tracking_screen.dart
IconButton(
  icon: Icon(Icons.person),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeProfileScreen(),
      ),
    );
  },
)
```

### **من صفحة الموظف إلى الصفحات الفرعية:**
- الحضور → `AttendanceListScreen`
- السيارات → `CarsListScreen`
- الرواتب → `SalariesListScreen`
- العمليات → `OperationsListScreen`

---

## 🎯 الميزات الإضافية المقترحة

1. **البحث والفلترة:**
   - فلترة الحضور حسب التاريخ
   - فلترة الرواتب حسب الشهر
   - فلترة العمليات حسب النوع والتاريخ

2. **التصدير:**
   - تصدير الحضور إلى PDF
   - تصدير الرواتب إلى Excel
   - تصدير العمليات إلى CSV

3. **الإشعارات:**
   - إشعار عند استلام راتب جديد
   - إشعار عند تعيين سيارة جديدة
   - إشعار عند تأكيد عملية

4. **الإحصائيات:**
   - رسم بياني للحضور الشهري
   - رسم بياني للرواتب السنوية
   - رسم بياني للعمليات

---

## ✅ قائمة المهام

- [ ] إنشاء نماذج البيانات (Models)
- [ ] إنشاء خدمة API (EmployeeApiService)
- [ ] إنشاء صفحة الموظف الرئيسية
- [ ] إنشاء صفحة قائمة الحضور
- [ ] إنشاء صفحة قائمة السيارات
- [ ] إنشاء صفحة قائمة الرواتب
- [ ] إنشاء صفحة قائمة العمليات
- [ ] إنشاء الويدجتات المخصصة
- [ ] إضافة معالجة الأخطاء
- [ ] إضافة حالات التحميل
- [ ] إضافة التحديث التلقائي
- [ ] اختبار التصميم على أجهزة مختلفة

---

**تاريخ الإنشاء:** 2025-01-27  
**آخر تحديث:** 2025-01-27

