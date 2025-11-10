import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// ============================================
/// 🎭 خدمة كشف الحياة - Liveness Detection Service
/// مكافحة الاحتيال والغش
/// ============================================
class LivenessDetectionService {
  final List<FaceHistory> _faceHistory = [];
  int _blinkCount = 0;

  /// التحقق من أن الوجه حي (ليس صورة أو فيديو)
  Future<LivenessResult> checkLiveness(Face face) async {
    // إضافة الوجه إلى التاريخ
    _faceHistory.add(FaceHistory(
      face: face,
      timestamp: DateTime.now(),
    ));

    // الاحتفاظ بآخر 10 إطارات فقط
    if (_faceHistory.length > 10) {
      _faceHistory.removeAt(0);
    }

    // 1. Motion Detection - كشف الحركة
    final motionResult = _detectMotion();
    if (!motionResult.hasMotion && _faceHistory.length >= 3) {
      return LivenessResult(
        isLive: false,
        confidence: 0.0,
        reason: 'يرجى تحريك رأسك قليلاً',
        checks: {
          'motion': false,
          'blink': null,
          'smile': null,
          'headPose': null,
        },
      );
    }

    // 2. Blink Detection - كشف الغمزة
    final blinkResult = await _detectBlink(face);
    if (!blinkResult.hasBlinked && _faceHistory.length >= 5) {
      return LivenessResult(
        isLive: false,
        confidence: 0.3,
        reason: 'يرجى إغماض عينيك ثم فتحهما',
        checks: {
          'motion': motionResult.hasMotion,
          'blink': false,
          'smile': null,
          'headPose': null,
        },
      );
    }

    // 3. Smile Detection - كشف الابتسامة
    final smileResult = _detectSmile(face);

    // 4. Head Pose Check - التحقق من وضعية الرأس
    final headPoseResult = _checkHeadPose(face);
    if (!headPoseResult.isStraight) {
      return LivenessResult(
        isLive: false,
        confidence: 0.4,
        reason: 'يرجى النظر مباشرة للكاميرا',
        checks: {
          'motion': motionResult.hasMotion,
          'blink': blinkResult.hasBlinked,
          'smile': smileResult.hasSmiled,
          'headPose': false,
        },
      );
    }

    // 5. Eye Open Check - التحقق من أن العيون مفتوحة
    final eyeOpenResult = _checkEyesOpen(face);
    if (!eyeOpenResult.bothEyesOpen) {
      return LivenessResult(
        isLive: false,
        confidence: 0.2,
        reason: 'يرجى فتح عينيك',
        checks: {
          'motion': motionResult.hasMotion,
          'blink': false,
          'smile': smileResult.hasSmiled,
          'headPose': headPoseResult.isStraight,
        },
      );
    }

    // حساب الثقة النهائية
    double confidence = 0.5; // Base confidence
    
    if (motionResult.hasMotion) confidence += 0.2;
    if (blinkResult.hasBlinked) confidence += 0.15;
    if (smileResult.hasSmiled) confidence += 0.1;
    if (headPoseResult.isStraight) confidence += 0.05;

    // إذا اجتاز جميع الاختبارات
    if (motionResult.hasMotion && 
        blinkResult.hasBlinked && 
        headPoseResult.isStraight &&
        eyeOpenResult.bothEyesOpen) {
      return LivenessResult(
        isLive: true,
        confidence: confidence.clamp(0.0, 1.0),
        reason: 'تم التحقق بنجاح',
        checks: {
          'motion': true,
          'blink': true,
          'smile': smileResult.hasSmiled,
          'headPose': true,
        },
      );
    }

    return LivenessResult(
      isLive: false,
      confidence: confidence.clamp(0.0, 1.0),
      reason: 'يرجى إكمال جميع متطلبات التحقق',
      checks: {
        'motion': motionResult.hasMotion,
        'blink': blinkResult.hasBlinked,
        'smile': smileResult.hasSmiled,
        'headPose': headPoseResult.isStraight,
      },
    );
  }

  /// كشف الحركة
  MotionResult _detectMotion() {
    if (_faceHistory.length < 3) {
      return MotionResult(hasMotion: false, movement: 0.0);
    }

    // مقارنة موضع الوجه بين الإطارات
    final recent = _faceHistory.sublist(_faceHistory.length - 3);
    double totalMovement = 0.0;

    for (int i = 1; i < recent.length; i++) {
      final prev = recent[i - 1].face.boundingBox;
      final curr = recent[i].face.boundingBox;

      final movement = sqrt(
        pow(curr.left - prev.left, 2) + pow(curr.top - prev.top, 2),
      );
      totalMovement += movement;
    }

    // إذا كانت الحركة أكبر من 15 بكسل
    final hasMotion = totalMovement > 15.0;
    
    return MotionResult(
      hasMotion: hasMotion,
      movement: totalMovement,
    );
  }

