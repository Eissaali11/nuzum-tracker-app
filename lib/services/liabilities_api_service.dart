import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/liability_model.dart';
import '../services/auth_service.dart';

/// ============================================
/// 💳 خدمة API للالتزامات المالية - Liabilities API Service
/// ============================================
class LiabilitiesApiService {
  static Dio get dio => AuthService.dio;

  /// ============================================
  /// 📊 جلب الالتزامات المالية - Get Liabilities
  /// ============================================
  static Future<Map<String, dynamic>> getLiabilities({
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      // محاولة المسار الأساسي
      try {
        debugPrint('🔄 [LiabilitiesAPI] Trying primary URL: ${ApiConfig.baseUrl}${ApiConfig.liabilitiesPath}');
        final response = await dio.get(
          ApiConfig.liabilitiesPath,
          queryParameters: queryParams,
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            try {
              final summary = LiabilitiesSummary.fromJson(data['data']);
              return {
                'success': true,
                'data': summary,
              };
            } catch (e) {
              debugPrint('❌ [LiabilitiesAPI] Error parsing liabilities: $e');
              return {
                'success': false,
                'error': 'خطأ في تحليل بيانات الالتزامات',
              };
            }
          }
        }

        // إذا كان الخطأ 404 أو 500 أو 503، جرب المسار البديل
        if (response.statusCode == 404 || response.statusCode == 500 || response.statusCode == 503) {
          debugPrint('⚠️ [LiabilitiesAPI] Primary URL returned ${response.statusCode}, trying backup...');
          return await _tryBackupLiabilities(queryParams);
        }

        return {
          'success': false,
          'error': 'فشل جلب الالتزامات. يرجى التحقق من إعدادات API',
        };
      } on DioException catch (e) {
        // إذا كان الخطأ 404 أو 500 أو 503، جرب المسار البديل
        final statusCode = e.response?.statusCode;
        if (statusCode == 404 || statusCode == 500 || statusCode == 503) {
          debugPrint('⚠️ [LiabilitiesAPI] Primary URL failed with $statusCode, trying backup...');
          return await _tryBackupLiabilities(queryParams);
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ [LiabilitiesAPI] Get liabilities error: $e');
      String errorMsg = 'حدث خطأ في جلب الالتزامات';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'فشل الاتصال بالخادم. يرجى التحقق من:\n1. اتصال الإنترنت\n2. إعدادات API في api_config.dart\n3. أن الخادم يعمل';
        } else if (e.response?.statusCode == 404) {
          errorMsg = 'المسار غير موجود (404). يرجى التحقق من إعدادات API في api_config.dart';
        } else if (e.response?.statusCode == 401) {
          errorMsg = 'غير مصرح (401). يرجى تسجيل الدخول مرة أخرى';
        }
      }
      return {
        'success': false,
        'error': errorMsg,
      };
    }
  }

  /// محاولة جلب الالتزامات من المسار البديل
  static Future<Map<String, dynamic>> _tryBackupLiabilities(
    Map<String, dynamic> queryParams,
  ) async {
    try {
      final backupUrl = '${ApiConfig.backupDomain}${ApiConfig.liabilitiesPath}';
      debugPrint('🔄 [LiabilitiesAPI] Trying backup URL: $backupUrl');

      // استخدام Dio جديد مع baseUrl فارغ للسماح بـ URL كامل
      // إضافة JWT token للطلبات البديلة
      final token = await AuthService.getToken();
      final backupDio = Dio(
        BaseOptions(
          baseUrl: '',
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await backupDio.get(
        backupUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          try {
            final summary = LiabilitiesSummary.fromJson(data['data']);
            return {
              'success': true,
              'data': summary,
            };
          } catch (e) {
            debugPrint('❌ [LiabilitiesAPI] Error parsing backup liabilities: $e');
            return {
              'success': false,
              'error': 'خطأ في تحليل بيانات الالتزامات من المسار البديل',
            };
          }
        }
      }

      return {
        'success': false,
        'error': 'فشل جلب الالتزامات من المسار البديل. يرجى التحقق من إعدادات API أو الاتصال بالإنترنت',
      };
    } catch (e) {
      debugPrint('❌ [LiabilitiesAPI] Backup URL also failed: $e');
      String errorMsg = 'فشل الاتصال بالخادم';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'فشل الاتصال بالخادم. يرجى التحقق من:\n1. اتصال الإنترنت\n2. إعدادات API في api_config.dart\n3. أن الخادم يعمل';
        } else if (e.response?.statusCode == 404) {
          errorMsg = 'المسار غير موجود (404). يرجى التحقق من إعدادات API في api_config.dart';
        } else if (e.response?.statusCode == 401) {
          errorMsg = 'غير مصرح (401). يرجى تسجيل الدخول مرة أخرى';
        }
      }
      return {
        'success': false,
        'error': errorMsg,
      };
    }
  }

  /// ============================================
  /// 💰 جلب الملخص المالي - Get Financial Summary
  /// ============================================
  static Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      // محاولة المسار الأساسي
      try {
        debugPrint('🔄 [LiabilitiesAPI] Trying primary URL: ${ApiConfig.baseUrl}${ApiConfig.financialSummaryPath}');
        final response = await dio.get(
          ApiConfig.financialSummaryPath, // GET /api/v1/employee/financial-summary ✅ متوفر الآن
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            try {
              final summary = FinancialSummary.fromJson(data['data'] ?? data);
              return {
                'success': true,
                'data': summary,
              };
            } catch (e) {
              debugPrint('❌ [LiabilitiesAPI] Error parsing financial summary: $e');
              debugPrint('📋 [LiabilitiesAPI] Response data: ${data['data'] ?? data}');
              return {
                'success': false,
                'error': 'خطأ في تحليل بيانات الملخص المالي',
              };
            }
          }
        }

        // إذا كان الخطأ 404 أو 500 أو 503، جرب المسار البديل
        if (response.statusCode == 404 || response.statusCode == 500 || response.statusCode == 503) {
          debugPrint('⚠️ [LiabilitiesAPI] Primary URL returned ${response.statusCode}, trying backup...');
          return await _tryBackupFinancialSummary();
        }

        return {
          'success': false,
          'error': 'فشل جلب الملخص المالي. يرجى التحقق من إعدادات API',
        };
      } on DioException catch (e) {
        // إذا كان الخطأ 404 أو 500 أو 503، جرب المسار البديل
        final statusCode = e.response?.statusCode;
        if (statusCode == 404 || statusCode == 500 || statusCode == 503) {
          debugPrint('⚠️ [LiabilitiesAPI] Primary URL failed with $statusCode, trying backup...');
          return await _tryBackupFinancialSummary();
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ [LiabilitiesAPI] Get financial summary error: $e');
      String errorMsg = 'حدث خطأ في جلب الملخص المالي';
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMsg = 'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت';
        } else if (e.response?.statusCode == 404) {
          errorMsg = 'المسار غير موجود (404). يرجى التحقق من إعدادات API';
        } else if (e.response?.statusCode == 401) {
          errorMsg = 'غير مصرح (401). يرجى تسجيل الدخول مرة أخرى';
        }
      }
      return {
        'success': false,
        'error': errorMsg,
      };
    }
  }

  /// محاولة جلب الملخص المالي من المسار البديل
  static Future<Map<String, dynamic>> _tryBackupFinancialSummary() async {
    try {
      final backupUrl = '${ApiConfig.backupDomain}${ApiConfig.financialSummaryPath}';
      debugPrint('🔄 [LiabilitiesAPI] Trying backup URL: $backupUrl');

      // استخدام Dio جديد مع baseUrl فارغ للسماح بـ URL كامل
      final token = await AuthService.getToken();
      final backupDio = Dio(
        BaseOptions(
          baseUrl: '',
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await backupDio.get(backupUrl);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          try {
            final summary = FinancialSummary.fromJson(data['data'] ?? data);
            return {
              'success': true,
              'data': summary,
            };
          } catch (e) {
            debugPrint('❌ [LiabilitiesAPI] Error parsing backup financial summary: $e');
            return {
              'success': false,
              'error': 'خطأ في تحليل بيانات الملخص المالي من المسار البديل',
            };
          }
        }
      }

      return {
        'success': false,
        'error': 'فشل جلب الملخص المالي من المسار البديل',
      };
    } catch (e) {
      debugPrint('❌ [LiabilitiesAPI] Backup financial summary also failed: $e');
      return {
        'success': false,
        'error': 'فشل الاتصال بالخادم',
      };
    }
  }
}

