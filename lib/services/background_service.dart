import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:nuzum_tracker/services/location_service.dart';
import 'package:nuzum_tracker/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

// -----------------------------------------------------------------------------
// تهيئة الخدمة (لا حاجة لـ workmanager)
// -----------------------------------------------------------------------------
Future<void> initializeService() async {
  try {
    debugPrint(
      '✅ [Service] Service initialization (using geolocator directly)',
    );
  } catch (e, stackTrace) {
    debugPrint('❌ [Service] Error initializing service: $e');
    debugPrint('❌ [Service] Stack trace: $stackTrace');
    rethrow;
  }
}

// -----------------------------------------------------------------------------
// متغيرات عامة للتتبع
// -----------------------------------------------------------------------------
Timer? _locationTimer;
Timer? _healthCheckTimer; // Timer للتحقق من استمرار التتبع
Timer? _networkCheckTimer; // Timer للتحقق من الاتصال وإرسال البيانات المحفوظة
StreamSubscription<Position>? _positionStreamSubscription;
Position? _lastPosition;
double? _currentSpeed;
double? _currentHeading;
double? _totalDistance; // إجمالي المسافة المقطوعة
DateTime? _lastSuccessfulUpdate;
List<Position> _trackedPositions = []; // قائمة بجميع المواقع المتتبعة

// متغيرات لتتبع فترة التوقف
DateTime? _stopStartTime; // وقت بدء التوقف
Position? _stopPosition; // موقع التوقف
double _stopDistanceThreshold = 50.0; // المسافة بالأمتار لتحديد التوقف (50 متر)
Duration _stopTimeThreshold = const Duration(minutes: 2); // الوقت الأدنى للتوقف (دقيقتان)

// -----------------------------------------------------------------------------
// بدء تتبع الموقع
// -----------------------------------------------------------------------------
Future<void> startLocationTracking() async {
  try {
    // التحقق من الأذونات
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("❌ [Tracking] Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint("❌ [Tracking] Location permissions are denied.");
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("❌ [Tracking] Location permissions are permanently denied.");
      return;
    }

    // إيقاف أي تتبع سابق
    await stopLocationTracking();

    // بدء تتبع الموقع المستمر
    debugPrint("🌍 [Tracking] Starting continuous location tracking...");

    // طلب Wake Lock لمنع النظام من إيقاف التطبيق
    try {
      await _requestWakeLock();
    } catch (e) {
      debugPrint('⚠️ [Tracking] Could not acquire wake lock: $e');
    }

    // طلب Battery Optimization exemption
    try {
      await _requestBatteryOptimizationExemption();
    } catch (e) {
      debugPrint('⚠️ [Tracking] Could not request battery optimization exemption: $e');
    }

    // بدء تتبع الموقع مع إعدادات محسّنة للخلفية
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // تحديث عند التحرك 10 أمتار
            timeLimit: null, // لا يوجد حد زمني
            // إعدادات إضافية للتتبع المستمر
          ),
        ).listen(
          (Position position) {
            _handleNewPosition(position);
            // إرسال فوري عند الحصول على موقع جديد
            _sendLocationUpdate();
          },
          onError: (error) {
            debugPrint('❌ [Tracking] Location stream error: $error');
            // إعادة المحاولة بعد 30 ثانية
            Future.delayed(const Duration(seconds: 30), () {
              if (_positionStreamSubscription == null) {
                startLocationTracking();
              }
            });
          },
          cancelOnError: false,
        );

    // أيضاً نستخدم Timer لإرسال البيانات كل دقيقة (كحل احتياطي للتأكد من الاستمرارية)
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      // التحقق من أن التتبع لا يزال نشطاً
      if (_positionStreamSubscription == null) {
        debugPrint('⚠️ [Tracking] Stream subscription lost, restarting...');
        timer.cancel();
        startLocationTracking();
        return;
      }
      await _sendLocationUpdate();
    });

    // إرسال فوري عند البدء
    await _sendLocationUpdate();
    _lastSuccessfulUpdate = DateTime.now();

    // بدء Health Check Timer للتحقق من استمرار التتبع كل 5 دقائق
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _performHealthCheck();
    });

    // بدء Network Check Timer للتحقق من الاتصال وإرسال البيانات المحفوظة كل دقيقتين
    _networkCheckTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      await _checkNetworkAndSendPending();
    });

    // بدء Token Check Timer للتحقق من الـ token وتجديده تلقائياً كل 10 دقائق
    Timer.periodic(const Duration(minutes: 10), (timer) async {
      try {
        final token = await AuthService.getValidToken();
        if (token == null) {
          debugPrint('⚠️ [Tracking] No valid token available');
        } else {
          debugPrint('✅ [Tracking] Token is valid');
        }
      } catch (e) {
        debugPrint('❌ [Tracking] Error checking token: $e');
      }
    });

    // محاولة إرسال البيانات المحفوظة فوراً عند البدء
    Future.delayed(const Duration(seconds: 5), () async {
      await _checkNetworkAndSendPending();
    });

    debugPrint('✅ [Tracking] Location tracking started successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ [Tracking] Error starting location tracking: $e');
    debugPrint('❌ [Tracking] Stack trace: $stackTrace');
  }
}

