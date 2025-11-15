import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';
import '../models/attendance_record.dart';
import '../models/face_model.dart';
import '../config/api_config.dart';
import 'face_recognition_service.dart';
import 'liveness_detection_service.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// ============================================
/// ✅ خدمة التحضير - Attendance Service
/// ============================================
class AttendanceService {
  final FaceRecognitionService _faceService;
  final LivenessDetectionService _livenessService;
  
  // إعدادات الموقع
  double? _workLatitude;
  double? _workLongitude;
  double _allowedRadius = 50.0; // 50 متر

  // إعدادات الأمان - Rate Limiting
  static const int _maxAttemptsPerHour = 3; // حد أقصى 3 محاولات في الساعة
  static const int _cooldownMinutes = 30; // 30 دقيقة بعد 3 محاولات فاشلة
  static const int _minTimeBetweenCheckIns = 60; // 60 ثانية بين محاولات التحضير

  AttendanceService({
    FaceRecognitionService? faceService,
    LivenessDetectionService? livenessService,
  })  : _faceService = faceService ?? FaceRecognitionService(),
        _livenessService = livenessService ?? LivenessDetectionService();

  /// تسجيل الوجه للموظف (Enrollment)
  Future<EnrollmentResult> enrollFace({
    required String employeeId,
    required File faceImage,
  }) async {
    try {
      // 1. اكتشاف الوجه
      final detectionResult = await _faceService.detectFaceFromFile(faceImage);
      
      if (detectionResult == null || !detectionResult.hasFace || detectionResult.face == null) {
        return EnrollmentResult(
          success: false,
          error: detectionResult?.message ?? 'لم يتم اكتشاف وجه',
        );
      }

      // 2. التحقق من جودة الوجه (معايير أكثر مرونة)
      if (detectionResult.quality == FaceQuality.poor) {
        // إعطاء توجيهات محددة للمستخدم
        String qualityTips = 'جودة الصورة ضعيفة. يرجى:\n';
        qualityTips += '• الاقتراب من الكاميرا أكثر\n';
        qualityTips += '• التأكد من إضاءة جيدة\n';
        qualityTips += '• النظر مباشرة للكاميرا\n';
        qualityTips += '• فتح العيون بشكل كامل\n';
        qualityTips += '• إبقاء الرأس مستقيماً';
        
        return EnrollmentResult(
          success: false,
          error: qualityTips,
        );
      }
      
      // قبول الجودة "fair" أيضاً (كانت مرفوضة سابقاً)
      if (detectionResult.quality == FaceQuality.fair) {
        debugPrint('⚠️ [Attendance] Face quality is fair, but accepting for enrollment');
      }

      // 3. استخراج الميزات
      final features = _faceService.extractFaceFeatures(detectionResult.face!);

      // 4. حفظ البيانات
      final faceData = FaceData(
        employeeId: employeeId,
        features: features,
        enrolledAt: DateTime.now(),
        imagePath: faceImage.path,
      );

      await _saveFaceData(faceData);

      return EnrollmentResult(
        success: true,
        faceData: faceData,
        quality: detectionResult.quality,
        confidence: detectionResult.confidence ?? 0.0,
      );
    } catch (e) {
      debugPrint('❌ [Attendance] Enrollment error: $e');
      return EnrollmentResult(
        success: false,
        error: 'حدث خطأ أثناء التسجيل: $e',
      );
    }
  }

  /// تسجيل التحضير (Check-in)
  Future<AttendanceResult> checkIn({
    required String employeeId,
    required Function(Face) onFaceDetected, // Callback للحصول على الوجه
  }) async {
    try {
      // 1. التحقق من وجود بيانات الوجه
      final storedFaceData = await _loadFaceData(employeeId);
      if (storedFaceData == null) {
        return AttendanceResult(
          success: false,
          error: 'لم يتم تسجيل الوجه. يرجى التسجيل أولاً',
        );
      }

      // 2. التحقق من الموقع
      final locationResult = await _verifyLocation();
      if (!locationResult.isValid) {
        return AttendanceResult(
          success: false,
          error: locationResult.error ?? 'الموقع غير صحيح',
          locationData: locationResult,
        );
      }

      // 3. انتظار اكتشاف الوجه من الكاميرا
      // (سيتم استدعاء onFaceDetected من الكاميرا)
      // هذا يتطلب integration مع Camera Widget

      return AttendanceResult(
        success: false,
        error: 'يجب استخدام checkInWithFace بدلاً من ذلك',
      );
    } catch (e) {
      debugPrint('❌ [Attendance] Check-in error: $e');
      return AttendanceResult(
        success: false,
        error: 'حدث خطأ: $e',
      );
    }
  }

