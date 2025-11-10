/// ============================================
/// 📅 نموذج الحضور - Attendance Model
/// ============================================
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

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'check_in': checkIn,
      'check_out': checkOut,
      'status': status.toString(),
      'hours_worked': hoursWorked,
      'late_minutes': lateMinutes,
      'early_leave_minutes': earlyLeaveMinutes,
      'notes': notes,
    };
  }
}

/// ============================================
/// 📊 حالة الحضور - Attendance Status
/// ============================================
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

  String get displayName {
    switch (this) {
      case AttendanceStatus.present:
        return 'حاضر';
      case AttendanceStatus.absent:
        return 'غائب';
      case AttendanceStatus.late:
        return 'متأخر';
      case AttendanceStatus.earlyLeave:
        return 'خروج مبكر';
      case AttendanceStatus.holiday:
        return 'إجازة';
    }
  }
}

/// ============================================
/// 📈 ملخص الحضور - Attendance Summary
/// ============================================
class AttendanceSummary {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int earlyLeaveDays;
  final double totalHours;

  AttendanceSummary({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.earlyLeaveDays,
    required this.totalHours,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: json['total_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      lateDays: json['late_days'] ?? 0,
      earlyLeaveDays: json['early_leave_days'] ?? 0,
      totalHours: (json['total_hours'] ?? 0.0).toDouble(),
    );
  }
}
