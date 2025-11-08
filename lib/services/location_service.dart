import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================
/// 🔒 تجاوز SSL - HTTP Overrides
/// ============================================
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

/// ============================================
/// 🔧 إعدادات الربط - API Configuration
/// ============================================
class ApiConfig {
  // الدومين الأساسي (URL الصحيح الذي يعمل)
  static const String primaryDomain = 'https://d72f2aef-918c-4148-9723-15870f8c7cf6-00-2c1ygyxvqoldk.riker.replit.dev';

  // الدومين البديل (احتياطي)
  static const String backupDomain = 'https://eissahr.replit.app';

  // مفتاح API
  static const String apiKey = 'test_location_key_2025';

  // مسار API
  static const String apiPath = '/api/external/employee-location';
  
  // مسار API لحالة التوقف
  static const String statusPath = '/api/external/employee-status';

  // الحصول على URL الكامل
  static String getPrimaryUrl() => '$primaryDomain$apiPath';
  static String getBackupUrl() => '$backupDomain$apiPath';
  static String getStatusUrl() => '$primaryDomain$statusPath';
  static String getStatusBackupUrl() => '$backupDomain$statusPath';
}

/// ============================================
/// 📦 نموذج الاستجابة - Response Model
/// ============================================
class LocationResponse {
  final bool success;
  final String? message;
  final LocationData? data;
  final String? error;

  LocationResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory LocationResponse.success(LocationData data, String message) {
    return LocationResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  factory LocationResponse.error(String error) {
    return LocationResponse(
      success: false,
      error: error,
    );
  }
}

/// ============================================
/// 📍 بيانات الموقع - Location Data
/// ============================================
class LocationData {
  final String jobNumber;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime recordedAt;
  final String? employeeName;
  final String? employeeId;

  LocationData({
    required this.jobNumber,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.recordedAt,
    this.employeeName,
    this.employeeId,
  });

  Map<String, dynamic> toJson({String? apiKey}) {
    return {
      'api_key': apiKey ?? ApiConfig.apiKey,
      'job_number': jobNumber,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'recorded_at': DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(recordedAt.toUtc()),
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      jobNumber: json['job_number'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] ?? DateTime.now().toIso8601String()),
      employeeName: json['employee_name'],
      employeeId: json['employee_id'],
    );
  }
}

/// ============================================
/// 💾 الموقع المعلق - Pending Location
/// ============================================
class PendingLocation {
  final String id;
  final LocationData locationData;
  final DateTime createdAt;
  final int retryCount;

