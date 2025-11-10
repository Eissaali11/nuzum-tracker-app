import '../models/attendance_model.dart';

/// ============================================
/// 📊 حاسبة الحضور - Attendance Calculator
/// ============================================
class AttendanceCalculator {
  /// حساب نسبة الحضور الشهري
  static double calculateMonthlyAttendanceRate(
    List<Attendance> attendanceList,
    int year,
    int month,
  ) {
    // تصفية الحضور للشهر المحدد
    final monthlyAttendance = attendanceList.where((attendance) {
      return attendance.date.year == year && attendance.date.month == month;
    }).toList();

    if (monthlyAttendance.isEmpty) return 0.0;

    // حساب عدد أيام الحضور
    final presentDays = monthlyAttendance
        .where((attendance) =>
            attendance.status == AttendanceStatus.present ||
            attendance.status == AttendanceStatus.late)
        .length;

    // حساب عدد أيام العمل (استثناء الإجازات)
    final workingDays = monthlyAttendance
        .where((attendance) => attendance.status != AttendanceStatus.holiday)
        .length;

    if (workingDays == 0) return 0.0;

    // حساب النسبة
    return (presentDays / workingDays) * 100;
  }

  /// حساب إحصائيات الحضور الشهري
  static Map<String, dynamic> calculateMonthlyStats(
    List<Attendance> attendanceList,
    int year,
    int month,
  ) {
    final monthlyAttendance = attendanceList.where((attendance) {
      return attendance.date.year == year && attendance.date.month == month;
    }).toList();

    if (monthlyAttendance.isEmpty) {
      return {
        'totalDays': 0,
        'presentDays': 0,
        'absentDays': 0,
        'lateDays': 0,
        'earlyLeaveDays': 0,
        'holidayDays': 0,
        'totalHours': 0.0,
        'attendanceRate': 0.0,
      };
    }

    int presentDays = 0;
    int absentDays = 0;
    int lateDays = 0;
    int earlyLeaveDays = 0;
    int holidayDays = 0;
    double totalHours = 0.0;

    for (final attendance in monthlyAttendance) {
      switch (attendance.status) {
        case AttendanceStatus.present:
          presentDays++;
          totalHours += attendance.hoursWorked;
          break;
        case AttendanceStatus.absent:
          absentDays++;
          break;
        case AttendanceStatus.late:
          lateDays++;
          presentDays++; // المتأخر يعتبر حاضر
          totalHours += attendance.hoursWorked;
          break;
        case AttendanceStatus.earlyLeave:
          earlyLeaveDays++;
          presentDays++; // الخروج المبكر يعتبر حاضر
          totalHours += attendance.hoursWorked;
          break;
        case AttendanceStatus.holiday:
          holidayDays++;
          break;
      }
    }

    final workingDays = monthlyAttendance.length - holidayDays;
    final attendanceRate = workingDays > 0
        ? ((presentDays / workingDays) * 100)
        : 0.0;

    return {
      'totalDays': monthlyAttendance.length,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'earlyLeaveDays': earlyLeaveDays,
      'holidayDays': holidayDays,
      'totalHours': totalHours,
      'attendanceRate': attendanceRate,
    };
  }

  /// الحصول على الحضور حسب الشهر
  static List<Attendance> getAttendanceByMonth(
    List<Attendance> attendanceList,
    int year,
    int month,
  ) {
    return attendanceList.where((attendance) {
      return attendance.date.year == year && attendance.date.month == month;
    }).toList();
  }
}

