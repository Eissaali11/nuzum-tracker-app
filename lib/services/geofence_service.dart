import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/geofence_circle.dart';
import 'employee_api_service.dart';
import '../utils/safe_preferences.dart';

/// ============================================
/// 🎯 خدمة Geofencing - Geofence Service
/// ============================================
/// تراقب الموقع وتتحقق من دخول الموظف إلى الدوائر الجغرافية
/// تعرض إشعارات على الشاشة عند الدخول
/// ============================================
class GeofenceService {
  static GeofenceService? _instance;
  static GeofenceService get instance => _instance ??= GeofenceService._();
  GeofenceService._();

  StreamSubscription<Position>? _positionSubscription;
  List<GeofenceCircle> _circles = [];
  Set<String> _enteredCircles = {}; // لتجنب إظهار الإشعار أكثر من مرة
  Timer? _checkTimer;
  bool _isMonitoring = false;
  
  // GlobalKey للوصول إلى Navigator من أي مكان
  static GlobalKey<NavigatorState>? navigatorKey;
  
  // Flutter Local Notifications
  static FlutterLocalNotificationsPlugin? _notifications;
  static bool _notificationsInitialized = false;
  
  /// تهيئة إشعارات النظام
  static Future<void> initializeNotifications() async {
    if (_notificationsInitialized) return;
    
    _notifications = FlutterLocalNotificationsPlugin();
    
    // إعدادات Android - استخدام أيقونة التطبيق
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // إعدادات iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('📱 [Geofence] Notification tapped: ${details.payload}');
        // يمكن فتح التطبيق أو صفحة معينة عند الضغط على الإشعار
      },
    );
    
    // إنشاء قناة إشعارات لـ Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications!.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          'geofence_notifications',
          'إشعارات الدوائر الجغرافية',
          description: 'إشعارات عند الوصول إلى الدوائر الجغرافية',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
    
    _notificationsInitialized = true;
    debugPrint('✅ [Geofence] Notifications initialized');
  }
  
  /// تعيين Navigator Key
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  /// بدء مراقبة الدوائر
  Future<void> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint('ℹ️ [Geofence] Already monitoring');
      return;
    }

    try {
      // جلب الدوائر من API أو من التخزين المحلي
      await _loadCircles();
      
      if (_circles.isEmpty) {
        debugPrint('⚠️ [Geofence] No circles to monitor');
        return;
      }

      _isMonitoring = true;
      _enteredCircles.clear();

      // بدء مراقبة الموقع
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // تحديث عند التحرك 10 أمتار
        ),
      ).listen(
        (Position position) {
          _checkPosition(position);
        },
        onError: (error) {
          debugPrint('❌ [Geofence] Location stream error: $error');
        },
      );

      // أيضاً نستخدم Timer للتحقق كل 30 ثانية
      _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          _checkPosition(position);
        } catch (e) {
          debugPrint('⚠️ [Geofence] Could not get position: $e');
        }
      });

      debugPrint('✅ [Geofence] Started monitoring ${_circles.length} circles');
    } catch (e) {
      debugPrint('❌ [Geofence] Error starting monitoring: $e');
      _isMonitoring = false;
    }
  }

  /// إيقاف مراقبة الدوائر
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _checkTimer?.cancel();
    _checkTimer = null;
    _enteredCircles.clear();
    debugPrint('✅ [Geofence] Stopped monitoring');
  }

  /// جلب الدوائر من API أو التخزين المحلي
  Future<void> _loadCircles() async {
    try {
      // محاولة جلب الدوائر من API
      final jobNumber = await SafePreferences.getString('jobNumber');
      final apiKey = await SafePreferences.getString('apiKey');

      if (jobNumber != null && apiKey != null) {
        // جلب بيانات الموظف التي قد تحتوي على معلومات الدائرة
        final response = await EmployeeApiService.getEmployeeProfile(
          jobNumber: jobNumber,
          apiKey: apiKey,
        );

        if (response.success && response.data != null) {
          // إذا كان API يعيد معلومات الدائرة، نستخدمها
          // حالياً سنستخدم قيم افتراضية أو من التخزين المحلي
        }
      }

      // جلب الدوائر من التخزين المحلي
      final prefs = await SharedPreferences.getInstance();
      final circlesJson = prefs.getString('geofence_circles');
      
      if (circlesJson != null) {
        final List<dynamic> circlesList = 
            (jsonDecode(circlesJson) as List<dynamic>);
        _circles = circlesList
            .map((json) => GeofenceCircle.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('✅ [Geofence] Loaded ${_circles.length} circles from storage');
      } else {
        // إنشاء دائرة افتراضية من بيانات الموظف
        await _createDefaultCircle(jobNumber, apiKey);
      }
    } catch (e) {
      debugPrint('❌ [Geofence] Error loading circles: $e');
    }
  }

  /// إنشاء دائرة افتراضية من بيانات الموظف
  Future<void> _createDefaultCircle(String? jobNumber, String? apiKey) async {
    try {
      // جلب معلومات موقع العمل من API أو استخدام قيم افتراضية
      // يمكن جلبها من API endpoint خاص بالدوائر
      final prefs = await SharedPreferences.getInstance();
      
      // محاولة جلب موقع العمل المحفوظ
      final workLat = prefs.getDouble('work_latitude');
      final workLng = prefs.getDouble('work_longitude');
      final workRadius = prefs.getDouble('work_radius') ?? 50.0;

      if (workLat != null && workLng != null && jobNumber != null) {
        final circle = GeofenceCircle(
          id: 'work_circle_$jobNumber',
          name: 'موقع العمل',
          latitude: workLat,
          longitude: workLng,
          radius: workRadius,
          employeeId: jobNumber,
          description: 'الدائرة الجغرافية لموقع العمل',
        );

        _circles = [circle];
        await _saveCircles();
        debugPrint('✅ [Geofence] Created default circle for work location');
      }
    } catch (e) {
      debugPrint('❌ [Geofence] Error creating default circle: $e');
    }
  }

  /// حفظ الدوائر محلياً
  Future<void> _saveCircles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final circlesJson = jsonEncode(
        _circles.map((circle) => circle.toJson()).toList(),
      );
      await prefs.setString('geofence_circles', circlesJson);
    } catch (e) {
      debugPrint('❌ [Geofence] Error saving circles: $e');
    }
  }

  /// إضافة دائرة جديدة
  Future<void> addCircle(GeofenceCircle circle) async {
    _circles.add(circle);
    await _saveCircles();
    debugPrint('✅ [Geofence] Added circle: ${circle.name}');
  }

  /// حذف دائرة
  Future<void> removeCircle(String circleId) async {
    _circles.removeWhere((circle) => circle.id == circleId);
    _enteredCircles.remove(circleId);
    await _saveCircles();
    debugPrint('✅ [Geofence] Removed circle: $circleId');
  }

  /// التحقق من الموقع الحالي
  void _checkPosition(Position position) {
    for (final circle in _circles) {
      final distance = circle.distanceTo(
        position.latitude,
        position.longitude,
      );

      final isInside = circle.contains(
        position.latitude,
        position.longitude,
      );

      if (isInside && !_enteredCircles.contains(circle.id)) {
        // دخول الدائرة لأول مرة - عرض إشعار
        _showEnterNotification(circle, distance);
        _enteredCircles.add(circle.id);
      } else if (!isInside && _enteredCircles.contains(circle.id)) {
        // خروج من الدائرة
        _enteredCircles.remove(circle.id);
        debugPrint('🚪 [Geofence] Exited circle: ${circle.name}');
      }
    }
  }

  /// عرض إشعار الدخول إلى الدائرة
  void _showEnterNotification(GeofenceCircle circle, double distance) async {
    debugPrint('🎯 [Geofence] Entered circle: ${circle.name} (${distance.toStringAsFixed(0)}m)');

    // 1. عرض إشعار النظام (في شريط الإشعارات)
    await _showSystemNotification(circle, distance);

    // 2. عرض إشعار على الشاشة باستخدام Navigator (إذا كان التطبيق مفتوحاً)
    if (navigatorKey?.currentContext != null) {
      showDialog(
        context: navigatorKey!.currentContext!,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1A237E),
                    Color(0xFF283593),
                    Color(0xFF1565C0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // العنوان
                    const Text(
                      '🎯 وصلت إلى الدائرة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // اسم الدائرة
                    Text(
                      circle.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // المسافة
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'المسافة: ${distance.toStringAsFixed(0)} متر',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (circle.description != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        circle.description!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    // زر الإغلاق
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A237E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'حسناً',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      
      // إغلاق تلقائي بعد 10 ثواني
      Future.delayed(const Duration(seconds: 10), () {
        if (navigatorKey?.currentContext != null) {
          try {
            Navigator.of(navigatorKey!.currentContext!).pop();
          } catch (e) {
            debugPrint('⚠️ [Geofence] Could not close dialog: $e');
          }
        }
      });
    } else {
      debugPrint('⚠️ [Geofence] Navigator key not set, cannot show notification');
    }
  }

  /// عرض إشعار النظام (في شريط الإشعارات)
  Future<void> _showSystemNotification(
    GeofenceCircle circle,
    double distance,
  ) async {
    if (!_notificationsInitialized || _notifications == null) {
      await initializeNotifications();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'geofence_notifications',
        'إشعارات الدوائر الجغرافية',
        channelDescription: 'إشعارات عند الوصول إلى الدوائر الجغرافية',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@drawable/ic_bg_service_small',
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications!.show(
        circle.id.hashCode, // ID فريد لكل دائرة
        '🎯 وصلت إلى الدائرة',
        '${circle.name}\nالمسافة: ${distance.toStringAsFixed(0)} متر',
        notificationDetails,
        payload: 'geofence_${circle.id}',
      );

      debugPrint('✅ [Geofence] System notification shown for: ${circle.name}');
    } catch (e) {
      debugPrint('❌ [Geofence] Error showing system notification: $e');
    }
  }

  /// جلب قائمة الدوائر
  List<GeofenceCircle> getCircles() => List.unmodifiable(_circles);

  /// التحقق من حالة المراقبة
  bool isMonitoring() => _isMonitoring;
}

