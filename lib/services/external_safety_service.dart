import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../utils/api_response.dart';
import 'api_logging_service.dart';
import 'auth_service.dart';

/// ============================================
/// 🛡️ خدمة فحص السلامة الخارجية - External Safety Service
/// ============================================
class ExternalSafetyService {
  static Dio get dio => AuthService.dio;

  /// ============================================
  /// 📋 إنشاء فحص سلامة جديد - Create Safety Check
  /// POST /api/v1/external-safety/checks
  /// ============================================
  static Future<ApiResponse<Map<String, dynamic>>> createSafetyCheck({
    required int vehicleId,
    required String driverName,
    required String driverNationalId,
    required String driverDepartment,
    required String driverCity,
    required String currentDelegate,
    String? notes,
  }) async {
    final startTime = DateTime.now();
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'يرجى تسجيل الدخول أولاً',
        );
      }

      final requestBody = {
        'vehicle_id': vehicleId,
        'driver_name': driverName,
        'driver_national_id': driverNationalId,
        'driver_department': driverDepartment,
        'driver_city': driverCity,
        'current_delegate': currentDelegate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      debugPrint('📤 [ExternalSafety] Creating safety check...');
      debugPrint('   Vehicle ID: $vehicleId');
      debugPrint('   Driver: $driverName');
      debugPrint('   Endpoint: ${ApiConfig.getExternalSafetyChecksUrl()}');

      // قائمة المسارات المحتملة للفحص
      // المسار الأساسي: POST /api/v1/external-safety/checks (على nuzum.site) - ✅ متاح الآن
      final possiblePaths = [
        ApiConfig.externalSafetyChecksPath, // /api/v1/external-safety/checks (الأولوية الأولى - nuzum.site)
        '/api/external-safety/checks', // بدون v1
        '/api/v1/safety-checks', // مسار بديل
        '/api/safety-checks', // مسار بديل بدون v1
      ];

      // قائمة Base URLs المحتملة
      final possibleBaseUrls = [
        ApiConfig.nuzumBaseUrl, // https://nuzum.site
        ApiConfig.baseUrl, // https://eissahr.replit.app
      ];

      DioException? lastException;
      Map<String, dynamic>? lastResponseData;

      // محاولة كل مسار مع كل base URL
      for (final baseUrl in possibleBaseUrls) {
        for (final path in possiblePaths) {
          try {
            debugPrint('📤 [ExternalSafety] Trying: $baseUrl$path');

            // استخدام Dio جديد
            final uploadDio = Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: ApiConfig.timeoutDuration,
              receiveTimeout: ApiConfig.timeoutDuration,
            ));

            final fullUrl = '$baseUrl$path';
            await ApiLoggingService.logApiRequest(
              method: 'POST',
              url: fullUrl,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer [REDACTED]',
              },
              body: requestBody,
              serviceName: 'external_safety',
            );

            final response = await uploadDio.post(
              path,
              data: requestBody,
              options: Options(
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                validateStatus: (status) => true, // قبول جميع رموز الحالة
              ),
            );

            final duration = DateTime.now().difference(startTime);
            await ApiLoggingService.logApiResponse(
              method: 'POST',
              url: fullUrl,
              statusCode: response.statusCode ?? 0,
              headers: response.headers.map,
              responseData: response.data,
              duration: duration,
              serviceName: 'external_safety',
            );

            debugPrint('📤 [ExternalSafety] Response status: ${response.statusCode}');
            debugPrint('📤 [ExternalSafety] Response data: ${response.data}');

            // إذا نجح الطلب (200 أو 201)
            if (response.statusCode == 200 || response.statusCode == 201) {
              final data = response.data as Map<String, dynamic>;
              if (data['success'] == true) {
                final checkData = data['data'] as Map<String, dynamic>;
                debugPrint('✅ [ExternalSafety] Safety check created successfully via: $baseUrl$path');
                debugPrint('   Check ID: ${checkData['check_id']}');
                debugPrint('   Vehicle Plate: ${checkData['vehicle_plate_number']}');

                return ApiResponse<Map<String, dynamic>>(
                  success: true,
                  data: checkData,
                  message: data['message'] ?? 'تم إنشاء فحص السلامة بنجاح',
                );
              } else {
                // إذا كان success = false، احفظ الاستجابة للمحاولة التالية
                lastResponseData = data;
                debugPrint('⚠️ [ExternalSafety] Request failed with success=false: ${data['message'] ?? data['error']}');
                continue; // جرب المسار التالي
              }
            } else if (response.statusCode == 404) {
              // إذا كان 404، جرب المسار التالي
              debugPrint('⚠️ [ExternalSafety] Path not found (404), trying next path...');
              continue;
            } else {
              // إذا كان خطأ آخر، احفظه
              lastResponseData = response.data is Map<String, dynamic>
                  ? response.data as Map<String, dynamic>
                  : {'error': 'Status ${response.statusCode}'};
              debugPrint('⚠️ [ExternalSafety] Request failed with status ${response.statusCode}');
              continue; // جرب المسار التالي
            }
          } on DioException catch (e) {
            lastException = e;
            debugPrint('⚠️ [ExternalSafety] DioException with $baseUrl$path: ${e.message}');
            if (e.response?.statusCode == 404) {
              continue; // جرب المسار التالي
            }
            // للأخطاء الأخرى، نواصل المحاولة
          } catch (e) {
            debugPrint('⚠️ [ExternalSafety] Exception with $baseUrl$path: $e');
            continue; // جرب المسار التالي
          }
        }
      }

      // إذا فشلت جميع المحاولات
      if (lastException != null) {
        throw lastException;
      }

      // إذا كان هناك استجابة محفوظة
      if (lastResponseData != null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: lastResponseData['message'] ?? 
                   lastResponseData['error'] ?? 
                   'فشل إنشاء فحص السلامة. يرجى التحقق من المسار الصحيح.',
        );
      }

      // إذا فشلت جميع المحاولات، نعيد رسالة خطأ واضحة
      String errorMessage = 'فشل إنشاء فحص السلامة.';
      
      // إذا كان الخطأ 404 من جميع المسارات
      if (lastException != null && lastException.response?.statusCode == 404) {
        errorMessage = '⚠️ الـ API غير متاح حالياً على السرفر.\n\n'
            'تم تجربة جميع المسارات الممكنة ولكن جميعها غير متاحة:\n'
            '• https://nuzum.site/api/v1/external-safety/checks\n'
            '• https://nuzum.site/api/external-safety/checks\n'
            '• https://eissahr.replit.app/api/v1/external-safety/checks\n'
            '• https://eissahr.replit.app/api/external-safety/checks\n\n'
            'يرجى:\n'
            '1. التحقق من أن الـ API متاح على السرفر\n'
            '2. المحاولة لاحقاً\n'
            '3. التواصل مع الدعم الفني';
      } else if (lastResponseData != null) {
        // إذا كان هناك استجابة من السرفر (مثل 400, 422, 500)
        final serverMessage = lastResponseData['message'] ?? lastResponseData['error'];
        if (serverMessage != null) {
          errorMessage = serverMessage.toString();
        }
      } else {
        // إذا لم يكن هناك استجابة أو استثناء محفوظ
        errorMessage = 'فشل الاتصال بالسرفر. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
      }
      
      debugPrint('❌ [ExternalSafety] Final error message: $errorMessage');
      
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: errorMessage,
      );
    } on DioException catch (e) {
      await ApiLoggingService.logApiError(
        method: 'POST',
        url: ApiConfig.getExternalSafetyChecksUrl(),
        error: e.message ?? e.toString(),
        statusCode: e.response?.statusCode,
        responseData: e.response?.data,
        serviceName: 'external_safety',
      );

      debugPrint('❌ [ExternalSafety] DioException creating check:');
      debugPrint('   Status code: ${e.response?.statusCode}');
      debugPrint('   Response data: ${e.response?.data}');
      debugPrint('   Error message: ${e.message}');

      String errorMessage = 'حدث خطأ أثناء إنشاء فحص السلامة';

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;

        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['error'] ??
              responseData['message'] ??
              'فشل إنشاء فحص السلامة: $statusCode';
        } else if (statusCode == 401) {
          errorMessage = 'يرجى تسجيل الدخول مرة أخرى';
        } else if (statusCode == 404) {
          errorMessage = 'المسار غير موجود على السرفر. يرجى التحقق من أن الـ API متاح.';
        } else if (statusCode == 422) {
          errorMessage = 'البيانات المدخلة غير صحيحة';
        } else if (statusCode == 500) {
          errorMessage = 'خطأ في الخادم. يرجى المحاولة لاحقاً';
        } else {
          errorMessage = 'فشل إنشاء فحص السلامة: $statusCode';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت';
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: errorMessage,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [ExternalSafety] Unexpected error creating check: $e');
      debugPrint('❌ [ExternalSafety] Stack trace: $stackTrace');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  /// ============================================
  /// 📤 رفع صورة للفحص - Upload Safety Check Image
  /// POST /api/v1/external-safety/checks/{check_id}/upload-image
  /// ============================================
  static Future<ApiResponse<Map<String, dynamic>>> uploadSafetyCheckImage({
    required int checkId,
    required File imageFile,
    String? description,
    required ProgressCallback onProgress,
  }) async {
    final startTime = DateTime.now();
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'يرجى تسجيل الدخول أولاً',
        );
      }

      debugPrint('📤 [ExternalSafety] Starting image upload for check ID: $checkId');
      debugPrint('📤 [ExternalSafety] Image file path: ${imageFile.path}');
      debugPrint('📤 [ExternalSafety] Image file exists: ${await imageFile.exists()}');
      debugPrint('📤 [ExternalSafety] Image file size: ${await imageFile.length()} bytes');

      // ضغط الصورة
      debugPrint('📤 [ExternalSafety] Compressing image...');
      final compressedFile = await _compressImage(imageFile);
      debugPrint('📤 [ExternalSafety] Compressed file size: ${await compressedFile.length()} bytes');

      // التحقق من وجود الملف المضغوط
      if (!await compressedFile.exists()) {
        debugPrint('❌ [ExternalSafety] Compressed file does not exist');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'فشل ضغط الصورة',
        );
      }

      // إنشاء MultipartFile
      final multipartFile = await MultipartFile.fromFile(
        compressedFile.path,
        filename: 'safety_check_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      // إنشاء FormData
      final formData = FormData.fromMap({
        'image': multipartFile,
        if (description != null && description.isNotEmpty) 'description': description,
      });

      debugPrint('📤 [ExternalSafety] FormData created successfully');
      debugPrint('📤 [ExternalSafety] Upload URL: ${ApiConfig.getExternalSafetyUploadImageUrl(checkId)}');

      // استخدام Dio جديد مع nuzum.site
      final uploadDio = Dio(BaseOptions(
        baseUrl: ApiConfig.nuzumBaseUrl,
        connectTimeout: ApiConfig.timeoutDuration,
        receiveTimeout: ApiConfig.timeoutDuration,
      ));

      final uploadUrl = ApiConfig.getExternalSafetyUploadImageUrl(checkId);
      
      await ApiLoggingService.logApiRequest(
        method: 'POST',
        url: uploadUrl,
        headers: {
          'Authorization': 'Bearer [REDACTED]',
        },
        body: {'image': '[FILE]', if (description != null) 'description': description},
        serviceName: 'external_safety',
      );

      final response = await uploadDio.post(
        '${ApiConfig.externalSafetyChecksPath}/$checkId/upload-image',
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => true,
        ),
      );

      final duration = DateTime.now().difference(startTime);
      
      await ApiLoggingService.logApiResponse(
        method: 'POST',
        url: uploadUrl,
        statusCode: response.statusCode ?? 0,
        headers: response.headers.map,
        responseData: response.data,
        duration: duration,
        serviceName: 'external_safety',
      );
      
      debugPrint('📤 [ExternalSafety] Request completed in ${duration.inMilliseconds}ms');
      debugPrint('📤 [ExternalSafety] Response status: ${response.statusCode}');
      debugPrint('📤 [ExternalSafety] Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final responseData = data['data'] ?? data;

        debugPrint('✅ [ExternalSafety] Image uploaded successfully');
        debugPrint('   Image ID: ${responseData['image_id']}');
        debugPrint('   Image URL: ${responseData['image_url']}');
        debugPrint('   Object Key: ${responseData['object_key']}');

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData,
          message: data['message'] ?? 'تم رفع الصورة بنجاح',
        );
      }

      final errorMessage = response.data is Map<String, dynamic>
          ? (response.data['error'] ?? response.data['message'] ?? 'فشل رفع الصورة')
          : 'فشل رفع الصورة: ${response.statusCode}';

      debugPrint('❌ [ExternalSafety] Upload failed: $errorMessage');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: errorMessage,
      );
    } on DioException catch (e) {
      await ApiLoggingService.logApiError(
        method: 'POST',
        url: ApiConfig.getExternalSafetyUploadImageUrl(checkId),
        error: e.message ?? e.toString(),
        statusCode: e.response?.statusCode,
        responseData: e.response?.data,
        serviceName: 'external_safety',
      );

      debugPrint('❌ [ExternalSafety] DioException during image upload:');
      debugPrint('   Status code: ${e.response?.statusCode}');
      debugPrint('   Response data: ${e.response?.data}');
      debugPrint('   Error message: ${e.message}');
      debugPrint('   Error type: ${e.type}');

      String errorMessage = 'حدث خطأ أثناء رفع الصورة';

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;

        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['error'] ??
              responseData['message'] ??
              'فشل رفع الصورة: $statusCode';
        } else if (statusCode == 401) {
          errorMessage = 'غير مصرح لك برفع الصورة. يرجى تسجيل الدخول مرة أخرى';
        } else if (statusCode == 404) {
          errorMessage = 'المسار غير موجود. يرجى التحقق من رقم الفحص';
        } else if (statusCode == 413) {
          errorMessage = 'حجم الصورة كبير جداً. يرجى تقليل حجم الصورة';
        } else if (statusCode == 422) {
          errorMessage = 'بيانات الصورة غير صالحة. يرجى التحقق من الملف';
        } else if (statusCode == 500) {
          errorMessage = 'خطأ في الخادم. يرجى المحاولة لاحقاً';
        } else {
          errorMessage = 'فشل رفع الصورة: $statusCode';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت';
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: errorMessage,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [ExternalSafety] Unexpected error during image upload: $e');
      debugPrint('❌ [ExternalSafety] Stack trace: $stackTrace');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  /// ============================================
  /// 📋 عرض تفاصيل الفحص - Get Safety Check Details
  /// GET /api/v1/external-safety/checks/{check_id}
  /// ============================================
  static Future<ApiResponse<Map<String, dynamic>>> getSafetyCheckDetails({
    required int checkId,
  }) async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'يرجى تسجيل الدخول أولاً',
        );
      }

      debugPrint('📤 [ExternalSafety] Getting safety check details for ID: $checkId');
      debugPrint('📤 [ExternalSafety] URL: ${ApiConfig.getExternalSafetyCheckUrl(checkId)}');

      // استخدام Dio جديد مع nuzum.site
      final uploadDio = Dio(BaseOptions(
        baseUrl: ApiConfig.nuzumBaseUrl,
        connectTimeout: ApiConfig.timeoutDuration,
        receiveTimeout: ApiConfig.timeoutDuration,
      ));

      final checkUrl = ApiConfig.getExternalSafetyCheckUrl(checkId);
      final startTime = DateTime.now();
      
      await ApiLoggingService.logApiRequest(
        method: 'GET',
        url: checkUrl,
        headers: {
          'Authorization': 'Bearer [REDACTED]',
        },
        serviceName: 'external_safety',
      );

      final response = await uploadDio.get(
        '${ApiConfig.externalSafetyChecksPath}/$checkId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final duration = DateTime.now().difference(startTime);
      
      await ApiLoggingService.logApiResponse(
        method: 'GET',
        url: checkUrl,
        statusCode: response.statusCode ?? 0,
        headers: response.headers.map,
        responseData: response.data,
        duration: duration,
        serviceName: 'external_safety',
      );

      debugPrint('📤 [ExternalSafety] Response status: ${response.statusCode}');
      debugPrint('📤 [ExternalSafety] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          debugPrint('✅ [ExternalSafety] Safety check details retrieved successfully');
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            data: data['data'] ?? data,
            message: data['message'] ?? 'تم جلب تفاصيل الفحص بنجاح',
          );
        } else {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: data['message'] ?? data['error'] ?? 'فشل جلب تفاصيل الفحص',
          );
        }
      }

      final errorMessage = response.data is Map<String, dynamic>
          ? (response.data['error'] ?? response.data['message'] ?? 'فشل جلب تفاصيل الفحص')
          : 'فشل جلب تفاصيل الفحص: ${response.statusCode}';

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: errorMessage,
      );
    } on DioException catch (e) {
      await ApiLoggingService.logApiError(
        method: 'GET',
        url: ApiConfig.getExternalSafetyCheckUrl(checkId),
        error: e.message ?? e.toString(),
        statusCode: e.response?.statusCode,
        responseData: e.response?.data,
        serviceName: 'external_safety',
      );

      debugPrint('❌ [ExternalSafety] DioException getting check details:');
      debugPrint('   Status code: ${e.response?.statusCode}');
      debugPrint('   Response data: ${e.response?.data}');
      debugPrint('   Error message: ${e.message}');

      String errorMessage = 'حدث خطأ أثناء جلب تفاصيل الفحص';

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        if (statusCode == 401) {
          errorMessage = 'يرجى تسجيل الدخول مرة أخرى';
        } else if (statusCode == 404) {
          errorMessage = 'الفحص غير موجود';
        } else if (statusCode == 500) {
          errorMessage = 'خطأ في الخادم. يرجى المحاولة لاحقاً';
        } else {
          errorMessage = 'فشل جلب تفاصيل الفحص: $statusCode';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت';
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: errorMessage,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [ExternalSafety] Unexpected error getting check details: $e');
      debugPrint('❌ [ExternalSafety] Stack trace: $stackTrace');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  /// ============================================
  /// 🚗 قائمة السيارات - Get Vehicles List
  /// GET /api/v1/external-safety/vehicles
  /// ============================================
  static Future<ApiResponse<List<Map<String, dynamic>>>> getVehiclesList() async {
    try {
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: 'يرجى تسجيل الدخول أولاً',
        );
      }

      debugPrint('📤 [ExternalSafety] Getting vehicles list');
      debugPrint('📤 [ExternalSafety] URL: ${ApiConfig.getExternalSafetyVehiclesUrl()}');

      // استخدام Dio جديد مع nuzum.site
      final uploadDio = Dio(BaseOptions(
        baseUrl: ApiConfig.nuzumBaseUrl,
        connectTimeout: ApiConfig.timeoutDuration,
        receiveTimeout: ApiConfig.timeoutDuration,
      ));

      final vehiclesUrl = ApiConfig.getExternalSafetyVehiclesUrl();
      final startTime = DateTime.now();
      
      await ApiLoggingService.logApiRequest(
        method: 'GET',
        url: vehiclesUrl,
        headers: {
          'Authorization': 'Bearer [REDACTED]',
        },
        serviceName: 'external_safety',
      );

      final response = await uploadDio.get(
        ApiConfig.externalSafetyVehiclesPath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final duration = DateTime.now().difference(startTime);
      
      await ApiLoggingService.logApiResponse(
        method: 'GET',
        url: vehiclesUrl,
        statusCode: response.statusCode ?? 0,
        headers: response.headers.map,
        responseData: response.data,
        duration: duration,
        serviceName: 'external_safety',
      );

      debugPrint('📤 [ExternalSafety] Response status: ${response.statusCode}');
      debugPrint('📤 [ExternalSafety] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          final vehicles = (data['data'] ?? data['vehicles'] ?? []) as List;
          debugPrint('✅ [ExternalSafety] Vehicles list retrieved successfully');
          debugPrint('   Vehicles count: ${vehicles.length}');

          return ApiResponse<List<Map<String, dynamic>>>(
            success: true,
            data: vehicles.map((v) => v as Map<String, dynamic>).toList(),
            message: data['message'] ?? 'تم جلب قائمة السيارات بنجاح',
          );
        } else {
          return ApiResponse<List<Map<String, dynamic>>>(
            success: false,
            message: data['message'] ?? data['error'] ?? 'فشل جلب قائمة السيارات',
          );
        }
      }

      final errorMessage = response.data is Map<String, dynamic>
          ? (response.data['error'] ?? response.data['message'] ?? 'فشل جلب قائمة السيارات')
          : 'فشل جلب قائمة السيارات: ${response.statusCode}';

      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: errorMessage,
      );
    } on DioException catch (e) {
      debugPrint('❌ [ExternalSafety] DioException getting vehicles list:');
      debugPrint('   Status code: ${e.response?.statusCode}');
      debugPrint('   Response data: ${e.response?.data}');
      debugPrint('   Error message: ${e.message}');

      String errorMessage = 'حدث خطأ أثناء جلب قائمة السيارات';

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        if (statusCode == 401) {
          errorMessage = 'يرجى تسجيل الدخول مرة أخرى';
        } else if (statusCode == 500) {
          errorMessage = 'خطأ في الخادم. يرجى المحاولة لاحقاً';
        } else {
          errorMessage = 'فشل جلب قائمة السيارات: $statusCode';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت';
      }

      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: errorMessage,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [ExternalSafety] Unexpected error getting vehicles list: $e');
      debugPrint('❌ [ExternalSafety] Stack trace: $stackTrace');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  /// ============================================
  /// 🖼️ ضغط الصورة - Compress Image
  /// ============================================
  static Future<File> _compressImage(File file) async {
    try {
      final fileSize = await file.length();
      // إذا كانت الصورة أقل من 2MB، لا حاجة للضغط
      if (fileSize < 2 * 1024 * 1024) {
        return file;
      }

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.absolute.path}_compressed.jpg',
        quality: 85,
        minWidth: 1920,
        minHeight: 1920,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        final compressedSize = await compressedFile.length();
        debugPrint('📦 [ExternalSafety] Image compressed: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB → ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
        return compressedFile;
      }

      return file;
    } catch (e) {
      debugPrint('⚠️ [ExternalSafety] Image compression failed, using original: $e');
      return file;
    }
  }
}

