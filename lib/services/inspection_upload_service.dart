import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/api_response.dart';
import '../widgets/inspection_upload_dialog.dart';
import 'auth_service.dart';
import 'requests_api_service.dart';

/// ============================================
/// 📸 خدمة رفع صور فحص السلامة - Inspection Upload Service
/// ============================================
class InspectionUploadService {
  /// توليد رابط رفع فريد
  Future<ApiResponse<String>> generateUploadLink(String vehicleId) async {
    try {
      final token = await AuthService.getToken();
      // استخدام HTTPS بدلاً من HTTP
      var url = ApiConfig.getGenerateInspectionLinkUrl(vehicleId).replaceFirst('http://', 'https://');

      debugPrint('🔗 [InspectionUpload] Generating link for vehicle: $vehicleId');
      debugPrint('🔗 [InspectionUpload] URL: $url');

      // إنشاء HTTP client مع تفعيل متابعة التوجيهات
      final client = http.Client();
      
      try {
        var response = await client.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'vehicle_id': vehicleId,
          }),
        ).timeout(ApiConfig.timeoutDuration);

        debugPrint('📤 [InspectionUpload] Response status: ${response.statusCode}');
        debugPrint('📤 [InspectionUpload] Response headers: ${response.headers}');
        debugPrint('📤 [InspectionUpload] Response body: ${response.body}');

        // معالجة التوجيهات (301, 302, 307, 308)
        if (response.statusCode >= 300 && response.statusCode < 400) {
          final location = response.headers['location'] ?? response.headers['Location'];
          if (location != null) {
            debugPrint('🔄 [InspectionUpload] Following redirect to: $location');
            // إذا كان التوجيه نسبي، قم ببنائه من URL الأساسي
            final redirectUrl = location.startsWith('http')
                ? location
                : Uri.parse(url).resolve(location).toString();
            
            // إعادة المحاولة مع URL الجديد
            response = await client.post(
              Uri.parse(redirectUrl),
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'vehicle_id': vehicleId,
              }),
            ).timeout(ApiConfig.timeoutDuration);
            
