import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ============================================
/// 🔍 خدمة تحليل الوجه - Face Recognition Service
/// ============================================
class FaceRecognitionService {
  final FaceDetector _faceDetector;
  
  FaceRecognitionService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            enableLandmarks: true,
            enableTracking: true,
            minFaceSize: 0.15,
            performanceMode: FaceDetectorMode.accurate,
          ),
        );

  /// اكتشاف الوجه من صورة الكاميرا
  Future<FaceDetectionResult?> detectFaceFromCameraImage(
    CameraImage cameraImage,
  ) async {
    try {
      final inputImage = _inputImageFromCameraImage(cameraImage);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        return FaceDetectionResult(
          hasFace: false,
          message: 'لم يتم اكتشاف وجه',
        );
      }
      
      // اختيار أكبر وجه (الأقرب للكاميرا)
      faces.sort((a, b) {
        final areaA = a.boundingBox.width * a.boundingBox.height;
        final areaB = b.boundingBox.width * b.boundingBox.height;
        return areaB.compareTo(areaA);
      });
      
      final face = faces.first;
      
      // التحقق من جودة الوجه
      final quality = assessFaceQuality(face);
      
      return FaceDetectionResult(
        hasFace: true,
        face: face,
        quality: quality,
        confidence: calculateConfidence(face),
      );
    } catch (e) {
      debugPrint('❌ [FaceRecognition] Error detecting face: $e');
      return FaceDetectionResult(
        hasFace: false,
        message: 'حدث خطأ أثناء تحليل الوجه: $e',
      );
    }
  }

  /// اكتشاف الوجه من ملف صورة
  Future<FaceDetectionResult?> detectFaceFromFile(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        return FaceDetectionResult(
          hasFace: false,
          message: 'لم يتم اكتشاف وجه في الصورة',
        );
      }
      
      final face = faces.first;
      final quality = assessFaceQuality(face);
      
      return FaceDetectionResult(
        hasFace: true,
        face: face,
        quality: quality,
        confidence: calculateConfidence(face),
      );
    } catch (e) {
      debugPrint('❌ [FaceRecognition] Error detecting face from file: $e');
      return FaceDetectionResult(
        hasFace: false,
        message: 'حدث خطأ: $e',
      );
    }
  }

  /// مقارنة وجهين (Face Matching)
  Future<FaceMatchResult> compareFaces({
    required Face face1,
    required Face face2,
    double threshold = 0.2, // 80% similarity
  }) async {
    try {
      final distance = _calculateFaceDistance(face1, face2);
      final isMatch = distance < threshold;
      final similarity = (1.0 - distance.clamp(0.0, 1.0)) * 100;
      
      return FaceMatchResult(
        isMatch: isMatch,
        similarity: similarity,
        distance: distance,
      );
    } catch (e) {
      debugPrint('❌ [FaceRecognition] Error comparing faces: $e');
      return FaceMatchResult(
        isMatch: false,
        similarity: 0.0,
        distance: 1.0,
        error: 'حدث خطأ أثناء المقارنة',
      );
    }
  }

  /// استخراج ميزات الوجه للتخزين
  Map<String, dynamic> extractFaceFeatures(Face face) {
    final landmarksList = <Map<String, dynamic>>[];
    face.landmarks.forEach((type, landmark) {
      if (landmark != null) {
        landmarksList.add({
          'type': type.toString(),
          'x': landmark.position.x,
          'y': landmark.position.y,
        });
      }
    });
    
    return {
      'landmarks': landmarksList,
      'boundingBox': {
        'left': face.boundingBox.left,
        'top': face.boundingBox.top,
        'width': face.boundingBox.width,
        'height': face.boundingBox.height,
      },
      'headEulerAngleY': face.headEulerAngleY,
      'headEulerAngleZ': face.headEulerAngleZ,
      'leftEyeOpenProbability': face.leftEyeOpenProbability,
      'rightEyeOpenProbability': face.rightEyeOpenProbability,
      'smilingProbability': face.smilingProbability,
    };
  }

  /// تقييم جودة الوجه
  FaceQuality assessFaceQuality(Face face) {
    double score = 0.0;
    int checks = 0;

    // 1. حجم الوجه (يجب أن يكون كبيراً بما فيه الكفاية)
    final faceArea = face.boundingBox.width * face.boundingBox.height;
    if (faceArea > 10000) {
      score += 0.3;
    }
    checks++;

    // 2. وجود Landmarks
    if (face.landmarks.isNotEmpty) {
      score += 0.3;
    }
    checks++;

    // 3. زاوية الرأس (يجب أن تكون مستقيمة)
    final yAngle = face.headEulerAngleY?.abs() ?? 0;
    final zAngle = face.headEulerAngleZ?.abs() ?? 0;
    if (yAngle < 15 && zAngle < 15) {
      score += 0.2;
    }
    checks++;

    // 4. العيون مفتوحة
    final leftEye = face.leftEyeOpenProbability ?? 0;
    final rightEye = face.rightEyeOpenProbability ?? 0;
    if (leftEye > 0.5 && rightEye > 0.5) {
      score += 0.2;
    }
    checks++;

    final qualityScore = score / checks;
    
    if (qualityScore >= 0.8) {
      return FaceQuality.excellent;
    } else if (qualityScore >= 0.6) {
      return FaceQuality.good;
    } else if (qualityScore >= 0.4) {
      return FaceQuality.fair;
    } else {
      return FaceQuality.poor;
    }
  }

  /// حساب الثقة في الوجه
  double calculateConfidence(Face face) {
    double confidence = 0.5; // Base confidence

    // إضافة نقاط بناءً على الميزات
    if (face.landmarks.length >= 10) confidence += 0.2;
    if (face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! > 0.5) {
      confidence += 0.1;
    }
    if (face.rightEyeOpenProbability != null && face.rightEyeOpenProbability! > 0.5) {
      confidence += 0.1;
    }
    if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() < 15) {
      confidence += 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// حساب المسافة بين وجهين
  double _calculateFaceDistance(Face face1, Face face2) {
    if (face1.landmarks.isEmpty || face2.landmarks.isEmpty) {
      return 1.0; // لا يمكن المقارنة
    }

    double totalDistance = 0.0;
    int matchedLandmarks = 0;

    // مقارنة Landmarks
    face1.landmarks.forEach((type, landmark1) {
      if (landmark1 != null) {
        final landmark2 = face2.landmarks[type];
        if (landmark2 != null) {
          final distance = _euclideanDistance(
            landmark1.position,
            landmark2.position,
          );
          totalDistance += distance;
          matchedLandmarks++;
        }
      }
    });

    if (matchedLandmarks == 0) return 1.0;

    // تطبيع المسافة
    final avgDistance = totalDistance / matchedLandmarks;
    final normalizedDistance = avgDistance / 100.0; // تطبيع بناءً على حجم الصورة

    return normalizedDistance.clamp(0.0, 1.0);
  }

  /// حساب المسافة الإقليدية بين نقطتين
  double _euclideanDistance(Point p1, Point p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// تحويل CameraImage إلى InputImage
  InputImage _inputImageFromCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageRotation = InputImageRotation.rotation0deg;
    
    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: imageRotation,
      format: InputImageFormat.yuv420,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );
  }

  void dispose() {
    _faceDetector.close();
  }
}

/// ============================================
/// 📊 نتائج اكتشاف الوجه
/// ============================================
class FaceDetectionResult {
  final bool hasFace;
  final Face? face;
  final FaceQuality? quality;
  final double? confidence;
  final String? message;

  FaceDetectionResult({
    required this.hasFace,
    this.face,
    this.quality,
    this.confidence,
    this.message,
  });
}

/// ============================================
/// 🎯 جودة الوجه
/// ============================================
enum FaceQuality {
  excellent, // ممتاز
  good,      // جيد
  fair,      // مقبول
  poor,      // ضعيف
}

/// ============================================
/// 🔄 نتائج مقارنة الوجوه
/// ============================================
class FaceMatchResult {
  final bool isMatch;
  final double similarity; // نسبة التشابه (0-100)
  final double distance;   // المسافة (0-1)
  final String? error;

  FaceMatchResult({
    required this.isMatch,
    required this.similarity,
    required this.distance,
    this.error,
  });
}

