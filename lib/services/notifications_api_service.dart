import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';

/// ============================================
/// 🔔 خدمة API للإشعارات - Notifications API Service
/// ============================================
class NotificationsApiService {
  static Dio get dio => AuthService.dio;

  /// ============================================
  /// 📬 جلب الإشعارات - Get Notifications
  /// ============================================
  static Future<Map<String, dynamic>> getNotifications({
    String? status, // 'all' or 'unread'
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }

      // محاولة المسار الأساسي
      try {
        debugPrint('🔄 [NotificationsAPI] Trying primary URL: ${ApiConfig.baseUrl}${ApiConfig.notificationsPath}');
        final response = await dio.get(
          ApiConfig.notificationsPath,
          queryParameters: queryParams,
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            try {
              final notificationsList = data['notifications'] as List? ?? data['data'] as List? ?? [];
              final notifications = notificationsList
                  .map(
                    (item) {
                      try {
                        return Notification.fromJson(item as Map<String, dynamic>);
                      } catch (e) {
                        debugPrint('⚠️ [NotificationsAPI] Error parsing notification: $e');
                        debugPrint('📋 [NotificationsAPI] Notification data: $item');
                        return null;
                      }
                    },
                  )
                  .whereType<Notification>()
                  .toList();

              return {
                'success': true,
                'data': notifications,
                'unread_count': data['unread_count'] as int? ?? 
                               data['unreadCount'] as int? ?? 
                               notifications.where((n) => !n.isRead).length,
              };
            } catch (e) {
              debugPrint('❌ [NotificationsAPI] Error parsing notifications: $e');
              debugPrint('📋 [NotificationsAPI] Response data: $data');
              return {
                'success': false,
                'error': 'خطأ في تحليل بيانات الإشعارات',
              };
            }
          }
        }

        // إذا كان الخطأ 404 أو 503، جرب المسار البديل
        if (response.statusCode == 404 || response.statusCode == 503) {
          debugPrint('⚠️ [NotificationsAPI] Primary URL returned ${response.statusCode}, trying backup...');
          return await _tryBackupNotifications(queryParams);
        }

        return {
          'success': false,
          'error': 'فشل جلب الإشعارات. يرجى التحقق من إعدادات API',
        };
      } on DioException catch (e) {
        // إذا كان الخطأ 404 أو 503، جرب المسار البديل
        if (e.response?.statusCode == 404 || e.response?.statusCode == 503) {
          debugPrint('⚠️ [NotificationsAPI] Primary URL failed with ${e.response?.statusCode}, trying backup...');
          return await _tryBackupNotifications(queryParams);
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ [NotificationsAPI] Get notifications error: $e');
      String errorMsg = 'حدث خطأ في جلب الإشعارات';
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
      return {'success': false, 'error': errorMsg};
    }
  }

  /// محاولة جلب الإشعارات من المسار البديل
  static Future<Map<String, dynamic>> _tryBackupNotifications(
    Map<String, dynamic> queryParams,
  ) async {
    try {
      final backupUrl = '${ApiConfig.backupDomain}${ApiConfig.notificationsPath}';
      debugPrint('🔄 [NotificationsAPI] Trying backup URL: $backupUrl');

      // استخدام Dio جديد مع baseUrl فارغ للسماح بـ URL كامل
      final backupDio = Dio(
        BaseOptions(
          baseUrl: '',
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      // إضافة Token
      final token = await AuthService.getToken();
      if (token != null) {
        backupDio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await backupDio.get(
        backupUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          try {
            final notificationsList = data['notifications'] as List? ?? data['data'] as List? ?? [];
            final notifications = notificationsList
                .map(
                  (item) {
                    try {
                      return Notification.fromJson(item as Map<String, dynamic>);
                    } catch (e) {
                      debugPrint('⚠️ [NotificationsAPI] Error parsing backup notification: $e');
                      return null;
                    }
                  },
                )
                .whereType<Notification>()
                .toList();

            return {
              'success': true,
              'data': notifications,
              'unread_count': data['unread_count'] as int? ?? 
                             data['unreadCount'] as int? ?? 
                             notifications.where((n) => !n.isRead).length,
            };
          } catch (e) {
            debugPrint('❌ [NotificationsAPI] Error parsing backup notifications: $e');
            return {
              'success': false,
              'error': 'خطأ في تحليل بيانات الإشعارات من المسار البديل',
            };
          }
        }
      }

      return {
        'success': false,
        'error': 'فشل جلب الإشعارات من المسار البديل. يرجى التحقق من إعدادات API أو الاتصال بالإنترنت',
      };
    } catch (e) {
      debugPrint('❌ [NotificationsAPI] Backup URL also failed: $e');
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
  /// ✅ تحديد الإشعار كمقروء - Mark as Read
  /// ============================================
  static Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      final response = await dio.put(
        '${ApiConfig.notificationsPath}/$notificationId/read', // PUT /api/v1/notifications/{id}/read
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'تم تحديد الإشعار كمقروء',
          };
        }
      }

      return {'success': false, 'error': 'فشل تحديث الإشعار'};
    } catch (e) {
      debugPrint('❌ [NotificationsAPI] Mark as read error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// ✅ تحديد جميع الإشعارات كمقروءة - Mark All as Read
  /// ============================================
  static Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final response = await dio.put(
        ApiConfig.markAllNotificationsReadPath, // PUT /api/v1/notifications/mark-all-read ✅ متوفر الآن
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'تم تحديد جميع الإشعارات كمقروءة',
          };
        }
      }

      return {'success': false, 'error': 'فشل تحديث الإشعارات'};
    } catch (e) {
      debugPrint('❌ [NotificationsAPI] Mark all as read error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }
}
