/// ============================================
/// 📱 نموذج ربط الجهاز والـ SIM - Device and SIM Binding Model
/// ============================================
class DeviceBinding {
  final int? id;
  final String? deviceId;
  final String? deviceModel;
  final String? deviceBrand;
  final String? simSerialNumber;
  final String? simOperator;
  final String? phoneNumber;
  final DateTime? bindingDate;
  final bool isActive;

  DeviceBinding({
    this.id,
    this.deviceId,
    this.deviceModel,
    this.deviceBrand,
    this.simSerialNumber,
    this.simOperator,
    this.phoneNumber,
    this.bindingDate,
    this.isActive = true,
  });

  factory DeviceBinding.fromJson(Map<String, dynamic> json) {
    return DeviceBinding(
      id: json['id'] as int?,
      deviceId: json['device_id'] as String?,
      deviceModel: json['device_model'] as String?,
      deviceBrand: json['device_brand'] as String?,
      simSerialNumber: json['sim_serial_number'] as String?,
      simOperator: json['sim_operator'] as String?,
      phoneNumber: json['phone_number'] as String?,
      bindingDate: json['binding_date'] != null
          ? DateTime.parse(json['binding_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_model': deviceModel,
      'device_brand': deviceBrand,
      'sim_serial_number': simSerialNumber,
      'sim_operator': simOperator,
      'phone_number': phoneNumber,
      'binding_date': bindingDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}