  PendingLocation({
    required this.id,
    required this.locationData,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_data': locationData.toJson(),
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  factory PendingLocation.fromJson(Map<String, dynamic> json) {
    return PendingLocation(
      id: json['id'],
      locationData: LocationData.fromJson(json['location_data']),
      createdAt: DateTime.parse(json['created_at']),
      retryCount: json['retry_count'] ?? 0,
    );
  }
}

/// ============================================
/// 🚀 خدمة API للموقع - Location API Service
/// ============================================
class LocationApiService {
  static const String _pendingLocationsKey = 'pending_locations';
  static const int _maxRetries = 3;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  /// ============================================
  /// ✅ اختبار الاتصال - Test Connection
  /// ============================================
  static Future<bool> testConnection({bool useBackup = false}) async {
    try {
      final url = useBackup ? ApiConfig.getBackupUrl() : ApiConfig.getPrimaryUrl();
      debugPrint('🔍 [TEST] Testing connection to: $url');

      final response = await http
          .get(Uri.parse(url))
          .timeout(_timeoutDuration);

      final success = response.statusCode == 200 || response.statusCode == 404;
      debugPrint(success
          ? '✅ [TEST] Connection successful!'
          : '❌ [TEST] Connection failed: ${response.statusCode}');

      return success;
    } catch (e) {
      debugPrint('❌ [TEST] Connection error: $e');
      return false;
    }
  }

  /// ============================================
  /// 📤 إرسال موقع - Send Location
  /// ============================================
  static Future<LocationResponse> sendLocation({
    required String jobNumber,
    required double latitude,
    required double longitude,
    double? accuracy,
    bool useBackup = false,
    String? apiKey,
  }) async {
    try {
      final locationData = LocationData(
        jobNumber: jobNumber,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        recordedAt: DateTime.now(),
      );

      final url = useBackup ? ApiConfig.getBackupUrl() : ApiConfig.getPrimaryUrl();
      debugPrint('📤 [SEND] Sending location to: $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(locationData.toJson(apiKey: apiKey)),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              debugPrint('⏱️ [SEND] Request timeout');
              throw TimeoutException('Request timeout', _timeoutDuration);
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final successData = LocationData.fromJson(responseData);
          debugPrint('✅ [SEND] Location sent successfully!');
          return LocationResponse.success(
            successData,
            'تم إرسال الموقع بنجاح',
          );
        } catch (e) {
          debugPrint('⚠️ [SEND] Success but failed to parse response: $e');
          return LocationResponse.success(
            locationData,
            'تم إرسال الموقع بنجاح',
          );
        }
      } else {
        final error = 'فشل الإرسال: ${response.statusCode} - ${response.body}';
        debugPrint('❌ [SEND] $error');
        return LocationResponse.error(error);
      }
    } catch (e) {
      final error = 'خطأ في الإرسال: $e';
      debugPrint('❌ [SEND] $error');
      return LocationResponse.error(error);
    }
  }

  /// ============================================
  /// 🔄 إرسال مع إعادة محاولة - Send with Retry
  /// ============================================
  static Future<LocationResponse> sendLocationWithRetry({
    required String jobNumber,
    required double latitude,
    required double longitude,
    double? accuracy,
    String? apiKey,
  }) async {
    // المحاولة الأولى - الدومين الأساسي
    var response = await sendLocation(
      jobNumber: jobNumber,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      useBackup: false,
      apiKey: apiKey,
    );

    if (response.success) {
      return response;
    }

    debugPrint('🔄 [RETRY] Primary domain failed, trying backup...');

    // المحاولة الثانية - الدومين البديل
    response = await sendLocation(
      jobNumber: jobNumber,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      useBackup: true,
      apiKey: apiKey,
    );

    if (response.success) {
      return response;
    }

    // فشل الإرسال - حفظ محلياً
    debugPrint('💾 [SAVE] Saving location locally for retry...');
    await savePendingLocation(
      jobNumber: jobNumber,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );

    return LocationResponse.error('فشل الإرسال، تم الحفظ محلياً لإعادة المحاولة لاحقاً');
  }

  /// ============================================
  /// 💾 حفظ موقع معلق - Save Pending Location
  /// ============================================
  static Future<void> savePendingLocation({
    required String jobNumber,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingList = await getPendingLocations();

      final pendingLocation = PendingLocation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        locationData: LocationData(
          jobNumber: jobNumber,
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          recordedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      pendingList.add(pendingLocation);

      final jsonList = pendingList.map((p) => p.toJson()).toList();
      await prefs.setString(_pendingLocationsKey, jsonEncode(jsonList));

      debugPrint('✅ [SAVE] Location saved locally (ID: ${pendingLocation.id})');
    } catch (e) {
      debugPrint('❌ [SAVE] Error saving location: $e');
    }
  }

  /// ============================================
  /// 📋 الحصول على المواقع المعلقة - Get Pending Locations
  /// ============================================
  static Future<List<PendingLocation>> getPendingLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pendingLocationsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => PendingLocation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ [GET] Error getting pending locations: $e');
      return [];
    }
  }

  /// ============================================
  /// 🔢 عدد المواقع المعلقة - Get Pending Count
  /// ============================================
  static Future<int> getPendingCount() async {
    final pendingList = await getPendingLocations();
    return pendingList.length;
  }

