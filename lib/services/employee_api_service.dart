import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../models/attendance_model.dart';
import '../models/car_model.dart';
import '../models/complete_employee_response.dart';
import '../models/employee_model.dart';
import '../models/operation_model.dart';
import '../models/salary_model.dart';
import '../models/vehicle_details_response.dart';
import '../services/api_logging_service.dart';
import '../services/auth_service.dart';
import '../utils/api_response.dart';
import '../utils/safe_preferences.dart';

/// ============================================
/// 👤 خدمة API للموظف - Employee API Service
/// ============================================
class EmployeeApiService {
  static const Duration timeoutDuration = ApiConfig.timeoutDuration;

  /// ============================================
  /// 🔧 إعدادات الطلب - Request Setup
  /// ============================================
  static Future<Map<String, String>> _getHeaders({bool includeToken = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    
    // إضافة JWT token إذا كان متوفراً ومطلوباً
    // ملاحظة: بعض الـ endpoints مثل employee-complete-profile لا تحتاج token
    if (includeToken) {
      try {
        final token = await AuthService.getToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        debugPrint('⚠️ [EmployeeAPI] Could not get token: $e');
      }
    }
    
    return headers;
  }

  static Map<String, dynamic> _getBaseBody({
    required String jobNumber,
    required String apiKey,
  }) {
    // استخدام API key الافتراضي إذا كان apiKey فارغاً
    final finalApiKey = apiKey.isEmpty ? ApiConfig.defaultApiKey : apiKey;
    
    return {
      'api_key': finalApiKey,
      'job_number': jobNumber,
    };
  }

  /// ============================================
  /// 👤 جلب بيانات الموظف - Get Employee Profile
  /// ============================================
  static Future<ApiResponse<Employee>> getEmployeeProfile({
    required String jobNumber,
    required String apiKey,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.getProfileUrl()),
            headers: await _getHeaders(),
            body: jsonEncode(_getBaseBody(
              jobNumber: jobNumber,
              apiKey: apiKey,
            )),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final employee = Employee.fromJson(data['data']);
          return ApiResponse.success(
            employee,
            data['message'] ?? 'تم جلب البيانات بنجاح',
          );
        } else {
          return ApiResponse.error(
            data['message'] ?? 'فشل جلب البيانات',
            data['error'],
          );
        }
      } else if (response.statusCode == 503) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable (503)',
        );
      } else {
        return ApiResponse.error(
          _getErrorMessage(response.statusCode),
          response.body,
        );
      }
    } catch (e) {
      debugPrint('❌ [EmployeeAPI] Error getting profile: $e');
      if (e.toString().contains('503') || e.toString().contains('Service Unavailable')) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable',
        );
      }
      return ApiResponse.error('حدث خطأ في الاتصال: $e');
    }
  }

  /// ============================================
  /// 📝 الحصول على رسالة الخطأ - Get Error Message
  /// ============================================
  static String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 301:
      case 302:
      case 307:
      case 308:
        return 'تم إعادة توجيه الرابط. جاري المحاولة بالرابط الاحتياطي...';
      case 400:
        return 'طلب غير صحيح';
      case 401:
        return 'غير مصرح. يرجى التحقق من المفتاح';
      case 403:
        return 'غير مسموح';
      case 404:
        return 'الخدمة غير موجودة';
      case 500:
        return 'خطأ في السيرفر';
      case 503:
        return 'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً';
      case 504:
        return 'انتهت مهلة الاتصال';
      default:
        return 'خطأ في الاتصال: $statusCode';
    }
  }

  /// ============================================
  /// 📅 جلب الحضور - Get Attendance
  /// ============================================
  static Future<ApiResponse<List<Attendance>>> getAttendance({
    required String jobNumber,
    required String apiKey,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = _getBaseBody(jobNumber: jobNumber, apiKey: apiKey);
      
      if (startDate != null) {
        body['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        body['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.getAttendanceUrl()),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final attendanceList = (data['data'] as List)
              .map((json) => Attendance.fromJson(json as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(
            attendanceList,
            data['message'] ?? 'تم جلب البيانات بنجاح',
          );
        } else {
          return ApiResponse.error(
            data['message'] ?? 'فشل جلب البيانات',
            data['error'],
          );
        }
      } else if (response.statusCode == 503) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable (503)',
        );
      } else {
        return ApiResponse.error(
          _getErrorMessage(response.statusCode),
          response.body,
        );
      }
    } catch (e) {
      debugPrint('❌ [EmployeeAPI] Error getting attendance: $e');
      if (e.toString().contains('503') || e.toString().contains('Service Unavailable')) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable',
        );
      }
      return ApiResponse.error('حدث خطأ في الاتصال: $e');
    }
  }

  /// ============================================
  /// 🚗 جلب تفاصيل السيارة - Get Car Details
  /// ============================================
  static Future<ApiResponse<Car>> getCarDetails({
    required String carId,
    required String jobNumber,
    required String apiKey,
    String? employeeId,
  }) async {
    try {
      // محاولة جلب employeeId من البيانات المحفوظة إذا لم يكن متوفراً
      if (employeeId == null || employeeId.isEmpty) {
        try {
          employeeId = await SafePreferences.getString('employee_id');
          debugPrint('🔍 [EmployeeAPI] Retrieved employee_id from storage: $employeeId');
        } catch (e) {
          debugPrint('⚠️ [EmployeeAPI] Could not get employee_id: $e');
        }
      }

      // محاولة استخدام endpoint الجديد من nuzum.site
      // 1. محاولة جلب عبر vehicle_id (GET /api/vehicles/{vehicle_id}/details)
      if (carId.isNotEmpty) {
        try {
          final url = ApiConfig.getVehicleDetailsUrl(carId);
          debugPrint('🚀 [EmployeeAPI] [1/4] Attempting to fetch vehicle details from: $url');
          debugPrint('   📋 Endpoint: GET /api/vehicles/{vehicle_id}/details');
          
          final response = await http
              .get(
                Uri.parse(url),
                headers: await _getHeaders(includeToken: false), // nuzum.site قد لا يحتاج token
              )
              .timeout(timeoutDuration);

          debugPrint('📥 [EmployeeAPI] Vehicle details response status: ${response.statusCode}');
          debugPrint('📥 [EmployeeAPI] Vehicle details response body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            debugPrint('✅ [EmployeeAPI] Vehicle details data keys: ${data.keys.toList()}');
            
            // إذا كانت الاستجابة تحتوي على vehicle wrapper (الشكل الجديد)
            if (data['vehicle'] != null) {
              try {
                final vehicleData = data['vehicle'] as Map<String, dynamic>;
                debugPrint('🚗 [EmployeeAPI] Found vehicle wrapper, parsing...');
                final car = Car.fromJson(vehicleData);
                debugPrint('✅ [EmployeeAPI] Successfully parsed car from vehicle wrapper');
                return ApiResponse.success(car, 'تم جلب التفاصيل بنجاح');
              } catch (e) {
                debugPrint('❌ [EmployeeAPI] Error parsing car from vehicle wrapper: $e');
              }
            }
            // إذا كانت الاستجابة تحتوي على بيانات السيارة مباشرة
            if (data.containsKey('car_id') || data.containsKey('plate_number') || data.containsKey('vehicle_id') || data.containsKey('id')) {
              try {
                final car = Car.fromJson(data);
                debugPrint('✅ [EmployeeAPI] Successfully parsed car from vehicle details endpoint');
                return ApiResponse.success(car, 'تم جلب التفاصيل بنجاح');
              } catch (e) {
                debugPrint('❌ [EmployeeAPI] Error parsing car data: $e');
              }
            }
            // إذا كانت الاستجابة تحتوي على data wrapper
            if (data['data'] != null) {
              try {
                final car = Car.fromJson(data['data'] as Map<String, dynamic>);
                debugPrint('✅ [EmployeeAPI] Successfully parsed car from data wrapper');
                return ApiResponse.success(car, 'تم جلب التفاصيل بنجاح');
              } catch (e) {
                debugPrint('❌ [EmployeeAPI] Error parsing car from data wrapper: $e');
              }
            }
          } else {
            debugPrint('⚠️ [EmployeeAPI] Vehicle details endpoint returned status: ${response.statusCode}');
          }
        } catch (e, stackTrace) {
          debugPrint('⚠️ [EmployeeAPI] Vehicle details endpoint failed: $e');
          debugPrint('📋 [EmployeeAPI] Stack trace: $stackTrace');
        }
      }

      // 2. محاولة جلب عبر employee_id (GET /api/employees/{employee_id}/vehicle) - هذا مهم جداً للسيارة الحالية
      if (employeeId != null && employeeId.isNotEmpty) {
        try {
          final url = ApiConfig.getEmployeeVehicleUrl(employeeId);
          debugPrint('🚀 [EmployeeAPI] [2/4] Attempting to fetch employee vehicle from: $url');
          debugPrint('   📋 Endpoint: GET /api/employees/{employee_id}/vehicle');
          
          final response = await http
              .get(
                Uri.parse(url),
                headers: await _getHeaders(includeToken: false), // nuzum.site قد لا يحتاج token
              )
              .timeout(timeoutDuration);

          debugPrint('📥 [EmployeeAPI] Employee vehicle response status: ${response.statusCode}');
          final responseBody = response.body;
          debugPrint('📥 [EmployeeAPI] Employee vehicle response body: ${responseBody.length > 500 ? responseBody.substring(0, 500) : responseBody}');

          if (response.statusCode == 200) {
            final data = jsonDecode(responseBody) as Map<String, dynamic>;
            debugPrint('✅ [EmployeeAPI] Employee vehicle data keys: ${data.keys.toList()}');
            
            // معالجة الشكل الجديد من API: {success, employee, vehicle, handover_records, handover_count}
            if (data.containsKey('success') && data['vehicle'] != null) {
              try {
                final vehicleData = data['vehicle'] as Map<String, dynamic>;
                debugPrint('🚗 [EmployeeAPI] Found new API format with vehicle, employee, and handover_records');
                debugPrint('   📋 Vehicle data keys: ${vehicleData.keys.toList()}');
                debugPrint('   📋 Handover records count: ${data['handover_count'] ?? 0}');
                debugPrint('   🖼️ Registration form image: ${vehicleData['registration_form_image']}');
                debugPrint('   🖼️ Registration image: ${vehicleData['registration_image']}');
                final car = Car.fromJson(vehicleData);
                debugPrint('   ✅ Parsed car - registrationFormImage: ${car.registrationFormImage}');
                debugPrint('   ✅ Parsed car - registrationImage: ${car.registrationImage}');
                // إذا كان carId فارغاً أو مطابقاً، نعيد السيارة
                if (carId.isEmpty || car.carId == carId) {
                  debugPrint('✅ [EmployeeAPI] Successfully parsed car from new API format: ${car.plateNumber}');
                  return ApiResponse.success(car, 'تم جلب التفاصيل بنجاح');
                } else {
                  debugPrint('⚠️ [EmployeeAPI] Car ID mismatch: expected $carId, got ${car.carId}');
                }
              } catch (e, stackTrace) {
                debugPrint('❌ [EmployeeAPI] Error parsing car from new API format: $e');
                debugPrint('📋 Stack trace: $stackTrace');
              }
            }
            // إذا كانت الاستجابة تحتوي على vehicle wrapper (الشكل القديم)
            else if (data['vehicle'] != null) {
              try {
                final vehicleData = data['vehicle'] as Map<String, dynamic>;
                debugPrint('🚗 [EmployeeAPI] Found vehicle wrapper, parsing...');
                debugPrint('   📋 Vehicle data keys: ${vehicleData.keys.toList()}');
                final car = Car.fromJson(vehicleData);
                // إذا كان carId فارغاً أو مطابقاً، نعيد السيارة
                if (carId.isEmpty || car.carId == carId) {
                  debugPrint('✅ [EmployeeAPI] Successfully parsed car from vehicle wrapper: ${car.plateNumber}');
                  return ApiResponse.success(car, 'تم جلب التفاصيل بنجاح');
                } else {
                  debugPrint('⚠️ [EmployeeAPI] Car ID mismatch: expected $carId, got ${car.carId}');
                }
              } catch (e, stackTrace) {
                debugPrint('❌ [EmployeeAPI] Error parsing car from vehicle wrapper: $e');
                debugPrint('📋 Stack trace: $stackTrace');
              }
            }
            // إذا كانت الاستجابة تحتوي على بيانات السيارة مباشرة
            if (data.containsKey('car_id') || data.containsKey('plate_number') || data.containsKey('vehicle_id') || data.containsKey('id')) {
              try {
                final car = Car.fromJson(data);
                if (carId.isEmpty || car.carId == carId) {
                  debugPrint('✅ [EmployeeAPI] Successfully parsed car from employee vehicle endpoint: ${car.plateNumber}');
                  return ApiResponse.success(car, 'تم جلب التفاصيل بنجاح');
                } else {
                  debugPrint('⚠️ [EmployeeAPI] Car ID mismatch: expected $carId, got ${car.carId}');
                }
              } catch (e) {
                debugPrint('❌ [EmployeeAPI] Error parsing car data: $e');
              }
            }
            // إذا كانت الاستجابة تحتوي على data wrapper
            if (data['data'] != null) {
              try {
                final car = Car.fromJson(data['data'] as Map<String, dynamic>);
                if (carId.isEmpty || car.carId == carId) {
                  debugPrint('✅ [EmployeeAPI] Successfully parsed car from data wrapper: ${car.plateNumber}');
                  return ApiResponse.success(car, 'تم جلب التفاصيل بنجاح');
                } else {
                  debugPrint('⚠️ [EmployeeAPI] Car ID mismatch: expected $carId, got ${car.carId}');
                }
              } catch (e) {
                debugPrint('❌ [EmployeeAPI] Error parsing car from data wrapper: $e');
              }
            }
          } else {
            debugPrint('⚠️ [EmployeeAPI] Employee vehicle endpoint returned status: ${response.statusCode}');
          }
        } catch (e, stackTrace) {
          debugPrint('⚠️ [EmployeeAPI] Employee vehicle endpoint failed: $e');
          debugPrint('📋 [EmployeeAPI] Stack trace: $stackTrace');
        }
      } else {
        debugPrint('⚠️ [EmployeeAPI] employeeId not available, skipping employee vehicle endpoint');
      }

      // 3. محاولة استخدام endpoint القديم
      try {
        final body = _getBaseBody(jobNumber: jobNumber, apiKey: apiKey);
        body['car_id'] = carId;

        final response = await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/api/external/employee-car-details'),
              headers: await _getHeaders(),
              body: jsonEncode(body),
            )
            .timeout(timeoutDuration);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == true) {
            final car = Car.fromJson(data['data'] as Map<String, dynamic>);
            return ApiResponse.success(
              car,
              data['message'] ?? 'تم جلب التفاصيل بنجاح',
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ [EmployeeAPI] Old car details endpoint not available');
      }

      // 4. إذا فشل كل شيء، استخدم complete profile كحل احتياطي
      final completeResponse = await getCompleteProfile(
        jobNumber: jobNumber,
        apiKey: apiKey,
      );

      if (completeResponse.success && completeResponse.data != null) {
        final allCars = [
          if (completeResponse.data!.currentCar != null) completeResponse.data!.currentCar!,
          ...completeResponse.data!.previousCars,
        ];

        final car = allCars.firstWhere(
          (c) => c.carId == carId,
          orElse: () => throw Exception('Car not found'),
        );

        return ApiResponse.success(car, 'تم جلب التفاصيل بنجاح');
      }

      return ApiResponse.error('لم يتم العثور على السيارة', 'Car not found');
    } catch (e) {
      debugPrint('❌ [EmployeeAPI] Error getting car details: $e');
      return ApiResponse.error('حدث خطأ في جلب التفاصيل: $e');
    }
  }

  /// ============================================
  /// 🚗 جلب السيارات - Get Cars
  /// ============================================
  static Future<ApiResponse<List<Car>>> getCars({
    required String jobNumber,
    required String apiKey,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.getCarsUrl()),
            headers: await _getHeaders(),
            body: jsonEncode(_getBaseBody(
              jobNumber: jobNumber,
              apiKey: apiKey,
            )),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final carsList = (data['data'] as List)
              .map((json) => Car.fromJson(json as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(
            carsList,
            data['message'] ?? 'تم جلب البيانات بنجاح',
          );
        } else {
          return ApiResponse.error(
            data['message'] ?? 'فشل جلب البيانات',
            data['error'],
          );
        }
      } else if (response.statusCode == 503) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable (503)',
        );
      } else {
        return ApiResponse.error(
          _getErrorMessage(response.statusCode),
          response.body,
        );
      }
    } catch (e) {
      debugPrint('❌ [EmployeeAPI] Error getting cars: $e');
      if (e.toString().contains('503') || e.toString().contains('Service Unavailable')) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable',
        );
      }
      return ApiResponse.error('حدث خطأ في الاتصال: $e');
    }
  }

  /// ============================================
  /// 💰 جلب الرواتب - Get Salaries
  /// ============================================
  static Future<ApiResponse<List<Salary>>> getSalaries({
    required String jobNumber,
    required String apiKey,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final body = _getBaseBody(jobNumber: jobNumber, apiKey: apiKey);
      
      if (startDate != null) {
        body['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        body['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.getSalariesUrl()),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final salariesList = (data['data'] as List)
              .map((json) => Salary.fromJson(json as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(
            salariesList,
            data['message'] ?? 'تم جلب البيانات بنجاح',
          );
        } else {
          return ApiResponse.error(
            data['message'] ?? 'فشل جلب البيانات',
            data['error'],
          );
        }
      } else if (response.statusCode == 503) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable (503)',
        );
      } else {
        return ApiResponse.error(
          _getErrorMessage(response.statusCode),
          response.body,
        );
      }
    } catch (e) {
      debugPrint('❌ [EmployeeAPI] Error getting salaries: $e');
      if (e.toString().contains('503') || e.toString().contains('Service Unavailable')) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable',
        );
      }
      return ApiResponse.error('حدث خطأ في الاتصال: $e');
    }
  }

  /// ============================================
  /// 📦 جلب العمليات - Get Operations
  /// ============================================
  static Future<ApiResponse<List<Operation>>> getOperations({
    required String jobNumber,
    required String apiKey,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      final body = _getBaseBody(jobNumber: jobNumber, apiKey: apiKey);
      
      if (startDate != null) {
        body['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        body['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
      }
      if (type != null && type != 'all') {
        body['type'] = type;
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.getOperationsUrl()),
            headers: await _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final operationsList = (data['data'] as List)
              .map((json) => Operation.fromJson(json as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(
            operationsList,
            data['message'] ?? 'تم جلب البيانات بنجاح',
          );
        } else {
          return ApiResponse.error(
            data['message'] ?? 'فشل جلب البيانات',
            data['error'],
          );
        }
      } else if (response.statusCode == 503) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable (503)',
        );
      } else {
        return ApiResponse.error(
          _getErrorMessage(response.statusCode),
          response.body,
        );
      }
    } catch (e) {
      debugPrint('❌ [EmployeeAPI] Error getting operations: $e');
      if (e.toString().contains('503') || e.toString().contains('Service Unavailable')) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable',
        );
      }
      return ApiResponse.error('حدث خطأ في الاتصال: $e');
    }
  }

  /// ============================================
  /// 📦 جلب الملف الشامل للموظف - Get Complete Employee Profile
  /// مع نظام تبديل تلقائي للرابط الاحتياطي
  /// ============================================
  static Future<ApiResponse<CompleteEmployeeResponse>> getCompleteProfile({
    required String jobNumber,
    required String apiKey,
    String? month,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // التحقق من أن job_number غير فارغ
    if (jobNumber.isEmpty) {
      debugPrint('❌ [EmployeeAPI] job_number is empty!');
      return ApiResponse.error(
        'الرقم الوظيفي غير موجود. يرجى التحقق من الإعدادات.',
        'Missing job number',
      );
    }
    
    // استخدام API key الافتراضي إذا كان apiKey فارغاً
    final finalApiKey = apiKey.isEmpty ? ApiConfig.defaultApiKey : apiKey;
    if (apiKey.isEmpty) {
      debugPrint('⚠️ [EmployeeAPI] api_key is empty, using default: ${ApiConfig.defaultApiKey}');
    }
    
    debugPrint('🔑 [EmployeeAPI] Using API key: ${finalApiKey.substring(0, finalApiKey.length > 10 ? 10 : finalApiKey.length)}...');
    debugPrint('👤 [EmployeeAPI] Job number: $jobNumber');
    
    final body = _getBaseBody(jobNumber: jobNumber, apiKey: finalApiKey);
    
    if (month != null) {
      body['month'] = month; // Format: YYYY-MM
    }
    if (startDate != null) {
      body['start_date'] = DateFormat('yyyy-MM-dd').format(startDate);
    }
    if (endDate != null) {
      body['end_date'] = DateFormat('yyyy-MM-dd').format(endDate);
    }

    // محاولة الاتصال بالرابط الأساسي أولاً
    // ملاحظة: هذا الـ endpoint لا يحتاج JWT token، فقط api_key في الـ body
    try {
      final primaryUrl = ApiConfig.getCompleteProfileUrl();
      final headers = await _getHeaders(includeToken: false); // لا نرسل token لهذا الـ endpoint
      
      debugPrint('🔗 [EmployeeAPI] Trying primary URL: $primaryUrl');
      debugPrint('📋 [EmployeeAPI] Request body: $body');
      debugPrint('🔑 [EmployeeAPI] Using api_key authentication (no JWT token)');
      
      final response = await http
          .post(
            Uri.parse(primaryUrl),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      debugPrint('📊 [EmployeeAPI] Primary response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == true) {
            final completeResponse = CompleteEmployeeResponse.fromJson(
              data['data'] as Map<String, dynamic>,
            );
            debugPrint('✅ [EmployeeAPI] Successfully loaded data from primary URL');
            return ApiResponse.success(
              completeResponse,
              data['message'] ?? 'تم جلب البيانات بنجاح',
            );
          } else {
            debugPrint('⚠️ [EmployeeAPI] Primary returned success=false: ${data['message']}');
            return ApiResponse.error(
              data['message'] ?? 'فشل جلب البيانات',
              data['error'],
            );
          }
        } catch (e) {
          debugPrint('❌ [EmployeeAPI] Error parsing primary response: $e');
          // جرب الرابط الاحتياطي
          return await _tryBackupCompleteProfile(body);
        }
      } else if (response.statusCode >= 300 && response.statusCode < 400) {
        // إعادة توجيه (301, 302, 307, 308)
        debugPrint('⚠️ [EmployeeAPI] Primary server returned ${response.statusCode} (redirect), trying backup...');
        return await _tryBackupCompleteProfile(body);
      } else if (response.statusCode == 503 || response.statusCode == 502 || response.statusCode == 504) {
        // سيرفر غير متاح
        debugPrint('⚠️ [EmployeeAPI] Primary server unavailable (${response.statusCode}), trying backup...');
        return await _tryBackupCompleteProfile(body);
      } else if (response.statusCode == 401) {
        // خطأ 401: غير مصرح - قد يكون الـ token منتهي الصلاحية
        debugPrint('❌ [EmployeeAPI] Primary server error: 401 (Unauthorized)');
        debugPrint('⚠️ [EmployeeAPI] Token may be expired or invalid');
        
        // محاولة تحديث الـ token إذا كان منتهي الصلاحية
        try {
          final token = await AuthService.getToken();
          if (token == null || token.isEmpty) {
            debugPrint('⚠️ [EmployeeAPI] No token found, user may need to login again');
            return ApiResponse.error(
              'غير مصرح. يرجى تسجيل الدخول مرة أخرى',
              'Unauthorized (401) - No token',
            );
          }
          
          // التحقق من انتهاء صلاحية الـ token
          final isExpired = await AuthService.isTokenExpired();
          if (isExpired) {
            debugPrint('⚠️ [EmployeeAPI] Token is expired, user needs to login again');
            return ApiResponse.error(
              'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مرة أخرى',
              'Unauthorized (401) - Token expired',
            );
          }
        } catch (e) {
          debugPrint('⚠️ [EmployeeAPI] Error checking token: $e');
        }
        
        // جرب الرابط الاحتياطي
        debugPrint('🔄 [EmployeeAPI] Trying backup URL as fallback...');
        final backupResult = await _tryBackupCompleteProfile(body);
        // إذا فشل الاحتياطي أيضاً، أرجع خطأ 401
        if (!backupResult.success) {
          return ApiResponse.error(
            'غير مصرح. يرجى التحقق من:\n1. تسجيل الدخول مرة أخرى\n2. صحة api_key',
            'Unauthorized (401)',
          );
        }
        return backupResult;
      } else {
        debugPrint('❌ [EmployeeAPI] Primary server error: ${response.statusCode}');
        // حتى في حالة الأخطاء الأخرى، جرب الرابط الاحتياطي
        debugPrint('🔄 [EmployeeAPI] Trying backup URL as fallback...');
        final backupResult = await _tryBackupCompleteProfile(body);
        // إذا فشل الاحتياطي أيضاً، أرجع خطأ الأساسي
        if (!backupResult.success) {
          return ApiResponse.error(
            _getErrorMessage(response.statusCode),
            response.body,
          );
        }
        return backupResult;
      }
    } catch (e) {
      debugPrint('❌ [EmployeeAPI] Exception with primary URL: $e');
      debugPrint('🔄 [EmployeeAPI] Trying backup URL...');
      // محاولة الرابط الاحتياطي في حالة الخطأ
      return await _tryBackupCompleteProfile(body);
    }
  }

  /// ============================================
  /// 🔄 محاولة الاتصال بالرابط الاحتياطي - Try Backup URL
  /// ============================================
  static Future<ApiResponse<CompleteEmployeeResponse>> _tryBackupCompleteProfile(
    Map<String, dynamic> body,
  ) async {
    try {
      final backupUrl = ApiConfig.getBackupCompleteProfileUrl();
      final headers = await _getHeaders(includeToken: false); // لا نرسل token لهذا الـ endpoint
      
      debugPrint('🔗 [EmployeeAPI] Trying backup URL: $backupUrl');
      debugPrint('📋 [EmployeeAPI] Request body: $body');
      debugPrint('🔑 [EmployeeAPI] Using api_key authentication (no JWT token)');
      
      final response = await http
          .post(
            Uri.parse(backupUrl),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(timeoutDuration);

      debugPrint('📊 [EmployeeAPI] Backup response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['success'] == true) {
            debugPrint('✅ [EmployeeAPI] Successfully connected via backup URL');
            final completeResponse = CompleteEmployeeResponse.fromJson(
              data['data'] as Map<String, dynamic>,
            );
            return ApiResponse.success(
              completeResponse,
              data['message'] ?? 'تم جلب البيانات بنجاح',
            );
          } else {
            debugPrint('⚠️ [EmployeeAPI] Backup returned success=false: ${data['message']}');
            return ApiResponse.error(
              data['message'] ?? 'فشل جلب البيانات',
              data['error'],
            );
          }
        } catch (e) {
          debugPrint('❌ [EmployeeAPI] Error parsing backup response: $e');
          return ApiResponse.error(
            'حدث خطأ في معالجة البيانات من السيرفر',
            'Parse Error: $e',
          );
        }
      } else if (response.statusCode == 401) {
        debugPrint('❌ [EmployeeAPI] Backup server error: 401 (Unauthorized)');
        return ApiResponse.error(
          'غير مصرح. يرجى التحقق من:\n1. تسجيل الدخول مرة أخرى\n2. صحة api_key\n3. أن الـ token صحيح',
          'Unauthorized (401)',
        );
      } else {
        debugPrint('❌ [EmployeeAPI] Backup server error: ${response.statusCode}');
        return ApiResponse.error(
          _getErrorMessage(response.statusCode),
          response.body,
        );
      }
    } catch (e) {
      debugPrint('❌ [EmployeeAPI] Exception with backup URL: $e');
      if (e.toString().contains('503') || e.toString().contains('Service Unavailable')) {
        return ApiResponse.error(
          'الخدمة غير متاحة حالياً. يرجى المحاولة لاحقاً.',
          'Service Unavailable',
        );
      }
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        return ApiResponse.error(
          'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.',
          'Connection Timeout',
        );
      }
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return ApiResponse.error(
          'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت.',
          'Network Error',
        );
      }
      return ApiResponse.error(
        'حدث خطأ في الاتصال: $e',
        'Connection Error',
      );
    }
  }

  /// ============================================
  /// 🚗 جلب تفاصيل السيارة الكاملة مع سجلات التسليم - Get Vehicle Details with Handovers
  /// ============================================
  static Future<ApiResponse<VehicleDetailsResponse>> getVehicleDetailsWithHandovers({
    required String employeeId,
    String? vehicleId,
  }) async {
    try {
      // محاولة جلب من endpoint الموظف أولاً
      final url = ApiConfig.getEmployeeVehicleUrl(employeeId);
      debugPrint('🚀 [EmployeeAPI] Fetching vehicle details with handovers from: $url');
      
      final response = await http
          .get(
            Uri.parse(url),
            headers: await _getHeaders(includeToken: false),
          )
          .timeout(timeoutDuration);

      debugPrint('📥 [EmployeeAPI] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // التحقق من أن الاستجابة تحتوي على الشكل الجديد
        if (data.containsKey('success') && data['vehicle'] != null) {
          try {
            final vehicleDetails = VehicleDetailsResponse.fromJson(data);
            debugPrint('✅ [EmployeeAPI] Successfully parsed vehicle details with handovers');
            debugPrint('   📋 Vehicle: ${vehicleDetails.vehicle?.plateNumber}');
            debugPrint('   📋 Handover records: ${vehicleDetails.handoverRecords.length}');
            return ApiResponse.success(vehicleDetails, 'تم جلب التفاصيل بنجاح');
          } catch (e, stackTrace) {
            debugPrint('❌ [EmployeeAPI] Error parsing vehicle details response: $e');
            debugPrint('📋 Stack trace: $stackTrace');
          }
        }
      }

      // إذا فشل، جرب endpoint السيارة مباشرة
      if (vehicleId != null && vehicleId.isNotEmpty) {
        try {
          final vehicleUrl = ApiConfig.getVehicleDetailsUrl(vehicleId);
          debugPrint('🚀 [EmployeeAPI] Trying vehicle details endpoint: $vehicleUrl');
          
          final vehicleResponse = await http
              .get(
                Uri.parse(vehicleUrl),
                headers: await _getHeaders(includeToken: false),
              )
              .timeout(timeoutDuration);

          if (vehicleResponse.statusCode == 200) {
            final vehicleData = jsonDecode(vehicleResponse.body) as Map<String, dynamic>;
            if (vehicleData.containsKey('success') && vehicleData['vehicle'] != null) {
              final vehicleDetails = VehicleDetailsResponse.fromJson(vehicleData);
              return ApiResponse.success(vehicleDetails, 'تم جلب التفاصيل بنجاح');
            }
          }
        } catch (e) {
          debugPrint('⚠️ [EmployeeAPI] Vehicle details endpoint failed: $e');
        }
      }

      return ApiResponse.error(
        'فشل جلب تفاصيل السيارة',
        'Failed to fetch vehicle details',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [EmployeeAPI] Error fetching vehicle details: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      return ApiResponse.error(
        'حدث خطأ في الاتصال: $e',
        'Connection Error',
      );
    }
  }

  /// ============================================
  /// 📦 Alias للدالة - للتوافق مع الملف الإرشادي
  /// ============================================
  @Deprecated('Use getCompleteProfile instead')
  static Future<ApiResponse<CompleteEmployeeResponse>> getEmployeeCompleteProfile({
    required String jobNumber,
    required String apiKey,
    String? month,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return getCompleteProfile(
      jobNumber: jobNumber,
      apiKey: apiKey,
      month: month,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