  /// تسجيل التحضير مع الوجه المكتشف
  Future<AttendanceResult> checkInWithFace({
    required String employeeId,
    required Face detectedFace,
    File? capturedImage,
  }) async {
    try {
      // 1. التحقق من وجود بيانات الوجه
      final storedFaceData = await _loadFaceData(employeeId);
      if (storedFaceData == null) {
        return AttendanceResult(
          success: false,
          error: 'لم يتم تسجيل الوجه. يرجى التسجيل أولاً',
        );
      }

      // 2. Liveness Detection
      _livenessService.reset();
      final livenessResult = await _livenessService.checkLiveness(detectedFace);
      
      if (!livenessResult.isLive) {
        // تسجيل محاولة فاشلة
        await _recordFailedAttempt(employeeId);
        
        return AttendanceResult(
          success: false,
          error: livenessResult.reason,
          livenessData: livenessResult,
        );
      }

      // 3. Face Matching - مقارنة الوجه المكتشف مع الوجه المسجل
      double confidence = 0.0;
      Face? capturedFace = detectedFace;
      
      // إذا كان لدينا صورة محفوظة، نستخدمها للمقارنة
      if (capturedImage != null) {
        final detectionResult = await _faceService.detectFaceFromFile(capturedImage);
        if (detectionResult != null && detectionResult.hasFace && detectionResult.face != null) {
          capturedFace = detectionResult.face;
          confidence = detectionResult.confidence ?? 0.0;
        } else {
          // استخدام جودة الوجه المكتشف مباشرة
          confidence = _faceService.calculateConfidence(detectedFace);
        }
      } else {
        // استخدام جودة الوجه مباشرة
        confidence = _faceService.calculateConfidence(detectedFace);
      }

      // محاولة مقارنة الوجوه إذا كان لدينا بيانات الوجه المسجل
      if (capturedFace != null) {
        try {
          // استخراج ميزات الوجه الحالي
          final currentFeatures = _faceService.extractFaceFeatures(capturedFace);
          
          // مقارنة بسيطة بناءً على landmarks
          final similarity = _compareFaceFeatures(
            storedFaceData.features,
            currentFeatures,
          );
          
          // استخدام أعلى قيمة بين confidence و similarity
          confidence = (confidence + similarity) / 2.0;
          
          debugPrint('🔍 [Attendance] Face similarity: ${(similarity * 100).toStringAsFixed(1)}%');
        } catch (e) {
          debugPrint('⚠️ [Attendance] Face comparison error: $e, using confidence only');
        }
      }

      // 3.1. التحقق من الاتصال بالإنترنت (مطلوب للتحقق من السيرفر)
      try {
        final connectivityResult = await _checkInternetConnection();
        if (!connectivityResult) {
          return AttendanceResult(
            success: false,
            error: 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال والمحاولة مرة أخرى',
          );
        }
      } catch (e) {
        debugPrint('⚠️ [Attendance] Internet check error: $e');
        // نستمر في حالة الخطأ
      }

      // 3.2. Rate Limiting - منع المحاولات المتكررة
      final rateLimitResult = await _checkRateLimit(employeeId);
      if (!rateLimitResult.allowed) {
        return AttendanceResult(
          success: false,
          error: rateLimitResult.message,
        );
      }

      // 3.3. Time-based Check - منع التحضير المتكرر في نفس اليوم
      final timeCheckResult = await _checkTimeRestrictions(employeeId);
      if (!timeCheckResult.allowed) {
        return AttendanceResult(
          success: false,
          error: timeCheckResult.message,
        );
      }

      // 3.3. Face Matching Threshold - رفع إلى 75% للأمان
      if (confidence < 0.75) {
        // تسجيل محاولة فاشلة
        await _recordFailedAttempt(employeeId);
        
        return AttendanceResult(
          success: false,
          error: 'الثقة في التعرف منخفضة (${(confidence * 100).toStringAsFixed(0)}%). يرجى المحاولة مرة أخرى',
          confidence: confidence,
        );
      }

      // 4. التحقق من الموقع
      final locationResult = await _verifyLocation();
      if (!locationResult.isValid) {
        // تسجيل محاولة فاشلة
        await _recordFailedAttempt(employeeId);
        
        return AttendanceResult(
          success: false,
          error: locationResult.error ?? 'الموقع غير صحيح',
          locationData: locationResult,
        );
      }

      // 5. إنشاء سجل التحضير
      final record = AttendanceRecord(
        employeeId: employeeId,
        timestamp: DateTime.now(),
        type: AttendanceType.check_in,
        location: LocationData(
          latitude: locationResult.latitude,
          longitude: locationResult.longitude,
          accuracy: locationResult.accuracy,
        ),
        confidence: confidence,
        livenessScore: livenessResult.confidence,
        imagePath: capturedImage?.path,
      );

      // 5. التحقق من السيرفر (إجباري - لا يمكن التحايل)
      debugPrint('🔒 [Attendance] Sending data to server for verification...');
      final serverVerification = await _verifyWithServer(
        employeeId: employeeId,
        capturedImage: capturedImage,
        locationResult: locationResult,
        detectedFace: capturedFace!,
        confidence: confidence,
        livenessResult: livenessResult,
        faceFeatures: _faceService.extractFaceFeatures(capturedFace),
      );

      if (!serverVerification.success) {
        // تسجيل محاولة فاشلة
        await _recordFailedAttempt(employeeId);
        
        return AttendanceResult(
          success: false,
          error: serverVerification.error ?? 'فشل التحقق من السيرفر. يرجى المحاولة مرة أخرى',
        );
      }

      // 6. حفظ محلياً (بعد موافقة السيرفر فقط)
      await _saveAttendanceRecord(record);

      // 6.1. تحديث آخر تحضير
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('attendance_last_checkin_$employeeId', record.timestamp.toIso8601String());
      await prefs.setString('attendance_last_type_$employeeId', 'check_in');
      
      // 6.2. إعادة تعيين محاولات فاشلة بعد النجاح
      await _resetFailedAttempts(employeeId);

      debugPrint('✅ [Attendance] Server verification successful!');

      return AttendanceResult(
        success: true,
        record: record,
        locationData: locationResult,
        livenessData: livenessResult,
        confidence: confidence,
      );
    } catch (e) {
      debugPrint('❌ [Attendance] Check-in error: $e');
      return AttendanceResult(
        success: false,
        error: 'حدث خطأ: $e',
      );
    }
  }