            debugPrint('📤 [InspectionUpload] Redirect response status: ${response.statusCode}');
            debugPrint('📤 [InspectionUpload] Redirect response body: ${response.body}');
          }
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          
          // التحقق من success
          if (data['success'] == true) {
            final uploadToken = data['token'] ?? data['upload_token'];
            
            if (uploadToken != null) {
              debugPrint('✅ [InspectionUpload] Link generated: $uploadToken');
              debugPrint('📋 [InspectionUpload] Upload URL: ${data['upload_url'] ?? 'N/A'}');
              debugPrint('📋 [InspectionUpload] Expires at: ${data['expires_at'] ?? 'N/A'}');
              
              return ApiResponse<String>(
                success: true,
                data: uploadToken,
                message: data['message'] ?? 'تم توليد رابط الرفع بنجاح',
              );
            } else {
              throw Exception('لم يتم العثور على token في الاستجابة');
            }
          } else {
            throw Exception(data['message'] ?? 'فشل توليد رابط الرفع');
          }
        } else if (response.statusCode == 404) {
          // محاولة مسارات بديلة
          debugPrint('⚠️ [InspectionUpload] Endpoint not found (404), trying alternative paths...');
          
          // محاولة 1: بدون "generate-"
          final altUrl1 = url.replaceAll('/generate-inspection-link', '/inspection-link');
          debugPrint('🔄 [InspectionUpload] Trying alternative 1: $altUrl1');
          
          try {
            var altResponse = await client.post(
              Uri.parse(altUrl1),
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'vehicle_id': vehicleId,
              }),
            ).timeout(ApiConfig.timeoutDuration);
            
            if (altResponse.statusCode == 200 || altResponse.statusCode == 201) {
              final data = jsonDecode(altResponse.body);
              final uploadToken = data['token'] ?? data['upload_token'];
              if (uploadToken != null) {
                debugPrint('✅ [InspectionUpload] Link generated with alternative path: $uploadToken');
                return ApiResponse<String>(
                  success: true,
                  data: uploadToken,
                  message: 'تم توليد رابط الرفع بنجاح',
                );
              }
            }
          } catch (e) {
            debugPrint('❌ [InspectionUpload] Alternative 1 failed: $e');
          }
          
          // محاولة 2: استخدام مسار مختلف
          final altUrl2 = '${ApiConfig.nuzumBaseUrl}/api/inspection/generate-link';
          debugPrint('🔄 [InspectionUpload] Trying alternative 2: $altUrl2');
          
          try {
            var altResponse = await client.post(
              Uri.parse(altUrl2),
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'vehicle_id': vehicleId,
              }),
            ).timeout(ApiConfig.timeoutDuration);
            
            if (altResponse.statusCode == 200 || altResponse.statusCode == 201) {
              final data = jsonDecode(altResponse.body);
              final uploadToken = data['token'] ?? data['upload_token'];
              if (uploadToken != null) {
                debugPrint('✅ [InspectionUpload] Link generated with alternative path 2: $uploadToken');
                return ApiResponse<String>(
                  success: true,
                  data: uploadToken,
                  message: 'تم توليد رابط الرفع بنجاح',
                );
              }
            }
          } catch (e) {
            debugPrint('❌ [InspectionUpload] Alternative 2 failed: $e');
          }
          
          // إذا فشلت جميع المحاولات
          final errorBody = response.body.isNotEmpty 
              ? response.body 
              : 'Endpoint غير موجود';
          throw Exception('فشل توليد رابط الرفع: Endpoint غير موجود (404). المسار: $url. الاستجابة: $errorBody');
        } else {
          final errorBody = response.body.isNotEmpty 
              ? response.body 
              : 'لا توجد تفاصيل';
          throw Exception('فشل توليد رابط الرفع: ${response.statusCode}. الاستجابة: $errorBody');
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('❌ [InspectionUpload] Error generating link: $e');
      return ApiResponse<String>(
        success: false,
        message: 'حدث خطأ أثناء توليد رابط الرفع: $e',
      );
    }
  }

  /// رفع صور الفحص - يستخدم Requests API (خطوتين)
  Future<ApiResponse<bool>> uploadInspection({
    required String vehicleId,
    required List<InspectionImageCard> images,
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('📤 [InspectionUpload] Using Requests API (2-step process) for vehicle: $vehicleId');
      debugPrint('📤 [InspectionUpload] Images count: ${images.length}');
      
      // تحويل InspectionImageCard إلى File
      final files = <File>[];
      String? combinedNotes;
      for (int i = 0; i < images.length; i++) {
        final card = images[i];
        if (card.imageFile != null) {
          files.add(card.imageFile!);
          if (card.notesController.text.isNotEmpty) {
            if (combinedNotes == null) {
              combinedNotes = 'صورة ${i + 1}: ${card.notesController.text}';
            } else {
              combinedNotes += '\nصورة ${i + 1}: ${card.notesController.text}';
            }
          }
        }
      }
      
      if (files.isEmpty) {
        return ApiResponse<bool>(
          success: false,
          message: 'يرجى إضافة صورة واحدة على الأقل',
        );
      }
      
      // الخطوة 1: إنشاء طلب الفحص بدون ملفات (JSON)
      debugPrint('📤 [InspectionUpload] Step 1: Creating inspection request (JSON)');
      
      // تحويل vehicleId من String إلى int مع التحقق من الصحة
      final parsedVehicleId = int.tryParse(vehicleId);
      if (parsedVehicleId == null || parsedVehicleId <= 0) {
        debugPrint('❌ [InspectionUpload] Invalid vehicle ID: $vehicleId');
        return ApiResponse<bool>(
          success: false,
          message: 'رقم السيارة غير صحيح: $vehicleId',
        );
      }
      
      final createResult = await _createInspectionRequestOnly(
        vehicleId: parsedVehicleId,
        inspectionType: 'receipt', // استخدام receipt للفحص الدوري (كما يتوقع السرفر)
        inspectionDate: DateTime.now(),
        notes: combinedNotes,
      );
      
      if (createResult['success'] != true) {
        debugPrint('❌ [InspectionUpload] Failed to create inspection request: ${createResult['error']}');
        return ApiResponse<bool>(
          success: false,
          message: createResult['error'] ?? 'فشل إنشاء طلب الفحص',
        );
      }
      
      final requestId = createResult['data']['request_id'] as int;
      debugPrint('✅ [InspectionUpload] Inspection request created with ID: $requestId');
      
      // الخطوة 2: رفع الصور واحدة تلو الأخرى
      debugPrint('📤 [InspectionUpload] Step 2: Uploading ${files.length} images');
      debugPrint('📤 [InspectionUpload] Request ID: $requestId');
      int uploadedCount = 0;
      
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        debugPrint('📤 [InspectionUpload] ========================================');
        debugPrint('📤 [InspectionUpload] Uploading image ${i + 1}/${files.length}');
        debugPrint('📤 [InspectionUpload] File path: ${file.path}');
        debugPrint('📤 [InspectionUpload] File exists: ${await file.exists()}');
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('📤 [InspectionUpload] File size: ${fileSize} bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
        }
        
        // محاولة رفع الصورة مع retry (3 محاولات)
        bool uploadSuccess = false;
        int retryCount = 0;
        const maxRetries = 3;
        
        while (!uploadSuccess && retryCount < maxRetries) {
          try {
            if (retryCount > 0) {
              debugPrint('🔄 [InspectionUpload] Retry ${retryCount}/$maxRetries for image ${i + 1}');
              // انتظار قبل إعادة المحاولة
              await Future.delayed(Duration(seconds: retryCount * 2));
            }
            
            debugPrint('📤 [InspectionUpload] Calling RequestsApiService.uploadInspectionImage...');
            final uploadStartTime = DateTime.now();
            
            final uploadResult = await RequestsApiService.uploadInspectionImage(
              requestId,
              file,
              onProgress: (sent, total) {
                if (onProgress != null && total > 0) {
                  // حساب التقدم الإجمالي
                  final imageProgress = sent / total;
                  final totalProgress = (uploadedCount + imageProgress) / files.length;
                  onProgress(totalProgress);
                  debugPrint('📊 [InspectionUpload] Progress: ${(totalProgress * 100).toStringAsFixed(1)}% (${sent}/${total} bytes)');
                }
              },
            );
            
            final uploadDuration = DateTime.now().difference(uploadStartTime);
            debugPrint('📤 [InspectionUpload] Upload completed in ${uploadDuration.inMilliseconds}ms');
            debugPrint('📤 [InspectionUpload] Upload result for image ${i + 1}: ${uploadResult['success']}');
            if (uploadResult['error'] != null) {
              debugPrint('❌ [InspectionUpload] Upload error: ${uploadResult['error']}');
            }
            if (uploadResult['data'] != null) {
              debugPrint('✅ [InspectionUpload] Upload data: ${uploadResult['data']}');
            }
            
            if (uploadResult['success'] == true) {
              uploadedCount++;
              uploadSuccess = true;
              debugPrint('✅ [InspectionUpload] Image ${i + 1} uploaded successfully');
              
              // إذا كان هناك warning (مثل خطأ قاعدة البيانات لكن الصورة محفوظة)
              if (uploadResult['warning'] != null) {
                debugPrint('⚠️ [InspectionUpload] Warning: ${uploadResult['warning']}');
              }
            } else {
              final errorMsg = uploadResult['error'] ?? 'فشل رفع الصورة';
              debugPrint('❌ [InspectionUpload] Failed to upload image ${i + 1}: $errorMsg');
              
              // إذا كان الخطأ متعلقاً بـ Token أو المصادقة، لا نعيد المحاولة
              if (errorMsg.contains('تسجيل الدخول') || 
                  errorMsg.contains('غير مصرح') ||
                  errorMsg.contains('401') ||
                  errorMsg.contains('Unauthorized')) {
                debugPrint('⚠️ [InspectionUpload] Authentication error, skipping retry');
                break;
              }
              
              // إذا كان الخطأ متعلقاً بالمسار (404)، لا نعيد المحاولة
              if (errorMsg.contains('404') || errorMsg.contains('غير موجود')) {
                debugPrint('⚠️ [InspectionUpload] Path not found error, skipping retry');
                break;
              }
              
              // إذا كان الخطأ 400 (لا يوجد ملفات مرفقة)، قد تكون مشكلة في FormData
              if (errorMsg.contains('400') || 
                  errorMsg.contains('لا يوجد ملفات') ||
                  errorMsg.contains('مرفقة')) {
                debugPrint('⚠️ [InspectionUpload] Bad request (400) - FormData issue, will retry...');
                retryCount++;
                continue;
              }
              
              // إذا كان الخطأ 500 (مشكلة في السرفر/قاعدة البيانات)، نعيد المحاولة
              if (errorMsg.contains('500') || 
                  errorMsg.contains('Google Drive') ||
                  errorMsg.contains('الخادم') ||
                  errorMsg.contains('قاعدة البيانات')) {
                debugPrint('⚠️ [InspectionUpload] Server error (500), will retry...');
                retryCount++;
                continue;
              }
              
              retryCount++;
            }
          } catch (e, stackTrace) {
            debugPrint('❌ [InspectionUpload] Exception uploading image ${i + 1}: $e');
            debugPrint('❌ [InspectionUpload] Stack trace: $stackTrace');
            retryCount++;
            
            // إذا كان الخطأ متعلقاً بالاتصال، نعيد المحاولة
            if (retryCount < maxRetries && 
                (e.toString().contains('timeout') || 
                 e.toString().contains('connection') ||
                 e.toString().contains('SocketException'))) {
              debugPrint('🔄 [InspectionUpload] Connection error, will retry...');
            } else {
              debugPrint('❌ [InspectionUpload] Non-retryable error, stopping retries');
              break;
            }
          }
        }
        
        if (!uploadSuccess) {
          debugPrint('❌ [InspectionUpload] Failed to upload image ${i + 1} after $maxRetries attempts');
          // نواصل رفع باقي الصور
        }
        debugPrint('📤 [InspectionUpload] ========================================');
      }
      
      if (uploadedCount == 0) {
        return ApiResponse<bool>(
          success: false,
          message: 'فشل رفع جميع الصور',
        );
      }
      
      if (onProgress != null) onProgress(1.0);
      
      debugPrint('✅ [InspectionUpload] Uploaded $uploadedCount/${files.length} images successfully');
      return ApiResponse<bool>(
        success: true,
        data: true,
        message: uploadedCount == files.length
            ? 'تم رفع جميع الصور بنجاح'
            : 'تم رفع $uploadedCount من ${files.length} صورة',
      );
      
    } catch (e) {
      debugPrint('❌ [InspectionUpload] Error uploading: $e');
      return ApiResponse<bool>(
        success: false,
        message: 'حدث خطأ أثناء رفع الصور: $e',
      );
    }
  }
  
  /// إنشاء طلب فحص بدون ملفات (JSON فقط)
  Future<Map<String, dynamic>> _createInspectionRequestOnly({
    required int vehicleId,
    required String inspectionType,
    required DateTime inspectionDate,
    String? notes,
  }) async {
    try {
      // استخدام getValidToken للتأكد من أن Token صالح
      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ [InspectionUpload] No valid token available');
        return {
          'success': false,
          'error': 'يرجى تسجيل الدخول أولاً',
        };
      }

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeoutDuration,
        receiveTimeout: ApiConfig.timeoutDuration,
      ));
      
      final requestBody = {
        'vehicle_id': vehicleId,
        'inspection_type': inspectionType,
        'inspection_date': inspectionDate.toIso8601String().split('T')[0],
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      
      debugPrint('📤 [InspectionUpload] Creating inspection request:');
      debugPrint('   Vehicle ID: $vehicleId');
      debugPrint('   Inspection Type: $inspectionType');
      debugPrint('   Inspection Date: ${inspectionDate.toIso8601String().split('T')[0]}');
      debugPrint('   Notes: ${notes ?? 'None'}');
      debugPrint('   Endpoint: ${ApiConfig.baseUrl}${ApiConfig.createCarInspectionPath}');
      debugPrint('   Token present: ${token.isNotEmpty}');
      
      final response = await dio.post(
        ApiConfig.createCarInspectionPath,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      debugPrint('📤 [InspectionUpload] Response status: ${response.statusCode}');
      debugPrint('📤 [InspectionUpload] Response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          final requestId = data['data']?['request_id'] ?? 
                           data['request_id'] ?? 
                           data['data']?['id'];
          
          if (requestId != null) {
            debugPrint('✅ [InspectionUpload] Request created successfully with ID: $requestId');
            return {
              'success': true,
              'data': {
                'request_id': requestId is int ? requestId : int.parse(requestId.toString()),
              },
            };
          } else {
            debugPrint('❌ [InspectionUpload] Request ID not found in response');
            return {
              'success': false,
              'error': 'لم يتم العثور على رقم الطلب في الاستجابة',
            };
          }
        } else {
          final errorMsg = data['message'] ?? data['error'] ?? 'فشل إنشاء الطلب';
          debugPrint('❌ [InspectionUpload] Request creation failed: $errorMsg');
          return {
            'success': false,
            'error': errorMsg,
          };
        }
      }
      
      final errorMessage = response.data is Map<String, dynamic>
          ? (response.data['error'] ?? response.data['message'] ?? 'فشل إنشاء الطلب')
          : 'فشل إنشاء الطلب: ${response.statusCode}';
      
      debugPrint('❌ [InspectionUpload] Request creation failed: $errorMessage');
      return {
        'success': false,
        'error': errorMessage,
      };
      
    } on DioException catch (e) {
      debugPrint('❌ [InspectionUpload] DioException creating request:');
      debugPrint('   Status code: ${e.response?.statusCode}');
      debugPrint('   Response data: ${e.response?.data}');
      debugPrint('   Error message: ${e.message}');
      debugPrint('   Error type: ${e.type}');
      
      String errorMessage = 'حدث خطأ أثناء إنشاء الطلب';
      
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;
        
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['error'] ?? 
                        responseData['message'] ?? 
                        'فشل إنشاء الطلب: $statusCode';
        } else if (statusCode == 401) {
          errorMessage = 'يرجى تسجيل الدخول مرة أخرى';
        } else if (statusCode == 404) {
          errorMessage = 'المسار غير موجود';
        } else if (statusCode == 422) {
          errorMessage = 'البيانات المدخلة غير صحيحة';
        } else if (statusCode == 500) {
          errorMessage = 'خطأ في الخادم. يرجى المحاولة لاحقاً';
        } else {
          errorMessage = 'فشل إنشاء الطلب: $statusCode';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة الاتصال. يرجى التحقق من اتصال الإنترنت';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'فشل الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت';
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ [InspectionUpload] Unexpected error creating request: $e');
      debugPrint('❌ [InspectionUpload] Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'حدث خطأ غير متوقع: ${e.toString()}',
      };
    }
  }
  
  /// رفع صور الفحص (الطريقة القديمة - محفوظة للرجوع إليها)
  @Deprecated('Use uploadInspection instead - it uses Requests API')
  Future<ApiResponse<bool>> uploadInspectionOldMethod({
    required String vehicleId,
    required List<InspectionImageCard> images,
    Function(double)? onProgress,
  }) async {
    try {
      // توليد رابط الرفع أولاً
      final linkResponse = await generateUploadLink(vehicleId);
      if (!linkResponse.success || linkResponse.data == null) {
        return ApiResponse<bool>(
          success: false,
          message: linkResponse.message ?? 'فشل توليد رابط الرفع',
        );
      }

      final uploadToken = linkResponse.data!;
      // استخدام HTTPS
      var url = ApiConfig.getInspectionUploadUrl(uploadToken).replaceFirst('http://', 'https://');

      debugPrint('📤 [InspectionUpload] Uploading ${images.length} images');
      debugPrint('📤 [InspectionUpload] Upload URL: $url');

      // إنشاء HTTP client
      final client = http.Client();
      
      try {
        // إنشاء multipart request
        var request = http.MultipartRequest('POST', Uri.parse(url));

        // إضافة الصور
        for (int i = 0; i < images.length; i++) {
          final card = images[i];
          if (card.imageFile != null) {
            final file = card.imageFile!;
            final fileName = file.path.split('/').last;
            
            // استخدام 'file' كاسم الحقل
            request.files.add(
              await http.MultipartFile.fromPath(
                'file',
                file.path,
                filename: fileName,
              ),
            );

            // إضافة الملاحظات إذا كانت موجودة
            if (card.notesController.text.isNotEmpty) {
              request.fields['notes_$i'] = card.notesController.text;
            }
          }
        }

        // إضافة معلومات إضافية
        request.fields['vehicle_id'] = vehicleId;
        request.fields['image_count'] = images.length.toString();

        // إضافة token
        final token = await AuthService.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        
        // إزالة Content-Type للسماح للمكتبة بإضافته تلقائياً مع boundary
        request.headers.remove('Content-Type');

        debugPrint('📤 [InspectionUpload] Request headers: ${request.headers}');
        debugPrint('📤 [InspectionUpload] Request fields: ${request.fields}');
        debugPrint('📤 [InspectionUpload] Request files count: ${request.files.length}');

        // إرسال الطلب مع تتبع التقدم
        var streamedResponse = await client.send(request).timeout(
          ApiConfig.timeoutDuration,
        );

        debugPrint('📤 [InspectionUpload] Streamed response status: ${streamedResponse.statusCode}');
        debugPrint('📤 [InspectionUpload] Response headers: ${streamedResponse.headers}');

        // معالجة التوجيهات (301, 302, 307, 308)
        if (streamedResponse.statusCode >= 300 && streamedResponse.statusCode < 400) {
          final location = streamedResponse.headers['location'] ?? streamedResponse.headers['Location'];
          if (location != null) {
            debugPrint('🔄 [InspectionUpload] Following redirect to: $location');
            final redirectUrl = location.startsWith('http')
                ? location
                : Uri.parse(url).resolve(location).toString();
            
            // إعادة إنشاء الطلب مع URL الجديد
            request = http.MultipartRequest('POST', Uri.parse(redirectUrl));
            
            // إعادة إضافة الملفات والحقول
            for (int i = 0; i < images.length; i++) {
              final card = images[i];
              if (card.imageFile != null) {
                final file = card.imageFile!;
                final fileName = file.path.split('/').last;
                request.files.add(
                  await http.MultipartFile.fromPath(
                    'file',
                    file.path,
                    filename: fileName,
                  ),
                );
                if (card.notesController.text.isNotEmpty) {
                  request.fields['notes_$i'] = card.notesController.text;
                }
              }
            }
            request.fields['vehicle_id'] = vehicleId;
            request.fields['image_count'] = images.length.toString();
            if (token != null) {
              request.headers['Authorization'] = 'Bearer $token';
            }
            request.headers.remove('Content-Type');
            
            streamedResponse = await client.send(request).timeout(
              ApiConfig.timeoutDuration,
            );
            debugPrint('📤 [InspectionUpload] Redirect response status: ${streamedResponse.statusCode}');
          }
        }

        // تتبع التقدم أثناء الإرسال
        int totalBytes = streamedResponse.contentLength ?? 0;
        int receivedBytes = 0;
        
        final responseBytes = <int>[];
        await for (final chunk in streamedResponse.stream) {
          responseBytes.addAll(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0 && onProgress != null) {
            final progress = receivedBytes / totalBytes;
            onProgress(progress);
          }
        }

        final response = http.Response.bytes(
          responseBytes,
          streamedResponse.statusCode,
          headers: streamedResponse.headers,
          request: streamedResponse.request,
        );

        debugPrint('📤 [InspectionUpload] Upload response: ${response.statusCode}');
        debugPrint('📤 [InspectionUpload] Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final data = jsonDecode(response.body);
            
            if (data['success'] == true || response.statusCode == 201) {
              debugPrint('✅ [InspectionUpload] Upload successful');
              if (onProgress != null) onProgress(1.0);
              
              return ApiResponse<bool>(
                success: true,
                data: true,
                message: data['message'] ?? 'تم رفع الصور بنجاح',
              );
            } else {
              throw Exception(data['message'] ?? 'فشل رفع الصور');
            }
          } catch (e) {
            // إذا فشل parsing JSON، قد تكون الاستجابة نصية
            if (response.body.isNotEmpty) {
              debugPrint('⚠️ [InspectionUpload] Response is not JSON: ${response.body}');
              // إذا كان status code 200/201، نعتبره نجاح
              if (response.statusCode == 200 || response.statusCode == 201) {
                if (onProgress != null) onProgress(1.0);
                return ApiResponse<bool>(
                  success: true,
                  data: true,
                  message: 'تم رفع الصور بنجاح',
                );
              }
            }
            throw Exception('فشل رفع الصور: ${e.toString()}');
          }
        } else {
          try {
            final errorData = jsonDecode(response.body);
            throw Exception(
              errorData['message'] ?? 
              'فشل رفع الصور: ${response.statusCode}',
            );
          } catch (e) {
            final errorBody = response.body.isNotEmpty 
                ? response.body 
                : 'لا توجد تفاصيل';
            throw Exception('فشل رفع الصور: ${response.statusCode}. الاستجابة: $errorBody');
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('❌ [InspectionUpload] Error uploading: $e');
      return ApiResponse<bool>(
        success: false,
        message: 'حدث خطأ أثناء رفع الصور: $e',
      );
    }
  }

  /// رفع صور الفحص (الطريقة القديمة - محفوظة للرجوع إليها)
  @Deprecated('Use uploadInspection instead - it uses Requests API')
  Future<ApiResponse<bool>> uploadInspectionOld({
    required String vehicleId,
    required List<InspectionImageCard> images,
    Function(double)? onProgress,
  }) async {
    try {
      // توليد رابط الرفع
      final linkResponse = await generateUploadLink(vehicleId);
      if (!linkResponse.success || linkResponse.data == null) {
        return ApiResponse<bool>(
          success: false,
          message: linkResponse.message ?? 'فشل توليد رابط الرفع',
        );
      }

      final uploadToken = linkResponse.data!;
      var url = ApiConfig.getInspectionUploadUrl(uploadToken);

      debugPrint('📤 [InspectionUpload] Uploading ${images.length} images');
      debugPrint('📤 [InspectionUpload] Upload URL: $url');

      // إنشاء HTTP client
      final client = http.Client();
      
      try {
        // إنشاء multipart request
        var request = http.MultipartRequest('POST', Uri.parse(url));

        // إضافة الصور - تجربة أسماء حقول مختلفة
        // بعض السيرفرات تتوقع 'file' أو 'files' بدلاً من 'images'
        for (int i = 0; i < images.length; i++) {
          final card = images[i];
          if (card.imageFile != null) {
            final file = card.imageFile!;
            final fileName = file.path.split('/').last;
            
            // استخدام 'file' بدلاً من 'images' (أكثر شيوعاً في APIs)
            request.files.add(
              await http.MultipartFile.fromPath(
                'file', // تغيير من 'images' إلى 'file'
                file.path,
                filename: fileName,
              ),
            );

            // إضافة الملاحظات إذا كانت موجودة
            if (card.notesController.text.isNotEmpty) {
              request.fields['notes_$i'] = card.notesController.text;
            }
          }
        }

        // إضافة معلومات إضافية
        request.fields['vehicle_id'] = vehicleId;
        request.fields['image_count'] = images.length.toString();

        // إضافة token
        final token = await AuthService.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        
        // إزالة Content-Type للسماح للمكتبة بإضافته تلقائياً مع boundary
        request.headers.remove('Content-Type');

        debugPrint('📤 [InspectionUpload] Request headers: ${request.headers}');
        debugPrint('📤 [InspectionUpload] Request fields: ${request.fields}');
        debugPrint('📤 [InspectionUpload] Request files count: ${request.files.length}');

        // إرسال الطلب مع تتبع التقدم
        var streamedResponse = await client.send(request).timeout(
          ApiConfig.timeoutDuration,
        );

        debugPrint('📤 [InspectionUpload] Streamed response status: ${streamedResponse.statusCode}');
        debugPrint('📤 [InspectionUpload] Response headers: ${streamedResponse.headers}');

        // معالجة التوجيهات (301, 302, 307, 308)
        if (streamedResponse.statusCode >= 300 && streamedResponse.statusCode < 400) {
          final location = streamedResponse.headers['location'] ?? streamedResponse.headers['Location'];
          if (location != null) {
            debugPrint('🔄 [InspectionUpload] Following redirect to: $location');
            final redirectUrl = location.startsWith('http')
                ? location
                : Uri.parse(url).resolve(location).toString();
            
            // إعادة إنشاء الطلب مع URL الجديد
            request = http.MultipartRequest('POST', Uri.parse(redirectUrl));
            
            // إعادة إضافة الملفات والحقول
            for (int i = 0; i < images.length; i++) {
              final card = images[i];
              if (card.imageFile != null) {
                final file = card.imageFile!;
                final fileName = file.path.split('/').last;
                request.files.add(
                  await http.MultipartFile.fromPath(
                    'file',
                    file.path,
                    filename: fileName,
                  ),
                );
                if (card.notesController.text.isNotEmpty) {
                  request.fields['notes_$i'] = card.notesController.text;
                }
              }
            }
            request.fields['vehicle_id'] = vehicleId;
            request.fields['image_count'] = images.length.toString();
            if (token != null) {
              request.headers['Authorization'] = 'Bearer $token';
            }
            request.headers.remove('Content-Type');
            
            streamedResponse = await client.send(request).timeout(
              ApiConfig.timeoutDuration,
            );
            debugPrint('📤 [InspectionUpload] Redirect response status: ${streamedResponse.statusCode}');
          }
        }

        // تتبع التقدم أثناء الإرسال
        int totalBytes = streamedResponse.contentLength ?? 0;
        int receivedBytes = 0;
        
        final responseBytes = <int>[];
        await for (final chunk in streamedResponse.stream) {
          responseBytes.addAll(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0 && onProgress != null) {
            final progress = receivedBytes / totalBytes;
            onProgress(progress);
          }
        }

        final response = http.Response.bytes(
          responseBytes,
          streamedResponse.statusCode,
          headers: streamedResponse.headers,
          request: streamedResponse.request,
        );

        debugPrint('📤 [InspectionUpload] Upload response: ${response.statusCode}');
        debugPrint('📤 [InspectionUpload] Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final data = jsonDecode(response.body);
            
            if (data['success'] == true || response.statusCode == 201) {
              debugPrint('✅ [InspectionUpload] Upload successful');
              if (onProgress != null) onProgress(1.0);
              
              return ApiResponse<bool>(
                success: true,
                data: true,
                message: data['message'] ?? 'تم رفع الصور بنجاح',
              );
            } else {
              throw Exception(data['message'] ?? 'فشل رفع الصور');
            }
          } catch (e) {
            // إذا فشل parsing JSON، قد تكون الاستجابة نصية
            if (response.body.isNotEmpty) {
              debugPrint('⚠️ [InspectionUpload] Response is not JSON: ${response.body}');
              // إذا كان status code 200/201، نعتبره نجاح
              if (response.statusCode == 200 || response.statusCode == 201) {
                if (onProgress != null) onProgress(1.0);
                return ApiResponse<bool>(
                  success: true,
                  data: true,
                  message: 'تم رفع الصور بنجاح',
                );
              }
            }
            throw Exception('فشل رفع الصور: ${e.toString()}');
          }
        } else if (response.statusCode == 404) {
          // محاولة مسارات بديلة للرفع
          debugPrint('⚠️ [InspectionUpload] Upload endpoint not found (404), trying alternatives...');
          
          // محاولة 1: إضافة /api/ في المسار
          final altUrl1 = url.replaceAll('/inspection-upload/', '/api/inspection-upload/');
          debugPrint('🔄 [InspectionUpload] Trying alternative upload URL 1: $altUrl1');
          
          try {
            var altRequest = http.MultipartRequest('POST', Uri.parse(altUrl1));
            for (int i = 0; i < images.length; i++) {
              final card = images[i];
              if (card.imageFile != null) {
                final file = card.imageFile!;
                final fileName = file.path.split('/').last;
                altRequest.files.add(
                  await http.MultipartFile.fromPath('file', file.path, filename: fileName),
                );
                if (card.notesController.text.isNotEmpty) {
                  altRequest.fields['notes_$i'] = card.notesController.text;
                }
              }
            }
            altRequest.fields['vehicle_id'] = vehicleId;
            altRequest.fields['image_count'] = images.length.toString();
            if (token != null) {
              altRequest.headers['Authorization'] = 'Bearer $token';
            }
            altRequest.headers.remove('Content-Type');
            
            var altStreamedResponse = await client.send(altRequest).timeout(
              ApiConfig.timeoutDuration,
            );
            
            final altResponseBytes = <int>[];
            await for (final chunk in altStreamedResponse.stream) {
              altResponseBytes.addAll(chunk);
            }
            
            final altResponse = http.Response.bytes(
              altResponseBytes,
              altStreamedResponse.statusCode,
              headers: altStreamedResponse.headers,
            );
            
            if (altResponse.statusCode == 200 || altResponse.statusCode == 201) {
              debugPrint('✅ [InspectionUpload] Upload successful with alternative URL');
              if (onProgress != null) onProgress(1.0);
              return ApiResponse<bool>(
                success: true,
                data: true,
                message: 'تم رفع الصور بنجاح',
              );
            }
          } catch (e) {
            debugPrint('❌ [InspectionUpload] Alternative upload URL 1 failed: $e');
          }
          
          final errorBody = response.body.isNotEmpty 
              ? response.body 
              : 'Endpoint غير موجود';
          throw Exception('فشل رفع الصور: Endpoint غير موجود (404). المسار: $url. الاستجابة: $errorBody');
        } else {
          try {
            final errorData = jsonDecode(response.body);
            throw Exception(
              errorData['message'] ?? 
              'فشل رفع الصور: ${response.statusCode}',
            );
          } catch (e) {
            final errorBody = response.body.isNotEmpty 
                ? response.body 
                : 'لا توجد تفاصيل';
            throw Exception('فشل رفع الصور: ${response.statusCode}. الاستجابة: $errorBody');
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('❌ [InspectionUpload] Error uploading: $e');
      return ApiResponse<bool>(
        success: false,
        message: 'حدث خطأ أثناء رفع الصور: $e',
      );
    }
  }

  /// التحقق من حالة الطلب
  Future<ApiResponse<Map<String, dynamic>>> checkStatus(String token) async {
    try {
      // استخدام HTTPS
      final url = ApiConfig.getInspectionStatusUrl(token).replaceFirst('http://', 'https://');
      
      debugPrint('🔍 [InspectionUpload] Checking status for token: $token');
      debugPrint('🔍 [InspectionUpload] Status URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(ApiConfig.timeoutDuration);

      debugPrint('📤 [InspectionUpload] Status response: ${response.statusCode}');
      debugPrint('📤 [InspectionUpload] Status response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          debugPrint('✅ [InspectionUpload] Status retrieved successfully');
          debugPrint('📋 [InspectionUpload] Inspection status: ${data['inspection']?['status'] ?? 'N/A'}');
          debugPrint('📋 [InspectionUpload] Status Arabic: ${data['inspection']?['status_arabic'] ?? 'N/A'}');
          
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            data: data,
            message: data['message'] ?? 'تم جلب الحالة بنجاح',
          );
        } else {
          throw Exception(data['message'] ?? 'فشل جلب الحالة');
        }
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'لا توجد تفاصيل';
        throw Exception('فشل جلب الحالة: ${response.statusCode}. الاستجابة: $errorBody');
      }
    } catch (e) {
      debugPrint('❌ [InspectionUpload] Error checking status: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'حدث خطأ أثناء جلب الحالة: $e',
      );
    }
  }
}

