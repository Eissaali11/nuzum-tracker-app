/// ============================================
/// 📋 نموذج سجل التسليم/الاستلام - Handover Record Model
/// ============================================
class HandoverRecord {
  final int id;
  final HandoverType handoverType;
  final String handoverTypeArabic;
  final DateTime handoverDate;
  final String handoverTime;
  final int mileage;
  final String vehiclePlateNumber;
  final String vehicleType;
  final String projectName;
  final String city;
  final String personName;
  final String supervisorName;
  final String fuelLevel;
  final String? notes;
  final String? formLink;
  final String? formLink2;
  final String? driverSignature;
  final String? supervisorSignature;
  final String? damageDiagram;
  final String? vehicleStatusSummary;
  final String? reasonForChange;
  final HandoverChecklist? checklist;
  final List<HandoverImage> images;

  HandoverRecord({
    required this.id,
    required this.handoverType,
    required this.handoverTypeArabic,
    required this.handoverDate,
    required this.handoverTime,
    required this.mileage,
    required this.vehiclePlateNumber,
    required this.vehicleType,
    required this.projectName,
    required this.city,
    required this.personName,
    required this.supervisorName,
    required this.fuelLevel,
    this.notes,
    this.formLink,
    this.formLink2,
    this.driverSignature,
    this.supervisorSignature,
    this.damageDiagram,
    this.vehicleStatusSummary,
    this.reasonForChange,
    this.checklist,
    required this.images,
  });

  factory HandoverRecord.fromJson(Map<String, dynamic> json) {
    return HandoverRecord(
      id: json['id'] ?? 0,
      handoverType: HandoverType.fromString(json['handover_type'] ?? ''),
      handoverTypeArabic: json['handover_type_arabic'] ?? '',
      handoverDate: _parseDate(json['handover_date']),
      handoverTime: json['handover_time'] ?? '',
      mileage: json['mileage'] ?? 0,
      vehiclePlateNumber: json['vehicle_plate_number'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      projectName: json['project_name'] ?? '',
      city: json['city'] ?? '',
      personName: json['person_name'] ?? '',
      supervisorName: json['supervisor_name'] ?? '',
      fuelLevel: json['fuel_level'] ?? '',
      notes: json['notes'],
      formLink: json['form_link'],
      formLink2: json['form_link_2'],
      driverSignature: json['driver_signature'],
      supervisorSignature: json['supervisor_signature'],
      damageDiagram: json['damage_diagram'],
      vehicleStatusSummary: json['vehicle_status_summary'],
      reasonForChange: json['reason_for_change'],
      checklist: json['checklist'] != null
          ? HandoverChecklist.fromJson(json['checklist'] as Map<String, dynamic>)
          : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((img) => HandoverImage.fromJson(img as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    try {
      if (dateValue is String) {
        if (dateValue.length == 10) {
          return DateTime.parse('$dateValue 00:00:00');
        }
        return DateTime.parse(dateValue);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'handover_type': handoverType.toString(),
      'handover_type_arabic': handoverTypeArabic,
      'handover_date': handoverDate.toIso8601String().split('T')[0],
      'handover_time': handoverTime,
      'mileage': mileage,
      'vehicle_plate_number': vehiclePlateNumber,
      'vehicle_type': vehicleType,
      'project_name': projectName,
      'city': city,
      'person_name': personName,
      'supervisor_name': supervisorName,
      'fuel_level': fuelLevel,
      'notes': notes,
      'form_link': formLink,
      'form_link_2': formLink2,
      'driver_signature': driverSignature,
      'supervisor_signature': supervisorSignature,
      'damage_diagram': damageDiagram,
      'vehicle_status_summary': vehicleStatusSummary,
      'reason_for_change': reasonForChange,
      'checklist': checklist?.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
    };
  }
}

/// ============================================
/// 📝 نوع التسليم - Handover Type
/// ============================================
enum HandoverType {
  delivery,
  receipt;

  static HandoverType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'delivery':
      case 'تسليم':
        return HandoverType.delivery;
      case 'receipt':
      case 'استلام':
        return HandoverType.receipt;
      default:
        return HandoverType.delivery;
    }
  }

  String get displayName {
    switch (this) {
      case HandoverType.delivery:
        return 'تسليم';
      case HandoverType.receipt:
        return 'استلام';
    }
  }
}

/// ============================================
/// ✅ قائمة فحص التسليم - Handover Checklist
/// ============================================
class HandoverChecklist {
  final bool spareTire;
  final bool fireExtinguisher;
  final bool firstAidKit;
  final bool warningTriangle;
  final bool tools;
  final bool oilLeaks;
  final bool gearIssue;
  final bool clutchIssue;
  final bool engineIssue;
  final bool windowsIssue;
  final bool tiresIssue;
  final bool bodyIssue;
  final bool electricityIssue;
  final bool lightsIssue;
  final bool acIssue;

  HandoverChecklist({
    required this.spareTire,
    required this.fireExtinguisher,
    required this.firstAidKit,
    required this.warningTriangle,
    required this.tools,
    required this.oilLeaks,
    required this.gearIssue,
    required this.clutchIssue,
    required this.engineIssue,
    required this.windowsIssue,
    required this.tiresIssue,
    required this.bodyIssue,
    required this.electricityIssue,
    required this.lightsIssue,
    required this.acIssue,
  });

  factory HandoverChecklist.fromJson(Map<String, dynamic> json) {
    return HandoverChecklist(
      spareTire: json['spare_tire'] ?? false,
      fireExtinguisher: json['fire_extinguisher'] ?? false,
      firstAidKit: json['first_aid_kit'] ?? false,
      warningTriangle: json['warning_triangle'] ?? false,
      tools: json['tools'] ?? false,
      oilLeaks: json['oil_leaks'] ?? false,
      gearIssue: json['gear_issue'] ?? false,
      clutchIssue: json['clutch_issue'] ?? false,
      engineIssue: json['engine_issue'] ?? false,
      windowsIssue: json['windows_issue'] ?? false,
      tiresIssue: json['tires_issue'] ?? false,
      bodyIssue: json['body_issue'] ?? false,
      electricityIssue: json['electricity_issue'] ?? false,
      lightsIssue: json['lights_issue'] ?? false,
      acIssue: json['ac_issue'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spare_tire': spareTire,
      'fire_extinguisher': fireExtinguisher,
      'first_aid_kit': firstAidKit,
      'warning_triangle': warningTriangle,
      'tools': tools,
      'oil_leaks': oilLeaks,
      'gear_issue': gearIssue,
      'clutch_issue': clutchIssue,
      'engine_issue': engineIssue,
      'windows_issue': windowsIssue,
      'tires_issue': tiresIssue,
      'body_issue': bodyIssue,
      'electricity_issue': electricityIssue,
      'lights_issue': lightsIssue,
      'ac_issue': acIssue,
    };
  }
}

/// ============================================
/// 📷 صورة التسليم - Handover Image
/// ============================================
class HandoverImage {
  final int id;
  final String url;
  final DateTime uploadedAt;

  HandoverImage({
    required this.id,
    required this.url,
    required this.uploadedAt,
  });

  factory HandoverImage.fromJson(Map<String, dynamic> json) {
    return HandoverImage(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
      uploadedAt: _parseDateTime(json['uploaded_at']),
    );
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue.replaceAll(' ', 'T'));
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

