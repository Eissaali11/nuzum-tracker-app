import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../services/attendance_service.dart';
import '../../services/face_recognition_service.dart';
import '../../services/liveness_detection_service.dart';
import '../../services/auth_service.dart';

/// ============================================
/// ✅ شاشة التحضير - Attendance Check-in Screen
/// ============================================
class AttendanceCheckInScreen extends StatefulWidget {
  const AttendanceCheckInScreen({super.key});

  @override
  State<AttendanceCheckInScreen> createState() =>
      _AttendanceCheckInScreenState();
}

class _AttendanceCheckInScreenState extends State<AttendanceCheckInScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _statusMessage;
  Face? _detectedFace;
  double _confidence = 0.0;

  final FaceRecognitionService _faceService = FaceRecognitionService();
  final LivenessDetectionService _livenessService = LivenessDetectionService();
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _statusMessage = 'لا توجد كاميرا متاحة';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _statusMessage = 'انظر للكاميرا مباشرة';
      });

      // بدء تحليل الوجه
      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'فشل تهيئة الكاميرا: $e';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;

    try {
      final result = await _faceService.detectFaceFromCameraImage(image);
      
      if (!mounted) return;

      if (result != null && result.hasFace && result.face != null) {
        setState(() {
          _detectedFace = result.face;
          _confidence = result.confidence ?? 0.0;
          _statusMessage = 'تم اكتشاف الوجه (${(_confidence * 100).toStringAsFixed(0)}%)';
        });
      } else {
        setState(() {
          _detectedFace = null;
          _statusMessage = result?.message ?? 'انظر للكاميرا مباشرة';
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    }
  }

  Future<void> _checkIn() async {
    if (_detectedFace == null) {
      setState(() {
        _statusMessage = 'الرجاء الانتظار حتى يتم اكتشاف الوجه';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'جاري التحقق...';
    });

    try {
      // 1. Liveness Detection
      _livenessService.reset();
      final livenessResult = await _livenessService.checkLiveness(_detectedFace!);

      if (!livenessResult.isLive) {
        setState(() {
          _isProcessing = false;
          _statusMessage = livenessResult.reason;
        });
        return;
      }

      // 2. Capture Image
      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      // 3. Check-in
      final employeeId = await AuthService.getEmployeeId();
      if (employeeId == null) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'الرجاء تسجيل الدخول أولاً';
        });
        return;
      }

      final result = await _attendanceService.checkInWithFace(
        employeeId: employeeId,
        detectedFace: _detectedFace!,
        capturedImage: imageFile,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _statusMessage = '✅ تم التحضير بنجاح!';
        });

        // إظهار رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تم تسجيل التحضير بنجاح',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // العودة للشاشة السابقة بعد 2 ثانية
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage = result.error ?? 'فشل التحضير';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = 'حدث خطأ: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'التحضير',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _cameraController != null)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          // Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _detectedFace != null
                      ? Colors.green
                      : Colors.white.withValues(alpha: 0.5),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.all(40),
            ),
          ),

          // Status Message
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _statusMessage ?? 'جاري التهيئة...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Confidence Indicator
          if (_detectedFace != null)
            Positioned(
              top: 180,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.face_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ثقة: ${(_confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Instructions
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInstruction(Icons.face_rounded, 'انظر مباشرة للكاميرا'),
                  const SizedBox(height: 8),
                  _buildInstruction(Icons.remove_red_eye_rounded, 'افتح عينيك'),
                  const SizedBox(height: 8),
                  _buildInstruction(Icons.straighten_rounded, 'أبق رأسك مستقيماً'),
                ],
              ),
            ),
          ),

          // Check-in Button
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _detectedFace != null && !_isProcessing
                      ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                      : [Colors.grey, Colors.grey.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_detectedFace != null && !_isProcessing
                            ? const Color(0xFF1A237E)
                            : Colors.grey)
                        .withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: (_detectedFace != null && !_isProcessing)
                    ? _checkIn
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'جاري التحقق...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _detectedFace != null
                                ? Icons.check_circle_rounded
                                : Icons.camera_alt_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _detectedFace != null
                                ? 'تسجيل التحضير'
                                : 'انتظر اكتشاف الوجه',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

