import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:nuzum_tracker/services/background_service.dart';
import 'package:nuzum_tracker/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/beautiful_card.dart';
import 'employee_profile_screen.dart';
import 'main_navigation_screen.dart';

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
  double? _currentSpeed;
  double? _latitude;
  double? _longitude;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadJobNumber();
    _listenToService();
    _startServiceIfNeeded();
  }

  Future<void> _startServiceIfNeeded() async {
    try {
      bool isActive = await isTrackingActive();
      if (isActive) {
        debugPrint('🚀 [Tracking] Starting location tracking...');

        try {
          await startLocationTracking();
          if (mounted) {
            setState(() {
              _deviceStatus = 'التتبع نشط';
              _lastUpdate = 'جاري جمع البيانات...';
            });
          }
          debugPrint('✅ [Tracking] Location tracking started successfully');
        } catch (startError) {
          debugPrint('❌ [Tracking] Error starting tracking: $startError');
          if (mounted) {
            setState(() {
              _deviceStatus = 'خطأ في بدء التتبع';
              _lastUpdate = 'فشل بدء خدمة التتبع';
            });
          }
        }
      } else {
        debugPrint(
          '⚠️ [Tracking] Tracking not configured (missing jobNumber or apiKey)',
        );
        if (mounted) {
          setState(() {
            _deviceStatus = 'غير مُعدّ';
            _lastUpdate = 'يرجى إعداد التطبيق أولاً';
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Tracking] Error in _startServiceIfNeeded: $e');
      debugPrint('❌ [Tracking] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _deviceStatus = 'خطأ في الخدمة';
          _lastUpdate = 'حدث خطأ: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
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
        LocationApiService.sendStopStatusWithRetry(
              jobNumber: jobNumber,
              apiKey: apiKey,
            )
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                debugPrint('⏱️ [Tracking] Stop status timeout');
                return false;
              },
            )
            .catchError((e) {
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
    _startLocationStream();

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        bool isActive = await isTrackingActive();
        if (isActive) {
          setState(() {
            _deviceStatus = 'التتبع نشط';
            if (_lastUpdate == 'لم يتم الإرسال بعد') {
              _lastUpdate = 'جاري جمع البيانات...';
            }
          });
        } else {
          setState(() {
            _deviceStatus = 'التتبع متوقف';
            _lastUpdate = 'الخدمة غير نشطة';
          });
        }
      } catch (e) {
        debugPrint('❌ [Tracking] Error checking status: $e');
      }
    });
  }

  void _startLocationStream() async {
    try {
      await startLocationTracking();

      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final position = getCurrentPosition();
        final speed = getCurrentSpeed();

        if (position != null) {
          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
            if (speed != null) {
              _currentSpeed = speed;
            }
            _lastUpdate =
                'آخر تحديث: ${DateFormat('hh:mm a', 'ar').format(DateTime.now())}';
          });
        }
      });

      debugPrint('✅ [Tracking] Location stream started');
    } catch (e) {
      debugPrint('❌ [Tracking] Error starting location stream: $e');
    }
  }

  Future<void> _refreshStatus() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _deviceStatus = 'جاري التحديث...';
      _lastUpdate = 'جاري التحديث...';
    });

    try {
      await performLocationUpdate();

      bool isActive = await isTrackingActive();
      if (isActive) {
        setState(() {
          _deviceStatus = 'التتبع نشط';
          _lastUpdate = 'تم التحديث بنجاح';
        });
      } else {
        setState(() {
          _deviceStatus = 'التتبع متوقف';
          _lastUpdate = 'الخدمة غير نشطة';
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
            Icon(Icons.stop_circle, color: Colors.red),
            SizedBox(width: 10),
            Text('إيقاف التتبع', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد أنك تريد إيقاف تتبع الموقع؟ سيتم مسح جميع البيانات.',
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

      await stopLocationTracking();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
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
            colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF1565C0)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar مخصص
              _buildCustomAppBar(),
              // المحتوى الرئيسي
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // بطاقة الحالة الرئيسية
                      _buildMainStatusCard(),
                      const SizedBox(height: 24),
                      // بطاقات المعلومات
                      _buildInfoGrid(),
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

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Drawer button
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
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
              _buildActionButton(
                icon: Icons.refresh,
                onPressed: _isRefreshing ? null : _refreshStatus,
                isLoading: _isRefreshing,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.person,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmployeeProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.stop_circle_outlined,
                onPressed: _stopTracking,
                color: Colors.red.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, color: color ?? Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMainStatusCard() {
    return BeautifulCard(
      gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.15),
        ],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
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
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A237E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 60,
                      color: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'التتبع نشط',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Job Number: $_jobNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatisticCard(
                title: 'حالة الخدمة',
                value: _deviceStatus,
                icon: Icons.sync,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticCard(
                title: 'آخر تحديث',
                value: _lastUpdate.length > 20
                    ? '${_lastUpdate.substring(0, 20)}...'
                    : _lastUpdate,
                icon: Icons.timer,
                color: Colors.green,
              ),
            ),
          ],
        ),
        if (_currentSpeed != null) ...[
          const SizedBox(height: 12),
          StatisticCard(
            title: 'السرعة الحالية',
            value: '${_currentSpeed!.toStringAsFixed(1)} km/h',
            icon: Icons.speed,
            color: Colors.orange,
          ),
        ],
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 12),
          BeautifulCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الموقع الحالي',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${_latitude!.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Lng: ${_longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmployeeCard() {
    return BeautifulCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: Color(0xFF1A237E), size: 24),
              SizedBox(width: 12),
              Text(
                'معلومات الموظف',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.badge, color: Color(0xFF1A237E), size: 24),
              const SizedBox(width: 12),
              Text(
                'الرقم الوظيفي: $_jobNumber',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
