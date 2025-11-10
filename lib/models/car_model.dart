/// ============================================
/// 🚗 نموذج السيارة - Car Model
/// ============================================
class Car {
  final String carId;
  final String plateNumber;
  final String? plateNumberEn;
  final String model;
  final String? modelEn;
  final String color;
  final String? colorEn;
  final CarStatus status;
  final DateTime assignedDate;
  final DateTime? unassignedDate;
  final String? photo;
  final String? notes;

  Car({
    required this.carId,
    required this.plateNumber,
    this.plateNumberEn,
    required this.model,
    this.modelEn,
    required this.color,
    this.colorEn,
    required this.status,
    required this.assignedDate,
    this.unassignedDate,
    this.photo,
    this.notes,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      carId: json['car_id'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      plateNumberEn: json['plate_number_en'],
      model: json['model'] ?? '',
      modelEn: json['model_en'],
      color: json['color'] ?? '',
      colorEn: json['color_en'],
      status: CarStatus.fromString(json['status'] ?? 'active'),
      assignedDate: DateTime.parse(json['assigned_date']),
      unassignedDate: json['unassigned_date'] != null
          ? DateTime.parse(json['unassigned_date'])
          : null,
      photo: json['photo'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'car_id': carId,
      'plate_number': plateNumber,
      'plate_number_en': plateNumberEn,
      'model': model,
      'model_en': modelEn,
      'color': color,
      'color_en': colorEn,
      'status': status.toString(),
      'assigned_date': assignedDate.toIso8601String(),
      'unassigned_date': unassignedDate?.toIso8601String(),
      'photo': photo,
      'notes': notes,
    };
  }
}

/// ============================================
/// 🚦 حالة السيارة - Car Status
/// ============================================
enum CarStatus {
  active,
  maintenance,
  retired;

  static CarStatus fromString(String value) {
    switch (value) {
      case 'active':
        return CarStatus.active;
      case 'maintenance':
        return CarStatus.maintenance;
      case 'retired':
        return CarStatus.retired;
      default:
        return CarStatus.active;
    }
  }

  String get displayName {
    switch (this) {
      case CarStatus.active:
        return 'نشط';
      case CarStatus.maintenance:
        return 'صيانة';
      case CarStatus.retired:
        return 'متقاعد';
    }
  }
}