  /// كشف الغمزة
  Future<BlinkResult> _detectBlink(Face face) async {
    if (_faceHistory.length < 3) {
      return BlinkResult(hasBlinked: false);
    }

    // البحث عن eye landmarks
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];

    if (leftEye == null || rightEye == null) {
      return BlinkResult(hasBlinked: false);
    }

    // التحقق من أن العيون كانت مغلقة ثم فتحت
    final currentLeftEye = face.leftEyeOpenProbability ?? 0.5;
    final currentRightEye = face.rightEyeOpenProbability ?? 0.5;

    // البحث في التاريخ عن لحظة كانت العيون مغلقة
    bool foundBlink = false;
    for (int i = _faceHistory.length - 3; i < _faceHistory.length - 1; i++) {
      if (i >= 0 && i < _faceHistory.length) {
        final historicalFace = _faceHistory[i].face;
        final historicalLeftEye = historicalFace.leftEyeOpenProbability ?? 0.5;
        final historicalRightEye = historicalFace.rightEyeOpenProbability ?? 0.5;

        // إذا كانت العيون مغلقة في الماضي ومفتوحة الآن
        if ((historicalLeftEye < 0.3 || historicalRightEye < 0.3) &&
            (currentLeftEye > 0.7 && currentRightEye > 0.7)) {
          foundBlink = true;
          _blinkCount++;
          break;
        }
      }
    }

    return BlinkResult(hasBlinked: foundBlink || _blinkCount > 0);
  }

  /// كشف الابتسامة
  SmileResult _detectSmile(Face face) {
    final smilingProbability = face.smilingProbability ?? 0.0;
    final hasSmiled = smilingProbability > 0.6;

    return SmileResult(
      hasSmiled: hasSmiled,
      probability: smilingProbability,
    );
  }

  /// التحقق من وضعية الرأس
  HeadPoseResult _checkHeadPose(Face face) {
    final yAngle = face.headEulerAngleY ?? 0;
    final zAngle = face.headEulerAngleZ ?? 0;
    final xAngle = face.headEulerAngleX ?? 0;

    // يجب أن تكون الزوايا قريبة من الصفر (رأس مستقيم)
    final isStraight = yAngle.abs() < 20 && 
                       zAngle.abs() < 20 && 
                       xAngle.abs() < 20;

    return HeadPoseResult(
      isStraight: isStraight,
      yAngle: yAngle,
      zAngle: zAngle,
      xAngle: xAngle,
    );
  }

  /// التحقق من أن العيون مفتوحة
  EyeOpenResult _checkEyesOpen(Face face) {
    final leftEye = face.leftEyeOpenProbability ?? 0.5;
    final rightEye = face.rightEyeOpenProbability ?? 0.5;

    return EyeOpenResult(
      bothEyesOpen: leftEye > 0.7 && rightEye > 0.7,
      leftEyeOpen: leftEye > 0.7,
      rightEyeOpen: rightEye > 0.7,
    );
  }

  /// إعادة تعيين الحالة
  void reset() {
    _faceHistory.clear();
    _blinkCount = 0;
  }
}

/// ============================================
/// 📊 نتائج Liveness Detection
/// ============================================
class LivenessResult {
  final bool isLive;
  final double confidence;
  final String reason;
  final Map<String, bool?> checks;

  LivenessResult({
    required this.isLive,
    required this.confidence,
    required this.reason,
    required this.checks,
  });
}

/// ============================================
/// 📝 تاريخ الوجوه
/// ============================================
class FaceHistory {
  final Face face;
  final DateTime timestamp;

  FaceHistory({
    required this.face,
    required this.timestamp,
  });
}

/// ============================================
/// 🏃 نتائج كشف الحركة
/// ============================================
class MotionResult {
  final bool hasMotion;
  final double movement;

  MotionResult({
    required this.hasMotion,
    required this.movement,
  });
}

/// ============================================
/// 👁️ نتائج كشف الغمزة
/// ============================================
class BlinkResult {
  final bool hasBlinked;

  BlinkResult({
    required this.hasBlinked,
  });
}

/// ============================================
/// 😊 نتائج كشف الابتسامة
/// ============================================
class SmileResult {
  final bool hasSmiled;
  final double probability;

  SmileResult({
    required this.hasSmiled,
    required this.probability,
  });
}

/// ============================================
/// 📐 نتائج وضعية الرأس
/// ============================================
class HeadPoseResult {
  final bool isStraight;
  final double yAngle;
  final double zAngle;
  final double xAngle;

  HeadPoseResult({
    required this.isStraight,
    required this.yAngle,
    required this.zAngle,
    required this.xAngle,
  });
}

/// ============================================
/// 👀 نتائج فتح العيون
/// ============================================
class EyeOpenResult {
  final bool bothEyesOpen;
  final bool leftEyeOpen;
  final bool rightEyeOpen;

  EyeOpenResult({
    required this.bothEyesOpen,
    required this.leftEyeOpen,
    required this.rightEyeOpen,
  });
}

