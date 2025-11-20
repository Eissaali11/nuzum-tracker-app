import 'package:flutter/material.dart';

import '../services/language_service.dart';

/// ============================================
/// 🌐 ترجمة التطبيق - App Localizations
/// ============================================
class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations();
  }

  // النصوص العربية
  static const Map<String, String> _arabic = {
    'app_title': 'Nuzum Tracker',
    'app_subtitle': 'نظام تتبع الموظفين',
    'loading': 'جاري تحميل البيانات...',
    'loading_text': 'جاري التحميل...',
    'error': 'حدث خطأ',
    'retry': 'إعادة المحاولة',
    'logout': 'تسجيل الخروج',
    'language': 'اللغة',
    'current_language': 'اللغة الحالية',
    'tracking': 'التتبع',
    'employee': 'الموظف',
    'attendance': 'الحضور',
    'salaries': 'الرواتب',
    'cars': 'السيارات',
    'requests': 'الطلبات',
    'liabilities': 'الالتزامات المالية',
    'notifications': 'الإشعارات',
    'profile': 'الملف الشخصي',
    'employee_profile': 'صفحة الموظف',
    'attendance_record_full': 'سجل الحضور والانصراف',
    'salary_record': 'سجل الرواتب',
    'linked_cars': 'السيارات المرتبطة',
    'create_requests': 'إنشاء ومتابعة الطلبات',
    'view_liabilities': 'عرض الالتزامات والمدفوعات',
    'view_notifications': 'عرض الإشعارات والتنبيهات',
    'location_tracking': 'تتبع الموقع',
    'employee_data': 'بيانات الموظف',
    'face_enrollment': 'تسجيل الوجه',
    'face_enrollment_desc': 'تسجيل بصمة الوجه للتحضير',
    'check_in': 'التحضير',
    'check_in_desc': 'تسجيل الحضور بتحليل الوجه',
    'logout_desc': 'الخروج من الحساب',
    'logout_confirm': 'هل أنت متأكد من تسجيل الخروج؟',
    'yes': 'نعم',
    'no': 'لا',
    'cancel': 'إلغاء',
    'settings': 'الإعدادات',
    'no_data': 'لا توجد بيانات',
    'connection_error': 'حدث خطأ في الاتصال',
    'load_failed': 'فشل جلب البيانات',
    'enter_job_number': 'الرجاء إدخال الرقم الوظيفي والمفتاح',
    'timeout': 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.',
    'not_sent_yet': 'لم يتم الإرسال بعد',
    'tracking_active': 'التتبع نشط',
    'collecting_data': 'جاري جمع البيانات...',
    'tracking_error': 'خطأ في بدء التتبع',
    'service_failed': 'فشل بدء خدمة التتبع',
    'not_configured': 'غير مُعدّ',
    'please_setup': 'يرجى إعداد التطبيق أولاً',
    'service_error': 'خطأ في الخدمة',
    'error_occurred': 'حدث خطأ',
    'stop_tracking': 'إيقاف التتبع',
    'confirm': 'تأكيد',
    'service_status': 'حالة الخدمة',
    'last_update': 'آخر تحديث',
    'current_speed': 'السرعة الحالية',
    'kmh': 'كم/س',
    'no_attendance_data': 'لا توجد بيانات حضور',
    'no_operations': 'لا توجد عمليات',
    'view_all': 'عرض الكل',
    'employee_page': 'صفحة الموظف',
    'logout_error': 'حدث خطأ أثناء تسجيل الخروج',
    'please_enter_job_number': 'الرجاء إدخال الرقم الوظيفي والمفتاح',
    'attendance_dashboard': 'داشبورد الحضور',
    'select_month': 'اختيار الشهر',
    'attendance_data_will_appear': 'سيتم عرض بيانات الحضور هنا عند توفرها',
    'selected_month': 'الشهر المحدد',
    'attendance_rate': 'نسبة الحضور',
    'excellent': 'ممتاز',
    'good': 'جيد',
    'needs_improvement': 'يحتاج تحسين',
    'of_days': 'من {totalDays} يوم',
    'present': 'حاضر',
    'days': 'أيام',
    'absent': 'غائب',
    'late': 'متأخر',
    'times': 'مرات',
    'early_leave': 'خروج مبكر',
    'total_hours': 'إجمالي الساعات',
    'hour': 'ساعة',
    'holidays': 'إجازات',
    'day': 'يوم',
    'attendance_record_short': 'سجل الحضور',
    'records': 'سجل',
    'no_attendance_records': 'لا توجد سجلات حضور لهذا الشهر',
    'salary_statistics': 'إحصائيات الرواتب',
    'total_salaries': 'إجمالي الرواتب',
    'average_salary': 'متوسط الراتب',
    'last_salary': 'آخر راتب',
    'highest_salary': 'أعلى راتب',
    'no_salaries': 'لا توجد رواتب',
    'car_statistics': 'إحصائيات السيارات',
    'active_cars': 'السيارات النشطة',
    'maintenance_cars': 'السيارات قيد الصيانة',
    'retired_cars': 'السيارات المتقاعدة',
    'no_linked_cars': 'لا توجد سيارات مرتبطة',
    'active': 'نشط',
    'maintenance': 'صيانة',
    'retired': 'متقاعد',
    'total': 'إجمالي',
    'count': 'عدد',
    'payment_date': 'تاريخ الدفع',
    'mark_all_read': 'تحديد الكل',
    'all_marked_read': 'تم تحديد جميع الإشعارات كمقروءة',
    'clear_filters': 'مسح الفلاتر',
    'all': 'الكل',
    'refresh': 'تحديث',
    'unread': 'غير المقروءة',
    'read': 'المقروءة',
    'total_notifications': 'إجمالي الإشعارات',
    'no_notifications': 'لا توجد إشعارات',
    'no_unread_notifications': 'لا توجد إشعارات غير مقروءة',
    'no_notifications_found': 'لم يتم العثور على أي إشعارات',
    'my_requests': 'طلباتي',
    'home': 'الرئيسية',
    'delete': 'حذف',
    'request_deleted': 'تم حذف الطلب بنجاح',
    'all_liabilities': 'جميع الالتزامات',
    'advance': 'سلفة',
    'damage': 'ضرر',
    'debt': 'دين',
    'advance_request': 'طلب سلفة',
    'liabilities_title': 'الالتزامات',
    'financial_summary': 'الملخص المالي',
    'cannot_open_link': 'لا يمكن فتح الرابط',
    'all_files_uploaded': 'تم رفع جميع الملفات بنجاح',
    'add_card': 'إضافة بطاقة',
    'add': 'إضافة',
    'camera': 'الكاميرا',
    'gallery': 'الاستديو',
    'choose_from_gallery': 'اختر من المعرض',
    'take_photo': 'التقط صورة',
    'request_details': 'تفاصيل الطلب',
    'required_photos': 'الصور المطلوبة',
    'photos_required': '5 صور مطلوبة',
    'liabilities_summary': 'ملخص الالتزامات',
    'total_liabilities': 'إجمالي الالتزامات',
    'paid_amount': 'المبلغ المدفوع',
    'remaining_amount': 'المبلغ المتبقي',
    'riyal': 'ر.س',
    'no_liabilities': 'لا توجد التزامات',
    'no_liabilities_filter': 'لا توجد التزامات مطابقة للفلتر المحدد',
    'progress_percentage': 'نسبة التقدم',
    'remaining_installments': 'أقساط متبقية',
    'due_date': 'تاريخ الاستحقاق',
    'current_salary': 'الراتب الحالي',
    'net_salary': 'صافي الراتب',
    'discount_rate': 'نسبة الخصم',
    'active_damages': 'التلفيات النشطة',
    'total_amount': 'المبلغ الإجمالي',
    'paid': 'مدفوع',
    'remaining': 'متبقي',
    'liability': 'التزام',
    'emergency_contacts': 'معلومات الطوارئ',
    'emergency_contacts_title': 'أرقام الطوارئ',
    'emergency_contacts_subtitle': 'اتصل بهذه الأرقام في حالات الطوارئ',
    'road_security_operations': 'عمليات أمن الطرق',
    'traffic_operations': 'عمليات المرور',
    'security_patrols_operations': 'عمليات الدوريات الأمنية',
    'police_operations': 'عمليات الشرطة',
    'red_crescent_operations': 'عمليات الهلال الأحمر',
    'civil_defense_operations': 'عمليات الدفاع المدني',
    'najm': 'نجم',
    'insurance': 'التامين',
    'insurance_file': 'ملف التأمين',
    'registration_image': 'صورة الاستمارة',
    'registration_form_image': 'صورة نموذج الاستمارة',
    'authorization_date': 'تاريخ التفويض',
    'authorization_expiry_date': 'تاريخ انتهاء التفويض',
    'inspection_expiry_date': 'تاريخ انتهاء الفحص الدوري',
    'registration_expiry_date': 'تاريخ انتهاء الاستمارة',
    'delivery_receipt_link': 'نموذج التليم أو الاستلام',
    'year': 'سنة الصنع',
    'assigned_date': 'تاريخ الربط',
    'unassigned_date': 'تاريخ إلغاء الربط',
    'model': 'الموديل',
    'color': 'اللون',
  };

  // النصوص الإنجليزية
  static const Map<String, String> _english = {
    'app_title': 'Nuzum Tracker',
    'app_subtitle': 'Employee Tracking System',
    'loading': 'Loading data...',
    'error': 'An error occurred',
    'retry': 'Retry',
    'logout': 'Logout',
    'language': 'Language',
    'current_language': 'Current language',
    'tracking': 'Tracking',
    'employee': 'Employee',
    'attendance': 'Attendance',
    'salaries': 'Salaries',
    'cars': 'Cars',
    'requests': 'Requests',
    'liabilities': 'Liabilities',
    'notifications': 'Notifications',
    'profile': 'Profile',
    'employee_profile': 'Employee Profile',
    'attendance_record_full': 'Attendance Record',
    'salary_record': 'Salary Record',
    'linked_cars': 'Linked Cars',
    'create_requests': 'Create and Track Requests',
    'view_liabilities': 'View Liabilities and Payments',
    'view_notifications': 'View Notifications and Alerts',
    'location_tracking': 'Location Tracking',
    'employee_data': 'Employee Data',
    'face_enrollment': 'Face Enrollment',
    'face_enrollment_desc': 'Register face for check-in',
    'check_in': 'Check In',
    'check_in_desc': 'Check in with face recognition',
    'logout_desc': 'Logout from account',
    'logout_confirm': 'Are you sure you want to logout?',
    'yes': 'Yes',
    'no': 'No',
    'cancel': 'Cancel',
    'settings': 'Settings',
    'no_data': 'No data available',
    'connection_error': 'Connection error occurred',
    'load_failed': 'Failed to load data',
    'enter_job_number': 'Please enter job number and API key',
    'timeout': 'Connection timeout. Please try again.',
    'not_sent_yet': 'Not sent yet',
    'tracking_active': 'Tracking Active',
    'collecting_data': 'Collecting data...',
    'tracking_error': 'Error starting tracking',
    'service_failed': 'Failed to start tracking service',
    'not_configured': 'Not Configured',
    'please_setup': 'Please setup the app first',
    'service_error': 'Service Error',
    'error_occurred': 'An error occurred',
    'stop_tracking': 'Stop Tracking',
    'confirm': 'Confirm',
    'service_status': 'Service Status',
    'last_update': 'Last Update',
    'current_speed': 'Current Speed',
    'kmh': 'km/h',
    'no_attendance_data': 'No attendance data',
    'no_operations': 'No operations',
    'view_all': 'View All',
    'employee_page': 'Employee Page',
    'logout_error': 'Error during logout',
    'please_enter_job_number': 'Please enter job number and API key',
    'attendance_dashboard': 'Attendance Dashboard',
    'select_month': 'Select Month',
    'attendance_data_will_appear':
        'Attendance data will appear here when available',
    'selected_month': 'Selected Month',
    'attendance_rate': 'Attendance Rate',
    'excellent': 'Excellent',
    'good': 'Good',
    'needs_improvement': 'Needs Improvement',
    'of_days': 'of {totalDays} days',
    'present': 'Present',
    'days': 'Days',
    'absent': 'Absent',
    'late': 'Late',
    'times': 'Times',
    'early_leave': 'Early Leave',
    'total_hours': 'Total Hours',
    'hour': 'Hour',
    'holidays': 'Holidays',
    'day': 'Day',
    'attendance_record_short': 'Attendance Record',
    'records': 'Records',
    'no_attendance_records': 'No attendance records for this month',
    'salary_statistics': 'Salary Statistics',
    'total_salaries': 'Total Salaries',
    'average_salary': 'Average Salary',
    'last_salary': 'Last Salary',
    'highest_salary': 'Highest Salary',
    'no_salaries': 'No salaries available',
    'car_statistics': 'Car Statistics',
    'active_cars': 'Active Cars',
    'maintenance_cars': 'Cars in Maintenance',
    'retired_cars': 'Retired Cars',
    'no_linked_cars': 'No linked cars',
    'active': 'Active',
    'maintenance': 'Maintenance',
    'retired': 'Retired',
    'total': 'Total',
    'count': 'Count',
    'payment_date': 'Payment Date',
    'mark_all_read': 'Mark All Read',
    'all_marked_read': 'All notifications marked as read',
    'clear_filters': 'Clear Filters',
    'all': 'All',
    'refresh': 'Refresh',
    'unread': 'Unread',
    'read': 'Read',
    'total_notifications': 'Total Notifications',
    'no_notifications': 'No notifications',
    'no_unread_notifications': 'No unread notifications',
    'no_notifications_found': 'No notifications found',
    'my_requests': 'My Requests',
    'home': 'Home',
    'delete': 'Delete',
    'request_deleted': 'Request deleted successfully',
    'all_liabilities': 'All Liabilities',
    'advance': 'Advance',
    'damage': 'Damage',
    'debt': 'Debt',
    'advance_request': 'Advance Request',
    'liabilities_title': 'Liabilities',
    'financial_summary': 'Financial Summary',
    'cannot_open_link': 'Cannot open link',
    'all_files_uploaded': 'All files uploaded successfully',
    'add_card': 'Add Card',
    'add': 'Add',
    'camera': 'Camera',
    'gallery': 'Gallery',
    'choose_from_gallery': 'Choose from Gallery',
    'take_photo': 'Take Photo',
    'request_details': 'Request Details',
    'required_photos': 'Required Photos',
    'photos_required': '5 photos required',
    'liabilities_summary': 'Liabilities Summary',
    'total_liabilities': 'Total Liabilities',
    'paid_amount': 'Paid Amount',
    'remaining_amount': 'Remaining Amount',
    'riyal': 'SAR',
    'no_liabilities': 'No Liabilities',
    'no_liabilities_filter': 'No liabilities match the selected filter',
    'progress_percentage': 'Progress Percentage',
    'remaining_installments': 'Remaining Installments',
    'due_date': 'Due Date',
    'current_salary': 'Current Salary',
    'net_salary': 'Net Salary',
    'discount_rate': 'Discount Rate',
    'active_damages': 'Active Damages',
    'total_amount': 'Total Amount',
    'paid': 'Paid',
    'remaining': 'Remaining',
    'liability': 'Liability',
    'emergency_contacts': 'Emergency Contacts',
    'emergency_contacts_title': 'Emergency Numbers',
    'emergency_contacts_subtitle': 'Call these numbers in case of emergency',
    'road_security_operations': 'Road Security Operations',
    'traffic_operations': 'Traffic Operations',
    'security_patrols_operations': 'Security Patrols Operations',
    'police_operations': 'Police Operations',
    'red_crescent_operations': 'Red Crescent Operations',
    'civil_defense_operations': 'Civil Defense Operations',
    'najm': 'Najm',
    'insurance': 'Insurance',
    'insurance_file': 'Insurance File',
    'registration_image': 'Registration Image',
    'registration_form_image': 'Registration Form Image',
    'authorization_date': 'Authorization Date',
    'authorization_expiry_date': 'Authorization Expiry Date',
    'inspection_expiry_date': 'Inspection Expiry Date',
    'registration_expiry_date': 'Registration Expiry Date',
    'delivery_receipt_link': 'Delivery/Receipt Form',
    'year': 'Year',
    'assigned_date': 'Assigned Date',
    'unassigned_date': 'Unassigned Date',
    'model': 'Model',
    'color': 'Color',
  };

  String translate(String key) {
    final isArabic = LanguageService.instance.isArabic;
    final translations = isArabic ? _arabic : _english;
    return translations[key] ?? key;
  }

  // Helper methods for common translations
  String get appTitle => translate('app_title');
  String get appSubtitle => translate('app_subtitle');
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');
  String get logout => translate('logout');
  String get language => translate('language');
  String get currentLanguage => translate('current_language');
  String get tracking => translate('tracking');
  String get employee => translate('employee');
  String get attendance => translate('attendance');
  String get salaries => translate('salaries');
  String get cars => translate('cars');
  String get requests => translate('requests');
  String get liabilities => translate('liabilities');
  String get notifications => translate('notifications');
  String get profile => translate('profile');
  String get employeeProfile => translate('employee_profile');
  String get attendanceRecordFull => translate('attendance_record_full');
  String get salaryRecord => translate('salary_record');
  String get linkedCars => translate('linked_cars');
  String get createRequests => translate('create_requests');
  String get viewLiabilities => translate('view_liabilities');
  String get viewNotifications => translate('view_notifications');
  String get locationTracking => translate('location_tracking');
  String get employeeData => translate('employee_data');
  String get faceEnrollment => translate('face_enrollment');
  String get faceEnrollmentDesc => translate('face_enrollment_desc');
  String get checkIn => translate('check_in');
  String get checkInDesc => translate('check_in_desc');
  String get logoutDesc => translate('logout_desc');
  String get logoutConfirm => translate('logout_confirm');
  String get yes => translate('yes');
  String get no => translate('no');
  String get cancel => translate('cancel');
  String get settings => translate('settings');
  String get noData => translate('no_data');
  String get connectionError => translate('connection_error');
  String get loadFailed => translate('load_failed');
  String get enterJobNumber => translate('enter_job_number');
  String get timeout => translate('timeout');
  String get loadingText => translate('loading_text');
  String get notSentYet => translate('not_sent_yet');
  String get trackingActive => translate('tracking_active');
  String get collectingData => translate('collecting_data');
  String get trackingError => translate('tracking_error');
  String get serviceFailed => translate('service_failed');
  String get notConfigured => translate('not_configured');
  String get pleaseSetup => translate('please_setup');
  String get serviceError => translate('service_error');
  String get errorOccurred => translate('error_occurred');
  String get stopTracking => translate('stop_tracking');
  String get confirm => translate('confirm');
  String get serviceStatus => translate('service_status');
  String get lastUpdate => translate('last_update');
  String get currentSpeed => translate('current_speed');
  String get kmh => translate('kmh');
  String get noAttendanceData => translate('no_attendance_data');
  String get noOperations => translate('no_operations');
  String get viewAll => translate('view_all');
  String get employeePage => translate('employee_page');
  String get logoutError => translate('logout_error');
  String get pleaseEnterJobNumber => translate('please_enter_job_number');
  String get attendanceDashboard => translate('attendance_dashboard');
  String get selectMonth => translate('select_month');
  String get attendanceDataWillAppear =>
      translate('attendance_data_will_appear');
  String get selectedMonth => translate('selected_month');
  String get attendanceRate => translate('attendance_rate');
  String get excellent => translate('excellent');
  String get good => translate('good');
  String get needsImprovement => translate('needs_improvement');
  String ofDays(int totalDays) {
    final template = translate('of_days');
    return template.replaceAll('{totalDays}', totalDays.toString());
  }

  String get present => translate('present');
  String get days => translate('days');
  String get absent => translate('absent');
  String get late => translate('late');
  String get times => translate('times');
  String get earlyLeave => translate('early_leave');
  String get totalHours => translate('total_hours');
  String get hour => translate('hour');
  String get holidays => translate('holidays');
  String get day => translate('day');
  String get attendanceRecord => translate('attendance_record_short');
  String get records => translate('records');
  String get noAttendanceRecords => translate('no_attendance_records');
  String get salaryStatistics => translate('salary_statistics');
  String get totalSalaries => translate('total_salaries');
  String get averageSalary => translate('average_salary');
  String get lastSalary => translate('last_salary');
  String get highestSalary => translate('highest_salary');
  String get noSalaries => translate('no_salaries');
  String get carStatistics => translate('car_statistics');
  String get activeCars => translate('active_cars');
  String get maintenanceCars => translate('maintenance_cars');
  String get retiredCars => translate('retired_cars');
  String get noLinkedCars => translate('no_linked_cars');
  String get active => translate('active');
  String get maintenance => translate('maintenance');
  String get retired => translate('retired');
  String get total => translate('total');
  String get count => translate('count');
  String get paymentDate => translate('payment_date');
  String get markAllRead => translate('mark_all_read');
  String get allMarkedRead => translate('all_marked_read');
  String get clearFilters => translate('clear_filters');
  String get all => translate('all');
  String get unread => translate('unread');
  String get read => translate('read');
  String get totalNotifications => translate('total_notifications');
  String get noNotifications => translate('no_notifications');
  String get noUnreadNotifications => translate('no_unread_notifications');
  String get noNotificationsFound => translate('no_notifications_found');
  String get home => translate('home');
  String get myRequests => translate('my_requests');
  String get delete => translate('delete');
  String get requestDeleted => translate('request_deleted');
  String get refresh => translate('refresh');
  String get advance => translate('advance');
  String get debt => translate('debt');
  String get damages => translate('damage');
  String get advanceRequest => translate('advance_request');
  String get liabilitiesTitle => translate('liabilities_title');
  String get financialSummary => translate('financial_summary');
  String get cannotOpenLink => translate('cannot_open_link');
  String get allFilesUploaded => translate('all_files_uploaded');
  String get addCard => translate('add_card');
  String get add => translate('add');
  String get camera => translate('camera');
  String get gallery => translate('gallery');
  String get chooseFromGallery => translate('choose_from_gallery');
  String get takePhoto => translate('take_photo');
  String get requestDetails => translate('request_details');
  String get requiredPhotos => translate('required_photos');
  String get photosRequired => translate('photos_required');
  String get liabilitiesSummary => translate('liabilities_summary');
  String get totalLiabilities => translate('total_liabilities');
  String get paidAmount => translate('paid_amount');
  String get remainingAmount => translate('remaining_amount');
  String get riyal => translate('riyal');
  String get noLiabilities => translate('no_liabilities');
  String get noLiabilitiesFilter => translate('no_liabilities_filter');
  String get progressPercentage => translate('progress_percentage');
  String remainingInstallments(int count) {
    final text = translate('remaining_installments');
    return '$text ($count)';
  }
  String get dueDate => translate('due_date');
  String get currentSalary => translate('current_salary');
  String get netSalary => translate('net_salary');
  String get discountRate => translate('discount_rate');
  String get activeDamages => translate('active_damages');
  String get totalAmount => translate('total_amount');
  String get paid => translate('paid');
  String get remaining => translate('remaining');
  String get liability => translate('liability');
  String get emergencyContacts => translate('emergency_contacts');
  String get emergencyContactsTitle => translate('emergency_contacts_title');
  String get emergencyContactsSubtitle => translate('emergency_contacts_subtitle');
  String get roadSecurityOperations => translate('road_security_operations');
  String get trafficOperations => translate('traffic_operations');
  String get securityPatrolsOperations => translate('security_patrols_operations');
  String get policeOperations => translate('police_operations');
  String get redCrescentOperations => translate('red_crescent_operations');
  String get civilDefenseOperations => translate('civil_defense_operations');
  String get najm => translate('najm');
  String get insurance => translate('insurance');
  String get insuranceFile => translate('insurance_file');
  String get registrationImage => translate('registration_image');
  String get registrationFormImage => translate('registration_form_image');
  String get authorizationDate => translate('authorization_date');
  String get authorizationExpiryDate => translate('authorization_expiry_date');
  String get inspectionExpiryDate => translate('inspection_expiry_date');
  String get registrationExpiryDate => translate('registration_expiry_date');
  String get deliveryReceiptLink => translate('delivery_receipt_link');
  String get year => translate('year');
  String get assignedDate => translate('assigned_date');
  String get unassignedDate => translate('unassigned_date');
  String get model => translate('model');
  String get color => translate('color');
}

// Extension method للوصول السريع
extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
