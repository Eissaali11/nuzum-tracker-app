import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

/// ============================================
/// 📝 خدمة تسجيل طلبات API - API Logging Service
/// ============================================
/// تسجيل جميع طلبات API والبيانات المرسلة والمستقبلة
/// وإرسالها إلى السيرفر للتحليل والمراقبة
/// ============================================
class ApiLoggingService {
  static const String _logsKey = 'api_logs_queue';
  static const int _maxLogsInMemory = 100; // أقصى عدد سجلات في الذاكرة
  static const int _batchSize = 50; // عدد السجلات المرسلة في كل مرة
  static const Duration _sendInterval = Duration(minutes: 5); // إرسال كل 5 دقائق

  /// ============================================
  /// 📝 تسجيل طلب API
  /// ============================================
  static Future<void> logApiRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    String? serviceName,
  }) async {
    try {
      final logEntry = {
        'type': 'request',
        'timestamp': DateTime.now().toIso8601String(),
        'method': method,
        'url': url,
        'headers': _sanitizeHeaders(headers),
        'body': _sanitizeBody(body),
        'query_parameters': queryParameters,
        'service_name': serviceName ?? 'unknown',
        'device_info': await _getDeviceInfo(),
      };

      await _addLogToQueue(logEntry);
      debugPrint('📝 [APILog] Request logged: $method $url');
    } catch (e) {
      debugPrint('❌ [APILog] Error logging request: $e');
    }
  }

  /// ============================================
  /// 📝 تسجيل استجابة API
  /// ============================================
  static Future<void> logApiResponse({
    required String method,
    required String url,
    required int statusCode,
    Map<String, dynamic>? headers,
    dynamic responseData,
    String? error,
    Duration? duration,
    String? serviceName,
  }) async {
    try {
      final logEntry = {
        'type': 'response',
        'timestamp': DateTime.now().toIso8601String(),
        'method': method,
        'url': url,
        'status_code': statusCode,
        'headers': _sanitizeHeaders(headers),
        'response_data': _sanitizeResponse(responseData),
        'error': error,
        'duration_ms': duration?.inMilliseconds,
        'service_name': serviceName ?? 'unknown',
        'device_info': await _getDeviceInfo(),
      };

      await _addLogToQueue(logEntry);
      debugPrint('📝 [APILog] Response logged: $method $url - $statusCode');
    } catch (e) {
      debugPrint('❌ [APILog] Error logging response: $e');
    }
  }

  /// ============================================
  /// 📝 تسجيل خطأ API
  /// ============================================
  static Future<void> logApiError({
    required String method,
    required String url,
    required String error,
    int? statusCode,
    dynamic responseData,
    String? serviceName,
  }) async {
    try {
      final logEntry = {
        'type': 'error',
        'timestamp': DateTime.now().toIso8601String(),
        'method': method,
        'url': url,
        'status_code': statusCode,
        'error': error,
        'response_data': _sanitizeResponse(responseData),
        'service_name': serviceName ?? 'unknown',
        'device_info': await _getDeviceInfo(),
      };

      await _addLogToQueue(logEntry);
      debugPrint('📝 [APILog] Error logged: $method $url - $error');
    } catch (e) {
      debugPrint('❌ [APILog] Error logging error: $e');
    }
  }

  /// ============================================
  /// 💾 إضافة سجل إلى قائمة الانتظار
  /// ============================================
  static Future<void> _addLogToQueue(Map<String, dynamic> logEntry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_logsKey);
      
      List<Map<String, dynamic>> logs = [];
      if (logsJson != null && logsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(logsJson) as List<dynamic>;
          logs = decoded.map((e) => e as Map<String, dynamic>).toList();
        } catch (e) {
          debugPrint('⚠️ [APILog] Error parsing logs: $e');
          logs = [];
        }
      }

      logs.add(logEntry);

      // الاحتفاظ بآخر N سجل فقط
      if (logs.length > _maxLogsInMemory) {
        logs = logs.sublist(logs.length - _maxLogsInMemory);
      }

      await prefs.setString(_logsKey, jsonEncode(logs));
    } catch (e) {
      debugPrint('❌ [APILog] Error adding log to queue: $e');
    }
  }

  /// ============================================
  /// 📤 إرسال السجلات إلى السيرفر
  /// ============================================
  static Future<bool> sendLogsToServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_logsKey);
      
      if (logsJson == null || logsJson.isEmpty) {
        debugPrint('ℹ️ [APILog] No logs to send');
        return true;
      }

      final decoded = jsonDecode(logsJson) as List<dynamic>;
      final logs = decoded.map((e) => e as Map<String, dynamic>).toList();

      if (logs.isEmpty) {
        return true;
      }

      // إرسال السجلات على دفعات
      int sentCount = 0;
      for (int i = 0; i < logs.length; i += _batchSize) {
        final batch = logs.sublist(
          i,
          i + _batchSize > logs.length ? logs.length : i + _batchSize,
        );

        final success = await _sendBatch(batch);
        if (success) {
          sentCount += batch.length;
        } else {
          debugPrint('⚠️ [APILog] Failed to send batch starting at index $i');
          break; // إذا فشل إرسال دفعة، نتوقف
        }
      }

      // حذف السجلات المرسلة
      if (sentCount > 0) {
        final remainingLogs = logs.sublist(sentCount);
        if (remainingLogs.isEmpty) {
          await prefs.remove(_logsKey);
        } else {
          await prefs.setString(_logsKey, jsonEncode(remainingLogs));
        }
        debugPrint('✅ [APILog] Sent $sentCount logs to server');
      }

      return sentCount == logs.length;
    } catch (e) {
      debugPrint('❌ [APILog] Error sending logs to server: $e');
      return false;
    }
  }

  /// ============================================
  /// 📤 إرسال دفعة من السجلات
  /// ============================================
  static Future<bool> _sendBatch(List<Map<String, dynamic>> batch) async {
    try {
      final token = await AuthService.getValidToken();
      final jobNumber = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('jobNumber'));

      final payload = {
        'logs': batch,
        'job_number': jobNumber,
        'app_version': '1.0.0', // يمكن تحديثه لاحقاً
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final url = '${ApiConfig.baseUrl}/api/v1/logs/api-requests';
      debugPrint('📤 [APILog] Sending ${batch.length} logs to: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [APILog] Logs sent successfully');
        return true;
      } else {
        debugPrint('❌ [APILog] Failed to send logs: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [APILog] Error sending batch: $e');
      return false;
    }
  }

  /// ============================================
  /// 🔍 الحصول على معلومات الجهاز
  /// ============================================
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'platform': Platform.operatingSystem,
        'platform_version': Platform.operatingSystemVersion,
        'job_number': prefs.getString('jobNumber'),
        'employee_id': prefs.getString('employee_id'),
      };
    } catch (e) {
      return {
        'platform': Platform.operatingSystem,
        'error': e.toString(),
      };
    }
  }

  /// ============================================
  /// 🧹 تنظيف Headers (إزالة معلومات حساسة)
  /// ============================================
  static Map<String, dynamic>? _sanitizeHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return null;

    final sanitized = Map<String, dynamic>.from(headers);
    
    // إخفاء Token ولكن الاحتفاظ بمعلوماته
    if (sanitized.containsKey('Authorization')) {
      final auth = sanitized['Authorization'] as String?;
      if (auth != null && auth.startsWith('Bearer ')) {
        sanitized['Authorization'] = 'Bearer ***${auth.substring(auth.length - 4)}';
      }
    }

    return sanitized;
  }

  /// ============================================
  /// 🧹 تنظيف Body (إزالة معلومات حساسة)
  /// ============================================
  static dynamic _sanitizeBody(dynamic body) {
    if (body == null) return null;

    try {
      if (body is Map<String, dynamic>) {
        final sanitized = Map<String, dynamic>.from(body);
        
        // إخفاء كلمات المرور والمفاتيح الحساسة
        final sensitiveKeys = ['password', 'national_id', 'api_key', 'secret'];
        for (final key in sensitiveKeys) {
          if (sanitized.containsKey(key)) {
            sanitized[key] = '***HIDDEN***';
          }
        }

        return sanitized;
      } else if (body is String) {
        // محاولة تحليل JSON
        try {
          final parsed = jsonDecode(body) as Map<String, dynamic>;
          return _sanitizeBody(parsed);
        } catch (e) {
          // إذا لم يكن JSON، إرجاع النص كما هو (محدود الطول)
          return body.length > 1000 ? '${body.substring(0, 1000)}...' : body;
        }
      } else {
        return body.toString();
      }
    } catch (e) {
      return body.toString();
    }
  }

  /// ============================================
  /// 🧹 تنظيف Response (إزالة معلومات حساسة)
  /// ============================================
  static dynamic _sanitizeResponse(dynamic response) {
    if (response == null) return null;

    try {
      if (response is Map<String, dynamic>) {
        final sanitized = Map<String, dynamic>.from(response);
        
        // إخفاء Token في الاستجابة
        if (sanitized.containsKey('token')) {
          final token = sanitized['token'] as String?;
          if (token != null && token.length > 8) {
            sanitized['token'] = '${token.substring(0, 4)}***${token.substring(token.length - 4)}';
          }
        }

        // تقليل حجم البيانات الكبيرة
        if (sanitized.containsKey('data') && sanitized['data'] is List) {
          final dataList = sanitized['data'] as List;
          if (dataList.length > 10) {
            sanitized['data'] = [
              ...dataList.take(10),
              {'_truncated': '... ${dataList.length - 10} more items'}
            ];
          }
        }

        return sanitized;
      } else if (response is String) {
        // تقليل حجم النص الطويل
        if (response.length > 2000) {
          return '${response.substring(0, 2000)}... [truncated ${response.length - 2000} chars]';
        }
        return response;
      } else {
        return response.toString();
      }
    } catch (e) {
      return response.toString();
    }
  }

  /// ============================================
  /// 📊 الحصول على عدد السجلات المعلقة
  /// ============================================
  static Future<int> getPendingLogsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_logsKey);
      
      if (logsJson == null || logsJson.isEmpty) {
        return 0;
      }

      final decoded = jsonDecode(logsJson) as List<dynamic>;
      return decoded.length;
    } catch (e) {
      debugPrint('❌ [APILog] Error getting pending logs count: $e');
      return 0;
    }
  }

  /// ============================================
  /// 🗑️ حذف جميع السجلات
  /// ============================================
  static Future<void> clearAllLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logsKey);
      debugPrint('✅ [APILog] All logs cleared');
    } catch (e) {
      debugPrint('❌ [APILog] Error clearing logs: $e');
    }
  }

  /// ============================================
  /// ⏰ بدء إرسال دوري للسجلات
  /// ============================================
  static void startPeriodicSending() {
    // إرسال السجلات كل 5 دقائق
    Future.delayed(_sendInterval, () async {
      await sendLogsToServer();
      startPeriodicSending(); // إعادة التشغيل
    });
  }
}