// -----------------------------------------------------------------------------
// معالجة موقع جديد
// -----------------------------------------------------------------------------
void _handleNewPosition(Position position) {
  try {
    double? distanceFromPrevious;
    double? speed;
    double? heading;
    Duration? stopDuration;

    // حساب المسافة والسرعة والاتجاه
    if (_lastPosition != null) {
      distanceFromPrevious = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      double timeDiff =
          (position.timestamp
              .difference(_lastPosition!.timestamp)
              .inMilliseconds /
          1000.0);

      if (timeDiff > 0) {
        double speedMs = distanceFromPrevious / timeDiff;
        speed = speedMs * 3.6; // تحويل إلى كم/ساعة
        _currentSpeed = speed;
      }

      // حساب الاتجاه (heading)
      heading = Geolocator.bearingBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _currentHeading = heading;

      // تحديد حالة التوقف
      if (distanceFromPrevious < _stopDistanceThreshold) {
        // المستخدم متوقف أو يتحرك قليلاً
        if (_stopStartTime == null) {
          // بدء فترة توقف جديدة
          _stopStartTime = _lastPosition!.timestamp;
          _stopPosition = _lastPosition;
          debugPrint('🛑 [Stop] Stop detected at: Lat ${_lastPosition!.latitude.toStringAsFixed(6)}, Lng ${_lastPosition!.longitude.toStringAsFixed(6)}');
        } else {
          // استمرار التوقف - حساب المدة
          final stopDurationCalc = position.timestamp.difference(_stopStartTime!);
          if (stopDurationCalc >= _stopTimeThreshold) {
            stopDuration = stopDurationCalc;
            debugPrint('⏱️ [Stop] Stop duration: ${_formatStopDuration(stopDuration)}');
          }
        }
      } else {
        // المستخدم يتحرك - إنهاء فترة التوقف إن وجدت
        if (_stopStartTime != null && _stopPosition != null) {
          final finalStopDuration = position.timestamp.difference(_stopStartTime!);
          if (finalStopDuration >= _stopTimeThreshold) {
            debugPrint('🚶 [Stop] Stop ended. Total duration: ${_formatStopDuration(finalStopDuration)}');
            debugPrint('📍 [Stop] Stop location: Lat ${_stopPosition!.latitude.toStringAsFixed(6)}, Lng ${_stopPosition!.longitude.toStringAsFixed(6)}');
          }
          _stopStartTime = null;
          _stopPosition = null;
        }
      }

      // تحديث إجمالي المسافة
      _totalDistance = (_totalDistance ?? 0) + distanceFromPrevious;
    }

    // حفظ الموقع في القائمة
    _trackedPositions.add(position);
    
    // الاحتفاظ بآخر 100 موقع فقط (لمنع استهلاك الذاكرة)
    if (_trackedPositions.length > 100) {
      _trackedPositions.removeAt(0);
    }

    _lastPosition = position;

    debugPrint(
      '📍 [Tracking] New position: Lat ${position.latitude.toStringAsFixed(6)}, Lng ${position.longitude.toStringAsFixed(6)}',
    );
    if (speed != null) {
      debugPrint(
        '🚗 [Tracking] Speed: ${speed.toStringAsFixed(2)} km/h',
      );
    }
    if (heading != null) {
      debugPrint(
        '🧭 [Tracking] Heading: ${heading.toStringAsFixed(1)}°',
      );
    }
    if (distanceFromPrevious != null) {
      debugPrint(
        '📏 [Tracking] Distance: ${distanceFromPrevious.toStringAsFixed(2)} m',
      );
    }
    if (_totalDistance != null) {
      debugPrint(
        '📊 [Tracking] Total distance: ${(_totalDistance! / 1000).toStringAsFixed(2)} km',
      );
    }
    if (stopDuration != null) {
      debugPrint(
        '⏸️ [Tracking] Stop duration: ${_formatStopDuration(stopDuration)}',
      );
    }
  } catch (e) {
    debugPrint('❌ [Tracking] Error handling new position: $e');
  }
}