  /// ============================================
  /// 🔁 إعادة إرسال المواقع المعلقة - Retry Pending Locations
  /// ============================================
  static Future<Map<String, dynamic>> retryPendingLocations() async {
    final pendingList = await getPendingLocations();
    if (pendingList.isEmpty) {
      debugPrint('📋 [RETRY] No pending locations to retry');
      return {
        'success': true,
        'sent': 0,
        'failed': 0,
        'message': 'لا توجد مواقع معلقة',
      };
    }

    debugPrint('🔄 [RETRY] Retrying ${pendingList.length} pending locations...');

    int sentCount = 0;
    int failedCount = 0;
    final List<PendingLocation> stillPending = [];

    for (final pending in pendingList) {
      if (pending.retryCount >= _maxRetries) {
        debugPrint('⏭️ [RETRY] Skipping ${pending.id} (max retries reached)');
        failedCount++;
        continue;
      }

      final response = await sendLocation(
        jobNumber: pending.locationData.jobNumber,
        latitude: pending.locationData.latitude,
        longitude: pending.locationData.longitude,
        accuracy: pending.locationData.accuracy,
        useBackup: false,
      );

      if (response.success) {
        sentCount++;
        debugPrint('✅ [RETRY] Successfully sent ${pending.id}');
      } else {
        // محاولة الدومين البديل
        final backupResponse = await sendLocation(
          jobNumber: pending.locationData.jobNumber,
          latitude: pending.locationData.latitude,
          longitude: pending.locationData.longitude,
          accuracy: pending.locationData.accuracy,
          useBackup: true,
        );

        if (backupResponse.success) {
          sentCount++;
          debugPrint('✅ [RETRY] Successfully sent ${pending.id} (backup)');
        } else {
          // زيادة عدد المحاولات
          final updatedPending = PendingLocation(
            id: pending.id,
            locationData: pending.locationData,
            createdAt: pending.createdAt,
            retryCount: pending.retryCount + 1,
          );
          stillPending.add(updatedPending);
          failedCount++;
          debugPrint('❌ [RETRY] Failed to send ${pending.id} (retry ${updatedPending.retryCount}/$_maxRetries)');
        }
      }
    }

    // حفظ المواقع المعلقة المتبقية
    if (stillPending.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonList = stillPending.map((p) => p.toJson()).toList();
        await prefs.setString(_pendingLocationsKey, jsonEncode(jsonList));
      } catch (e) {
        debugPrint('❌ [RETRY] Error saving remaining pending locations: $e');
      }
    } else {
      // حذف جميع المواقع المعلقة إذا تم إرسالها جميعاً
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_pendingLocationsKey);
      } catch (e) {
        debugPrint('❌ [RETRY] Error clearing pending locations: $e');
      }
    }

    final result = {
      'success': true,
      'sent': sentCount,
      'failed': failedCount,
      'total': pendingList.length,
      'message': 'تم إرسال $sentCount من ${pendingList.length} موقع',
    };

    debugPrint('📊 [RETRY] Result: $result');
    return result;
  }

  /// ============================================
  /// 🗑️ حذف موقع معلق - Delete Pending Location
  /// ============================================
  static Future<bool> deletePendingLocation(String id) async {
    try {
      final pendingList = await getPendingLocations();
      pendingList.removeWhere((p) => p.id == id);

      final prefs = await SharedPreferences.getInstance();
      if (pendingList.isEmpty) {
        await prefs.remove(_pendingLocationsKey);
      } else {
        final jsonList = pendingList.map((p) => p.toJson()).toList();
        await prefs.setString(_pendingLocationsKey, jsonEncode(jsonList));
      }

      debugPrint('✅ [DELETE] Pending location deleted: $id');
      return true;
    } catch (e) {
      debugPrint('❌ [DELETE] Error deleting pending location: $e');
      return false;
    }
  }

  /// ============================================
  /// 🗑️ حذف جميع المواقع المعلقة - Clear All Pending
  /// ============================================
  static Future<bool> clearAllPendingLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingLocationsKey);
      debugPrint('✅ [CLEAR] All pending locations cleared');
      return true;
    } catch (e) {
      debugPrint('❌ [CLEAR] Error clearing pending locations: $e');
      return false;
    }
  }

  /// ============================================
  /// 🛑 إرسال حالة التوقف - Send Stop Status
  /// ============================================
  static Future<bool> sendStopStatus({
    required String jobNumber,
    String? apiKey,
    bool useBackup = false,
  }) async {
    try {
      final url = useBackup ? ApiConfig.getStatusBackupUrl() : ApiConfig.getStatusUrl();
      debugPrint('🛑 [STOP] Sending stop status to: $url');

      final body = {
        'api_key': apiKey ?? ApiConfig.apiKey,
        'job_number': jobNumber,
        'status': 'stopped',
        'stopped_at': DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc()),
      };

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(body),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              debugPrint('⏱️ [STOP] Request timeout');
              throw TimeoutException('Request timeout', _timeoutDuration);
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [STOP] Stop status sent successfully!');
        return true;
      } else {
        debugPrint('❌ [STOP] Failed to send stop status: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [STOP] Error sending stop status: $e');
      return false;
    }
  }

  /// ============================================
  /// 🛑 إرسال حالة التوقف مع إعادة محاولة - Send Stop Status with Retry
  /// ============================================
  static Future<bool> sendStopStatusWithRetry({
    required String jobNumber,
    String? apiKey,
  }) async {
    // المحاولة الأولى - الدومين الأساسي
    var success = await sendStopStatus(
      jobNumber: jobNumber,
      apiKey: apiKey,
      useBackup: false,
    );

    if (success) {
      return true;
    }

    debugPrint('🔄 [STOP] Primary domain failed, trying backup...');

    // المحاولة الثانية - الدومين البديل
    success = await sendStopStatus(
      jobNumber: jobNumber,
      apiKey: apiKey,
      useBackup: true,
    );

    return success;
  }
}

