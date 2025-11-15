import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/request_model.dart';
import '../services/auth_service.dart';

/// ============================================
/// 📋 خدمة API للطلبات - Requests API Service
/// ============================================
class RequestsApiService {
  static Dio get dio => AuthService.dio;

  /// ============================================
  /// 📋 جلب قائمة الطلبات - Get My Requests
  /// ============================================
  static Future<Map<String, dynamic>> getMyRequests({
    String? type,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      // محاولة المسار الأساسي
      try {
        debugPrint('🔄 [RequestsAPI] Trying primary URL: ${ApiConfig.baseUrl}${ApiConfig.myRequestsPath}');
        final response = await dio.get(
          ApiConfig.myRequestsPath,
          queryParameters: queryParams,
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            final requests = (data['requests'] as List)
                .map((item) => Request.fromJson(item as Map<String, dynamic>))
                .toList();

            return {
              'success': true,
              'data': requests,
              'statistics': RequestStatistics.fromJson(data['statistics'] ?? {}),
            };
          }
        }

        // إذا كان الخطأ 404 أو 500 أو 503، جرب المسار البديل
        if (response.statusCode == 404 || response.statusCode == 500 || response.statusCode == 503) {
          debugPrint('⚠️ [RequestsAPI] Primary URL returned ${response.statusCode}, trying backup...');
          return await _tryBackupMyRequests(queryParams);
        }

        return {'success': false, 'error': 'فشل جلب الطلبات'};
      } on DioException catch (e) {
        // إذا كان الخطأ 404 أو 500 أو 503، جرب المسار البديل
        final statusCode = e.response?.statusCode;
        if (statusCode == 404 || statusCode == 500 || statusCode == 503) {
          debugPrint('⚠️ [RequestsAPI] Primary URL failed with $statusCode, trying backup...');
          return await _tryBackupMyRequests(queryParams);
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Get requests error: $e');
      return {
        'success': false,
        'error': 'حدث خطأ: ${_getErrorMessage(e)}',
      };
    }
  }

  /// محاولة جلب الطلبات من المسار البديل
  static Future<Map<String, dynamic>> _tryBackupMyRequests(
    Map<String, dynamic> queryParams,
  ) async {
    try {
      final backupUrl = '${ApiConfig.backupDomain}${ApiConfig.myRequestsPath}';
      debugPrint('🔄 [RequestsAPI] Trying backup URL: $backupUrl');

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
          final requests = (data['requests'] as List)
              .map((item) => Request.fromJson(item as Map<String, dynamic>))
              .toList();

          return {
            'success': true,
            'data': requests,
            'statistics': RequestStatistics.fromJson(data['statistics'] ?? {}),
          };
        }
      }

      return {
        'success': false,
        'error': 'فشل جلب الطلبات من المسار البديل. يرجى التحقق من إعدادات API أو الاتصال بالإنترنت',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Backup URL also failed: $e');
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

  /// الحصول على رسالة خطأ واضحة
  static String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        switch (statusCode) {
          case 404:
            return 'المسار غير موجود (404). يرجى التحقق من إعدادات API';
          case 401:
            return 'غير مصرح (401). يرجى تسجيل الدخول مرة أخرى';
          case 403:
            return 'غير مسموح (403)';
          case 500:
            return 'خطأ في الخادم (500)';
          case 503:
            return 'الخدمة غير متاحة حالياً (503)';
          default:
            return 'خطأ في الاتصال: $statusCode';
        }
      } else if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';
      } else if (error.type == DioExceptionType.connectionError) {
        return 'فشل الاتصال بالخادم. تحقق من اتصال الإنترنت';
      }
    }
    return error.toString();
  }

  /// ============================================
  /// 💰 إنشاء طلب سلفة - Create Advance Payment
  /// ============================================
  static Future<Map<String, dynamic>> createAdvancePayment(
    AdvancePaymentRequest request, {
    ProgressCallback? onProgress,
  }) async {
    try {
      // إذا كانت هناك صورة، استخدم multipart/form-data
      if (request.imagePath != null) {
        final file = File(request.imagePath!);
        if (!await file.exists()) {
          return {'success': false, 'error': 'ملف الصورة غير موجود'};
        }

        // ضغط الصورة
        final compressedFile = await _compressImage(file);
        
        // استخدام FormData لإرسال البيانات مع الصورة
        final multipartFile = await MultipartFile.fromFile(
          compressedFile.path,
          filename: 'advance_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        
        final formData = FormData.fromMap({
          'employee_id': request.employeeId,
          'requested_amount': request.requestedAmount.toString(),
          if (request.reason != null) 'reason': request.reason,
          if (request.installments != null) 'installments': request.installments.toString(),
          'advance_image': multipartFile,
        });

        debugPrint('🔄 [RequestsAPI] Creating advance payment request with image');
        debugPrint('📤 [RequestsAPI] Uploading advance image: ${compressedFile.path}');
        
        // استخدام Dio جديد بدون Content-Type افتراضي للطلبات multipart
        final token = await AuthService.getToken();
        final multipartDio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.timeoutDuration,
            receiveTimeout: ApiConfig.timeoutDuration,
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
            },
          ),
        );
        
        // إزالة أي Content-Type موجود مسبقاً لضمان أن Dio يضبطه تلقائياً
        multipartDio.options.headers.remove('Content-Type');
        
        try {
          final response = await multipartDio.post(
            ApiConfig.createAdvancePath,
            data: formData,
            onSendProgress: onProgress,
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
              contentType: null, // السماح لـ Dio بضبط Content-Type تلقائياً
            ),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data as Map<String, dynamic>;
            if (data['success'] == true) {
              final requestId = data['data']?['request_id'] ?? data['data']?['id'];
              
              // محاولة رفع الصورة على Google Drive
              if (requestId != null) {
                debugPrint('📤 [RequestsAPI] Uploading advance image to Drive...');
                try {
                  final driveUploadResult = await _uploadAdvanceImageToDrive(
                    requestId,
                    compressedFile,
                    onProgress: onProgress ?? (sent, total) {},
                  );
                  
                  if (driveUploadResult['success'] == true && driveUploadResult['drive_url'] != null) {
                    debugPrint('✅ [RequestsAPI] Advance image uploaded to Drive successfully!');
                    return {
                      'success': true,
                      'message': 'تم رفع طلب السلفة والصورة على Google Drive بنجاح',
                      'data': {
                        'request_id': requestId,
                        'status': data['data']?['status'] ?? 'pending',
                        'pdf_url': data['data']?['pdf_url'],
                        'drive_url': driveUploadResult['drive_url'],
                      },
                    };
                  }
                } catch (e) {
                  debugPrint('⚠️ [RequestsAPI] Error uploading to Drive: $e');
                }
              }
              
              return {
                'success': true,
                'message': data['message'] ?? 'تم إنشاء الطلب بنجاح',
                'data': {
                  'request_id': requestId,
                  'status': data['data']?['status'] ?? 'pending',
                  'pdf_url': data['data']?['pdf_url'],
                },
              };
            }
          }
          
          // إذا لم يكن success: true
          return {
            'success': false,
            'error': response.data is Map ? (response.data['error'] ?? response.data['message'] ?? 'فشل إنشاء الطلب') : 'فشل إنشاء الطلب',
          };
        } on DioException catch (e) {
          // معالجة الأخطاء
          final statusCode = e.response?.statusCode;
          final errorData = e.response?.data;
          
          debugPrint('❌ [RequestsAPI] Create advance payment error: $statusCode');
          debugPrint('📋 [RequestsAPI] Error data: $errorData');
          
          if (statusCode == 400) {
            String errorMessage = 'فشل إنشاء طلب السلفة';
            if (errorData is Map<String, dynamic>) {
              errorMessage = errorData['error'] as String? ?? 
                            errorData['message'] as String? ?? 
                            errorData['errors']?.toString() ?? 
                            'البيانات المرسلة غير صحيحة. يرجى التحقق من جميع الحقول';
            }
            return {
              'success': false,
              'error': errorMessage,
            };
          }
          
          if (statusCode == 415) {
            debugPrint('⚠️ [RequestsAPI] 415 Unsupported Media Type - trying without image...');
            // محاولة إرسال الطلب بدون صورة
            try {
              final requestData = request.toJson();
              final response = await dio.post(
                ApiConfig.createAdvancePath,
                data: requestData,
              );
              
              if (response.statusCode == 200 || response.statusCode == 201) {
                final data = response.data as Map<String, dynamic>;
                if (data['success'] == true) {
                  return {
                    'success': true,
                    'message': 'تم إنشاء الطلب بنجاح (بدون صورة)',
                    'data': {
                      'request_id': data['data']['request_id'],
                      'status': data['data']['status'],
                      'pdf_url': data['data']['pdf_url'],
                    },
                  };
                }
              }
            } catch (e2) {
              debugPrint('❌ [RequestsAPI] Failed to create without image: $e2');
            }
            
            return {
              'success': false,
              'error': 'السيرفر لا يقبل نوع المحتوى المرسل. يرجى المحاولة بدون صورة.',
            };
          }
          
          return {
            'success': false,
            'error': errorData is Map ? (errorData['error'] ?? errorData['message'] ?? 'فشل إنشاء الطلب') : 'فشل إنشاء الطلب',
          };
        }
      } else {
        // لا توجد صورة، استخدم JSON عادي
        final requestData = request.toJson();
        final fullUrl = '${ApiConfig.baseUrl}${ApiConfig.createAdvancePath}';
        
        debugPrint('🔄 [RequestsAPI] Creating advance payment request (no image)');
        debugPrint('📍 [RequestsAPI] URL: $fullUrl');
        debugPrint('📋 [RequestsAPI] Request data: $requestData');
        
        final response = await dio.post(
          ApiConfig.createAdvancePath,
          data: requestData,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            return {
              'success': true,
              'message': data['message'] ?? 'تم إنشاء الطلب بنجاح',
              'data': {
                'request_id': data['data']['request_id'],
                'status': data['data']['status'],
                'pdf_url': data['data']['pdf_url'],
              },
            };
          }
        }
      }

      // إذا وصلنا هنا، فشل الطلب
      return {
        'success': false,
        'error': 'فشل إنشاء الطلب',
      };
    } on DioException catch (e) {
      // معالجة خطأ 400
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        String errorMessage = 'فشل إنشاء طلب السلفة';
        
        if (errorData is Map<String, dynamic>) {
          errorMessage = errorData['error'] as String? ?? 
                        errorData['message'] as String? ?? 
                        errorData['errors']?.toString() ?? 
                        'البيانات المرسلة غير صحيحة. يرجى التحقق من جميع الحقول';
        }
        
        debugPrint('❌ [RequestsAPI] 400 Bad Request: $errorMessage');
        debugPrint('📋 [RequestsAPI] Response data: $errorData');
        
        return {
          'success': false,
          'error': errorMessage,
        };
      }
      
      // إذا كان الخطأ 404، جرب المسار الموحد
      if (e.response?.statusCode == 404) {
        debugPrint('⚠️ [RequestsAPI] Specialized path returned 404, trying unified path...');
        try {
          // استخدام نفس البيانات مباشرة (بدون type و data wrapper)
          final response = await dio.post(
            ApiConfig.requestsBasePath, // POST /api/v1/requests
            data: {
              'type': 'advance_payment',
              ...request.toJson(),
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data as Map<String, dynamic>;
            if (data['success'] == true) {
              return {
                'success': true,
                'message': data['message'] ?? 'تم إنشاء الطلب بنجاح',
                'data': {
                  'request_id': data['data']['request_id'],
                  'status': data['data']['status'],
                  'pdf_url': data['data']['pdf_url'],
                },
              };
            }
          }

          return {
            'success': false,
            'error': response.data['error'] ?? 'فشل إنشاء الطلب',
          };
        } catch (e2) {
          debugPrint('❌ [RequestsAPI] Unified path also failed: $e2');
          return {'success': false, 'error': 'حدث خطأ: $e2'};
        }
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Create advance error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 🧾 رفع فاتورة - Create Invoice
  /// ============================================
  static Future<Map<String, dynamic>> createInvoice(
    InvoiceRequest request, {
    required ProgressCallback onProgress,
  }) async {
    try {
      final file = File(request.imagePath!);
      if (!await file.exists()) {
        return {'success': false, 'error': 'ملف الصورة غير موجود'};
      }

      // التحقق من وجود الملف الأصلي
      debugPrint('📁 [RequestsAPI] Original file path: ${file.path}');
      debugPrint('📁 [RequestsAPI] Original file exists: ${await file.exists()}');
      if (await file.exists()) {
        final originalSize = await file.length();
        debugPrint('📁 [RequestsAPI] Original file size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      }

      // ضغط الصورة
      final compressedFile = await _compressImage(file);
      
      // التحقق من وجود الملف المضغوط
      debugPrint('📁 [RequestsAPI] Compressed file path: ${compressedFile.path}');
      debugPrint('📁 [RequestsAPI] Compressed file exists: ${await compressedFile.exists()}');
      if (await compressedFile.exists()) {
        final compressedSize = await compressedFile.length();
        debugPrint('📁 [RequestsAPI] Compressed file size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
      } else {
        debugPrint('❌ [RequestsAPI] Compressed file does not exist!');
        return {'success': false, 'error': 'فشل ضغط الصورة'};
      }

      // محاولة المسار المتخصص أولاً
      try {
        // محاولة مع 'invoice_image' (حسب الوثائق)
        // ملاحظة: amount يجب أن يكون String حسب التوثيق
        final multipartFile = await MultipartFile.fromFile(
          compressedFile.path,
          filename: 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        
        debugPrint('📦 [RequestsAPI] MultipartFile created: ${multipartFile.filename}');
        debugPrint('📦 [RequestsAPI] MultipartFile length: ${multipartFile.length} bytes');
        
        final formData = FormData.fromMap({
          'vendor_name': request.vendorName,
          'amount': request.amount.toString(), // تحويل إلى String
          if (request.description != null) 'description': request.description,
          'invoice_image': multipartFile,
        });

        debugPrint('🔄 [RequestsAPI] Trying specialized invoice path: ${ApiConfig.createInvoicePath}');
        debugPrint('📤 [RequestsAPI] Uploading invoice image: ${compressedFile.path}');
        debugPrint('📋 [RequestsAPI] Form data fields: vendor_name=${request.vendorName}, amount=${request.amount.toString()}');
        debugPrint('📋 [RequestsAPI] Form data fields count: ${formData.fields.length}');
        debugPrint('📋 [RequestsAPI] Form data files count: ${formData.files.length}');
        debugPrint('📋 [RequestsAPI] Form data has invoice_image: ${formData.files.any((f) => f.key == 'invoice_image')}');
        if (formData.files.isNotEmpty) {
          debugPrint('📋 [RequestsAPI] Form data files keys: ${formData.files.map((f) => f.key).join(', ')}');
        }
        
        debugPrint('🚀 [RequestsAPI] Sending POST request to: ${ApiConfig.createInvoicePath}');
        // استخدام Dio جديد بدون Content-Type افتراضي للطلبات multipart
        final token = await AuthService.getToken();
        final multipartDio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.timeoutDuration,
            receiveTimeout: ApiConfig.timeoutDuration,
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
            },
          ),
        );
        
        // إزالة أي Content-Type موجود مسبقاً لضمان أن Dio يضبطه تلقائياً
        multipartDio.options.headers.remove('Content-Type');
        
        debugPrint('📤 [RequestsAPI] Sending multipart request with ${formData.files.length} files');
        debugPrint('📋 [RequestsAPI] Form data fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');
        debugPrint('📋 [RequestsAPI] Form data files: ${formData.files.map((e) => e.key).join(', ')}');
        
        final response = await multipartDio.post(
          ApiConfig.createInvoicePath, // POST /api/v1/requests/create-invoice
          data: formData,
          onSendProgress: onProgress,
          options: Options(
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              // لا نضبط Content-Type - Dio سيفعل ذلك تلقائياً مع boundary
            },
            contentType: null, // السماح لـ Dio بضبط Content-Type تلقائياً
          ),
        );

        debugPrint('📥 [RequestsAPI] Response status code: ${response.statusCode}');
        debugPrint('📥 [RequestsAPI] Response data: ${response.data}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data as Map<String, dynamic>;
          debugPrint('✅ [RequestsAPI] Response success: ${data['success']}');
          if (data['success'] == true) {
            final requestId = data['data']?['request_id'] ?? data['data']?['id'];
            final uploadEndpoint = data['data']?['upload_endpoint'];
            
            debugPrint('✅ [RequestsAPI] Invoice request created with ID: $requestId');
            
            // محاولة رفع الصورة على Google Drive مباشرة
            // استخدام endpoint خاص لرفع صورة الفاتورة على Drive (مشابه لرفع صور الفحص)
            if (requestId != null) {
              debugPrint('📤 [RequestsAPI] Uploading invoice image to Drive...');
              try {
                // محاولة 1: استخدام endpoint خاص لرفع صورة الفاتورة على Drive
                final driveUploadResult = await _uploadInvoiceImageToDrive(
                  requestId,
                  compressedFile,
                  onProgress: onProgress,
                );
                
                if (driveUploadResult['success'] == true) {
                  final driveUrl = driveUploadResult['drive_url'];
                  debugPrint('✅ [RequestsAPI] Invoice image uploaded to Drive successfully! Drive URL: $driveUrl');
                  return {
                    'success': true,
                    'message': 'تم رفع الفاتورة والصورة على Google Drive بنجاح',
                    'data': {
                      'request_id': requestId,
                      'status': data['data']?['status'] ?? 'pending',
                      'drive_url': driveUrl,
                    },
                  };
                } else {
                  debugPrint('⚠️ [RequestsAPI] Drive upload failed, trying regular upload endpoint...');
                  
                  // محاولة 2: إذا كان هناك upload_endpoint، قم برفع الصورة تلقائياً
                  if (uploadEndpoint != null) {
                    debugPrint('📤 [RequestsAPI] Uploading image to: $uploadEndpoint');
                    try {
                      final uploadResult = await _uploadInvoiceImage(
                        requestId,
                        compressedFile,
                        uploadEndpoint: uploadEndpoint,
                        onProgress: onProgress,
                      );
                      
                      if (uploadResult['success'] == true) {
                        debugPrint('✅ [RequestsAPI] Invoice image uploaded successfully!');
                        return {
                          'success': true,
                          'message': 'تم رفع الفاتورة والصورة بنجاح',
                          'data': {
                            'request_id': requestId,
                            'status': data['data']?['status'] ?? 'pending',
                            'drive_url': uploadResult['drive_url'],
                            'file_url': uploadResult['file_url'],
                          },
                        };
                      } else {
                        debugPrint('⚠️ [RequestsAPI] Invoice created but image upload failed: ${uploadResult['error']}');
                        // الطلب تم إنشاؤه بنجاح حتى لو فشل رفع الصورة
                        return {
                          'success': true,
                          'message': 'تم إنشاء الطلب بنجاح، لكن فشل رفع الصورة. يمكنك رفعها لاحقاً',
                          'data': {
                            'request_id': requestId,
                            'status': data['data']?['status'] ?? 'pending',
                            'upload_endpoint': uploadEndpoint,
                          },
                        };
                      }
                    } catch (e) {
                      debugPrint('⚠️ [RequestsAPI] Error uploading image: $e');
                      // الطلب تم إنشاؤه بنجاح حتى لو فشل رفع الصورة
                      return {
                        'success': true,
                        'message': 'تم إنشاء الطلب بنجاح، لكن فشل رفع الصورة. يمكنك رفعها لاحقاً',
                        'data': {
                          'request_id': requestId,
                          'status': data['data']?['status'] ?? 'pending',
                          'upload_endpoint': uploadEndpoint,
                        },
                      };
                    }
                  } else {
                    // لا يوجد upload_endpoint، لكن الصورة تم حفظها محلياً
                    // محاولة رفع الصورة على Drive مباشرة
                    debugPrint('⚠️ [RequestsAPI] No upload_endpoint, but image saved locally. Trying to upload to Drive...');
                    try {
                      final driveUploadResult = await _uploadInvoiceImageToDrive(
                        requestId,
                        compressedFile,
                        onProgress: onProgress,
                      );
                      
                      if (driveUploadResult['success'] == true && driveUploadResult['drive_url'] != null) {
                        debugPrint('✅ [RequestsAPI] Invoice image uploaded to Drive successfully!');
                        return {
                          'success': true,
                          'message': 'تم رفع الفاتورة والصورة على Google Drive بنجاح',
                          'data': {
                            'request_id': requestId,
                            'status': data['data']?['status'] ?? 'pending',
                            'drive_url': driveUploadResult['drive_url'],
                            'image_saved': data['data']?['image_saved'] ?? false,
                            'local_path': data['data']?['local_path'],
                          },
                        };
                      } else {
                        debugPrint('⚠️ [RequestsAPI] Drive upload failed, but invoice created successfully');
                        return {
                          'success': true,
                          'message': data['message'] ?? 'تم رفع الفاتورة بنجاح (محلياً فقط)',
                          'data': {
                            'request_id': requestId,
                            'status': data['data']?['status'] ?? 'pending',
                            'image_saved': data['data']?['image_saved'] ?? false,
                            'local_path': data['data']?['local_path'],
                          },
                        };
                      }
                    } catch (e) {
                      debugPrint('⚠️ [RequestsAPI] Error uploading to Drive: $e');
                      return {
                        'success': true,
                        'message': data['message'] ?? 'تم رفع الفاتورة بنجاح (محلياً فقط)',
                        'data': {
                          'request_id': requestId,
                          'status': data['data']?['status'] ?? 'pending',
                          'image_saved': data['data']?['image_saved'] ?? false,
                          'local_path': data['data']?['local_path'],
                        },
                      };
                    }
                  }
                }
              } catch (e) {
                debugPrint('⚠️ [RequestsAPI] Error uploading to Drive: $e');
                // الطلب تم إنشاؤه بنجاح حتى لو فشل رفع الصورة على Drive
                return {
                  'success': true,
                  'message': 'تم إنشاء الطلب بنجاح، لكن فشل رفع الصورة على Drive. يمكنك رفعها لاحقاً',
                  'data': {
                    'request_id': requestId,
                    'status': data['data']?['status'] ?? 'pending',
                  },
                };
              }
            } else {
              // لا يوجد requestId، لكن الطلب تم بنجاح
              // محاولة رفع الصورة على Drive حتى لو لم يكن هناك requestId
              debugPrint('⚠️ [RequestsAPI] No request ID, but invoice created. Image saved locally only.');
              return {
                'success': true,
                'message': data['message'] ?? 'تم رفع الفاتورة بنجاح (محلياً)',
                'data': {
                  'status': data['data']?['status'] ?? 'pending',
                  'image_saved': data['data']?['image_saved'] ?? false,
                  'local_path': data['data']?['local_path'],
                },
              };
            }
          } else {
            debugPrint('❌ [RequestsAPI] Response success is false: ${data['message'] ?? data['error']}');
          }
        }

        // معالجة خطأ 400
        if (response.statusCode == 400) {
          final errorData = response.data;
          String errorMessage = 'فشل رفع الفاتورة';
          
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['error'] as String? ?? 
                          errorData['message'] as String? ?? 
                          errorData['errors']?.toString() ?? 
                          'البيانات المرسلة غير صحيحة. يرجى التحقق من جميع الحقول';
          }
          
          debugPrint('❌ [RequestsAPI] 400 Bad Request: $errorMessage');
          debugPrint('📋 [RequestsAPI] Response data: $errorData');
          
          return {
            'success': false,
            'error': errorMessage,
          };
        }

        return {
          'success': false,
          'error': response.data is Map ? (response.data['error'] ?? 'فشل رفع الفاتورة') : 'فشل رفع الفاتورة',
        };
      } on DioException catch (e) {
        // معالجة خطأ 400
        if (e.response?.statusCode == 400) {
          final errorData = e.response?.data;
          String errorMessage = 'فشل رفع الفاتورة';
          
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['error'] as String? ?? 
                          errorData['message'] as String? ?? 
                          errorData['errors']?.toString() ?? 
                          'البيانات المرسلة غير صحيحة. يرجى التحقق من جميع الحقول';
          }
          
          debugPrint('❌ [RequestsAPI] 400 Bad Request: $errorMessage');
          debugPrint('📋 [RequestsAPI] Response data: $errorData');
          
          return {
            'success': false,
            'error': errorMessage,
          };
        }
        
        // إذا كان الخطأ 404 أو 400، جرب المسار الموحد أو اسم حقل مختلف
        if (e.response?.statusCode == 404 || e.response?.statusCode == 400) {
          debugPrint('⚠️ [RequestsAPI] Specialized path returned ${e.response?.statusCode}, trying unified path with different field name...');
          
          // محاولة مع 'invoice_image' في المسار الموحد أيضاً (حسب التوثيق)
          try {
            final formData = FormData.fromMap({
              'type': 'invoice',
              'vendor_name': request.vendorName,
              'amount': request.amount.toString(), // تحويل إلى String
              if (request.description != null) 'description': request.description,
              'invoice_image': await MultipartFile.fromFile( // استخدام invoice_image حتى في المسار الموحد
                compressedFile.path,
                filename: 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
                contentType: MediaType('image', 'jpeg'),
              ),
            });

            debugPrint('📤 [RequestsAPI] Uploading invoice to unified path with "invoice_image" field');
            
            // استخدام Dio جديد بدون Content-Type افتراضي
            final token = await AuthService.getToken();
            final unifiedMultipartDio = Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.timeoutDuration,
                receiveTimeout: ApiConfig.timeoutDuration,
                headers: {
                  if (token != null) 'Authorization': 'Bearer $token',
                },
              ),
            );
            
            // إزالة أي Content-Type موجود مسبقاً
            unifiedMultipartDio.options.headers.remove('Content-Type');
            
            final response = await unifiedMultipartDio.post(
              ApiConfig.requestsBasePath, // POST /api/v1/requests
              data: formData,
              onSendProgress: onProgress,
              options: Options(
                headers: {
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                contentType: null, // السماح لـ Dio بضبط Content-Type تلقائياً
              ),
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
              final data = response.data as Map<String, dynamic>;
              if (data['success'] == true) {
                return {
                  'success': true,
                  'message': data['message'] ?? 'تم رفع الفاتورة بنجاح',
                  'data': {
                    'request_id': data['data']?['request_id'] ?? data['data']?['id'],
                    'status': data['data']?['status'] ?? 'pending',
                  },
                };
              }
            }

            // معالجة خطأ 400 في المسار الموحد
            if (response.statusCode == 400) {
              final errorData = response.data;
              String errorMessage = 'فشل رفع الفاتورة';
              
              if (errorData is Map<String, dynamic>) {
                errorMessage = errorData['error'] as String? ?? 
                              errorData['message'] as String? ?? 
                              errorData['errors']?.toString() ?? 
                              'البيانات المرسلة غير صحيحة';
              }
              
              debugPrint('❌ [RequestsAPI] Unified path 400 Bad Request: $errorMessage');
              return {
                'success': false,
                'error': errorMessage,
              };
            }

            return {
              'success': false,
              'error': response.data is Map ? (response.data['error'] ?? 'فشل رفع الفاتورة') : 'فشل رفع الفاتورة',
            };
          } catch (e2) {
            debugPrint('❌ [RequestsAPI] Unified path also failed: $e2');
            // إرجاع الخطأ الأصلي من المسار المتخصص
            if (e.response?.statusCode == 400) {
              final errorData = e.response?.data;
              String errorMessage = 'فشل رفع الفاتورة';
              
              if (errorData is Map<String, dynamic>) {
                errorMessage = errorData['error'] as String? ?? 
                              errorData['message'] as String? ?? 
                              errorData['errors']?.toString() ?? 
                              'البيانات المرسلة غير صحيحة. يرجى التحقق من جميع الحقول';
              }
              
              return {
                'success': false,
                'error': errorMessage,
              };
            }
            return {'success': false, 'error': 'حدث خطأ: $e2'};
          }
        }
        
        // لا حاجة لـ fallback مع 'image' - حسب التوثيق يجب استخدام 'invoice_image' فقط
        // إذا وصلنا هنا، فشلت جميع المحاولات
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Create invoice error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 🚗 إنشاء طلب غسيل سيارة - Create Car Wash
  /// ============================================
  static Future<Map<String, dynamic>> createCarWash(
    CarWashRequest request, {
    required ProgressCallback onProgress,
  }) async {
    try {
      if (!request.hasAllPhotos) {
        return {'success': false, 'error': 'يجب رفع جميع الصور المطلوبة'};
      }

      // ضغط جميع الصور
      final compressedPhotos = <String, File>{};
      for (final entry in request.photos.entries) {
        if (entry.value != null) {
          final file = File(entry.value!);
          compressedPhotos[entry.key] = await _compressImage(file);
        }
      }

      // محاولة المسار المتخصص أولاً
      try {
        // استخدام أسماء الحقول الصحيحة حسب التوثيق: photo_plate, photo_front, إلخ
        final formData = FormData.fromMap({
          // إرسال employee_id لربط الطلب بالمستخدم
          'employee_id': request.employeeId,
          // إرسال vehicle_id دائماً، واستخدم 0 عند الإدخال اليدوي
          'vehicle_id': request.vehicleId,
          'service_type': request.serviceType,
          if (request.requestedDate != null) ...{
            // بعض الخوادم تستخدم scheduled_date وأخرى requested_date
            'scheduled_date':
                request.requestedDate!.toIso8601String().split('T')[0],
            'requested_date':
                request.requestedDate!.toIso8601String().split('T')[0],
          },
          if (request.manualCarInfo != null && request.manualCarInfo!.isNotEmpty)
            'manual_car_info': request.manualCarInfo,
          // أسماء الحقول الصحيحة حسب التوثيق
          'photo_plate': await MultipartFile.fromFile(
            compressedPhotos['plate']!.path,
            filename: 'plate_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
          'photo_front': await MultipartFile.fromFile(
            compressedPhotos['front']!.path,
            filename: 'front_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
          'photo_back': await MultipartFile.fromFile(
            compressedPhotos['back']!.path,
            filename: 'back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
          'photo_right_side': await MultipartFile.fromFile(
            compressedPhotos['right_side']!.path,
            filename: 'right_side_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
          'photo_left_side': await MultipartFile.fromFile(
            compressedPhotos['left_side']!.path,
            filename: 'left_side_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        });

        debugPrint('🔄 [RequestsAPI] Trying specialized car wash path: ${ApiConfig.createCarWashPath}');
        // استخدام Dio جديد مع URL كامل للطلبات multipart
        final token = await AuthService.getToken();
        final fullUrl = '${ApiConfig.baseUrl}${ApiConfig.createCarWashPath}';
        debugPrint('📤 [RequestsAPI] Full URL: $fullUrl');
        
        // إنشاء Dio instance جديد بدون أي headers افتراضية
        final multipartDio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.timeoutDuration,
            receiveTimeout: ApiConfig.timeoutDuration,
            // لا نضيف أي headers هنا - سنضيفها في Options
          ),
        );
        
        // إزالة أي Content-Type موجود مسبقاً
        multipartDio.options.headers.remove('Content-Type');
        
        debugPrint('📤 [RequestsAPI] Sending multipart request with ${formData.files.length} files');
        debugPrint('📋 [RequestsAPI] Form data fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');
        debugPrint('📋 [RequestsAPI] Form data files: ${formData.files.map((e) => '${e.key}: ${e.value.filename}').join(', ')}');
        
        final response = await multipartDio.post(
          ApiConfig.createCarWashPath, // POST /api/v1/requests/create-car-wash
          data: formData,
          onSendProgress: onProgress,
          options: Options(
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              // لا نضبط Content-Type - Dio سيفعل ذلك تلقائياً مع boundary عند استخدام FormData
            },
            // لا نضبط contentType - Dio سيفعل ذلك تلقائياً مع boundary
            contentType: null,
          ),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            return {
              'success': true,
              'message': data['message'] ?? 'تم إنشاء الطلب بنجاح',
              'data': {
                'request_id': data['data']['request_id'],
                'status': data['data']['status'],
              },
            };
          }
        }

        // معالجة خطأ 415 في المسار المتخصص - جرب المسار الموحد مباشرة
        if (response.statusCode == 415) {
          debugPrint('⚠️ [RequestsAPI] Specialized path returned 415, trying unified path...');
          // سيتم تجربة المسار الموحد في catch block أدناه
        }

        return {
          'success': false,
          'error': response.data['error'] ?? 'فشل إنشاء الطلب',
        };
      } on DioException catch (e) {
        // معالجة أخطاء شائعة: 415/404/400 - جرب المسار الموحد وأظهر رسالة واضحة
        final statusCode = e.response?.statusCode;
        if (statusCode == 400) {
          final errorData = e.response?.data;
          String errorMessage = 'فشل إنشاء الطلب';
          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['error'] as String? ??
                errorData['message'] as String? ??
                errorData['errors']?.toString() ??
                errorMessage;
          }
          debugPrint('❌ [RequestsAPI] 400 Bad Request: $errorMessage');
          // سنستمر ونحاول المسار الموحد أيضاً
        }
        if (statusCode == 415 || statusCode == 404 || statusCode == 400) {
          debugPrint('⚠️ [RequestsAPI] Specialized path returned $statusCode, trying JSON-first then upload flow...');

          // 1) أنشئ الطلب بدون ملفات (JSON فقط)
          try {
            debugPrint('📤 [RequestsAPI] Creating car wash request as JSON first...');
            final jsonResponse = await dio.post(
              ApiConfig.requestsBasePath, // POST /api/v1/requests
              data: {
                'type': 'car_wash',
                'employee_id': request.employeeId,
                'vehicle_id': request.vehicleId,
                'service_type': request.serviceType,
                if (request.requestedDate != null)
                  'requested_date':
                      request.requestedDate!.toIso8601String().split('T')[0],
                if (request.manualCarInfo != null &&
                    request.manualCarInfo!.isNotEmpty)
                  'manual_car_info': request.manualCarInfo,
              },
            );

                if (jsonResponse.statusCode == 200 ||
                    jsonResponse.statusCode == 201) {
                  final body = jsonResponse.data as Map<String, dynamic>;
                  if (body['success'] == true) {
                    final createdId =
                        body['data']?['request_id'] ?? body['data']?['id'];
                    if (createdId is int) {
                      debugPrint(
                          '✅ [RequestsAPI] Car wash request created as JSON. ID: $createdId. Now uploading images...');

                      // 2) ارفع كل صورة بشكل منفصل باستخدام endpoint الرفع العام
                      int uploaded = 0;
                      final List<File> filesToUpload = [
                        compressedPhotos['plate']!,
                        compressedPhotos['front']!,
                        compressedPhotos['back']!,
                        compressedPhotos['right_side']!,
                        compressedPhotos['left_side']!,
                      ];

                      for (final file in filesToUpload) {
                        final uploadResult = await _uploadInvoiceImage(
                          createdId,
                          file,
                          onProgress: onProgress,
                        );
                        if (uploadResult['success'] == true) {
                          uploaded++;
                        } else {
                          debugPrint(
                              '⚠️ [RequestsAPI] Upload one image failed: ${uploadResult['error']}');
                        }
                      }

                      if (uploaded > 0) {
                        return {
                          'success': true,
                          'message':
                              'تم إنشاء الطلب ورفع $uploaded من أصل ${filesToUpload.length} صورة',
                          'data': {
                            'request_id': createdId,
                            'status': body['data']?['status'] ?? 'pending',
                            'uploaded_count': uploaded,
                          },
                        };
                      } else {
                        return {
                          'success': true,
                          'message':
                              'تم إنشاء الطلب بنجاح، لكن فشل رفع الصور. يمكنك رفعها لاحقاً من تفاصيل الطلب',
                          'data': {
                            'request_id': createdId,
                            'status': body['data']?['status'] ?? 'pending',
                            'uploaded_count': 0,
                          },
                        };
                      }
                    }
                  }
                }

            // إذا لم يتم الإنشاء بالـ JSON
            return {
              'success': false,
              'error': jsonResponse.data is Map
                  ? (jsonResponse.data['error'] ??
                      jsonResponse.data['message'] ??
                      'فشل إنشاء الطلب (JSON)')
                  : 'فشل إنشاء الطلب (JSON)',
            };
          } catch (jsonCreateError) {
            debugPrint(
                '❌ [RequestsAPI] JSON-first flow failed: $jsonCreateError');
            if (jsonCreateError is DioException) {
              final errorData = jsonCreateError.response?.data;
              String errorMessage = 'فشل إنشاء الطلب';
              if (errorData is Map<String, dynamic>) {
                errorMessage = errorData['error'] as String? ??
                    errorData['message'] as String? ??
                    errorData['errors']?.toString() ??
                    errorMessage;
              }
              return {
                'success': false,
                'error': errorMessage,
              };
            }
            return {
              'success': false,
              'error':
                  'السيرفر رفض multipart وأيضاً فشل إنشاء الطلب JSON: $jsonCreateError',
            };
          }
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Create car wash error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 🔍 إنشاء طلب فحص سيارة - Create Car Inspection
  /// POST /api/v1/requests/create-car-inspection
  /// Content-Type: multipart/form-data
  /// ============================================
  static Future<Map<String, dynamic>> createCarInspection({
    required int vehicleId,
    required String inspectionType,
    required DateTime inspectionDate,
    String? notes,
    required List<File> files,
    ProgressCallback? onProgress,
  }) async {
    try {
      // التحقق من عدد الملفات
      final images = files.where((f) {
        final ext = f.path.split('.').last.toLowerCase();
        return ['jpg', 'jpeg', 'png', 'heic'].contains(ext);
      }).toList();
      final videos = files.where((f) {
        final ext = f.path.split('.').last.toLowerCase();
        return ['mp4', 'mov', 'avi'].contains(ext);
      }).toList();

      if (images.isEmpty) {
        return {'success': false, 'error': 'يجب رفع صورة واحدة على الأقل'};
      }
      if (images.length > 20) {
        return {'success': false, 'error': 'الحد الأقصى 20 صورة'};
      }
      if (videos.length > 3) {
        return {'success': false, 'error': 'الحد الأقصى 3 فيديوهات'};
      }

      // ضغط الصور
      final compressedFiles = <File>[];
      for (final file in files) {
        final ext = file.path.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'heic'].contains(ext)) {
          compressedFiles.add(await _compressImage(file));
        } else {
          compressedFiles.add(file);
        }
      }

      // إنشاء FormData
      final formData = FormData.fromMap({
        'vehicle_id': vehicleId,
        'inspection_type': inspectionType,
        'inspection_date': inspectionDate.toIso8601String().split('T')[0],
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'files': await Future.wait(
          compressedFiles.map((f) => MultipartFile.fromFile(
            f.path,
            filename: f.path.split('/').last,
          )),
        ),
      });

      debugPrint('🔄 [RequestsAPI] Creating car inspection with ${files.length} files');
      debugPrint('📋 [RequestsAPI] Vehicle ID: $vehicleId');
      debugPrint('📋 [RequestsAPI] Inspection Type: $inspectionType');
      debugPrint('📋 [RequestsAPI] Inspection Date: ${inspectionDate.toIso8601String().split('T')[0]}');
      debugPrint('📋 [RequestsAPI] Files count: ${compressedFiles.length}');
      
      final token = await AuthService.getToken();
      
      // إنشاء Dio instance جديد بدون أي headers افتراضية
      final multipartDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
          // لا نضيف أي headers هنا - سنضيفها في Options
        ),
      );
      
      // إزالة أي Content-Type موجود مسبقاً
      multipartDio.options.headers.remove('Content-Type');
      
      debugPrint('📤 [RequestsAPI] Sending multipart request to: ${ApiConfig.createCarInspectionPath}');
      debugPrint('📋 [RequestsAPI] Form data fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');
      debugPrint('📋 [RequestsAPI] Form data files: ${formData.files.length} files');

      try {
        final response = await multipartDio.post(
          ApiConfig.createCarInspectionPath, // POST /api/v1/requests/create-car-inspection
          data: formData,
          onSendProgress: onProgress,
          options: Options(
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              // لا نضبط Content-Type - Dio سيفعل ذلك تلقائياً مع boundary عند استخدام FormData
            },
            // لا نضبط contentType - Dio سيفعل ذلك تلقائياً مع boundary
            contentType: null,
          ),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data as Map<String, dynamic>;
          if (data['success'] == true) {
            debugPrint('✅ [RequestsAPI] Car inspection created successfully: ${data['data']['request_id']}');
            return {
              'success': true,
              'message': data['message'] ?? 'تم إنشاء الطلب بنجاح',
              'data': {
                'request_id': data['data']['request_id'],
                'media_uploaded': data['data']['media_uploaded'],
              },
            };
          }
        }

        debugPrint('⚠️ [RequestsAPI] Car inspection creation failed: ${response.statusCode}');
        return {
          'success': false,
          'error': response.data['error'] ?? response.data['message'] ?? 'فشل إنشاء الطلب',
        };
      } on DioException catch (e) {
        // معالجة خطأ 415 بشكل خاص
        if (e.response?.statusCode == 415) {
          debugPrint('❌ [RequestsAPI] 415 Unsupported Media Type - server configuration issue');
          debugPrint('📋 [RequestsAPI] Response: ${e.response?.data}');
          return {
            'success': false,
            'error': 'السيرفر لا يقبل نوع المحتوى المرسل. يرجى التحقق من إعدادات السيرفر.',
          };
        }
        
        // معالجة أخطاء أخرى
        debugPrint('❌ [RequestsAPI] Create inspection DioException: ${e.type}');
        debugPrint('📋 [RequestsAPI] Status code: ${e.response?.statusCode}');
        debugPrint('📋 [RequestsAPI] Response: ${e.response?.data}');
        
        if (e.response != null) {
          return {
            'success': false,
            'error': e.response!.data['error'] ?? 
                     e.response!.data['message'] ?? 
                     'فشل إنشاء الطلب: ${e.response!.statusCode}',
          };
        }
        
        rethrow;
      } catch (e) {
        debugPrint('❌ [RequestsAPI] Create inspection error: $e');
        return {'success': false, 'error': 'حدث خطأ: $e'};
      }
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Create inspection outer error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 📤 رفع صورة فحص - Upload Inspection Image
  /// ============================================
  static Future<Map<String, dynamic>> uploadInspectionImage(
    int requestId,
    File imageFile, {
    required ProgressCallback onProgress,
  }) async {
    try {
      final compressedFile = await _compressImage(imageFile);

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          compressedFile.path,
          filename: 'inspection.jpg',
        ),
      });

      final response = await dio.post(
        '${ApiConfig.uploadInspectionImagePath}/$requestId/upload-inspection-image',
        data: formData,
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'data': {
            'media_id': data['media_id'],
            'drive_url': data['drive_url'],
          },
        };
      }

      return {'success': false, 'error': 'فشل رفع الصورة'};
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Upload image error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 🎥 رفع فيديو فحص - Upload Inspection Video
  /// ============================================
  static Future<Map<String, dynamic>> uploadInspectionVideo(
    int requestId,
    File videoFile, {
    required ProgressCallback onProgress,
  }) async {
    try {
      // التحقق من حجم الفيديو (max 500MB)
      final fileSize = await videoFile.length();
      if (fileSize > 500 * 1024 * 1024) {
        return {
          'success': false,
          'error': 'حجم الفيديو كبير جداً (الحد الأقصى 500MB)',
        };
      }

      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: videoFile.path.split('/').last,
        ),
      });

      final response = await dio.post(
        '${ApiConfig.uploadInspectionVideoPath}/$requestId/upload-inspection-video',
        data: formData,
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'data': {
            'media_id': data['media_id'],
            'drive_url': data['drive_url'],
            'upload_status': data['upload_status'],
          },
        };
      }

      return {'success': false, 'error': 'فشل رفع الفيديو'};
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Upload video error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 📄 جلب تفاصيل الطلب - Get Request Details
  /// ============================================
  static Future<Map<String, dynamic>> getRequestDetails(int requestId) async {
    try {
      debugPrint('🔄 [RequestsAPI] Getting general request details: $requestId');
      final response = await dio.get(
        '${ApiConfig.requestDetailsPath}/$requestId',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          debugPrint('✅ [RequestsAPI] Request details retrieved successfully');
          return {'success': true, 'data': data['data']};
        }
      }

      return {'success': false, 'error': 'فشل جلب التفاصيل'};
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      
      if (statusCode == 404) {
        debugPrint('⚠️ [RequestsAPI] Request not found (404): $requestId');
        return {'success': false, 'error': 'الطلب غير موجود'};
      }
      
      debugPrint('❌ [RequestsAPI] Get details error: $e');
      debugPrint('📋 [RequestsAPI] Status code: $statusCode');
      debugPrint('📋 [RequestsAPI] Response: ${e.response?.data}');
      
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 
                 e.response?.data['error'] ?? 
                 'فشل جلب التفاصيل',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Get details error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 🗑️ حذف الطلب - Delete Request
  /// ============================================
  static Future<Map<String, dynamic>> deleteRequest(int requestId) async {
    try {
      debugPrint('🔄 [RequestsAPI] Deleting request: $requestId');
      
      // محاولة المسار الأساسي
      try {
        debugPrint('🔄 [RequestsAPI] Attempting DELETE on: ${ApiConfig.deleteRequestPath}/$requestId');
        final response = await dio.delete(
          '${ApiConfig.deleteRequestPath}/$requestId',
        );

        debugPrint('📥 [RequestsAPI] DELETE response status: ${response.statusCode}');
        debugPrint('📥 [RequestsAPI] DELETE response data: ${response.data}');

        if (response.statusCode == 200 || response.statusCode == 204) {
          final data = response.data as Map<String, dynamic>?;
          if (data == null || data['success'] != false) {
            debugPrint('✅ [RequestsAPI] Request deleted successfully');
            return {
              'success': true,
              'message': 'تم حذف الطلب بنجاح',
            };
          }
        }

        // معالجة خطأ 405 (Method Not Allowed)
        if (response.statusCode == 405) {
          debugPrint('⚠️ [RequestsAPI] DELETE method not allowed (405), trying POST instead...');
          return await _tryDeleteWithPost(requestId);
        }

        // إذا كان الخطأ 404 أو 500 أو 503، جرب المسار البديل
        if (response.statusCode == 404 || 
            response.statusCode == 500 || 
            response.statusCode == 503) {
          debugPrint('⚠️ [RequestsAPI] Primary URL returned ${response.statusCode}, trying backup...');
          return await _tryBackupDeleteRequest(requestId);
        }

        final data = response.data as Map<String, dynamic>?;
        final errorMessage = data?['error'] as String? ?? 
                            data?['message'] as String? ?? 
                            'فشل حذف الطلب (${response.statusCode})';
        debugPrint('❌ [RequestsAPI] Delete failed: $errorMessage');
        return {
          'success': false,
          'error': errorMessage,
        };
      } on DioException catch (e) {
        // معالجة خطأ 405 (Method Not Allowed) - قد يتطلب POST بدلاً من DELETE
        final statusCode = e.response?.statusCode;
        if (statusCode == 405) {
          debugPrint('⚠️ [RequestsAPI] DELETE method not allowed (405), trying POST with delete action...');
          return await _tryDeleteWithPost(requestId);
        }
        
        // إذا كان الخطأ 404 أو 500 أو 503، جرب المسار البديل
        if (statusCode == 404 || statusCode == 500 || statusCode == 503) {
          debugPrint('⚠️ [RequestsAPI] Primary URL failed with $statusCode, trying backup...');
          return await _tryBackupDeleteRequest(requestId);
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Delete request error: $e');
      return {
        'success': false,
        'error': 'حدث خطأ: ${_getErrorMessage(e)}',
      };
    }
  }

  /// ============================================
  /// 🔄 محاولة الحذف باستخدام POST بدلاً من DELETE
  /// ============================================
  static Future<Map<String, dynamic>> _tryDeleteWithPost(int requestId) async {
    try {
      debugPrint('🔄 [RequestsAPI] Trying DELETE with POST method for request: $requestId');
      
      // محاولة 1: POST مع action: 'delete'
      try {
        final response = await dio.post(
          '${ApiConfig.deleteRequestPath}/$requestId/delete',
          data: {'action': 'delete'},
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data as Map<String, dynamic>?;
          if (data == null || data['success'] != false) {
            debugPrint('✅ [RequestsAPI] Request deleted successfully (POST method)');
            return {
              'success': true,
              'message': 'تم حذف الطلب بنجاح',
            };
          }
        }
      } catch (e) {
        debugPrint('⚠️ [RequestsAPI] POST /delete failed: $e');
      }
      
      // محاولة 2: POST مباشرة على نفس المسار مع _method
      try {
        final response = await dio.post(
          '${ApiConfig.deleteRequestPath}/$requestId',
          data: {'_method': 'DELETE'},
        );
        
        if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
          debugPrint('✅ [RequestsAPI] Request deleted successfully (POST with _method)');
          return {
            'success': true,
            'message': 'تم حذف الطلب بنجاح',
          };
        }
      } catch (e) {
        debugPrint('⚠️ [RequestsAPI] POST with _method failed: $e');
      }
      
      // محاولة 3: POST بدون بيانات
      try {
        final response = await dio.post(
          '${ApiConfig.deleteRequestPath}/$requestId',
        );
        
        if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
          final data = response.data as Map<String, dynamic>?;
          if (data == null || data['success'] != false) {
            debugPrint('✅ [RequestsAPI] Request deleted successfully (POST without data)');
            return {
              'success': true,
              'message': 'تم حذف الطلب بنجاح',
            };
          }
        }
      } catch (e) {
        debugPrint('⚠️ [RequestsAPI] POST without data failed: $e');
      }
      
      // محاولة 4: PUT مع action: delete
      try {
        final response = await dio.put(
          '${ApiConfig.deleteRequestPath}/$requestId',
          data: {'action': 'delete', 'status': 'deleted'},
        );
        
        if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
          debugPrint('✅ [RequestsAPI] Request deleted successfully (PUT method)');
          return {
            'success': true,
            'message': 'تم حذف الطلب بنجاح',
          };
        }
      } catch (e) {
        debugPrint('⚠️ [RequestsAPI] PUT method failed: $e');
      }
      
      return {
        'success': false,
        'error': 'فشل حذف الطلب. السيرفر لا يدعم DELETE method وجميع المحاولات البديلة فشلت',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Delete with POST error: $e');
      return {
        'success': false,
        'error': 'حدث خطأ: ${_getErrorMessage(e)}',
      };
    }
  }

  /// محاولة حذف الطلب من المسار البديل
  static Future<Map<String, dynamic>> _tryBackupDeleteRequest(
    int requestId,
  ) async {
    try {
      final backupUrl = '${ApiConfig.backupDomain}${ApiConfig.deleteRequestPath}/$requestId';
      debugPrint('🔄 [RequestsAPI] Trying backup URL: $backupUrl');

      // استخدام Dio جديد مع baseUrl فارغ للسماح بـ URL كامل
      // إضافة JWT token للطلبات البديلة
      final token = await AuthService.getToken();
      final backupDio = Dio(
        BaseOptions(
          baseUrl: '',
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final response = await backupDio.delete(backupUrl);

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ [RequestsAPI] Request deleted from backup URL');
        return {
          'success': true,
          'message': 'تم حذف الطلب بنجاح',
        };
      }

      return {
        'success': false,
        'error': 'فشل حذف الطلب من الخادم البديل',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Backup delete error: $e');
      return {
        'success': false,
        'error': 'حدث خطأ: ${_getErrorMessage(e)}',
      };
    }
  }

  /// ============================================
  /// 📤 رفع صورة السلفة على Google Drive - Upload Advance Image to Drive
  /// ============================================
  static Future<Map<String, dynamic>> _uploadAdvanceImageToDrive(
    int requestId,
    File imageFile, {
    required ProgressCallback onProgress,
  }) async {
    try {
      debugPrint('📤 [RequestsAPI] Uploading advance image to Drive for request: $requestId');
      
      final compressedFile = await _compressImage(imageFile);
      
      // استخدام نفس endpoint المستخدم لرفع صور الفحص (يعيد drive_url)
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressedFile.path,
          filename: 'advance_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'file_type': 'image',
      });
      
      // استخدام Dio جديد بدون Content-Type افتراضي
      final token = await AuthService.getToken();
      final multipartDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      
      // محاولة استخدام endpoint خاص لرفع صورة السلفة على Drive
      // إذا لم يكن متوفراً، استخدم endpoint عام
      final endpoints = [
        '/api/v1/requests/$requestId/upload-advance-image', // endpoint خاص للسلفة
        '/api/v1/requests/$requestId/upload', // endpoint عام
      ];
      
      for (final endpoint in endpoints) {
        try {
          debugPrint('🔄 [RequestsAPI] Trying endpoint: $endpoint');
          final response = await multipartDio.post(
            endpoint,
            data: formData,
            onSendProgress: onProgress,
          );
          
          debugPrint('📥 [RequestsAPI] Drive upload response status: ${response.statusCode}');
          debugPrint('📥 [RequestsAPI] Drive upload response data: ${response.data}');
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data as Map<String, dynamic>;
            if (data['success'] == true) {
              final driveUrl = data['drive_url'] ?? data['data']?['drive_url'];
              final fileUrl = data['file_url'] ?? data['data']?['file_url'];
              
              if (driveUrl != null) {
                debugPrint('✅ [RequestsAPI] Advance image uploaded to Drive! URL: $driveUrl');
                return {
                  'success': true,
                  'drive_url': driveUrl,
                  'message': 'تم رفع الصورة على Google Drive بنجاح',
                };
              } else if (fileUrl != null) {
                debugPrint('⚠️ [RequestsAPI] Image uploaded to server but no Drive URL. File URL: $fileUrl');
                return {
                  'success': true,
                  'file_url': fileUrl,
                  'message': 'تم رفع الصورة على السيرفر (لم يتم رفعها على Drive)',
                };
              } else {
                debugPrint('⚠️ [RequestsAPI] Upload successful but no drive_url or file_url in response');
                return {
                  'success': true,
                  'message': 'تم رفع الصورة بنجاح (لم يتم إرجاع رابط Drive)',
                };
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [RequestsAPI] Endpoint $endpoint failed: $e');
          continue;
        }
      }
      
      return {
        'success': false,
        'error': 'فشل رفع الصورة على Google Drive',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Upload advance image to Drive error: $e');
      return {
        'success': false,
        'error': 'حدث خطأ أثناء رفع الصورة على Drive: $e',
      };
    }
  }

  /// ============================================
  /// 📤 رفع صورة الفاتورة على Google Drive - Upload Invoice Image to Drive
  /// ============================================
  static Future<Map<String, dynamic>> _uploadInvoiceImageToDrive(
    int requestId,
    File imageFile, {
    required ProgressCallback onProgress,
  }) async {
    try {
      debugPrint('📤 [RequestsAPI] Uploading invoice image to Drive for request: $requestId');
      
      final compressedFile = await _compressImage(imageFile);
      
      // استخدام نفس endpoint المستخدم لرفع صور الفحص (يعيد drive_url)
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressedFile.path,
          filename: 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'file_type': 'image',
      });
      
      // استخدام Dio جديد بدون Content-Type افتراضي
      final token = await AuthService.getToken();
      final multipartDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      
      // محاولة استخدام endpoint خاص لرفع صورة الفاتورة على Drive
      // إذا لم يكن متوفراً، استخدم endpoint عام
      final endpoints = [
        '/api/v1/requests/$requestId/upload-invoice-image', // endpoint خاص للفاتورة
        '/api/v1/requests/$requestId/upload', // endpoint عام
      ];
      
      for (final endpoint in endpoints) {
        try {
          debugPrint('🔄 [RequestsAPI] Trying endpoint: $endpoint');
          final response = await multipartDio.post(
            endpoint,
            data: formData,
            onSendProgress: onProgress,
          );
          
          debugPrint('📥 [RequestsAPI] Drive upload response status: ${response.statusCode}');
          debugPrint('📥 [RequestsAPI] Drive upload response data: ${response.data}');
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = response.data as Map<String, dynamic>;
            if (data['success'] == true) {
              final driveUrl = data['drive_url'] ?? data['data']?['drive_url'];
              final fileUrl = data['file_url'] ?? data['data']?['file_url'];
              
              if (driveUrl != null) {
                debugPrint('✅ [RequestsAPI] Invoice image uploaded to Drive! URL: $driveUrl');
                return {
                  'success': true,
                  'drive_url': driveUrl,
                  'message': 'تم رفع الصورة على Google Drive بنجاح',
                };
              } else if (fileUrl != null) {
                debugPrint('⚠️ [RequestsAPI] Image uploaded to server but no Drive URL. File URL: $fileUrl');
                return {
                  'success': true,
                  'file_url': fileUrl,
                  'message': 'تم رفع الصورة على السيرفر (لم يتم رفعها على Drive)',
                };
              } else {
                debugPrint('⚠️ [RequestsAPI] Upload successful but no drive_url or file_url in response');
                return {
                  'success': true,
                  'message': 'تم رفع الصورة بنجاح (لم يتم إرجاع رابط Drive)',
                };
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [RequestsAPI] Endpoint $endpoint failed: $e');
          continue;
        }
      }
      
      return {
        'success': false,
        'error': 'فشل رفع الصورة على Google Drive',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Upload invoice image to Drive error: $e');
      return {
        'success': false,
        'error': 'حدث خطأ أثناء رفع الصورة على Drive: $e',
      };
    }
  }

  /// ============================================
  /// ============================================
  /// 📤 رفع صورة الفاتورة - Upload Invoice Image
  /// ============================================
  static Future<Map<String, dynamic>> _uploadInvoiceImage(
    int requestId,
    File imageFile, {
    String? uploadEndpoint,
    required ProgressCallback onProgress,
  }) async {
    try {
      // إذا كان uploadEndpoint مساراً نسبياً، أضف baseUrl
      String endpoint;
      if (uploadEndpoint != null) {
        if (uploadEndpoint.startsWith('http')) {
          endpoint = uploadEndpoint; // URL كامل
        } else {
          endpoint = '${ApiConfig.baseUrl}$uploadEndpoint'; // مسار نسبي
        }
      } else {
        endpoint = '${ApiConfig.baseUrl}/api/v1/requests/$requestId/upload';
      }
      debugPrint('📤 [RequestsAPI] Uploading invoice image to: $endpoint');
      
      // حسب التوثيق، يجب أن يكون files قائمة ملفات
      // لكن قد يكون السيرفر يتوقع file (مفرد) أو files (جمع)
      final multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: 'invoice_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      
      debugPrint('📦 [RequestsAPI] MultipartFile size: ${multipartFile.length} bytes');
      
      // استخدام FormData مباشرة وإضافة الملفات يدوياً
      // حسب التوثيق: file: [file] - يجب أن يكون file (مفرد) مع قائمة ملفات
      final formData = FormData();
      formData.files.add(MapEntry('file', multipartFile)); // استخدام 'file' (مفرد) مع ملف واحد
      formData.fields.add(MapEntry('file_type', 'image'));
      
      debugPrint('📦 [RequestsAPI] FormData created with files: ${formData.files.length}');
      debugPrint('📦 [RequestsAPI] FormData file key: ${formData.files.first.key}');

      debugPrint('📦 [RequestsAPI] Upload form data created');
      
      // استخدام Dio مع baseUrl فارغ للسماح بـ URL كامل
      final uploadDio = Dio(
        BaseOptions(
          baseUrl: '',
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
        ),
      );
      
      // إضافة JWT token
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        uploadDio.options.headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await uploadDio.post(
        endpoint,
        data: formData,
        onSendProgress: onProgress,
      );

      debugPrint('📥 [RequestsAPI] Upload response status: ${response.statusCode}');
      debugPrint('📥 [RequestsAPI] Upload response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          // التحقق من وجود drive_url في الـ response
          final driveUrl = data['drive_url'] ?? data['data']?['drive_url'];
          final fileUrl = data['file_url'] ?? data['data']?['file_url'];
          final uploadedFiles = data['uploaded_files'] as List?;
          
          if (driveUrl != null) {
            debugPrint('✅ [RequestsAPI] Image uploaded to Drive successfully! Drive URL: $driveUrl');
            return {
              'success': true,
              'message': data['message'] ?? 'تم رفع الصورة على Google Drive بنجاح',
              'drive_url': driveUrl,
            };
          } else if (fileUrl != null) {
            debugPrint('✅ [RequestsAPI] Image uploaded to server successfully! File URL: $fileUrl');
            return {
              'success': true,
              'message': data['message'] ?? 'تم رفع الصورة على السيرفر بنجاح',
              'file_url': fileUrl,
            };
          } else if (uploadedFiles != null && uploadedFiles.isNotEmpty) {
            debugPrint('✅ [RequestsAPI] Image uploaded successfully! Files: ${uploadedFiles.length}');
            return {
              'success': true,
              'message': data['message'] ?? 'تم رفع الصورة بنجاح',
            };
          } else {
            // إذا كان success: true لكن uploaded_files فارغ، جرب طرق أخرى
            debugPrint('⚠️ [RequestsAPI] Success but no files uploaded. Trying alternative methods...');
            
            // محاولة 1: بدون file_type
            try {
              final retryFormData = FormData();
              retryFormData.files.add(MapEntry('file', multipartFile));
              debugPrint('🔄 [RequestsAPI] Retry 1: file without file_type');
              
              final retryResponse = await uploadDio.post(
                endpoint,
                data: retryFormData,
                onSendProgress: onProgress,
              );
              
              if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
                final retryData = retryResponse.data as Map<String, dynamic>;
                final retryUploadedFiles = retryData['uploaded_files'] as List?;
                if (retryUploadedFiles != null && retryUploadedFiles.isNotEmpty) {
                  debugPrint('✅ [RequestsAPI] Image uploaded successfully (without file_type)!');
                  return {
                    'success': true,
                    'message': retryData['message'] ?? 'تم رفع الصورة بنجاح',
                  };
                }
              }
            } catch (e) {
              debugPrint('⚠️ [RequestsAPI] Retry 1 failed: $e');
            }
            
            // محاولة 2: files (جمع) بدون قائمة
            try {
              final retryFormData = FormData();
              retryFormData.files.add(MapEntry('files', multipartFile));
              retryFormData.fields.add(MapEntry('file_type', 'image'));
              debugPrint('🔄 [RequestsAPI] Retry 2: files (plural) without list');
              
              final retryResponse = await uploadDio.post(
                endpoint,
                data: retryFormData,
                onSendProgress: onProgress,
              );
              
              if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
                final retryData = retryResponse.data as Map<String, dynamic>;
                final retryUploadedFiles = retryData['uploaded_files'] as List?;
                if (retryUploadedFiles != null && retryUploadedFiles.isNotEmpty) {
                  debugPrint('✅ [RequestsAPI] Image uploaded successfully (with files plural)!');
                  return {
                    'success': true,
                    'message': retryData['message'] ?? 'تم رفع الصورة بنجاح',
                  };
                }
              }
            } catch (e) {
              debugPrint('⚠️ [RequestsAPI] Retry 2 failed: $e');
            }
            
            // إذا فشلت جميع المحاولات
            debugPrint('❌ [RequestsAPI] All upload attempts failed');
            return {
              'success': false,
              'error': 'فشل رفع الصورة. السيرفر لم يقبل الملف',
            };
          }
        }
      }

      return {
        'success': false,
        'error': response.data is Map ? (response.data['error'] ?? 'فشل رفع الصورة') : 'فشل رفع الصورة',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Upload invoice image error: $e');
      return {
        'success': false,
        'error': 'حدث خطأ أثناء رفع الصورة: $e',
      };
    }
  }

  /// ============================================
  /// 🚗 جلب تفاصيل طلب غسيل سيارة - Get Car Wash Request Details
  /// GET /api/v1/requests/car-wash/{request_id}
  /// ============================================
  static Future<Map<String, dynamic>> getCarWashRequestDetails(int requestId) async {
    try {
      debugPrint('🔄 [RequestsAPI] Getting car wash request details: $requestId');
      final response = await dio.get(
        '/api/v1/requests/car-wash/$requestId',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          debugPrint('✅ [RequestsAPI] Car wash details retrieved successfully');
          return {
            'success': true,
            'data': data['request'],
          };
        }
      }

      return {
        'success': false,
        'error': response.data['message'] ?? 'فشل جلب التفاصيل',
      };
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      
      // معالجة الأخطاء الشائعة بشكل صامت (لأننا سنحاول المسار العام لاحقاً)
      if (statusCode == 404) {
        debugPrint('⚠️ [RequestsAPI] Car wash endpoint not found (404) - trying general endpoint');
        return {'success': false, 'error': 'not_found'};
      }
      
      if (statusCode == 405) {
        debugPrint('⚠️ [RequestsAPI] Car wash method not allowed (405) - endpoint may not support GET');
        return {'success': false, 'error': 'method_not_allowed'};
      }
      
      debugPrint('❌ [RequestsAPI] Get car wash details error: $e');
      return {'success': false, 'error': 'حدث خطأ: ${_getErrorMessage(e)}'};
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Get car wash details error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 🔍 جلب تفاصيل طلب فحص سيارة - Get Car Inspection Request Details
  /// GET /api/v1/requests/car-inspection/{request_id}
  /// ============================================
  static Future<Map<String, dynamic>> getCarInspectionRequestDetails(int requestId) async {
    try {
      debugPrint('🔄 [RequestsAPI] Getting car inspection request details: $requestId');
      final response = await dio.get(
        '/api/v1/requests/car-inspection/$requestId',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['request'],
          };
        }
      }

      return {
        'success': false,
        'error': response.data['message'] ?? 'فشل جلب التفاصيل',
      };
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      
      // معالجة الأخطاء الشائعة بشكل صامت (لأننا سنحاول المسار العام لاحقاً)
      if (statusCode == 404) {
        debugPrint('⚠️ [RequestsAPI] Car inspection endpoint not found (404) - trying general endpoint');
        return {'success': false, 'error': 'not_found'};
      }
      
      if (statusCode == 405) {
        debugPrint('⚠️ [RequestsAPI] Car inspection method not allowed (405) - endpoint may not support GET');
        return {'success': false, 'error': 'method_not_allowed'};
      }
      
      debugPrint('❌ [RequestsAPI] Get car inspection details error: $e');
      return {'success': false, 'error': 'حدث خطأ: ${_getErrorMessage(e)}'};
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Get car inspection details error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 🚗 قائمة طلبات الغسيل - Get Car Wash Requests
  /// GET /api/v1/requests/car-wash
  /// ============================================
  static Future<Map<String, dynamic>> getCarWashRequests({
    String? status,
    int? vehicleId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (status != null && status.isNotEmpty) 'status': status,
        if (vehicleId != null) 'vehicle_id': vehicleId,
        if (fromDate != null) 'from_date': fromDate.toIso8601String().split('T')[0],
        if (toDate != null) 'to_date': toDate.toIso8601String().split('T')[0],
      };

      debugPrint('🔄 [RequestsAPI] Getting car wash requests: $queryParams');
      final response = await dio.get(
        '/api/v1/requests/car-wash',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['requests'],
            'pagination': data['pagination'],
          };
        }
      }

      return {
        'success': false,
        'error': response.data['message'] ?? 'فشل جلب الطلبات',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Get car wash requests error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 🔍 قائمة طلبات الفحص - Get Car Inspection Requests
  /// GET /api/v1/requests/car-inspection
  /// ============================================
  static Future<Map<String, dynamic>> getCarInspectionRequests({
    String? status,
    int? vehicleId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (status != null && status.isNotEmpty) 'status': status,
        if (vehicleId != null) 'vehicle_id': vehicleId,
        if (fromDate != null) 'from_date': fromDate.toIso8601String().split('T')[0],
        if (toDate != null) 'to_date': toDate.toIso8601String().split('T')[0],
      };

      debugPrint('🔄 [RequestsAPI] Getting car inspection requests: $queryParams');
      final response = await dio.get(
        '/api/v1/requests/car-inspection',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['requests'],
            'pagination': data['pagination'],
          };
        }
      }

      return {
        'success': false,
        'error': response.data['message'] ?? 'فشل جلب الطلبات',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Get car inspection requests error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// ✏️ تحديث طلب غسيل سيارة - Update Car Wash Request
  /// PUT /api/v1/requests/car-wash/{request_id}
  /// ============================================
  static Future<Map<String, dynamic>> updateCarWashRequest({
    required int requestId,
    int? vehicleId,
    String? serviceType,
    DateTime? scheduledDate,
    String? notes,
    File? photoPlate,
    File? photoFront,
    File? photoBack,
    File? photoRightSide,
    File? photoLeftSide,
    List<int>? deleteMediaIds,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (vehicleId != null) 'vehicle_id': vehicleId,
        if (serviceType != null) 'service_type': serviceType,
        if (scheduledDate != null) 'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (photoPlate != null)
          'photo_plate': await MultipartFile.fromFile(photoPlate.path),
        if (photoFront != null)
          'photo_front': await MultipartFile.fromFile(photoFront.path),
        if (photoBack != null)
          'photo_back': await MultipartFile.fromFile(photoBack.path),
        if (photoRightSide != null)
          'photo_right_side': await MultipartFile.fromFile(photoRightSide.path),
        if (photoLeftSide != null)
          'photo_left_side': await MultipartFile.fromFile(photoLeftSide.path),
        if (deleteMediaIds != null && deleteMediaIds.isNotEmpty)
          'delete_media_ids': deleteMediaIds,
      });

      debugPrint('🔄 [RequestsAPI] Updating car wash request: $requestId');
      final token = await AuthService.getToken();
      final multipartDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      multipartDio.options.headers.remove('Content-Type');

      final response = await multipartDio.put(
        '/api/v1/requests/car-wash/$requestId',
        data: formData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          contentType: null,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'تم تحديث الطلب بنجاح',
            'data': data['request'],
          };
        }
      }

      return {
        'success': false,
        'error': response.data['message'] ?? 'فشل تحديث الطلب',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Update car wash error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// ✏️ تحديث طلب فحص سيارة - Update Car Inspection Request
  /// PUT /api/v1/requests/car-inspection/{request_id}
  /// ============================================
  static Future<Map<String, dynamic>> updateCarInspectionRequest({
    required int requestId,
    int? vehicleId,
    String? inspectionType,
    DateTime? inspectionDate,
    String? notes,
    List<File>? newFiles,
    List<int>? deleteMediaIds,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (vehicleId != null) 'vehicle_id': vehicleId,
        if (inspectionType != null) 'inspection_type': inspectionType,
        if (inspectionDate != null) 'inspection_date': inspectionDate.toIso8601String().split('T')[0],
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (newFiles != null && newFiles.isNotEmpty)
          'files': await Future.wait(
            newFiles.map((f) => MultipartFile.fromFile(f.path)),
          ),
        if (deleteMediaIds != null && deleteMediaIds.isNotEmpty)
          'delete_media_ids': deleteMediaIds,
      });

      debugPrint('🔄 [RequestsAPI] Updating car inspection request: $requestId');
      final token = await AuthService.getToken();
      final multipartDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.timeoutDuration,
          receiveTimeout: ApiConfig.timeoutDuration,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      multipartDio.options.headers.remove('Content-Type');

      final response = await multipartDio.put(
        '/api/v1/requests/car-inspection/$requestId',
        data: formData,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
          contentType: null,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'تم تحديث الطلب بنجاح',
            'data': data['request'],
          };
        }
      }

      return {
        'success': false,
        'error': response.data['message'] ?? 'فشل تحديث الطلب',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Update car inspection error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 🗑️ حذف صورة من طلب غسيل - Delete Car Wash Media
  /// DELETE /api/v1/requests/car-wash/{request_id}/media/{media_id}
  /// ============================================
  static Future<Map<String, dynamic>> deleteCarWashMedia(int requestId, int mediaId) async {
    try {
      debugPrint('🔄 [RequestsAPI] Deleting car wash media: $requestId/$mediaId');
      final response = await dio.delete(
        '/api/v1/requests/car-wash/$requestId/media/$mediaId',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'تم حذف الصورة بنجاح',
            'remaining_media_count': data['remaining_media_count'],
          };
        }
      }

      return {
        'success': false,
        'error': response.data['message'] ?? 'فشل حذف الصورة',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Delete car wash media error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// ============================================
  /// 🗑️ حذف ملف من طلب فحص - Delete Car Inspection Media
  /// DELETE /api/v1/requests/car-inspection/{request_id}/media/{media_id}
  /// ============================================
  static Future<Map<String, dynamic>> deleteCarInspectionMedia(int requestId, int mediaId) async {
    try {
      debugPrint('🔄 [RequestsAPI] Deleting car inspection media: $requestId/$mediaId');
      final response = await dio.delete(
        '/api/v1/requests/car-inspection/$requestId/media/$mediaId',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'تم حذف الملف بنجاح',
            'remaining_media': data['remaining_media'],
          };
        }
      }

      return {
        'success': false,
        'error': response.data['message'] ?? 'فشل حذف الملف',
      };
    } catch (e) {
      debugPrint('❌ [RequestsAPI] Delete car inspection media error: $e');
      return {'success': false, 'error': 'حدث خطأ: $e'};
    }
  }

  /// 🗜️ ضغط الصورة - Compress Image
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
        minHeight: 1080,
      );

      return File(result!.path);
    } catch (e) {
      debugPrint('⚠️ [RequestsAPI] Compression failed, using original: $e');
      return file;
    }
  }
}
