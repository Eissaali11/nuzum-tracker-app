import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// ============================================
/// 🔧 خدمة API نظام نُظم - Nuzum API Service
/// ============================================
/// خدمة موحدة للتعامل مع API نظام نُظم v1
class NuzumApiService {
  static const String baseUrl = ApiConfig.baseUrl;
  final storage = const FlutterSecureStorage();

  /// ============================================
  /// 🔐 إدارة التوكن - Token Management
  /// ============================================
  
  /// حفظ التوكن
  Future<void> saveToken(String token) async {
    await storage.write(key: 'jwt_token', value: token);
  }

  /// جلب التوكن
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  /// حذف التوكن (تسجيل الخروج)
  Future<void> deleteToken() async {
    await storage.delete(key: 'jwt_token');
  }

  /// Headers مع التوكن
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// ============================================
  /// 🔑 تسجيل الدخول - Login
  /// ============================================
  Future<Map<String, dynamic>?> login(String employeeId, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.getV1LoginUrl()),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employee_id': employeeId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success']) {
          await saveToken(data['token']);
          return data;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [NuzumAPI] Login error: $e');
      return null;
    }
  }

  /// ============================================
  /// 📋 جلب قائمة الطلبات - Get Requests
  /// ============================================
  Future<List<dynamic>> getRequests({
    int page = 1,
    int perPage = 20,
    String? status,
    String? type,
  }) async {
    try {
      final headers = await getHeaders();
      
      String queryParams = '?page=$page&per_page=$perPage';
      if (status != null) queryParams += '&status=$status';
      if (type != null) queryParams += '&type=$type';

      final response = await http.get(
        Uri.parse('${ApiConfig.getV1RequestsUrl()}$queryParams'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['requests'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ [NuzumAPI] Get requests error: $e');
      return [];
    }
  }

  /// ============================================
  /// 📄 جلب تفاصيل طلب معين - Get Request Details
  /// ============================================
  Future<Map<String, dynamic>?> getRequestDetails(int requestId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.getV1RequestDetailsUrl(requestId)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['request'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ [NuzumAPI] Get request details error: $e');
      return null;
    }
  }

  /// ============================================
  /// ➕ إنشاء طلب جديد - Create Request
  /// ============================================
  Future<int?> createRequest(Map<String, dynamic> requestData) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.getV1RequestsUrl()),
        headers: headers,
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['request_id'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ [NuzumAPI] Create request error: $e');
      return null;
    }
  }

  /// ============================================
  /// 📊 جلب أنواع الطلبات - Get Request Types
  /// ============================================
  Future<List<dynamic>> getRequestTypes() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getV1RequestTypesUrl()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['types'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ [NuzumAPI] Get request types error: $e');
      return [];
    }
  }

  /// ============================================
  /// 📈 جلب الإحصائيات - Get Statistics
  /// ============================================
  Future<Map<String, dynamic>?> getStatistics() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.getV1RequestStatisticsUrl()),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['statistics'];
      }
      return null;
    } catch (e) {
      debugPrint('❌ [NuzumAPI] Get statistics error: $e');
      return null;
    }
  }

  /// ============================================
  /// 🚗 جلب السيارات - Get Vehicles
  /// ============================================
  Future<List<dynamic>> getVehicles() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.getV1VehiclesUrl()),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['vehicles'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ [NuzumAPI] Get vehicles error: $e');
      return [];
    }
  }

  /// ============================================
  /// 🔔 جلب الإشعارات - Get Notifications
  /// ============================================
  Future<Map<String, dynamic>?> getNotifications({
    bool unreadOnly = false,
    int page = 1,
  }) async {
    try {
      final headers = await getHeaders();
      final queryParams = '?unread_only=$unreadOnly&page=$page';
      
      final response = await http.get(
        Uri.parse('${ApiConfig.getV1NotificationsUrl()}$queryParams'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint('❌ [NuzumAPI] Get notifications error: $e');
      return null;
    }
  }

  /// ============================================
  /// ✅ تعليم إشعار كمقروء - Mark Notification as Read
  /// ============================================
  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.getV1NotificationReadUrl(notificationId)),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ [NuzumAPI] Mark notification error: $e');
      return false;
    }
  }
}

/// ============================================
/// 📤 خدمة رفع الملفات - File Upload Service
/// ============================================
class FileUploadService {
  static const String baseUrl = ApiConfig.baseUrl;
  final dio = Dio();
  final storage = const FlutterSecureStorage();

  /// رفع ملفات لطلب معين
  Future<Map<String, dynamic>?> uploadFiles(
    int requestId,
    List<File> files,
  ) async {
    try {
      final token = await storage.read(key: 'jwt_token');
      if (token == null) return null;

      List<MultipartFile> multipartFiles = [];
      for (var file in files) {
        multipartFiles.add(
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        );
      }

      FormData formData = FormData.fromMap({
        'files': multipartFiles,
      });

      final response = await dio.post(
        ApiConfig.getV1RequestUploadUrl(requestId),
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        onSendProgress: (sent, total) {
          debugPrint('📤 [Upload] Progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [Upload] Error: $e');
      return null;
    }
  }
}

