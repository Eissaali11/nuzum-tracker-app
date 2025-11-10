/// ============================================
/// 📦 نموذج الاستجابة الشاملة للموظف - Complete Employee Response Model
/// ============================================
import 'employee_model.dart';
import 'attendance_model.dart';
import 'car_model.dart';
import 'salary_model.dart';
import 'operation_model.dart';

class CompleteEmployeeResponse {
  final Employee employee;
  final Car? currentCar;
  final List<Car> previousCars;
  final List<Attendance> attendance;
  final List<Salary> salaries;
  final List<Operation> operations;
  final CompleteEmployeeStatistics statistics;

  CompleteEmployeeResponse({
    required this.employee,
    this.currentCar,
    required this.previousCars,
    required this.attendance,
    required this.salaries,
    required this.operations,
    required this.statistics,
  });

  factory CompleteEmployeeResponse.fromJson(Map<String, dynamic> json) {
    return CompleteEmployeeResponse(
      employee: Employee.fromJson(json['employee'] as Map<String, dynamic>),
      currentCar: json['current_car'] != null
          ? Car.fromJson(json['current_car'] as Map<String, dynamic>)
          : null,
      previousCars: (json['previous_cars'] as List<dynamic>?)
              ?.map((item) => Car.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      attendance: (json['attendance'] as List<dynamic>?)
              ?.map((item) => Attendance.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      salaries: (json['salaries'] as List<dynamic>?)
              ?.map((item) => Salary.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      operations: (json['operations'] as List<dynamic>?)
              ?.map((item) => Operation.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      statistics: CompleteEmployeeStatistics.fromJson(
        json['statistics'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee': employee.toJson(),
      'current_car': currentCar?.toJson(),
      'previous_cars': previousCars.map((car) => car.toJson()).toList(),
      'attendance': attendance.map((att) => att.toJson()).toList(),
      'salaries': salaries.map((sal) => sal.toJson()).toList(),
      'operations': operations.map((op) => op.toJson()).toList(),
      'statistics': statistics.toJson(),
    };
  }
}

/// ============================================
/// 📊 إحصائيات الموظف الشاملة - Complete Employee Statistics
/// ============================================
class CompleteEmployeeStatistics {
  final AttendanceStatistics attendance;
  final SalaryStatistics salaries;
  final CarStatistics cars;
  final OperationStatistics operations;

  CompleteEmployeeStatistics({
    required this.attendance,
    required this.salaries,
    required this.cars,
    required this.operations,
  });

  factory CompleteEmployeeStatistics.fromJson(Map<String, dynamic> json) {
    return CompleteEmployeeStatistics(
      attendance: AttendanceStatistics.fromJson(
        json['attendance'] as Map<String, dynamic>,
      ),
      salaries: SalaryStatistics.fromJson(
        json['salaries'] as Map<String, dynamic>,
      ),
      cars: CarStatistics.fromJson(
        json['cars'] as Map<String, dynamic>,
      ),
      operations: OperationStatistics.fromJson(
        json['operations'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendance': attendance.toJson(),
      'salaries': salaries.toJson(),
      'cars': cars.toJson(),
      'operations': operations.toJson(),
    };
  }
}

/// ============================================
/// 📅 إحصائيات الحضور - Attendance Statistics
/// ============================================
class AttendanceStatistics {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int earlyLeaveDays;
  final double totalHours;
  final double attendanceRate;

  AttendanceStatistics({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.earlyLeaveDays,
    required this.totalHours,
    required this.attendanceRate,
  });

  factory AttendanceStatistics.fromJson(Map<String, dynamic> json) {
    return AttendanceStatistics(
      totalDays: json['total_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      lateDays: json['late_days'] ?? 0,
      earlyLeaveDays: json['early_leave_days'] ?? 0,
      totalHours: (json['total_hours'] ?? 0.0).toDouble(),
      attendanceRate: (json['attendance_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'late_days': lateDays,
      'early_leave_days': earlyLeaveDays,
      'total_hours': totalHours,
      'attendance_rate': attendanceRate,
    };
  }
}

/// ============================================
/// 💰 إحصائيات الرواتب - Salary Statistics
/// ============================================
class SalaryStatistics {
  final int totalSalaries;
  final double totalAmount;
  final double averageAmount;
  final double lastSalary;
  final DateTime? lastPaidDate;

  SalaryStatistics({
    required this.totalSalaries,
    required this.totalAmount,
    required this.averageAmount,
    required this.lastSalary,
    this.lastPaidDate,
  });

  factory SalaryStatistics.fromJson(Map<String, dynamic> json) {
    return SalaryStatistics(
      totalSalaries: json['total_salaries'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      averageAmount: (json['average_amount'] ?? 0.0).toDouble(),
      lastSalary: (json['last_salary'] ?? 0.0).toDouble(),
      lastPaidDate: json['last_paid_date'] != null
          ? DateTime.parse(json['last_paid_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_salaries': totalSalaries,
      'total_amount': totalAmount,
      'average_amount': averageAmount,
      'last_salary': lastSalary,
      'last_paid_date': lastPaidDate?.toIso8601String(),
    };
  }
}

/// ============================================
/// 🚗 إحصائيات السيارات - Car Statistics
/// ============================================
class CarStatistics {
  final bool currentCar;
  final int totalCars;
  final int activeCars;
  final int maintenanceCars;
  final int retiredCars;

  CarStatistics({
    required this.currentCar,
    required this.totalCars,
    required this.activeCars,
    required this.maintenanceCars,
    required this.retiredCars,
  });

  factory CarStatistics.fromJson(Map<String, dynamic> json) {
    return CarStatistics(
      currentCar: json['current_car'] ?? false,
      totalCars: json['total_cars'] ?? 0,
      activeCars: json['active_cars'] ?? 0,
      maintenanceCars: json['maintenance_cars'] ?? 0,
      retiredCars: json['retired_cars'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_car': currentCar,
      'total_cars': totalCars,
      'active_cars': activeCars,
      'maintenance_cars': maintenanceCars,
      'retired_cars': retiredCars,
    };
  }
}

/// ============================================
/// 📦 إحصائيات العمليات - Operation Statistics
/// ============================================
class OperationStatistics {
  final int totalOperations;
  final int deliveryCount;
  final int pickupCount;
  final int completedCount;

  OperationStatistics({
    required this.totalOperations,
    required this.deliveryCount,
    required this.pickupCount,
    required this.completedCount,
  });

  factory OperationStatistics.fromJson(Map<String, dynamic> json) {
    return OperationStatistics(
      totalOperations: json['total_operations'] ?? 0,
      deliveryCount: json['delivery_count'] ?? 0,
      pickupCount: json['pickup_count'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_operations': totalOperations,
      'delivery_count': deliveryCount,
      'pickup_count': pickupCount,
      'completed_count': completedCount,
    };
  }
}