  /// التحقق من الموقع
  Future<LocationVerificationResult> _verifyLocation() async {
    try {
      // 1. الحصول على الموقع
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 2. تحميل إعدادات موقع العمل
      await _loadWorkLocation();

      // 3. التحقق من Geofencing
      if (_workLatitude == null || _workLongitude == null) {
        // إذا لم يتم تعيين موقع العمل، نقبل أي موقع
        return LocationVerificationResult(
          isValid: true,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        );
      }

      final distance = Geolocator.distanceBetween(
        _workLatitude!,
        _workLongitude!,
        position.latitude,
        position.longitude,
      );

      // 4. التحقق من Mock Location (Android)
      final isMockLocation = await _checkMockLocation(position);

      return LocationVerificationResult(
        isValid: distance <= _allowedRadius && !isMockLocation,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        distance: distance,
        isMockLocation: isMockLocation,
        error: distance > _allowedRadius
            ? 'أنت خارج نطاق موقع العمل (${distance.toStringAsFixed(0)} متر)'
            : isMockLocation
                ? 'تم اكتشاف موقع مزيف'
                : null,
      );
    } catch (e) {
      debugPrint('❌ [Attendance] Location verification error: $e');
      return LocationVerificationResult(
        isValid: false,
        latitude: 0.0,
        longitude: 0.0,
        error: 'فشل الحصول على الموقع: $e',
      );
    }
  }

