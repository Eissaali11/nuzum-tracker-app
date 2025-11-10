/// ============================================
/// 👤 نموذج بيانات الوجه - Face Model
/// ============================================
class FaceData {
  final String employeeId;
  final Map<String, dynamic> features; // Face features
  final DateTime enrolledAt;
  final String? imagePath; // Optional: للعرض فقط

  FaceData({
    required this.employeeId,
    required this.features,
    required this.enrolledAt,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'features': features,
      'enrolled_at': enrolledAt.toIso8601String(),
      if (imagePath != null) 'image_path': imagePath,
    };
  }

  factory FaceData.fromJson(Map<String, dynamic> json) {
    return FaceData(
      employeeId: json['employee_id'] as String,
      features: json['features'] as Map<String, dynamic>,
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      imagePath: json['image_path'] as String?,
    );
  }
}