// -----------------------------------------------------------------------------
// تنسيق مدة التوقف
// -----------------------------------------------------------------------------
String _formatStopDuration(Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (days > 0) {
    return '${days} يوم ${hours} ساعة ${minutes} دقيقة';
  } else if (hours > 0) {
    return '${hours} ساعة ${minutes} دقيقة ${seconds} ثانية';
  } else if (minutes > 0) {
    return '${minutes} دقيقة ${seconds} ثانية';
  } else {
    return '${seconds} ثانية';
  }
}

// -----------------------------------------------------------------------------
// الحصول على مدة التوقف الحالية
// -----------------------------------------------------------------------------
Duration? _getCurrentStopDuration() {
  if (_stopStartTime == null) {
    return null;
  }
  return DateTime.now().difference(_stopStartTime!);
}

// -----------------------------------------------------------------------------
// إرسال تحديث الموقع
// -----------------------------------------------------------------------------
Future<void> _sendLocationUpdate() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jobNumber = prefs.getString('jobNumber');
    final apiKey = prefs.getString('apiKey');

    if (jobNumber == null || apiKey == null) {
      debugPrint('⚠️ [Tracking] jobNumber or apiKey is null');
      return;
    }

    // استخدام آخر موقع معروف أو الحصول على موقع جديد
    Position position;
    if (_lastPosition != null) {
      position = _lastPosition!;
    } else {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      _lastPosition = position;
    }

    // حساب المسافة من الموقع السابق
    double? distanceFromPrevious;
    if (_trackedPositions.length > 1) {
      final previousPosition = _trackedPositions[_trackedPositions.length - 2];
      distanceFromPrevious = Geolocator.distanceBetween(
        previousPosition.latitude,
        previousPosition.longitude,
        position.latitude,
        position.longitude,
      );
    }

    // حساب مدة التوقف الحالية
    Duration? stopDuration;
    if (_stopStartTime != null && _stopPosition != null) {
      final currentStopDuration = _getCurrentStopDuration();
      if (currentStopDuration != null && currentStopDuration >= _stopTimeThreshold) {
        stopDuration = currentStopDuration;
      }
    }

    debugPrint(
      '🛰️ [Tracking] Sending location: Lat ${position.latitude.toStringAsFixed(6)}, Lng ${position.longitude.toStringAsFixed(6)}',
    );

    // محاولة إرسال الموقع إلى السيرفر
    try {
      final response = await LocationApiService.sendLocationWithRetry(
        jobNumber: jobNumber,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        apiKey: apiKey,
      );

      final now = DateFormat('hh:mm a', 'ar').format(DateTime.now());
      if (response.success) {
        _lastSuccessfulUpdate = DateTime.now();
        debugPrint('✅ [Tracking] Location sent successfully at $now');
      } else {
        // فشل الإرسال - حفظ محلياً مع تفاصيل التنقل
        debugPrint('💾 [Tracking] Failed to send, saving locally...');
        await LocationApiService.savePendingLocation(
          jobNumber: jobNumber,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          speed: _currentSpeed,
          heading: _currentHeading,
          distanceFromPrevious: distanceFromPrevious,
          stopDuration: stopDuration,
          isOffline: true,
        );
        debugPrint('❌ [Tracking] Failed to send location: ${response.error}');
      }
    } catch (e) {
      // خطأ في الاتصال - حفظ محلياً
      debugPrint('💾 [Tracking] Network error, saving locally: $e');
      await LocationApiService.savePendingLocation(
        jobNumber: jobNumber,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: _currentSpeed,
        heading: _currentHeading,
        distanceFromPrevious: distanceFromPrevious,
        stopDuration: stopDuration,
        isOffline: true,
      );
    }
  } catch (e) {
    debugPrint('🔥 [Tracking] Error in _sendLocationUpdate: $e');
    // حتى في حالة الخطأ، حاول حفظ الموقع محلياً
    try {
      final prefs = await SharedPreferences.getInstance();
      final jobNumber = prefs.getString('jobNumber');
      final apiKey = prefs.getString('apiKey');
      
      if (jobNumber != null && apiKey != null && _lastPosition != null) {
        final currentStopDuration = _getCurrentStopDuration();
        await LocationApiService.savePendingLocation(
          jobNumber: jobNumber,
          latitude: _lastPosition!.latitude,
          longitude: _lastPosition!.longitude,
          accuracy: _lastPosition!.accuracy,
          speed: _currentSpeed,
          heading: _currentHeading,
          stopDuration: (currentStopDuration != null && currentStopDuration >= _stopTimeThreshold) 
              ? currentStopDuration 
              : null,
          isOffline: true,
        );
      }
    } catch (saveError) {
      debugPrint('❌ [Tracking] Could not save location locally: $saveError');
    }
  }
}