  /// التحقق من Mock Location
  Future<bool> _checkMockLocation(Position position) async {
    if (Platform.isAndroid) {
      return position.isMocked;
    }
    return false;
  }

  /// تحميل إعدادات موقع العمل
  Future<void> _loadWorkLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _workLatitude = prefs.getDouble('work_latitude');
    _workLongitude = prefs.getDouble('work_longitude');
    _allowedRadius = prefs.getDouble('work_radius') ?? 50.0;
  }

  /// حفظ بيانات الوجه
  Future<void> _saveFaceData(FaceData faceData) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'face_data_${faceData.employeeId}';
    final json = jsonEncode(faceData.toJson());
    
    // تشفير البيانات (مبسط)
    final bytes = utf8.encode(json);
    final hash = sha256.convert(bytes);
    
    await prefs.setString(key, json);
    await prefs.setString('${key}_hash', hash.toString());
  }

  /// تحميل بيانات الوجه
  Future<FaceData?> _loadFaceData(String employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'face_data_$employeeId';
      final jsonString = prefs.getString(key);
      
      if (jsonString == null) return null;
      
      // التحقق من التوقيع
      final storedHash = prefs.getString('${key}_hash');
      final bytes = utf8.encode(jsonString);
      final hash = sha256.convert(bytes);
      
      if (storedHash != hash.toString()) {
        debugPrint('⚠️ [Attendance] Face data hash mismatch');
        return null;
      }
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return FaceData.fromJson(json);
    } catch (e) {
      debugPrint('❌ [Attendance] Error loading face data: $e');
      return null;
    }
  }

  /// حفظ سجل التحضير
  Future<void> _saveAttendanceRecord(AttendanceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'attendance_${record.employeeId}_${record.timestamp.millisecondsSinceEpoch}';
    await prefs.setString(key, jsonEncode(record.toJson()));
  }

  /// مقارنة ميزات الوجه
  double _compareFaceFeatures(
    Map<String, dynamic> storedFeatures,
    Map<String, dynamic> currentFeatures,
  ) {
    try {
      // مقارنة landmarks
      final storedLandmarks = storedFeatures['landmarks'] as List?;
      final currentLandmarks = currentFeatures['landmarks'] as List?;
      
      if (storedLandmarks == null || currentLandmarks == null) {
        return 0.5; // قيمة افتراضية
      }

      // حساب المسافة بين landmarks المتشابهة
      double totalDistance = 0.0;
      int matchedCount = 0;

      for (final storedLandmark in storedLandmarks) {
        final storedType = storedLandmark['type'] as String?;
        if (storedType == null) continue;

        // البحث عن landmark مطابق في currentFeatures
        for (final currentLandmark in currentLandmarks) {
          if (currentLandmark['type'] == storedType) {
            final storedX = (storedLandmark['x'] as num?)?.toDouble() ?? 0.0;
            final storedY = (storedLandmark['y'] as num?)?.toDouble() ?? 0.0;
            final currentX = (currentLandmark['x'] as num?)?.toDouble() ?? 0.0;
            final currentY = (currentLandmark['y'] as num?)?.toDouble() ?? 0.0;

            final distance = _euclideanDistance(
              storedX, storedY,
              currentX, currentY,
            );
            totalDistance += distance;
            matchedCount++;
            break;
          }
        }
      }

      if (matchedCount == 0) return 0.5;

      // تطبيع المسافة (كلما كانت المسافة أصغر، كانت التشابه أكبر)
      final avgDistance = totalDistance / matchedCount;
      final normalizedDistance = (avgDistance / 100.0).clamp(0.0, 1.0);
      final similarity = 1.0 - normalizedDistance;

      return similarity.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('❌ [Attendance] Error comparing face features: $e');
      return 0.5;
    }
  }

  /// حساب المسافة الإقليدية
  double _euclideanDistance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return (dx * dx + dy * dy) * 0.5; // sqrt not needed for comparison
  }

  /// التحقق من Rate Limiting
  Future<RateLimitResult> _checkRateLimit(String employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // الحصول على آخر محاولات التحضير
      final attemptsKey = 'attendance_attempts_$employeeId';
      final attemptsJson = prefs.getString(attemptsKey);
      
      List<DateTime> attempts = [];
      if (attemptsJson != null) {
        final attemptsList = jsonDecode(attemptsJson) as List;
        attempts = attemptsList.map((e) => DateTime.parse(e as String)).toList();
      }
      
      // إزالة المحاولات القديمة (أكثر من ساعة)
      attempts.removeWhere((attempt) => 
        now.difference(attempt).inHours >= 1
      );
      
      // التحقق من عدد المحاولات
      if (attempts.length >= _maxAttemptsPerHour) {
        // حساب وقت الانتظار
        final oldestAttempt = attempts.first;
        final waitTime = 60 - now.difference(oldestAttempt).inMinutes;
        
        if (waitTime > 0) {
          return RateLimitResult(
            allowed: false,
            message: 'تم تجاوز الحد الأقصى للمحاولات. يرجى الانتظار $waitTime دقيقة',
          );
        }
      }
      
      // إضافة المحاولة الحالية
      attempts.add(now);
      await prefs.setString(attemptsKey, jsonEncode(
        attempts.map((e) => e.toIso8601String()).toList()
      ));
      
      // التحقق من Cooldown (بعد 3 محاولات فاشلة)
      final failedAttemptsKey = 'attendance_failed_attempts_$employeeId';
      final failedCount = prefs.getInt(failedAttemptsKey) ?? 0;
      
      if (failedCount >= 3) {
        final lastFailedTime = prefs.getString('attendance_last_failed_$employeeId');
        if (lastFailedTime != null) {
          final lastFailed = DateTime.parse(lastFailedTime);
          final minutesSinceFailed = now.difference(lastFailed).inMinutes;
          
          if (minutesSinceFailed < _cooldownMinutes) {
            final remainingMinutes = _cooldownMinutes - minutesSinceFailed;
            return RateLimitResult(
              allowed: false,
              message: 'تم تجاوز عدد المحاولات الفاشلة. يرجى الانتظار $remainingMinutes دقيقة',
            );
          } else {
            // إعادة تعيين العداد بعد انتهاء Cooldown
            await prefs.setInt(failedAttemptsKey, 0);
          }
        }
      }
      
      return RateLimitResult(allowed: true);
    } catch (e) {
      debugPrint('❌ [Attendance] Rate limit check error: $e');
      // في حالة الخطأ، نسمح بالمحاولة (fail open)
      return RateLimitResult(allowed: true);
    }
  }

  /// التحقق من Time Restrictions
  Future<TimeCheckResult> _checkTimeRestrictions(String employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // التحقق من آخر تحضير في نفس اليوم
      final lastCheckInKey = 'attendance_last_checkin_$employeeId';
      final lastCheckInTime = prefs.getString(lastCheckInKey);
      
      if (lastCheckInTime != null) {
        final lastCheckIn = DateTime.parse(lastCheckInTime);
        
        // إذا كان نفس اليوم
        if (lastCheckIn.year == now.year &&
            lastCheckIn.month == now.month &&
            lastCheckIn.day == now.day) {
          
          // التحقق من الوقت بين المحاولات
          final secondsSinceLastCheckIn = now.difference(lastCheckIn).inSeconds;
          if (secondsSinceLastCheckIn < _minTimeBetweenCheckIns) {
            final remainingSeconds = _minTimeBetweenCheckIns - secondsSinceLastCheckIn;
            return TimeCheckResult(
              allowed: false,
              message: 'يرجى الانتظار $remainingSeconds ثانية قبل المحاولة مرة أخرى',
            );
          }
          
          // منع التحضير المتكرر في نفس اليوم (إلا إذا كان خروج ثم تحضير)
          final lastTypeKey = 'attendance_last_type_$employeeId';
          final lastType = prefs.getString(lastTypeKey);
          
          if (lastType == 'check_in') {
            return TimeCheckResult(
              allowed: false,
              message: 'تم تسجيل التحضير اليوم بالفعل. يرجى تسجيل الخروج أولاً',
            );
          }
        }
      }
      
      return TimeCheckResult(allowed: true);
    } catch (e) {
      debugPrint('❌ [Attendance] Time check error: $e');
      return TimeCheckResult(allowed: true);
    }
  }

  /// تسجيل محاولة فاشلة
  Future<void> _recordFailedAttempt(String employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedAttemptsKey = 'attendance_failed_attempts_$employeeId';
      final failedCount = (prefs.getInt(failedAttemptsKey) ?? 0) + 1;
      
      await prefs.setInt(failedAttemptsKey, failedCount);
      await prefs.setString('attendance_last_failed_$employeeId', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ [Attendance] Error recording failed attempt: $e');
    }
  }

  /// إعادة تعيين محاولات فاشلة بعد نجاح
  Future<void> _resetFailedAttempts(String employeeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('attendance_failed_attempts_$employeeId', 0);
    } catch (e) {
      debugPrint('❌ [Attendance] Error resetting failed attempts: $e');
    }
  }

  /// التحقق من السيرفر (إجباري - يمنع الاحتيال)
  Future<ServerVerificationResult> _verifyWithServer({
    required String employeeId,
    required File? capturedImage,
    required LocationVerificationResult locationResult,
    required Face detectedFace,
    required double confidence,
    required LivenessResult livenessResult,
    required Map<String, dynamic> faceFeatures,
  }) async {
    try {
      // 1. الحصول على Device Fingerprint
      final deviceInfo = await _getDeviceFingerprint();
      
      // 2. الحصول على Token
      final token = await AuthService.getToken();
      if (token == null) {
        return ServerVerificationResult(
          success: false,
          error: 'يرجى تسجيل الدخول أولاً',
        );
      }

      // 3. إنشاء FormData مع جميع البيانات
      final formData = FormData();
      
      // البيانات الأساسية
      formData.fields.addAll([
        MapEntry('employee_id', employeeId),
        MapEntry('latitude', locationResult.latitude.toString()),
        MapEntry('longitude', locationResult.longitude.toString()),
        MapEntry('accuracy', locationResult.accuracy?.toString() ?? '0'),
        MapEntry('confidence', confidence.toString()),
        MapEntry('liveness_score', livenessResult.confidence.toString()),
        MapEntry('liveness_checks', jsonEncode(livenessResult.checks)),
        MapEntry('face_features', jsonEncode(faceFeatures)),
        MapEntry('device_fingerprint', jsonEncode(deviceInfo)),
        MapEntry('timestamp', DateTime.now().toUtc().toIso8601String()),
        MapEntry('is_mock_location', locationResult.isMockLocation.toString()),
      ]);

      // إضافة الصورة إذا كانت موجودة
      if (capturedImage != null && await capturedImage.exists()) {
        // ضغط الصورة
        final compressedImage = await _compressImage(capturedImage);
        formData.files.add(
          MapEntry(
            'face_image',
            await MultipartFile.fromFile(
              compressedImage.path,
              filename: 'face_${DateTime.now().millisecondsSinceEpoch}.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          ),
        );
      }

      // 4. إرسال للسيرفر (مع timeout)
      final dio = AuthService.dio;
      final response = await dio.post(
        ApiConfig.checkInPath,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // إزالة Content-Type للسماح لـ Dio بتعيينه تلقائياً لـ multipart
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // 5. التحقق من الاستجابة
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          debugPrint('✅ [Attendance] Server verification passed');
          return ServerVerificationResult(
            success: true,
            serverTimestamp: data['server_timestamp'] != null
                ? DateTime.parse(data['server_timestamp'] as String)
                : null,
            verificationId: data['verification_id'] as String?,
          );
        } else {
          return ServerVerificationResult(
            success: false,
            error: data['error'] as String? ?? data['message'] as String? ?? 'فشل التحقق من السيرفر',
          );
        }
      } else {
        return ServerVerificationResult(
          success: false,
          error: 'خطأ في الاتصال بالسيرفر (${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [Attendance] Server verification error: ${e.message}');
      if (e.response != null) {
        final errorData = e.response!.data as Map<String, dynamic>?;
        return ServerVerificationResult(
          success: false,
          error: errorData?['error'] as String? ??
              errorData?['message'] as String? ??
              'فشل التحقق من السيرفر',
        );
      }
      return ServerVerificationResult(
        success: false,
        error: 'فشل الاتصال بالسيرفر: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ [Attendance] Server verification error: $e');
      return ServerVerificationResult(
        success: false,
        error: 'حدث خطأ أثناء التحقق: $e',
      );
    }
  }

  /// الحصول على Device Fingerprint
  Future<Map<String, dynamic>> _getDeviceFingerprint() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      Map<String, dynamic> fingerprint = {
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'package_name': packageInfo.packageName,
      };

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        fingerprint.addAll({
          'platform': 'android',
          'device_id': androidInfo.id,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'product': androidInfo.product,
          'android_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        fingerprint.addAll({
          'platform': 'ios',
          'identifier_for_vendor': iosInfo.identifierForVendor,
          'model': iosInfo.model,
          'name': iosInfo.name,
          'system_name': iosInfo.systemName,
          'system_version': iosInfo.systemVersion,
        });
      }

      return fingerprint;
    } catch (e) {
      debugPrint('⚠️ [Attendance] Error getting device fingerprint: $e');
      return {'error': 'could_not_get_device_info'};
    }
  }

  /// التحقق من الاتصال بالإنترنت
  Future<bool> _checkInternetConnection() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://www.google.com',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// ضغط الصورة
  Future<File> _compressImage(File imageFile) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes != null) {
        final compressedFile = File('${imageFile.path}_compressed.jpg');
        await compressedFile.writeAsBytes(compressedBytes);
        return compressedFile;
      }
      return imageFile;
    } catch (e) {
      debugPrint('⚠️ [Attendance] Image compression error: $e');
      return imageFile;
    }
  }

  void dispose() {
    _faceService.dispose();
  }
}

