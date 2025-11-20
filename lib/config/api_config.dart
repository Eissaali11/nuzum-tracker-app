/// ============================================
/// 🔧 إعدادات API - API Configuration
/// ============================================
class ApiConfig {
  // الدومين الأساسي - الرابط الجديد
  static const String baseUrl = 'https://eissahr.replit.app';
  
  // الدومين الجديد لبيانات السيارات (يستخدم HTTPS)
  static const String nuzumBaseUrl = 'https://nuzum.site';

  // الدومين البديل (احتياطي)
  static const String backupDomain = 'https://d72f2aef-918c-4148-9723-15870f8c7cf6-00-2c1ygyxvqoldk.riker.replit.dev';

  // مفتاح API الافتراضي
  static const String defaultApiKey = 'test_location_key_2025';

  // Google Drive Folder IDs
  // رابط المجلد: https://drive.google.com/drive/folders/1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe
  static const String invoiceDriveFolderId = '1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe';
  static const String advanceDriveFolderId = '1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe'; // نفس المجلد أو مجلد منفصل
  static const String carWashDriveFolderId = '1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe'; // نفس المجلد أو مجلد منفصل
  static const String inspectionDriveFolderId = '1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe'; // نفس المجلد أو مجلد منفصل

  // Timeout للطلبات
  static const Duration timeoutDuration = Duration(seconds: 30);

  // مسارات API - يستخدم /api/external/ (غير متوفر في v1)
  static const String locationPath = '/api/external/employee-location';
  static const String statusPath = '/api/external/employee-status';
  static const String profilePath = '/api/external/employee-profile';
  static const String attendancePath = '/api/external/employee-attendance';
  static const String carsPath = '/api/external/employee-cars';
  static const String salariesPath = '/api/external/employee-salaries';
  static const String operationsPath = '/api/external/employee-operations';
  // مسار الملف الشامل للموظف - يستخدم /api/external/ (غير متوفر في v1)
  static const String completeProfilePath =
      '/api/external/employee-complete-profile';

  // مسارات طلبات الموظفين - تم التحديث لاستخدام v1
  static const String requestsBasePath = '/api/v1/requests';
  static const String myRequestsPath = requestsBasePath; // GET /api/v1/requests
  static const String createAdvancePath =
      '$requestsBasePath/create-advance-payment'; // ✅ متوفر الآن
  static const String createInvoicePath = '$requestsBasePath/create-invoice'; // ✅ متوفر الآن
  static const String createCarWashPath = '$requestsBasePath/create-car-wash'; // ✅ متوفر الآن
  static const String createCarInspectionPath =
      '$requestsBasePath/create-car-inspection'; // ✅ متوفر الآن
  static const String requestDetailsPath = requestsBasePath; // GET /api/v1/requests/{id}
  static const String deleteRequestPath = requestsBasePath; // DELETE /api/v1/requests/{id}
  static const String uploadInspectionImagePath =
      requestsBasePath; // POST /api/v1/requests/{id}/upload-inspection-image
  static const String uploadInspectionVideoPath =
      requestsBasePath; // POST /api/v1/requests/{id}/upload-inspection-video
  static const String requestUploadPath = requestsBasePath; // POST /api/v1/requests/{id}/upload

  // مسارات الالتزامات المالية - ✅ متوفرة الآن
  static const String liabilitiesPath = '/api/v1/employee/liabilities'; // ✅ متوفر
  static const String financialSummaryPath =
      '/api/v1/employee/financial-summary'; // ✅ متوفر

  // مسارات الإشعارات - تم التحديث لاستخدام v1
  static const String notificationsPath = '/api/v1/notifications';
  static const String markNotificationReadPath =
      notificationsPath; // PUT /api/v1/notifications/{id}/read
  static const String markAllNotificationsReadPath =
      '$notificationsPath/mark-all-read'; // ✅ متوفر الآن

  // مسار تسجيل الدخول - تم التحديث لاستخدام v1
  static const String loginPath = '/api/v1/auth/login';
  
  // مسار تسجيل الحضور مع التحقق الكامل - v1
  static const String checkInPath = '/api/v1/attendance/check-in';
  static const String checkOutPath = '/api/v1/attendance/check-out';
  
  // ============================================
  // 🆕 مسارات API الجديدة (نظام نُظم v1)
  // ============================================
  // مسارات API v1
  static const String v1BasePath = '/api/v1';
  
  // مسارات المصادقة v1
  static const String v1LoginPath = '$v1BasePath/auth/login';
  static const String v1RefreshTokenPath = '$v1BasePath/auth/refresh';
  
