/// ============================================
/// 📝 سجل التحضير - Attendance Record
/// ============================================
class AttendanceRecord {
  final String employeeId;
  final DateTime timestamp;
  final AttendanceType type; // check_in, check_out
  final LocationData location;
  final double confidence; // Face recognition confidence
  final double livenessScore; // Liveness detection score
  final String? imagePath; // Optional: صورة التحضير
  final Map<String, dynamic>? metadata; // بيانات إضافية

  AttendanceRecord({
    required this.employeeId,
    required this.timestamp,
    required this.type,
    required this.location,
    required this.confidence,
    required this.livenessScore,
    this.imagePath,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'location': location.toJson(),
      'confidence': confidence,
      'liveness_score': livenessScore,
      if (imagePath != null) 'image_path': imagePath,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      employeeId: json['employee_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: AttendanceType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AttendanceType.check_in,
      ),
      location: LocationData.fromJson(json['location'] as Map<String, dynamic>),
      confidence: (json['confidence'] as num).toDouble(),
      livenessScore: (json['liveness_score'] as num).toDouble(),
      imagePath: json['image_path'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// ============================================
/// 📍 بيانات الموقع - Location Data
/// ============================================
class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// ============================================
/// 🕐 نوع التحضير - Attendance Type
/// ============================================
enum AttendanceType {
  check_in,  // تحضير
  check_out, // خروج
}

