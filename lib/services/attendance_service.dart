import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_record.dart';
import '../models/face_model.dart';
import 'face_recognition_service.dart';
import 'liveness_detection_service.dart';
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

      // 2. التحقق من جودة الوجه
      if (detectionResult.quality == FaceQuality.poor) {
        return EnrollmentResult(
          success: false,
          error: 'جودة الصورة ضعيفة. يرجى التقاط صورة أوضح',
        );
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
        return AttendanceResult(
          success: false,
          error: livenessResult.reason,
          livenessData: livenessResult,
        );
      }

      // 3. Face Matching
      // نحتاج لتحويل storedFaceData.features إلى Face object
      // هذا يتطلب implementation إضافي
      // للبساطة، سنستخدم confidence من Face Detection
      double confidence = 0.0;
      if (capturedImage != null) {
        final detectionResult = await _faceService.detectFaceFromFile(capturedImage);
        confidence = detectionResult?.confidence ?? 0.0;
      } else {
        // استخدام جودة الوجه مباشرة
        confidence = _faceService.calculateConfidence(detectedFace);
      }

      if (confidence < 0.7) {
        return AttendanceResult(
          success: false,
          error: 'الثقة في التعرف منخفضة. يرجى المحاولة مرة أخرى',
          confidence: confidence,
        );
      }

      // 4. التحقق من الموقع
      final locationResult = await _verifyLocation();
      if (!locationResult.isValid) {
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

      // 6. حفظ محلياً
      await _saveAttendanceRecord(record);

      // 7. إرسال إلى API (اختياري)
      try {
        await _sendToServer(record);
      } catch (e) {
        debugPrint('⚠️ [Attendance] Failed to send to server: $e');
        // نستمر حتى لو فشل الإرسال
      }

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

  /// إرسال إلى السيرفر
  Future<void> _sendToServer(AttendanceRecord record) async {
    // TODO: إرسال إلى API
    // يمكن استخدام RequestsApiService أو إنشاء خدمة منفصلة
    debugPrint('📤 [Attendance] Sending to server: ${record.toJson()}');
  }

  void dispose() {
    _faceService.dispose();
  }
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