/// ============================================
/// 🚦 نتائج Rate Limiting
/// ============================================
class RateLimitResult {
  final bool allowed;
  final String? message;

  RateLimitResult({
    required this.allowed,
    this.message,
  });
}

/// ============================================
/// ⏰ نتائج Time Check
/// ============================================
class TimeCheckResult {
  final bool allowed;
  final String? message;

  TimeCheckResult({
    required this.allowed,
    this.message,
  });
}

/// ============================================
/// 🔒 نتائج التحقق من السيرفر
/// ============================================
class ServerVerificationResult {
  final bool success;
  final String? error;
  final DateTime? serverTimestamp;
  final String? verificationId;

  ServerVerificationResult({
    required this.success,
    this.error,
    this.serverTimestamp,
    this.verificationId,
  });
}

/// ============================================
/// 📊 نتائج التسجيل
/// ============================================
class EnrollmentResult {
  final bool success;
  final FaceData? faceData;
  final FaceQuality? quality;
  final double? confidence;
  final String? error;

  EnrollmentResult({
    required this.success,
    this.faceData,
    this.quality,
    this.confidence,
    this.error,
  });
}

/// ============================================
/// 📊 نتائج التحضير
/// ============================================
class AttendanceResult {
  final bool success;
  final AttendanceRecord? record;
  final LocationVerificationResult? locationData;
  final LivenessResult? livenessData;
  final double? confidence;
  final String? error;

  AttendanceResult({
    required this.success,
    this.record,
    this.locationData,
    this.livenessData,
    this.confidence,
    this.error,
  });
}

/// ============================================
/// 📍 نتائج التحقق من الموقع
/// ============================================
class LocationVerificationResult {
  final bool isValid;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? distance;
  final bool isMockLocation;
  final String? error;

  LocationVerificationResult({
    required this.isValid,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.distance,
    this.isMockLocation = false,
    this.error,
  });
}

