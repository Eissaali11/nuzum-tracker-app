import 'car_model.dart';
import 'handover_record_model.dart';

/// ============================================
/// 🚗 استجابة تفاصيل السيارة الكاملة - Vehicle Details Response
/// ============================================
class VehicleDetailsResponse {
  final bool success;
  final EmployeeInfo? employee;
  final Car? vehicle;
  final List<HandoverRecord> handoverRecords;
  final int handoverCount;

  VehicleDetailsResponse({
    required this.success,
    this.employee,
    this.vehicle,
    required this.handoverRecords,
    required this.handoverCount,
  });

  factory VehicleDetailsResponse.fromJson(Map<String, dynamic> json) {
    return VehicleDetailsResponse(
      success: json['success'] ?? false,
      employee: json['employee'] != null
          ? EmployeeInfo.fromJson(json['employee'] as Map<String, dynamic>)
          : null,
      vehicle: json['vehicle'] != null
          ? Car.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
      handoverRecords: (json['handover_records'] as List<dynamic>?)
              ?.map((record) =>
                  HandoverRecord.fromJson(record as Map<String, dynamic>))
              .toList() ??
          [],
      handoverCount: json['handover_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'employee': employee?.toJson(),
      'vehicle': vehicle?.toJson(),
      'handover_records':
          handoverRecords.map((record) => record.toJson()).toList(),
      'handover_count': handoverCount,
    };
  }
}

/// ============================================
/// 👤 معلومات الموظف - Employee Info
/// ============================================
class EmployeeInfo {
  final int id;
  final String employeeId;
  final String name;
  final String mobile;
  final String? mobilePersonal;
  final String jobTitle;
  final String department;

  EmployeeInfo({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.mobile,
    this.mobilePersonal,
    required this.jobTitle,
    required this.department,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      mobilePersonal: json['mobile_personal'],
      jobTitle: json['job_title'] ?? '',
      department: json['department'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'name': name,
      'mobile': mobile,
      'mobile_personal': mobilePersonal,
      'job_title': jobTitle,
      'department': department,
    };
  }
}

