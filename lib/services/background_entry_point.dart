import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'location_service.dart' show LocationApiService;
import '../models/geofence_circle.dart';

/// ============================================
/// 🚀 نقطة دخول خدمة الخلفية - Background Service Entry Point
/// ============================================
/// هذا الملف يحتوي على الدوال التي تعمل في الخلفية
/// يجب أن تكون دوال entry point مستقلة ويمكن استدعاؤها من isolate منفصل
/// ============================================

/// دالة البدء للـ Flutter Background Service
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  // تهيئة تنسيق التاريخ للخلفية
  try {
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('en', null);
    debugPrint('✅ [Background] Date formatting initialized');
  } catch (e) {
    debugPrint('⚠️ [Background] Could not initialize date formatting: $e');
  }
  
  if (service is AndroidServiceInstance) {
    service.on('setAsForegroundService').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackgroundService').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // بدء تتبع الموقع في الخلفية - يعمل بشكل مستمر حتى عند إغلاق التطبيق
  // هذا Timer يستمر في العمل حتى عند إغلاق التطبيق بالكامل
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // تحديث الإشعار بشكل مستمر
          try {
            final timeStr = DateFormat('hh:mm a').format(DateTime.now());
            service.setForegroundNotificationInfo(
              title: "Nuzum Tracker",
              content: "تتبع الموقع نشط - $timeStr",
            );
          } catch (e) {
            // في حالة فشل تنسيق التاريخ، استخدم نص بسيط
            service.setForegroundNotificationInfo(
              title: "Nuzum Tracker",
              content: "تتبع الموقع نشط",
            );
          }
        }
      }

      // إرسال تحديث الموقع - يستمر حتى عند إغلاق التطبيق
      await _sendLocationUpdateFromBackground();
      debugPrint('✅ [BackgroundService] Location update sent (running in background)');
      
      // التحقق من Geofencing (الدوائر الجغرافية) - يعمل حتى عند إغلاق التطبيق
      await _checkGeofencingInBackground();
    } catch (e) {
      debugPrint('❌ [BackgroundService] Error sending location: $e');
      // محاولة إعادة المحاولة بعد 10 ثواني
      Future.delayed(const Duration(seconds: 10), () async {
        try {
          await _sendLocationUpdateFromBackground();
        } catch (e2) {
          debugPrint('❌ [BackgroundService] Retry failed: $e2');
        }
      });
    }
  });
}

/// دالة iOS Background
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// إرسال تحديث الموقع من الخلفية
Future<void> _sendLocationUpdateFromBackground() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jobNumber = prefs.getString('jobNumber');
    final apiKey = prefs.getString('apiKey');

    if (jobNumber == null || apiKey == null || jobNumber.isEmpty || apiKey.isEmpty) {
      debugPrint('⚠️ [Background] No jobNumber or apiKey found');
      return;
    }

    // الحصول على الموقع الحالي
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    // إرسال الموقع
    final response = await LocationApiService.sendLocationWithRetry(
      jobNumber: jobNumber,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      apiKey: apiKey,
    );

    if (response.success) {
      debugPrint('✅ [Background] Location sent successfully');
    } else {
      debugPrint('❌ [Background] Failed to send location: ${response.error}');
      // حفظ محلياً
      await LocationApiService.savePendingLocation(
        jobNumber: jobNumber,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    }
  } catch (e) {
    debugPrint('❌ [Background] Error in _sendLocationUpdateFromBackground: $e');
  }
}

/// التحقق من Geofencing في الخلفية
Future<void> _checkGeofencingInBackground() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final circlesJson = prefs.getString('geofence_circles');
    
    if (circlesJson == null) {
      return; // لا توجد دوائر للمراقبة
    }
    
    final List<dynamic> circlesList = jsonDecode(circlesJson) as List<dynamic>;
    final circles = circlesList
        .map((json) => GeofenceCircle.fromJson(json as Map<String, dynamic>))
        .toList();
    
    if (circles.isEmpty) {
      return;
    }
    
    // الحصول على الموقع الحالي
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
    
    // التحقق من كل دائرة
    for (final circle in circles) {
      final distance = circle.distanceTo(
        position.latitude,
        position.longitude,
      );
      
      final isInside = circle.contains(
        position.latitude,
        position.longitude,
      );
      
      // التحقق من أننا لم ندخل هذه الدائرة من قبل (في هذه الجلسة)
      final enteredKey = 'geofence_entered_${circle.id}';
      final hasEntered = prefs.getBool(enteredKey) ?? false;
      
      if (isInside && !hasEntered) {
        // دخول الدائرة لأول مرة - عرض إشعار النظام
        await _showGeofenceNotificationInBackground(circle, distance);
        await prefs.setBool(enteredKey, true);
        debugPrint('🎯 [Background] Entered circle: ${circle.name}');
      } else if (!isInside && hasEntered) {
        // خروج من الدائرة
        await prefs.remove(enteredKey);
        debugPrint('🚪 [Background] Exited circle: ${circle.name}');
      }
    }
  } catch (e) {
    debugPrint('❌ [Background] Error checking geofencing: $e');
  }
}

/// عرض إشعار Geofencing في الخلفية
Future<void> _showGeofenceNotificationInBackground(
  GeofenceCircle circle,
  double distance,
) async {
  try {
    // تهيئة إشعارات النظام إذا لم تكن مهيأة
    final notifications = FlutterLocalNotificationsPlugin();
    
    const androidDetails = AndroidNotificationDetails(
      'geofence_notifications',
      'إشعارات الدوائر الجغرافية',
      channelDescription: 'إشعارات عند الوصول إلى الدوائر الجغرافية',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_bg_service_small',
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

    await notifications.show(
      circle.id.hashCode,
      '🎯 وصلت إلى الدائرة',
      '${circle.name}\nالمسافة: ${distance.toStringAsFixed(0)} متر',
      notificationDetails,
      payload: 'geofence_${circle.id}',
    );

    debugPrint('✅ [Background] Geofence notification shown: ${circle.name}');
  } catch (e) {
    debugPrint('❌ [Background] Error showing geofence notification: $e');
  }
}