// -----------------------------------------------------------------------------
// إيقاف تتبع الموقع
// -----------------------------------------------------------------------------
Future<void> stopLocationTracking() async {
  try {
    _locationTimer?.cancel();
    _locationTimer = null;

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    _networkCheckTimer?.cancel();
    _networkCheckTimer = null;

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    _lastPosition = null;
    _currentSpeed = null;
    _currentHeading = null;
    _totalDistance = null;
    _lastSuccessfulUpdate = null;
    _trackedPositions.clear();
    _stopStartTime = null;
    _stopPosition = null;

    // إطلاق Wake Lock
    try {
      await _releaseWakeLock();
    } catch (e) {
      debugPrint('⚠️ [Tracking] Could not release wake lock: $e');
    }

    debugPrint('✅ [Tracking] Location tracking stopped');
  } catch (e) {
    debugPrint('❌ [Tracking] Error stopping location tracking: $e');
  }
}

// -----------------------------------------------------------------------------
// طلب Wake Lock لمنع النظام من إيقاف التطبيق
// -----------------------------------------------------------------------------
Future<void> _requestWakeLock() async {
  try {
    const platform = MethodChannel('com.nuzum.tracker/wakelock');
    await platform.invokeMethod('acquireWakeLock');
    debugPrint('✅ [Tracking] Wake lock acquired');
  } catch (e) {
    debugPrint('⚠️ [Tracking] Wake lock not available: $e');
  }
}

// -----------------------------------------------------------------------------
// إطلاق Wake Lock
// -----------------------------------------------------------------------------
Future<void> _releaseWakeLock() async {
  try {
    const platform = MethodChannel('com.nuzum.tracker/wakelock');
    await platform.invokeMethod('releaseWakeLock');
    debugPrint('✅ [Tracking] Wake lock released');
  } catch (e) {
    debugPrint('⚠️ [Tracking] Could not release wake lock: $e');
  }
}

