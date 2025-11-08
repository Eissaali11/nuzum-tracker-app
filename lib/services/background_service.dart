import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:nuzum_tracker/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// -----------------------------------------------------------------------------
// تهيئة الخدمة
// -----------------------------------------------------------------------------
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'nuzum_tracker_foreground',
      initialNotificationTitle: 'Nuzum Tracker',
      initialNotificationContent: 'خدمة التتبع نشطة',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// -----------------------------------------------------------------------------
// نقطة الدخول الخاصة بأنظمة iOS
// -----------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// -----------------------------------------------------------------------------
// نقطة الدخول الرئيسية ومنطق الخدمة الخلفية
// -----------------------------------------------------------------------------
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await initializeDateFormatting('ar', null);
  HttpOverrides.global = MyHttpOverrides();

  Timer? timer;
  String? lastUpdate;

  Future<void> performLocationUpdate() async {
    try {
      // --- ⬇️⬇️ بداية الكود الجديد باستخدام Geolocator ⬇️⬇️ ---

      // 1. التحقق من أن خدمة الموقع (GPS) مفعلة على الجهاز
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("❌ [BG Service] Location services are disabled.");
        lastUpdate = 'خطأ: الرجاء تفعيل خدمة الموقع (GPS)';
        service.invoke('update', {'lastUpdate': lastUpdate!});
        return;
      }

      // 2. التحقق من أذونات الموقع
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("❌ [BG Service] Location permissions are denied.");
        lastUpdate = 'خطأ: إذن الوصول للموقع مرفوض';
        service.invoke('update', {'lastUpdate': lastUpdate!});
        // ملاحظة: لا يمكننا طلب الإذن من الخلفية. يجب على المستخدم منحه يدويًا.
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          "❌ [BG Service] Location permissions are permanently denied.",
        );
        lastUpdate = 'خطأ: تم رفض إذن الموقع بشكل دائم';
        service.invoke('update', {'lastUpdate': lastUpdate!});
        return;
      }

      // 3. إذا كانت الأذونات ممنوحة والخدمة تعمل، احصل على الموقع الحالي
      debugPrint(
        "🌍 [BG Service] Permissions are OK. Getting current position...",
      );
      final Position position =
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint("⏱️ [BG Service] Location request timeout");
              throw TimeoutException(
                'Location request timeout',
                const Duration(seconds: 15),
              );
            },
          );

      // --- ⬆️⬆️ نهاية الكود الجديد باستخدام Geolocator ⬆️⬆️ ---

      final prefs = await SharedPreferences.getInstance();
      final jobNumber = prefs.getString('jobNumber');
      final apiKey = prefs.getString('apiKey');

      if (jobNumber == null || apiKey == null) {
        timer?.cancel();
        service.stopSelf();
        return;
      }

      debugPrint(
        '🛰️ [BG Service] Got location: Lat ${position.latitude}, Lng ${position.longitude}',
      );

      // 4. إرسال الموقع إلى السيرفر مع إعادة محاولة تلقائية
      final response = await LocationApiService.sendLocationWithRetry(
        jobNumber: jobNumber,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        apiKey: apiKey, // استخدام apiKey من SharedPreferences
      );

      final now = DateFormat('hh:mm a', 'ar').format(DateTime.now());
      if (response.success) {
        lastUpdate = 'آخر إرسال ناجح: $now';
        debugPrint('✅ [BG Service] Location sent successfully!');
        service.invoke('update', {'lastUpdate': lastUpdate!});
      } else {
        lastUpdate = 'فشل الإرسال الأخير: $now';
        debugPrint('❌ [BG Service] Failed to send location: ${response.error}');
        service.invoke('update', {'lastUpdate': lastUpdate!});
      }
    } catch (e) {
      debugPrint('🔥 [BG Service] An unexpected error occurred: $e');
      lastUpdate = 'حدث خطأ غير متوقع';
      service.invoke('update', {'lastUpdate': lastUpdate!});
    }
  }

  // ضبط المؤقت للعمل كل دقيقة واحدة (لأغراض الاختبار)
  timer = Timer.periodic(const Duration(minutes: 1), (timerInstance) async {
    debugPrint("---------------------[ Timer Tick ]---------------------");
    await performLocationUpdate();
  });

  // تشغيل فوري عند بدء الخدمة لأول مرة
  debugPrint("------------------[ Service Started ]------------------");
  await performLocationUpdate();

  // دالة لإرسال حالة التوقف
  Future<void> sendStopStatusToServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobNumber = prefs.getString('jobNumber');
      final apiKey = prefs.getString('apiKey');

      if (jobNumber != null && apiKey != null) {
        debugPrint('🛑 [BG Service] Sending stop status to server...');
        await LocationApiService.sendStopStatusWithRetry(
          jobNumber: jobNumber,
          apiKey: apiKey,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⏱️ [BG Service] Stop status timeout');
            return false;
          },
        );
        debugPrint('✅ [BG Service] Stop status sent successfully');
      } else {
        debugPrint(
          '⚠️ [BG Service] Cannot send stop status: jobNumber or apiKey is null',
        );
      }
    } catch (e) {
      debugPrint('❌ [BG Service] Error sending stop status: $e');
    }
  }

  service.on('stopService').listen((event) async {
    debugPrint("------------------[ Stopping Service ]-----------------");

    // إرسال حالة التوقف إلى النظام
    await sendStopStatusToServer();

    timer?.cancel();
    service.stopSelf();
  });

  // معالج عند توقف الخدمة نفسها (عند إغلاق التطبيق)
  service.on('destroy').listen((event) async {
    debugPrint("------------------[ Service Destroyed ]-----------------");
    await sendStopStatusToServer();
  });

  // معالج طلب التحديث الفوري
  service.on('updateNow').listen((event) async {
    debugPrint("------------------[ Manual Update Request ]-----------------");
    await performLocationUpdate();
  });

  // معالج طلب الحصول على الحالة
  service.on('getStatus').listen((event) {
    debugPrint("------------------[ Status Request ]-----------------");
    service.invoke('update', {
      'status': 'الخدمة تعمل في الخلفية',
      'lastUpdate': lastUpdate ?? 'لم يتم الإرسال بعد',
    });
  });

  service.invoke('update', {'status': 'الخدمة تعمل في الخلفية'});
}
