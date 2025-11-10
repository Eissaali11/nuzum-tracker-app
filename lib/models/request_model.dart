/// ============================================
/// 📋 نموذج الطلب - Request Model
/// ============================================
class Request {
  final int id;
  final String type; // 'advance', 'invoice', 'car_wash', 'car_inspection'
  final String title;
  final String status; // 'pending', 'approved', 'rejected', 'completed'
  final double? amount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminNotes;
  final Map<String, dynamic>? typeSpecificData;

  Request({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.adminNotes,
    this.typeSpecificData,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      adminNotes: json['admin_notes'] as String?,
      typeSpecificData:
          json['advance_data'] ??
          json['invoice_data'] ??
          json['car_wash_data'] ??
          json['inspection_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'status': status,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'admin_notes': adminNotes,
    };
  }

  String get typeLabel {
    switch (type) {
      case 'advance':
        return 'طلب سلفة';
      case 'invoice':
        return 'رفع فاتورة';
      case 'car_wash':
        return 'طلب غسيل سيارة';
      case 'car_inspection':
        return 'فحص وتوثيق سيارة';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'معتمد';
      case 'rejected':
        return 'مرفوض';
      case 'completed':
        return 'مكتمل';
      default:
        return status;
    }
  }
}

/// ============================================
/// 💰 نموذج طلب السلفة - Advance Payment Request
/// ============================================
class AdvancePaymentRequest {
  final int? requestId;
  final int employeeId;
  final double requestedAmount;
  final String? reason;
  final int? installments; // 1-12 months
  final String? imagePath; // مسار صورة مرفقة (اختياري)

  AdvancePaymentRequest({
    this.requestId,
    required this.employeeId,
    required this.requestedAmount,
    this.reason,
    this.installments,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'requested_amount': requestedAmount,
      if (reason != null) 'reason': reason,
      if (installments != null) 'installments': installments,
      // imagePath لا يُرسل في JSON - يتم رفعه كملف منفصل
    };
  }

  double calculateMonthlyInstallment() {
    if (installments == null || installments == 0) return requestedAmount;
    return requestedAmount / installments!;
  }
}

/// ============================================
/// 🧾 نموذج رفع الفاتورة - Invoice Request
/// ============================================
class InvoiceRequest {
  final int? requestId;
  final int employeeId;
  final String vendorName;
  final double amount;
  final String? description;
  final String? imagePath; // Local file path

  InvoiceRequest({
    this.requestId,
    required this.employeeId,
    required this.vendorName,
    required this.amount,
    this.description,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'vendor_name': vendorName,
      'amount': amount,
      if (description != null) 'description': description,
    };
  }
}

/// ============================================
/// 🚗 نموذج طلب غسيل السيارة - Car Wash Request
/// ============================================
class CarWashRequest {
  final int? requestId;
  final int employeeId;
  final int vehicleId; // 0 للإدخال اليدوي
  final String? manualCarInfo; // معلومات السيارة للإدخال اليدوي
  final String serviceType; // 'normal', 'polish', 'full_clean'
  final DateTime? requestedDate;
  final Map<String, String?>
  photos; // plate, front, back, right_side, left_side

  CarWashRequest({
    this.requestId,
    required this.employeeId,
    required this.vehicleId,
    this.manualCarInfo,
    required this.serviceType,
    this.requestedDate,
    required this.photos,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'vehicle_id': vehicleId,
      if (manualCarInfo != null && manualCarInfo!.isNotEmpty)
        'manual_car_info': manualCarInfo,
      'service_type': serviceType,
      if (requestedDate != null)
        'requested_date': requestedDate!.toIso8601String(),
    };
  }

  String get serviceTypeLabel {
    switch (serviceType) {
      case 'normal':
        return 'غسيل عادي';
      case 'polish':
        return 'تلميع';
      case 'full_clean':
        return 'تنظيف شامل';
      default:
        return serviceType;
    }
  }

  bool get hasAllPhotos {
    return photos['plate'] != null &&
        photos['front'] != null &&
        photos['back'] != null &&
        photos['right_side'] != null &&
        photos['left_side'] != null;
  }
}

/// ============================================
/// 🔍 نموذج فحص وتوثيق السيارة - Car Inspection Request
/// ============================================
class CarInspectionRequest {
  final int? requestId;
  final int employeeId;
  final int vehicleId;
  final String inspectionType; // 'accident', 'periodic', 'receipt'
  final String? description;
  final List<String>? imagePaths;
  final List<String>? videoPaths;

  CarInspectionRequest({
    this.requestId,
    required this.employeeId,
    required this.vehicleId,
    required this.inspectionType,
    this.description,
    this.imagePaths,
    this.videoPaths,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'vehicle_id': vehicleId,
      'inspection_type': inspectionType,
      if (description != null) 'description': description,
    };
  }

  String get inspectionTypeLabel {
    switch (inspectionType) {
      case 'accident':
        return 'حادث';
      case 'periodic':
        return 'دوري';
      case 'receipt':
        return 'استلام';
      default:
        return inspectionType;
    }
  }
}

/// ============================================
/// 📊 إحصائيات الطلبات - Request Statistics
/// ============================================
class RequestStatistics {
  final int activeRequests;
  final int approvedRequests;
  final int rejectedRequests;
  final int totalRequests;

  RequestStatistics({
    required this.activeRequests,
    required this.approvedRequests,
    required this.rejectedRequests,
    required this.totalRequests,
  });

  factory RequestStatistics.fromJson(Map<String, dynamic> json) {
    return RequestStatistics(
      activeRequests: json['active_requests'] ?? 0,
      approvedRequests: json['approved_requests'] ?? 0,
      rejectedRequests: json['rejected_requests'] ?? 0,
      totalRequests: json['total_requests'] ?? 0,
    );
  }
}
