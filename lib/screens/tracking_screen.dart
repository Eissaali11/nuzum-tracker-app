import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nuzum_tracker/services/background_service.dart';
import 'package:nuzum_tracker/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/language_service.dart';
import '../utils/app_localizations.dart';
import '../widgets/beautiful_card.dart';
import 'employee_profile_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  String _deviceStatus = AppLocalizations().loadingText;
  String _lastUpdate = AppLocalizations().notSentYet;
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
              _deviceStatus = AppLocalizations().trackingActive;
              _lastUpdate = AppLocalizations().collectingData;
            });
          }
          debugPrint('✅ [Tracking] Location tracking started successfully');
        } catch (startError) {
          debugPrint('❌ [Tracking] Error starting tracking: $startError');
          if (mounted) {
            setState(() {
              _deviceStatus = AppLocalizations().trackingError;
              _lastUpdate = AppLocalizations().serviceFailed;
            });
          }
        }
      } else {
        debugPrint(
          '⚠️ [Tracking] Tracking not configured (missing jobNumber or apiKey)',
        );
        if (mounted) {
          setState(() {
            _deviceStatus = AppLocalizations().notConfigured;
            _lastUpdate = AppLocalizations().pleaseSetup;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Tracking] Error in _startServiceIfNeeded: $e');
      debugPrint('❌ [Tracking] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _deviceStatus = AppLocalizations().serviceError;
          _lastUpdate = '${AppLocalizations().errorOccurred}: ${e.toString()}';
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
                '${AppLocalizations().lastUpdate}: ${DateFormat('hh:mm a', LanguageService.instance.isArabic ? 'ar' : 'en').format(DateTime.now())}';
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

  /// بناء رأس الصفحة بتصميم أنيق ومميز
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // أيقونة تحديث على اليسار
              _buildActionButton(
                icon: Icons.refresh_rounded,
                onPressed: _isRefreshing ? null : _refreshStatus,
                isLoading: _isRefreshing,
                tooltip: 'تحديث',
              ),

              // العنوان الرئيسي مع أيقونة تحديد الموقع في المنتصف
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة تحديد الموقع مع تأثيرات جمالية
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green.withValues(alpha: 0.4),
                            Colors.greenAccent.withValues(alpha: 0.3),
                            Colors.lightGreenAccent.withValues(alpha: 0.2),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // تأثير توهج خلفي
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // الأيقونة الرئيسية
                          const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'حالة التتبع',
                            style: _getTextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // نقطة حالة متوهجة
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [Colors.greenAccent, Colors.green],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withValues(
                                        alpha: 0.9,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.greenAccent.withValues(alpha: 0.3),
                                      Colors.green.withValues(alpha: 0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'نشط',
                                  style: _getTextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // أيقونة الملف الشخصي على اليمين
              _buildActionButton(
                icon: Icons.person_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmployeeProfileScreen(),
                    ),
                  );
                },
                tooltip: 'الملف الشخصي',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// استخدام نفس الخط العام للتطبيق
  TextStyle _getTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final isArabic = LanguageService.instance.isArabic;
    if (isArabic) {
      try {
        return GoogleFonts.cairo(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      } catch (e) {
        return TextStyle(
          fontFamily: 'Noto Sans Arabic',
          fontFamilyFallback: const ['Cairo', 'Tajawal', 'Arial', 'Roboto'],
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      }
    } else {
      return TextStyle(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['Arial', 'Helvetica', 'sans-serif'],
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }

  /// بناء زر إجراء بتصميم أنيق ومميز مع تأثيرات جمالية
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
    Color? color,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.15),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Tooltip(
            message: tooltip ?? '',
            preferBelow: false,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: _getTextStyle(fontSize: 12, color: Colors.white),
            child: Container(
              padding: const EdgeInsets.all(14),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(icon, color: color ?? Colors.white, size: 24),
            ),
          ),
        ),
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
          Text(
            AppLocalizations().trackingActive,
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
                title: AppLocalizations().serviceStatus,
                value: _deviceStatus,
                icon: Icons.sync,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatisticCard(
                title: AppLocalizations().lastUpdate,
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
            title: AppLocalizations().currentSpeed,
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
