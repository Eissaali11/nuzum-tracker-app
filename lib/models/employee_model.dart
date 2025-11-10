/// ============================================
/// 👤 نموذج الموظف - Employee Model
/// ============================================
class Employee {
  final String jobNumber;
  final String name;
  final String? nameEn;
  final String? nationalId;
  final DateTime? birthDate;
  final DateTime? hireDate;
  final String? nationality;
  final DateTime? residenceExpiryDate;
  final String? sponsorName;
  final String? absherPhone;
  final String department;
  final String? departmentEn;
  final String section;
  final String? sectionEn;
  final String position;
  final String? positionEn;
  final String? phone;
  final String? email;
  final bool isDriver;
  final EmployeePhotos? photos;
  final String? address;

  Employee({
    required this.jobNumber,
    required this.name,
    this.nameEn,
    this.nationalId,
    this.birthDate,
    this.hireDate,
    this.nationality,
    this.residenceExpiryDate,
    this.sponsorName,
    this.absherPhone,
    required this.department,
    this.departmentEn,
    required this.section,
    this.sectionEn,
    required this.position,
    this.positionEn,
    this.phone,
    this.email,
    required this.isDriver,
    this.photos,
    this.address,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      jobNumber: json['job_number'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      nationalId: json['national_id'],
      birthDate: json['birth_date'] != null 
          ? DateTime.parse(json['birth_date']) 
          : null,
      hireDate: json['hire_date'] != null 
          ? DateTime.parse(json['hire_date']) 
          : null,
      nationality: json['nationality'],
      residenceExpiryDate: json['residence_expiry_date'] != null 
          ? DateTime.parse(json['residence_expiry_date']) 
          : null,
      sponsorName: json['sponsor_name'],
      absherPhone: json['absher_phone'],
      department: json['department'] ?? '',
      departmentEn: json['department_en'],
      section: json['section'] ?? '',
      sectionEn: json['section_en'],
      position: json['position'] ?? '',
      positionEn: json['position_en'],
      phone: json['phone'],
      email: json['email'],
      isDriver: json['is_driver'] ?? false,
      photos: json['photos'] != null ? EmployeePhotos.fromJson(json['photos']) : null,
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_number': jobNumber,
      'name': name,
      'name_en': nameEn,
      'national_id': nationalId,
      'birth_date': birthDate?.toIso8601String(),
      'hire_date': hireDate?.toIso8601String(),
      'nationality': nationality,
      'residence_expiry_date': residenceExpiryDate?.toIso8601String(),
      'sponsor_name': sponsorName,
      'absher_phone': absherPhone,
      'department': department,
      'department_en': departmentEn,
      'section': section,
      'section_en': sectionEn,
      'position': position,
      'position_en': positionEn,
      'phone': phone,
      'email': email,
      'is_driver': isDriver,
      'photos': photos?.toJson(),
      'address': address,
    };
  }
}

/// ============================================
/// 📸 صور الموظف - Employee Photos
/// ============================================
class EmployeePhotos {
  final String? personal;
  final String? id;
  final String? license;

  EmployeePhotos({
    this.personal,
    this.id,
    this.license,
  });

  factory EmployeePhotos.fromJson(Map<String, dynamic> json) {
    return EmployeePhotos(
      personal: json['personal'],
      id: json['id'],
      license: json['license'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personal': personal,
      'id': id,
      'license': license,
    };
  }
}

