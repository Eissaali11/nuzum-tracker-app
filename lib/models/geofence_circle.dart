import 'package:geolocator/geolocator.dart';

/// ============================================
/// 🎯 نموذج دائرة Geofence - Geofence Circle Model
/// ============================================
class GeofenceCircle {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // بالمتار
  final String? employeeId; // الموظف المرتبط بهذه الدائرة
  final String? description;
  final DateTime? createdAt;

  GeofenceCircle({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.employeeId,
    this.description,
    this.createdAt,
  });

  factory GeofenceCircle.fromJson(Map<String, dynamic> json) {
    return GeofenceCircle(
      id: json['id'] ?? json['circle_id'] ?? '',
      name: json['name'] ?? json['circle_name'] ?? '',
      latitude: (json['latitude'] ?? json['lat'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['lng'] ?? json['lon'] ?? 0.0).toDouble(),
      radius: (json['radius'] ?? json['allowed_radius'] ?? 50.0).toDouble(),
      employeeId: json['employee_id'] ?? json['job_number'],
      description: json['description'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'employee_id': employeeId,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// حساب المسافة من نقطة معينة إلى مركز الدائرة
  double distanceTo(double lat, double lng) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      lat,
      lng,
    );
  }

  /// التحقق من أن النقطة داخل الدائرة
  bool contains(double lat, double lng) {
    return distanceTo(lat, lng) <= radius;
  }
}