  // مسارات الطلبات v1
  static const String v1RequestsPath = '$v1BasePath/requests';
  static const String v1RequestTypesPath = '$v1RequestsPath/types';
  static const String v1RequestStatisticsPath = '$v1RequestsPath/statistics';
  
  // مسارات السيارات v1
  static const String v1VehiclesPath = '$v1BasePath/vehicles';
  
  // مسارات السيارات الجديدة (nuzum.site)
  static const String employeeVehiclePath = '/api/employees'; // GET /api/employees/{employee_id}/vehicle
  static const String vehicleDetailsPath = '/api/vehicles'; // GET /api/vehicles/{vehicle_id}/details
  
  // مسارات الإشعارات v1
  static const String v1NotificationsPath = '$v1BasePath/notifications';
  
  // الحصول على URLs v1
  static String getV1LoginUrl() => '$baseUrl$v1LoginPath';
  static String getV1RequestsUrl() => '$baseUrl$v1RequestsPath';
  static String getV1RequestDetailsUrl(int id) => '$baseUrl$v1RequestsPath/$id';
  static String getV1RequestTypesUrl() => '$baseUrl$v1RequestTypesPath';
  static String getV1RequestStatisticsUrl() => '$baseUrl$v1RequestStatisticsPath';
  static String getV1VehiclesUrl() => '$baseUrl$v1VehiclesPath';
  static String getV1NotificationsUrl() => '$baseUrl$v1NotificationsPath';
  static String getV1NotificationReadUrl(int id) => '$baseUrl$v1NotificationsPath/$id/read';
  static String getV1RequestUploadUrl(int id) => '$baseUrl$v1RequestsPath/$id/upload';

  // الحصول على URLs
  static String getLocationUrl() => '$baseUrl$locationPath';
  static String getStatusUrl() => '$baseUrl$statusPath';
  static String getProfileUrl() => '$baseUrl$profilePath';
  static String getAttendanceUrl() => '$baseUrl$attendancePath';
  static String getCarsUrl() => '$baseUrl$carsPath';
  static String getSalariesUrl() => '$baseUrl$salariesPath';
  static String getOperationsUrl() => '$baseUrl$operationsPath';
  static String getCompleteProfileUrl() => '$baseUrl$completeProfilePath';

  // URLs البديلة
  static String getBackupLocationUrl() => '$backupDomain$locationPath';
  static String getBackupStatusUrl() => '$backupDomain$statusPath';
  static String getBackupCompleteProfileUrl() =>
      '$backupDomain$completeProfilePath';
  
  // URLs الجديدة لبيانات السيارات (nuzum.site)
  static String getEmployeeVehicleUrl(String employeeId) => 
      '$nuzumBaseUrl$employeeVehiclePath/$employeeId/vehicle';
  static String getVehicleDetailsUrl(String vehicleId) => 
      '$nuzumBaseUrl$vehicleDetailsPath/$vehicleId/details';
  
  // ============================================
  // 📸 مسارات رفع صور فحص السلامة - Inspection Upload
  // ============================================
  // توليد رابط رفع
  static String getGenerateInspectionLinkUrl(String vehicleId) =>
      '$nuzumBaseUrl/api/vehicles/$vehicleId/generate-inspection-link';
  
  // رفع الصور
  static String getInspectionUploadUrl(String token) =>
      '$nuzumBaseUrl/inspection-upload/$token';
  
  // حالة الطلب
  static String getInspectionStatusUrl(String token) =>
      '$nuzumBaseUrl/api/inspection-status/$token';
  
  // ============================================
  // 📝 مسارات تسجيل API - API Logging
  // ============================================
  static const String apiLogsPath = '/api/v1/logs/api-requests'; // POST
  static String getApiLogsUrl() => '$baseUrl$apiLogsPath';
  
  // ============================================
  // 🛡️ مسارات فحص السلامة الخارجية - External Safety Checks
  // ============================================
  static const String externalSafetyBasePath = '/api/v1/external-safety';
  static const String externalSafetyChecksPath = '$externalSafetyBasePath/checks'; // POST /api/v1/external-safety/checks
  static const String externalSafetyVehiclesPath = '$externalSafetyBasePath/vehicles'; // GET /api/v1/external-safety/vehicles
  
  // Helper methods for External Safety URLs
  static String getExternalSafetyCheckUrl(int checkId) => '$nuzumBaseUrl$externalSafetyChecksPath/$checkId';
  static String getExternalSafetyChecksUrl() => '$nuzumBaseUrl$externalSafetyChecksPath';
  static String getExternalSafetyVehiclesUrl() => '$nuzumBaseUrl$externalSafetyVehiclesPath';
  static String getExternalSafetyUploadImageUrl(int checkId) => '$nuzumBaseUrl$externalSafetyChecksPath/$checkId/upload-image';
}
