/// ============================================
/// 📦 نموذج العملية - Operation Model
/// ============================================
class Operation {
  final String operationId;
  final OperationType type;
  final DateTime date;
  final String time;
  final String carId;
  final String carPlateNumber;
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
    required this.carId,
    required this.carPlateNumber,
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
      carId: json['car_id'] ?? '',
      carPlateNumber: json['car_plate_number'] ?? '',
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

  Map<String, dynamic> toJson() {
    return {
      'operation_id': operationId,
      'type': type.toString(),
      'date': date.toIso8601String(),
      'time': time,
      'car_id': carId,
      'car_plate_number': carPlateNumber,
      'client_name': clientName,
      'client_phone': clientPhone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toString(),
      'items_count': itemsCount,
      'total_amount': totalAmount,
      'currency': currency,
      'notes': notes,
      'signature': signature,
    };
  }
}

/// ============================================
/// 📤 نوع العملية - Operation Type
/// ============================================
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

  String get displayName {
    switch (this) {
      case OperationType.delivery:
        return 'تسليم';
      case OperationType.pickup:
        return 'استلام';
    }
  }
}

/// ============================================
/// ✅ حالة العملية - Operation Status
/// ============================================
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

  String get displayName {
    switch (this) {
      case OperationStatus.completed:
        return 'مكتمل';
      case OperationStatus.pending:
        return 'معلق';
      case OperationStatus.cancelled:
        return 'ملغي';
    }
  }
}

/// ============================================
/// 📊 ملخص العمليات - Operation Summary
/// ============================================
class OperationSummary {
  final int totalOperations;
  final int deliveryCount;
  final int pickupCount;
  final int completedCount;
  final int pendingCount;
  final double totalAmount;

  OperationSummary({
    required this.totalOperations,
    required this.deliveryCount,
    required this.pickupCount,
    required this.completedCount,
    required this.pendingCount,
    required this.totalAmount,
  });

  factory OperationSummary.fromJson(Map<String, dynamic> json) {
    return OperationSummary(
      totalOperations: json['total_operations'] ?? 0,
      deliveryCount: json['delivery_count'] ?? 0,
      pickupCount: json['pickup_count'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
    );
  }
}

