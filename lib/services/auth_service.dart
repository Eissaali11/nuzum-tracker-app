import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../utils/safe_preferences.dart';
import 'api_logging_service.dart';

/// ============================================
/// 🔐 خدمة المصادقة - Authentication Service
/// ============================================
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _employeeIdKey = 'employee_id';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  static Dio? _dio;

  /// تهيئة Dio مع Interceptors
  static Dio get dio {
    _dio ??= Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeoutDuration,
        receiveTimeout: ApiConfig.timeoutDuration,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // إضافة Interceptor لإضافة Token تلقائياً
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // تسجيل الطلب
          final startTime = DateTime.now();
          options.extra['start_time'] = startTime;
          
          // استخراج service name من URL
          final serviceName = _extractServiceName(options.path);
          
          ApiLoggingService.logApiRequest(
            method: options.method,
            url: '${options.baseUrl}${options.path}',
            headers: options.headers,
            body: options.data,
            queryParameters: options.queryParameters,
            serviceName: serviceName,
          );
          
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // تسجيل الاستجابة
          final startTime = response.requestOptions.extra['start_time'] as DateTime?;
          final duration = startTime != null 
              ? DateTime.now().difference(startTime)
              : null;
          
          final serviceName = _extractServiceName(response.requestOptions.path);
          
          ApiLoggingService.logApiResponse(
            method: response.requestOptions.method,
            url: '${response.requestOptions.baseUrl}${response.requestOptions.path}',
            statusCode: response.statusCode ?? 0,
            headers: response.headers.map,
            responseData: response.data,
            duration: duration,
            serviceName: serviceName,
          );
          
          return handler.next(response);
        },
        onError: (error, handler) async {
          // تسجيل الخطأ
          final serviceName = _extractServiceName(error.requestOptions.path);
          
          ApiLoggingService.logApiError(
            method: error.requestOptions.method,
            url: '${error.requestOptions.baseUrl}${error.requestOptions.path}',
            error: error.message ?? error.toString(),
            statusCode: error.response?.statusCode,
            responseData: error.response?.data,
            serviceName: serviceName,
          );
          
          // إذا كان الخطأ 401 (Unauthorized)، جرب refresh token
          if (error.response?.statusCode == 401) {
            final refreshed = await refreshToken();
            if (refreshed) {
              // إعادة المحاولة مع token جديد
              final opts = error.requestOptions;
              final token = await getToken();
              opts.headers['Authorization'] = 'Bearer $token';
              final response = await _dio!.fetch(opts);
              return handler.resolve(response);
            } else {
              // فشل refresh - فقط مسح بيانات المصادقة، لا بيانات التتبع
              // هذا يمنع توقف خدمة التتبع عند فشل تجديد Token
              debugPrint('⚠️ [Auth] Token refresh failed, clearing auth data only (keeping tracking data)');
              await SafePreferences.setString(_tokenKey, '');
              await SafePreferences.setString(_employeeIdKey, '');
              await SafePreferences.setString(_refreshTokenKey, '');
              await SafePreferences.setString(_tokenExpiryKey, '');
              // لا نمسح jobNumber و apiKey - خدمة التتبع تحتاجها
            }
          }
          return handler.next(error);
        },
      ),
    );

    return _dio!;
  }

  /// دالة مساعدة لاستخراج اسم الخدمة من المسار
  static String _extractServiceName(String path) {
    if (path.contains('/auth/')) return 'auth';
    if (path.contains('/requests/')) return 'requests';
    if (path.contains('/employee/')) return 'employee';
    if (path.contains('/vehicles/')) return 'vehicles';
    if (path.contains('/attendance/')) return 'attendance';
    if (path.contains('/notifications/')) return 'notifications';
    if (path.contains('/logs/')) return 'logging';
    if (path.contains('/external/')) return 'external';
    return 'unknown';
  }

  /// تسجيل الدخول
  /// يستخدم national_id بدلاً من password
  static Future<Map<String, dynamic>> login({
    required String employeeId,
    required String nationalId,
  }) async {
    // استخدام nuzum.site لتسجيل الدخول - المسار الصحيح
    try {
      final loginUrl = '${ApiConfig.nuzumBaseUrl}${ApiConfig.loginPath}';
      debugPrint('🔄 [Auth] Trying login: $loginUrl');
      
      final loginData = {
        'employee_id': employeeId,
        'national_id': nationalId,
      };
      debugPrint('📤 [Auth] Login data: $loginData');
      
      // استخدام Dio جديد مع baseUrl فارغ للسماح بـ URL كامل
      final loginDio = Dio(
        BaseOptions(
          baseUrl: '',
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      final response = await loginDio.post(
        loginUrl, // POST https://eissahr.replit.app/api/v1/auth/login
        data: loginData,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true) {
          // Token مباشرة في Response (ليس في data.token)
          final token = data['token'] as String;
          final employee = data['employee'] as Map<String, dynamic>?;
          // حفظ refresh token إذا كان موجوداً
          final refreshToken = data['refresh_token'] as String? ?? 
                              data['refreshToken'] as String?;

          // حفظ Token
          await saveToken(token);
          await SafePreferences.setString(_employeeIdKey, employeeId);
          // حفظ nationalId للتحقق من حالة تسجيل الدخول
          await SafePreferences.setString('nationalId', nationalId);
          
          // حفظ refresh token إذا كان موجوداً
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await SafePreferences.setString(_refreshTokenKey, refreshToken);
            debugPrint('✅ [Auth] Refresh token saved');
          }

          // حفظ بيانات الموظف إذا كانت متوفرة
          if (employee != null) {
            await SafePreferences.setString('employee_name', employee['name'] ?? '');
            await SafePreferences.setString('employee_email', employee['email'] ?? '');
            await SafePreferences.setString('employee_department', employee['department'] ?? '');
          }

          // تعيين انتهاء الصلاحية (365 يوم - سنة كاملة - تسجيل دخول مستمر)
          final expiryDate = DateTime.now().add(const Duration(days: 365));
          await SafePreferences.setString(
            _tokenExpiryKey,
            expiryDate.toIso8601String(),
          );

          debugPrint('✅ [Auth] Login successful for employee: $employeeId');
          
          return {
            'success': true,
            'message': 'تم تسجيل الدخول بنجاح',
            'data': {
              'token': token,
              'employee': employee,
            },
          };
        } else {
          return {
            'success': false,
            'error': data['error'] ?? 'فشل تسجيل الدخول',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'خطأ في الاتصال: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      // معالجة خطأ 401 (Unauthorized)
      if (e.response?.statusCode == 401) {
        final errorData = e.response?.data;
        String errorMessage = 'فشل تسجيل الدخول';
        
        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['error'] as String? ?? 
                        errorData['message'] as String? ?? 
                        'البيانات المدخلة غير صحيحة. يرجى التحقق من رقم الموظف والهوية الوطنية';
        }
        
        debugPrint('❌ [Auth] Login failed with 401: $errorMessage');
        debugPrint('📋 [Auth] Response data: ${e.response?.data}');
        
        return {
          'success': false,
          'error': errorMessage,
        };
      }
      
      // إذا كان الخطأ 404، جرب المسار من backupDomain
      if (e.response?.statusCode == 404) {
        debugPrint('⚠️ [Auth] Base domain path returned 404, trying backup domain path...');
        try {
          final loginUrl = '${ApiConfig.backupDomain}${ApiConfig.loginPath}';
          debugPrint('🔄 [Auth] Trying backup domain login: $loginUrl');
          
          final loginDio = Dio(
            BaseOptions(
              baseUrl: '',
              connectTimeout: ApiConfig.timeoutDuration,
              receiveTimeout: ApiConfig.timeoutDuration,
              headers: {'Content-Type': 'application/json'},
            ),
          );
          
          final response = await loginDio.post(
            loginUrl,
            data: {
              'employee_id': employeeId,
              'national_id': nationalId,
            },
          );

          if (response.statusCode == 200) {
            final data = response.data as Map<String, dynamic>;

            if (data['success'] == true) {
              // Token مباشرة في Response أو في data.token
              final token = data['token'] ?? data['data']?['token'] as String?;
              if (token == null) {
                return {
                  'success': false,
                  'error': 'لم يتم العثور على token في الاستجابة',
                };
              }

              final employee = data['employee'] ?? data['data']?['employee'] as Map<String, dynamic>?;
              // حفظ refresh token إذا كان موجوداً
              final refreshToken = data['refresh_token'] as String? ?? 
                                  data['refreshToken'] as String?;

              // حفظ Token
              await saveToken(token);
              await SafePreferences.setString(_employeeIdKey, employeeId);
              
              // حفظ refresh token إذا كان موجوداً
              if (refreshToken != null && refreshToken.isNotEmpty) {
                await SafePreferences.setString(_refreshTokenKey, refreshToken);
                debugPrint('✅ [Auth] Refresh token saved (backup)');
              }

              // حفظ بيانات الموظف إذا كانت متوفرة
              if (employee != null) {
                await SafePreferences.setString('employee_name', employee['name'] ?? '');
                await SafePreferences.setString('employee_email', employee['email'] ?? '');
                await SafePreferences.setString('employee_department', employee['department'] ?? '');
              }

              // تعيين انتهاء الصلاحية (365 يوم - سنة كاملة - تسجيل دخول مستمر)
              final expiryDate = DateTime.now().add(const Duration(days: 365));
              await SafePreferences.setString(
                _tokenExpiryKey,
                expiryDate.toIso8601String(),
              );

              debugPrint('✅ [Auth] Login successful via external path for employee: $employeeId');
              
              return {
                'success': true,
                'message': 'تم تسجيل الدخول بنجاح',
                'data': {
                  'token': token,
                  'employee': employee,
                },
              };
            } else {
              return {
                'success': false,
                'error': data['error'] ?? 'فشل تسجيل الدخول',
              };
            }
          } else {
            return {
              'success': false,
              'error': 'خطأ في الاتصال: ${response.statusCode}',
            };
          }
        } on DioException catch (e2) {
          // معالجة خطأ 401 في المسار الاحتياطي
          if (e2.response?.statusCode == 401) {
            final errorData = e2.response?.data;
            String errorMessage = 'فشل تسجيل الدخول';
            
            if (errorData is Map<String, dynamic>) {
              errorMessage = errorData['error'] as String? ?? 
                            errorData['message'] as String? ?? 
                            'البيانات المدخلة غير صحيحة. يرجى التحقق من رقم الموظف والهوية الوطنية';
            }
            
            debugPrint('❌ [Auth] Backup domain login failed with 401: $errorMessage');
            debugPrint('📋 [Auth] Backup response data: ${e2.response?.data}');
            return {
              'success': false,
              'error': errorMessage,
            };
          }
          
          debugPrint('❌ [Auth] Backup domain path also failed: $e2');
          return {
            'success': false,
            'error': 'فشل تسجيل الدخول. يرجى التحقق من:\n1. رقم الموظف والهوية الوطنية\n2. اتصال الإنترنت\n3. أن الخادم يعمل\n\nBase URL: ${ApiConfig.baseUrl}',
          };
        } catch (e2) {
          debugPrint('❌ [Auth] Backup domain path error: $e2');
          return {
            'success': false,
            'error': 'حدث خطأ في الاتصال: $e2',
          };
        }
      }
      
      debugPrint('❌ [Auth] Login error: $e');
      String errorMsg = 'حدث خطأ في تسجيل الدخول';
      
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;
        
        if (responseData is Map && responseData['error'] != null) {
          errorMsg = responseData['error'] as String;
        } else if (statusCode == 401) {
          errorMsg = 'رقم الموظف أو الهوية الوطنية غير صحيحة';
        } else if (statusCode == 404) {
          errorMsg = 'المسار غير موجود. يرجى التحقق من إعدادات API';
        } else if (statusCode == 500) {
          errorMsg = 'خطأ في الخادم. يرجى المحاولة لاحقاً';
        } else {
          errorMsg = 'خطأ في الاتصال: $statusCode';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = 'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت';
      }
      
      return {'success': false, 'error': errorMsg};
    } catch (e) {
      debugPrint('❌ [Auth] Login error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// حفظ Token
  static Future<void> saveToken(String token) async {
    await SafePreferences.setString(_tokenKey, token);
  }

  /// الحصول على Token
  static Future<String?> getToken() async {
    return await SafePreferences.getString(_tokenKey);
  }

  /// التحقق من انتهاء صلاحية Token
  static Future<bool> isTokenExpired() async {
    final expiryStr = await SafePreferences.getString(_tokenExpiryKey);
    if (expiryStr == null) return false;

    try {
      final expiryDate = DateTime.parse(expiryStr);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return false;
    }
  }

  /// تحديث Token
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await SafePreferences.getString(_refreshTokenKey);
      if (refreshToken == null) {
        debugPrint('⚠️ [Auth] No refresh token available');
        return false;
      }

      // محاولة استخدام endpoint v1 أولاً
      try {
        final loginDio = Dio(
          BaseOptions(
            baseUrl: '',
            connectTimeout: ApiConfig.timeoutDuration,
            receiveTimeout: ApiConfig.timeoutDuration,
            headers: {'Content-Type': 'application/json'},
          ),
        );

        final refreshUrl = '${ApiConfig.baseUrl}${ApiConfig.v1RefreshTokenPath}';
        debugPrint('🔄 [Auth] Trying to refresh token: $refreshUrl');
        
        final response = await loginDio.post(
          refreshUrl,
          data: {'refresh_token': refreshToken},
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            final token = data['token'] ?? data['data']?['token'] as String?;
            if (token != null) {
              await saveToken(token);
              // تحديث تاريخ انتهاء الصلاحية (365 يوم - سنة كاملة - تسجيل دخول مستمر)
              final expiryDate = DateTime.now().add(const Duration(days: 365));
              await SafePreferences.setString(
                _tokenExpiryKey,
                expiryDate.toIso8601String(),
              );
              debugPrint('✅ [Auth] Token refreshed successfully');
              return true;
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [Auth] v1 refresh failed, trying external endpoint: $e');
      }

      // محاولة استخدام endpoint external كبديل
      try {
        final loginDio = Dio(
          BaseOptions(
            baseUrl: '',
            connectTimeout: ApiConfig.timeoutDuration,
            receiveTimeout: ApiConfig.timeoutDuration,
            headers: {'Content-Type': 'application/json'},
          ),
        );

        final refreshUrl = '${ApiConfig.baseUrl}/api/external/auth/refresh';
        debugPrint('🔄 [Auth] Trying external refresh endpoint: $refreshUrl');
        
        final response = await loginDio.post(
          refreshUrl,
          data: {'refresh_token': refreshToken},
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            final token = data['token'] ?? data['data']?['token'] as String?;
            if (token != null) {
              await saveToken(token);
              // تحديث تاريخ انتهاء الصلاحية (365 يوم - سنة كاملة - تسجيل دخول مستمر)
              final expiryDate = DateTime.now().add(const Duration(days: 365));
              await SafePreferences.setString(
                _tokenExpiryKey,
                expiryDate.toIso8601String(),
              );
              debugPrint('✅ [Auth] Token refreshed successfully (external)');
              return true;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ [Auth] External refresh also failed: $e');
      }

      return false;
    } catch (e) {
      debugPrint('❌ [Auth] Refresh token error: $e');
      return false;
    }
  }

  /// تسجيل الخروج
  /// [clearTrackingData]: إذا كان true، يتم مسح بيانات التتبع أيضاً (jobNumber, apiKey)
  /// عند false، يتم الاحتفاظ ببيانات التتبع حتى عند تسجيل الخروج من المصادقة
  /// هذا يسمح لخدمة التتبع بالاستمرار في العمل حتى لو تم تسجيل الخروج من الواجهة
  static Future<void> logout({bool clearTrackingData = false}) async {
    await SafePreferences.setString(_tokenKey, '');
    await SafePreferences.setString(_employeeIdKey, '');
    await SafePreferences.setString(_refreshTokenKey, '');
    await SafePreferences.setString(_tokenExpiryKey, '');
    // مسح بيانات تسجيل الدخول المحفوظة
    await SafePreferences.setString('nationalId', '');
    
    // فقط عند تسجيل الخروج الصريح من المستخدم، نمسح بيانات التتبع
    // هذا يمنع توقف التتبع عند فشل تجديد Token تلقائياً
    if (clearTrackingData) {
      await SafePreferences.setString('jobNumber', '');
      await SafePreferences.setString('apiKey', '');
      debugPrint('🛑 [Auth] Tracking data cleared (explicit logout)');
    } else {
      debugPrint('ℹ️ [Auth] Auth data cleared, but tracking data preserved');
    }
  }

  /// التحقق من حالة تسجيل الدخول
  /// يعتمد على وجود بيانات المستخدم (jobNumber, nationalId) حتى لو انتهى Token
  /// هذا يضمن بقاء المستخدم مسجل دخول بعد أول تسجيل دخول
  static Future<bool> isLoggedIn() async {
    // التحقق من وجود بيانات المستخدم الأساسية
    final jobNumber = await SafePreferences.getString('jobNumber');
    final nationalId = await SafePreferences.getString('nationalId');
    
    // إذا كانت بيانات المستخدم موجودة، يعتبر مسجل دخول حتى لو انتهى Token
    if (jobNumber != null && 
        jobNumber.isNotEmpty && 
        nationalId != null && 
        nationalId.isNotEmpty) {
      
      // محاولة تجديد Token إذا كان منتهياً (في الخلفية)
      final token = await getToken();
      if (token == null || token.isEmpty) {
        // لا يوجد Token - محاولة تجديده
        debugPrint('🔄 [Auth] No token found, attempting refresh...');
        await refreshToken();
        return true; // نعتبره مسجل دخول حتى لو فشل التجديد
      }
      
      final isExpired = await isTokenExpired();
      if (isExpired) {
        // Token منتهي - محاولة تجديده في الخلفية
        debugPrint('🔄 [Auth] Token expired, attempting refresh...');
        await refreshToken();
        return true; // نعتبره مسجل دخول حتى لو فشل التجديد
      }
      
      return true; // Token صالح وبيانات موجودة
    }
    
    // لا توجد بيانات مستخدم - غير مسجل دخول
    return false;
  }

  /// التحقق من أن Token سينتهي قريباً (خلال 5 دقائق)
  static Future<bool> isTokenExpiringSoon() async {
    final expiryStr = await SafePreferences.getString(_tokenExpiryKey);
    if (expiryStr == null) return false;

    try {
      final expiryDate = DateTime.parse(expiryStr);
      final timeUntilExpiry = expiryDate.difference(DateTime.now());
      // إذا كان الوقت المتبقي أقل من 5 دقائق
      return timeUntilExpiry.inMinutes < 5;
    } catch (e) {
      return false;
    }
  }

  /// الحصول على Token صالح (يتم تجديده تلقائياً إذا كان على وشك الانتهاء)
  static Future<String?> getValidToken() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [Auth] No token found');
        return null;
      }

      // التحقق من انتهاء الصلاحية
      final isExpired = await isTokenExpired();
      if (isExpired) {
        debugPrint('⚠️ [Auth] Token expired, attempting refresh...');
        final refreshed = await refreshToken();
        if (refreshed) {
          return await getToken();
        } else {
          debugPrint('❌ [Auth] Failed to refresh expired token');
          return null;
        }
      }

      // التحقق من أن Token على وشك الانتهاء (خلال 5 دقائق)
      final isExpiringSoon = await isTokenExpiringSoon();
      if (isExpiringSoon) {
        debugPrint('⚠️ [Auth] Token expiring soon, attempting refresh...');
        final refreshed = await refreshToken();
        if (refreshed) {
          return await getToken();
        } else {
          debugPrint('⚠️ [Auth] Failed to refresh token, using current token');
          // نستخدم الـ token الحالي حتى لو فشل التجديد
          return token;
        }
      }

      return token;
    } catch (e) {
      debugPrint('❌ [Auth] Error getting valid token: $e');
      return await getToken(); // إرجاع الـ token الحالي حتى لو حدث خطأ
    }
  }

  /// الحصول على Employee ID
  static Future<String?> getEmployeeId() async {
    return await SafePreferences.getString(_employeeIdKey);
  }
}
