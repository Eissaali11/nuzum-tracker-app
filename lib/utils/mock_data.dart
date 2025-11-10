import '../models/attendance_model.dart';
import '../models/car_model.dart';
import '../models/salary_model.dart';

/// ============================================
/// 🎭 بيانات افتراضية للعرض - Mock Data
/// ============================================

class MockData {
  /// بيانات الحضور الافتراضية
  static List<Attendance> getMockAttendance() {
    final now = DateTime.now();
    final List<Attendance> attendance = [];

    // إنشاء بيانات للحضور لآخر 30 يوم
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      
      // تخطي عطلات نهاية الأسبوع (الجمعة والسبت)
      if (date.weekday == 5 || date.weekday == 6) {
        attendance.add(Attendance(
          date: date,
          status: AttendanceStatus.holiday,
          hoursWorked: 0,
          notes: 'عطلة نهاية الأسبوع',
        ));
        continue;
      }

      // إنشاء حالات مختلفة
      AttendanceStatus status;
      String? checkIn;
      String? checkOut;
      double hoursWorked;
      int lateMinutes = 0;

      if (i % 7 == 0) {
        // غائب كل 7 أيام
        status = AttendanceStatus.absent;
        checkIn = null;
        checkOut = null;
        hoursWorked = 0;
      } else if (i % 5 == 0) {
        // متأخر كل 5 أيام
        status = AttendanceStatus.late;
        checkIn = '08:30';
        checkOut = '17:00';
        hoursWorked = 8.0;
        lateMinutes = 30;
      } else if (i % 3 == 0) {
        // خروج مبكر كل 3 أيام
        status = AttendanceStatus.earlyLeave;
        checkIn = '08:00';
        checkOut = '15:30';
        hoursWorked = 7.5;
      } else {
        // حاضر عادي
        status = AttendanceStatus.present;
        checkIn = '08:00';
        checkOut = '17:00';
        hoursWorked = 9.0;
      }

      attendance.add(Attendance(
        date: date,
        checkIn: checkIn,
        checkOut: checkOut,
        status: status,
        hoursWorked: hoursWorked,
        lateMinutes: lateMinutes,
      ));
    }

    return attendance;
  }

  /// بيانات الرواتب الافتراضية
  static List<Salary> getMockSalaries() {
    final now = DateTime.now();
    final List<Salary> salaries = [];

    // إنشاء رواتب لآخر 12 شهر
    for (int i = 0; i < 12; i++) {
      int targetMonth = now.month - i;
      int targetYear = now.year;
      
      // معالجة الشهور السالبة
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }

      final date = DateTime(targetYear, targetMonth, 1);

      final monthNames = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];

      final monthName = monthNames[date.month - 1];
      final month = '$monthName ${date.year}';

      // تحديد الحالة
      SalaryStatus status;
      DateTime? paidDate;
      
      if (i == 0) {
        // آخر راتب - مدفوع
        status = SalaryStatus.paid;
        paidDate = date.add(const Duration(days: 5));
      } else if (i == 1) {
        // قبل الأخير - معلق
        status = SalaryStatus.pending;
        paidDate = null;
      } else {
        // الباقي - مدفوع
        status = SalaryStatus.paid;
        paidDate = date.add(const Duration(days: 5));
      }

      // المبلغ الأساسي
      final baseAmount = 5000.0 + (i * 100.0); // زيادة تدريجية
      final allowances = 500.0;
      final bonuses = i % 3 == 0 ? 1000.0 : 0.0; // مكافأة كل 3 أشهر
      final overtime = 200.0;
      final deductions = 100.0;
      final totalAmount = baseAmount + allowances + bonuses + overtime - deductions;

      salaries.add(Salary(
        salaryId: 'SAL-${date.year}-${date.month.toString().padLeft(2, '0')}',
        month: month,
        amount: totalAmount,
        currency: 'ر.س',
        paidDate: paidDate,
        status: status,
        details: SalaryDetails(
          baseSalary: baseAmount,
          allowances: allowances,
          deductions: deductions,
          bonuses: bonuses,
          overtime: overtime,
          tax: 0.0,
        ),
        notes: i == 0 ? 'تم الدفع بنجاح' : null,
      ));
    }

    return salaries;
  }

  /// بيانات السيارات الافتراضية
  static List<Car> getMockCars() {
    final now = DateTime.now();
    final List<Car> cars = [];

    final carModels = [
      'تويوتا كامري',
      'هوندا أكورد',
      'نيسان ألتيما',
      'هيونداي إلنترا',
      'شيفروليه ماليبو',
    ];

    final carColors = [
      'أبيض',
      'أسود',
      'فضي',
      'أزرق',
      'أحمر',
    ];

    final plateNumbers = [
      'أ ب ج 1234',
      'د هـ و 5678',
      'ز ح ط 9012',
      'ي ك ل 3456',
      'م ن س 7890',
    ];

    // إنشاء 5 سيارات
    for (int i = 0; i < 5; i++) {
      CarStatus status;
      if (i == 0) {
        status = CarStatus.active;
      } else if (i == 1) {
        status = CarStatus.maintenance;
      } else if (i == 2) {
        status = CarStatus.retired;
      } else {
        status = CarStatus.active;
      }

      cars.add(Car(
        carId: 'CAR-${i + 1}',
        plateNumber: plateNumbers[i],
        model: carModels[i],
        color: carColors[i],
        status: status,
        assignedDate: now.subtract(Duration(days: (i + 1) * 30)),
        unassignedDate: status == CarStatus.retired
            ? now.subtract(Duration(days: 5))
            : null,
        notes: status == CarStatus.maintenance
            ? 'في الصيانة - متوقع الانتهاء خلال أسبوع'
            : null,
      ));
    }

    return cars;
  }
}