// -----------------------------------------------------------------------------
// طلب Battery Optimization Exemption
// -----------------------------------------------------------------------------
Future<void> _requestBatteryOptimizationExemption() async {
  try {
    const platform = MethodChannel('com.nuzum.tracker/battery');
    await platform.invokeMethod('requestIgnoreBatteryOptimizations');
    debugPrint('✅ [Tracking] Battery optimization exemption requested');
  } catch (e) {
    debugPrint('⚠️ [Tracking] Battery optimization exemption not available: $e');
  }
}

// -----------------------------------------------------------------------------
// التحقق من الاتصال وإرسال البيانات المحفوظة
// -----------------------------------------------------------------------------
Future<void> _checkNetworkAndSendPending() async {
  try {
    // التحقق من وجود مواقع محفوظة
    final pendingCount = await LocationApiService.getPendingCount();
    if (pendingCount == 0) {
      return;
    }

    debugPrint('🔄 [Network] Checking network and sending $pendingCount pending locations...');

    // التحقق من الاتصال
    final hasConnection = await LocationApiService.testConnection();
    if (!hasConnection) {
      debugPrint('⚠️ [Network] No network connection, will retry later');
      return;
    }

    // محاولة إرسال المواقع المحفوظة
    final result = await LocationApiService.retryPendingLocations();
    if (result['success'] == true) {
      final sent = result['sent'] as int;
      final failed = result['failed'] as int;
      debugPrint('✅ [Network] Sent $sent locations, $failed failed');
    }
  } catch (e) {
    debugPrint('❌ [Network] Error checking network: $e');
  }
}

// -----------------------------------------------------------------------------
// Health Check - التحقق من استمرار التتبع
// -----------------------------------------------------------------------------
Future<void> _performHealthCheck() async {
  try {
    // التحقق من أن Stream لا يزال نشطاً
    if (_positionStreamSubscription == null) {
      debugPrint('⚠️ [Tracking] Health check: Stream subscription is null, restarting...');
      await startLocationTracking();
      return;
    }

    // التحقق من آخر تحديث ناجح
    if (_lastSuccessfulUpdate != null) {
      final timeSinceLastUpdate = DateTime.now().difference(_lastSuccessfulUpdate!);
      if (timeSinceLastUpdate.inMinutes > 10) {
        debugPrint('⚠️ [Tracking] Health check: No update for ${timeSinceLastUpdate.inMinutes} minutes, restarting...');
        await stopLocationTracking();
        await Future.delayed(const Duration(seconds: 5));
        await startLocationTracking();
        return;
      }
    }

    // محاولة الحصول على موقع جديد للتحقق
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _lastPosition = position;
      debugPrint('✅ [Tracking] Health check: Location service is working');
    } catch (e) {
      debugPrint('⚠️ [Tracking] Health check: Could not get current position: $e');
      // إعادة تشغيل التتبع
      await stopLocationTracking();
      await Future.delayed(const Duration(seconds: 5));
      await startLocationTracking();
    }
  } catch (e) {
    debugPrint('❌ [Tracking] Health check error: $e');
  }
}

// -----------------------------------------------------------------------------
// إرسال الموقع إلى السيرفر (للاستخدام المباشر)
// -----------------------------------------------------------------------------
Future<void> performLocationUpdate() async {
  await _sendLocationUpdate();
}

// -----------------------------------------------------------------------------
// التحقق من حالة التتبع
// -----------------------------------------------------------------------------
Future<bool> isTrackingActive() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jobNumber = prefs.getString('jobNumber');
    final apiKey = prefs.getString('apiKey');
    return jobNumber != null &&
        apiKey != null &&
        _positionStreamSubscription != null;
  } catch (e) {
    debugPrint('❌ [Tracking] Error checking tracking status: $e');
    return false;
  }
}

// -----------------------------------------------------------------------------
// الحصول على السرعة الحالية
// -----------------------------------------------------------------------------
double? getCurrentSpeed() {
  return _currentSpeed;
}

// -----------------------------------------------------------------------------
// الحصول على الموقع الحالي
// -----------------------------------------------------------------------------
Position? getCurrentPosition() {
  return _lastPosition;
}
