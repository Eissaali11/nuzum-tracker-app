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
  // معلومات إضافية للسيارة
  final String? insurance; // التامين
  final String? insuranceFile; // ملف التأمين
  final String? registrationImage; // صورة الاستمارة
  final String? registrationFormImage; // صورة نموذج الاستمارة
  final DateTime? authorizationDate; // تاريخ التفويض
  final DateTime? authorizationExpiryDate; // تاريخ انتهاء التفويض
  final DateTime? inspectionExpiryDate; // تاريخ انتهاء الفحص الدوري
  final DateTime? registrationExpiryDate; // تاريخ انتهاء الاستمارة
  final String? deliveryReceiptLink; // رابط نموذج التليم أو الاستلام
  final String? year; // سنة الصنع
  // حقول إضافية من API الجديد
  final String? typeOfCar; // نوع السيارة (باص، سيدان، إلخ)
  final String? statusArabic; // الحالة بالعربية
  final String? driverName; // اسم السائق
  final String? project; // المشروع
  final String? licenseImage; // صورة الرخصة
  final String? plateImage; // صورة اللوحة
  final String? driveFolderLink; // رابط مجلد Google Drive
  final DateTime? createdAt; // تاريخ الإنشاء
  final DateTime? updatedAt; // تاريخ التحديث

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
    this.insurance,
    this.insuranceFile,
    this.registrationImage,
    this.registrationFormImage,
    this.authorizationDate,
    this.authorizationExpiryDate,
    this.inspectionExpiryDate,
    this.registrationExpiryDate,
    this.deliveryReceiptLink,
    this.year,
    this.typeOfCar,
    this.statusArabic,
    this.driverName,
    this.project,
    this.licenseImage,
    this.plateImage,
    this.driveFolderLink,
    this.createdAt,
    this.updatedAt,
  });

  /// مساعد لتحليل التواريخ بصيغ مختلفة
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is String) {
        // محاولة تحليل بصيغ مختلفة
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          // محاولة صيغة YYYY-MM-DD
          if (dateValue.length == 10) {
            return DateTime.parse('$dateValue 00:00:00');
          }
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// مساعد لتحليل حقول النصوص مع محاولة عدة مفاتيح
  static String? _parseStringField(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  factory Car.fromJson(Map<String, dynamic> json) {
    // إنشاء car_id فريد إذا كان فارغاً
    final rawCarId = json['car_id'] ?? json['vehicle_id'] ?? json['id']?.toString() ?? '';
    final plateNumber = json['plate_number'] ?? '';
    final carId = rawCarId.isEmpty && plateNumber.isNotEmpty
        ? 'temp_${plateNumber.replaceAll(' ', '_').replaceAll('-', '_')}'
        : rawCarId;
    
    // دعم بنية API الجديدة: make + model
    String model = json['model'] ?? '';
    final make = json['make'] ?? '';
    if (make.isNotEmpty && model.isNotEmpty) {
      model = '$make $model';
    } else if (make.isNotEmpty) {
      model = make;
    }
    
    return Car(
      carId: carId,
      plateNumber: json['plate_number'] ?? '',
      plateNumberEn: json['plate_number_en'],
      model: model,
      modelEn: json['model_en'],
      color: json['color'] ?? '',
      colorEn: json['color_en'],
      status: CarStatus.fromString(json['status'] ?? 'active'),
      assignedDate: _parseDateTime(json['assigned_date']) ?? DateTime.now(),
      unassignedDate: json['unassigned_date'] != null
          ? _parseDateTime(json['unassigned_date'])
          : null,
      photo: json['photo'],
      notes: json['notes'],
      insurance: json['insurance'],
      insuranceFile: json['insurance_file'] ?? json['insuranceFile'],
      registrationImage: json['registration_image'] ?? json['registrationImage'],
      registrationFormImage: _parseStringField(json, ['registration_form_image', 'registrationFormImage', 'registration_form']),
      authorizationDate: json['authorization_date'] != null
          ? _parseDateTime(json['authorization_date'])
          : json['authorizationDate'] != null
              ? _parseDateTime(json['authorizationDate'])
              : null,
      authorizationExpiryDate: json['authorization_expiry_date'] != null
          ? _parseDateTime(json['authorization_expiry_date'])
          : json['authorizationExpiryDate'] != null
              ? _parseDateTime(json['authorizationExpiryDate'])
              : null,
      inspectionExpiryDate: json['inspection_expiry_date'] != null
          ? _parseDateTime(json['inspection_expiry_date'])
          : json['inspectionExpiryDate'] != null
              ? _parseDateTime(json['inspectionExpiryDate'])
              : null,
      registrationExpiryDate: json['registration_expiry_date'] != null
          ? _parseDateTime(json['registration_expiry_date'])
          : json['registrationExpiryDate'] != null
              ? _parseDateTime(json['registrationExpiryDate'])
              : null,
      deliveryReceiptLink: json['delivery_receipt_link'] ?? json['deliveryReceiptLink'],
      year: json['year']?.toString() ?? (json['year'] is int ? json['year'].toString() : null),
      typeOfCar: json['type_of_car'],
      statusArabic: json['status_arabic'],
      driverName: json['driver_name'],
      project: json['project'],
      licenseImage: json['license_image'],
      plateImage: json['plate_image'],
      driveFolderLink: json['drive_folder_link'],
      createdAt: json['created_at'] != null ? _parseDateTime(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? _parseDateTime(json['updated_at']) : null,
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
      'insurance': insurance,
      'insurance_file': insuranceFile,
      'registration_image': registrationImage,
      'registration_form_image': registrationFormImage,
      'authorization_date': authorizationDate?.toIso8601String(),
      'authorization_expiry_date': authorizationExpiryDate?.toIso8601String(),
      'inspection_expiry_date': inspectionExpiryDate?.toIso8601String(),
      'registration_expiry_date': registrationExpiryDate?.toIso8601String(),
      'delivery_receipt_link': deliveryReceiptLink,
      'year': year,
      'type_of_car': typeOfCar,
      'status_arabic': statusArabic,
      'driver_name': driverName,
      'project': project,
      'license_image': licenseImage,
      'plate_image': plateImage,
      'drive_folder_link': driveFolderLink,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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
    switch (value.toLowerCase()) {
      case 'active':
      case 'in_project': // حالة نشطة مع سائق
      case 'نشطة':
      case 'نشطة مع سائق':
        return CarStatus.active;
      case 'maintenance':
      case 'صيانة':
        return CarStatus.maintenance;
      case 'retired':
      case 'متقاعد':
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
