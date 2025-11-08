import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:nuzum_tracker/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'setup_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  String _deviceStatus = 'جاري التحميل...';
  String _lastUpdate = 'لم يتم الإرسال بعد';
  String _jobNumber = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadJobNumber();
    _listenToService();
  }

  @override
  void dispose() {
    // إرسال حالة التوقف عند إغلاق الشاشة
    _sendStopStatusOnDispose();
    super.dispose();
  }

  Future<void> _sendStopStatusOnDispose() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobNumber = prefs.getString('jobNumber');
      final apiKey = prefs.getString('apiKey');
      
      if (jobNumber != null && apiKey != null) {
        debugPrint('🛑 [Tracking] Screen is closing, sending stop status...');
        // إرسال بدون انتظار (fire and forget)
        LocationApiService.sendStopStatusWithRetry(
          jobNumber: jobNumber,
          apiKey: apiKey,
        ).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('⏱️ [Tracking] Stop status timeout');
            return false;
          },
        ).catchError((e) {
          debugPrint('❌ [Tracking] Error sending stop status: $e');
          return false;
        });
      }
    } catch (e) {
      debugPrint('❌ [Tracking] Error in _sendStopStatusOnDispose: $e');
    }
  }

  void _loadJobNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _jobNumber = prefs.getString('jobNumber') ?? 'غير معروف';
    });
  }

  void _listenToService() {
    final service = FlutterBackgroundService();
    service.on('update').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _deviceStatus = event['status'] ?? _deviceStatus;
          _lastUpdate = event['lastUpdate'] ?? _lastUpdate;
        });
      }
    });
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _deviceStatus = 'جاري التحديث...';
      _lastUpdate = 'جاري التحديث...';
    });

    try {
      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();

      if (isRunning) {
        // إرسال طلب تحديث فوري للخدمة الخلفية
        service.invoke('updateNow');

        // انتظر قليلاً للحصول على التحديث
        await Future.delayed(const Duration(seconds: 2));

        // تحديث الحالة من الخدمة
        service.invoke('getStatus');
      } else {
        setState(() {
          _deviceStatus = 'الخدمة غير نشطة';
          _lastUpdate = 'الخدمة متوقفة';
        });
      }
    } catch (e) {
      setState(() {
        _deviceStatus = 'خطأ في التحديث';
        _lastUpdate = 'حدث خطأ: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _stopTracking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('إيقاف التتبع'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في إيقاف خدمة التتبع وحذف البيانات؟',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('تأكيد', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // إرسال حالة التوقف إلى النظام قبل إيقاف الخدمة
      try {
        final prefs = await SharedPreferences.getInstance();
        final jobNumber = prefs.getString('jobNumber');
        final apiKey = prefs.getString('apiKey');
        
        if (jobNumber != null && apiKey != null) {
          debugPrint('🛑 [Tracking] Sending stop status to server...');
          await LocationApiService.sendStopStatusWithRetry(
            jobNumber: jobNumber,
            apiKey: apiKey,
          );
          debugPrint('✅ [Tracking] Stop status sent successfully');
        }
      } catch (e) {
        debugPrint('❌ [Tracking] Error sending stop status: $e');
      }
      
      final service = FlutterBackgroundService();
      service.invoke('stopService');

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SetupScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF1A237E), // Deep Indigo
              Color(0xFF283593), // Indigo
              Color(0xFF1565C0), // Blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar مخصص
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'حالة التتبع',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        // زر التحديث
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: _isRefreshing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                            onPressed: _isRefreshing ? null : _refreshStatus,
                            tooltip: 'تحديث الحالة',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // زر الإيقاف
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.stop_circle_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _stopTracking,
                            tooltip: 'إيقاف التتبع',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // المحتوى الرئيسي
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // بطاقة الحالة الرئيسية
                      _buildMainStatusCard(),
                      const SizedBox(height: 32),
                      // بطاقات المعلومات
                      _buildInfoCard(
                        'حالة الخدمة',
                        _deviceStatus,
                        Icons.sync,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        'آخر تحديث',
                        _lastUpdate,
                        Icons.timer,
                        Colors.green,
                      ),
                      const SizedBox(height: 24),
                      // بطاقة معلومات الموظف
                      _buildEmployeeCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainStatusCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // الأيقونة
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icons/app_logo.png',
                width: 140,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A237E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          // النص الرئيسي
          const Text(
            'التتبع نشط',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.green, size: 12),
                SizedBox(width: 8),
                Text(
                  'يعمل بشكل طبيعي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.badge_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الرقم الوظيفي',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _jobNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