/// ============================================
/// 📝 أمثلة عملية - Examples
/// ============================================

/// مثال 1: إرسال موقع بسيط
/// Simple location send example
Future<void> example1_SimpleSend() async {
  final response = await LocationApiService.sendLocation(
    jobNumber: 'EMP001',
    latitude: 24.7136,
    longitude: 46.6753,
    accuracy: 10.5,
  );

  if (response.success) {
    print('✅ تم الإرسال: ${response.data?.employeeName}');
  } else {
    print('❌ فشل الإرسال: ${response.error}');
  }
}

/// مثال 2: إرسال مع إعادة محاولة تلقائية
/// Send with automatic retry
Future<void> example2_SendWithRetry() async {
  final response = await LocationApiService.sendLocationWithRetry(
    jobNumber: 'EMP002',
    latitude: 24.7136,
    longitude: 46.6753,
    accuracy: 15.0,
  );

  if (response.success) {
    print('✅ تم الإرسال بنجاح!');
  } else {
    print('⚠️ ${response.error}');
  }
}

/// مثال 3: اختبار الاتصال
/// Test connection example
Future<void> example3_TestConnection() async {
  // اختبار الدومين الأساسي
  final primaryOk = await LocationApiService.testConnection(useBackup: false);
  print('الدومين الأساسي: ${primaryOk ? "✅ متصل" : "❌ غير متصل"}');

  // اختبار الدومين البديل
  final backupOk = await LocationApiService.testConnection(useBackup: true);
  print('الدومين البديل: ${backupOk ? "✅ متصل" : "❌ غير متصل"}');
}

/// مثال 4: إعادة إرسال المواقع المعلقة
/// Retry pending locations example
Future<void> example4_RetryPending() async {
  final result = await LocationApiService.retryPendingLocations();
  print('📊 النتيجة:');
  print('  - تم الإرسال: ${result['sent']}');
  print('  - فشل: ${result['failed']}');
  print('  - المجموع: ${result['total']}');
  print('  - الرسالة: ${result['message']}');
}

/// مثال 5: فحص المواقع المعلقة
/// Check pending locations example
Future<void> example5_CheckPending() async {
  final count = await LocationApiService.getPendingCount();
  print('📋 عدد المواقع المعلقة: $count');

  if (count > 0) {
    final pendingList = await LocationApiService.getPendingLocations();
    print('📝 المواقع المعلقة:');
    for (final pending in pendingList) {
      print('  - ID: ${pending.id}');
      print('    Job: ${pending.locationData.jobNumber}');
      print('    Location: ${pending.locationData.latitude}, ${pending.locationData.longitude}');
      print('    Retries: ${pending.retryCount}');
      print('    Created: ${pending.createdAt}');
    }
  }
}

