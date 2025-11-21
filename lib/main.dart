import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nuzum_tracker/screens/splash_screen.dart';
import 'package:nuzum_tracker/services/api_logging_service.dart';
import 'package:nuzum_tracker/services/api_service.dart';
import 'package:nuzum_tracker/services/background_service.dart';
import 'package:nuzum_tracker/services/geofence_service.dart';
import 'package:nuzum_tracker/services/language_service.dart';
import 'package:nuzum_tracker/services/location_service.dart';
import 'package:nuzum_tracker/utils/safe_preferences.dart';

// GlobalKey للوصول إلى Navigator من أي مكان (لإشعارات Geofencing)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // معالجة الأخطاء غير المتوقعة في main
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      // في release mode، طباعة الخطأ فقط
      print('❌ [Main] Flutter Error: ${details.exception}');
      print('❌ [Main] Stack: ${details.stack}');
    }
  };

  // معالجة الأخطاء غير المتوقعة من async operations
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('❌ [Main] Uncaught error: $error');
      debugPrint('❌ [Main] Stack: $stack');
    } else {
      print('❌ [Main] Uncaught error: $error');
    }
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // تعيين Navigator Key لخدمة Geofencing
  try {
    GeofenceService.setNavigatorKey(navigatorKey);
  } catch (e) {
    debugPrint('⚠️ [Main] Error setting navigator key: $e');
  }

  // تهيئة إشعارات النظام مع معالجة الأخطاء
  try {
    await GeofenceService.initializeNotifications()
        .timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ [Main] Geofence notifications initialization timeout');
        return;
      },
    );
  } catch (e, stackTrace) {
    debugPrint('⚠️ [Main] Warning: Could not initialize geofence notifications: $e');
    debugPrint('⚠️ [Main] Stack trace: $stackTrace');
    // نستمر في التطبيق حتى لو فشلت تهيئة الإشعارات
  }

  // إعطاء وقت للـ platform channels للتهيئة
  // تأخير أطول لضمان جاهزية path_provider
  await Future.delayed(const Duration(milliseconds: 500));

  try {
    HttpOverrides.global = MyHttpOverrides();

    // تهيئة تنسيق التاريخ مع معالجة الأخطاء
    try {
      await initializeDateFormatting('ar', null);
    } catch (e) {
      debugPrint('⚠️ [Main] Warning: Could not initialize date formatting: $e');
      // نستمر في التطبيق حتى لو فشلت تهيئة التاريخ
    }

    // تهيئة الخدمة مع معالجة الأخطاء
    try {
      await initializeService();
    } catch (e) {
      debugPrint('⚠️ [Main] Warning: Could not initialize service: $e');
      // نستمر في التطبيق حتى لو فشلت تهيئة الخدمة
    }

    // تهيئة API Logging Service - بدء الإرسال الدوري للسجلات
    try {
      ApiLoggingService.startPeriodicSending();
      debugPrint('✅ [Main] API Logging Service initialized');
    } catch (e) {
      debugPrint('⚠️ [Main] Warning: Could not initialize API logging: $e');
    }

    // محاولة بدء التتبع تلقائياً إذا كان التطبيق مُعدّ
    // هذا يضمن بدء التتبع حتى عند فتح التطبيق بعد إغلاقه
    try {
      final jobNumber = await SafePreferences.getString('jobNumber');
      final apiKey = await SafePreferences.getString('apiKey');

      if (jobNumber != null &&
          apiKey != null &&
          jobNumber.isNotEmpty &&
          apiKey.isNotEmpty) {
        debugPrint('🚀 [Main] Auto-starting location tracking...');
        // تأخير بسيط قبل البدء لضمان جاهزية جميع الخدمات
        Future.delayed(const Duration(seconds: 3), () async {
          try {
            // بدء التتبع - سيبدأ Flutter Background Service تلقائياً
            await startLocationTracking();
            debugPrint('✅ [Main] Location tracking auto-started successfully');

            // التأكد من أن Flutter Background Service يعمل
            final service = FlutterBackgroundService();
            final isRunning = await service.isRunning();
            if (!isRunning) {
              debugPrint(
                '⚠️ [Main] Background service not running, starting...',
              );
              await service.startService();
            }
          } catch (e) {
            debugPrint('⚠️ [Main] Could not auto-start tracking: $e');
            // محاولة إعادة البدء بعد 5 ثواني
            Future.delayed(const Duration(seconds: 5), () async {
              try {
                await startLocationTracking();
              } catch (e2) {
                debugPrint('❌ [Main] Retry failed: $e2');
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ [Main] Could not check for auto-start: $e');
    }

    // تأخير إضافي قبل تشغيل التطبيق لضمان جاهزية جميع الـ plugins
    await Future.delayed(const Duration(milliseconds: 200));

    runApp(const MyApp());
  } catch (e, stackTrace) {
    // طباعة الخطأ في جميع الحالات (debug و release)
    if (kDebugMode) {
      debugPrint('❌ [Main] Error during initialization: $e');
      debugPrint('❌ [Main] Stack trace: $stackTrace');
    } else {
      // في release mode، يمكن إرسال الخطأ إلى خدمة تحليل الأخطاء
      print('❌ [Main] Error during initialization: $e');
    }

    // حتى في حالة الخطأ، حاول تشغيل التطبيق لعرض رسالة خطأ للمستخدم
    // أو الانتقال مباشرة إلى SplashScreen
    runApp(
      MaterialApp(
        title: 'Nuzum Tracker',
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(), // الانتقال مباشرة إلى SplashScreen بدلاً من رسالة خطأ
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  TextTheme? _cairoTextTheme;
  TextStyle? _cairoFont;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // تحميل الخط بعد تأخير لضمان جاهزية platform channels
    _loadArabicFont();

    // الاستماع لتغييرات اللغة
    LanguageService.instance.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    setState(() {
      // إعادة تحميل الخطوط عند تغيير اللغة
      _loadArabicFont();
    });
  }

  Future<void> _loadArabicFont() async {
    // تأخير إضافي قبل تحميل الخط
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // تحميل خط Cairo بشكل آمن
      final cairoFont = GoogleFonts.cairo();
      final cairoTextTheme = GoogleFonts.cairoTextTheme();

      if (mounted) {
        setState(() {
          _cairoFont = cairoFont;
          _cairoTextTheme = cairoTextTheme;
        });
      }
    } catch (e) {
      debugPrint('⚠️ [App] Warning: Could not load Cairo font: $e');
      // استخدام خط افتراضي إذا فشل تحميل Cairo
      if (mounted) {
        setState(() {
          _cairoFont = const TextStyle(
            fontFamily: 'Noto Sans Arabic',
            fontFamilyFallback: ['Cairo', 'Tajawal', 'Arial', 'Roboto'],
          );
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('🔄 [App] Lifecycle state changed: $state');

    // لا نرسل حالة التوقف أبداً - التطبيق يجب أن يستمر في العمل حتى عند إغلاقه
    // فقط عند حذف التطبيق سيتم إيقاف الخدمة

    // عند تصغير النافذة أو إغلاقها - التأكد من استمرار التتبع
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      debugPrint(
        '📱 [App] App going to background, ensuring tracking continues...',
      );
      _ensureTrackingIsActive();

      // التأكد من أن Flutter Background Service يعمل
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          final service = FlutterBackgroundService();
          final isRunning = await service.isRunning();
          if (!isRunning) {
            debugPrint('⚠️ [App] Background service stopped, restarting...');
            await service.startService();
          }
        } catch (e) {
          debugPrint('⚠️ [App] Could not check/start background service: $e');
        }
      });
    }

    // عند العودة للتطبيق - التأكد من أن التتبع لا يزال نشطاً
    if (state == AppLifecycleState.resumed) {
      _ensureTrackingIsActive();
    }
  }

  Future<void> _ensureTrackingIsActive() async {
    try {
      final jobNumber = await SafePreferences.getString('jobNumber');
      final apiKey = await SafePreferences.getString('apiKey');

      if (jobNumber != null &&
          apiKey != null &&
          jobNumber.isNotEmpty &&
          apiKey.isNotEmpty) {
        final isActive = await isTrackingActive();
        if (!isActive) {
          debugPrint('🔄 [App] Tracking is not active, restarting...');
          await startLocationTracking();
        } else {
          // حتى لو كان التتبع نشطاً، أرسل تحديث فوري للتأكد
          debugPrint('✅ [App] Tracking is active, sending immediate update...');
          try {
            await performLocationUpdate();
          } catch (e) {
            debugPrint('⚠️ [App] Could not send immediate update: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [App] Could not ensure tracking is active: $e');
    }
  }

  @override
  void dispose() {
    // لا نرسل حالة التوقف - التطبيق يجب أن يستمر في العمل
    // الخدمة الخلفية ستستمر في إرسال الموقع حتى عند إغلاق التطبيق
    debugPrint('ℹ️ [App] App disposing, but background service will continue');
    LanguageService.instance.removeListener(_onLanguageChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _sendStopStatusIfNeeded() async {
    try {
      // استخدام SafePreferences بدلاً من SharedPreferences مباشرة
      final jobNumber = await SafePreferences.getString('jobNumber');
      final apiKey = await SafePreferences.getString('apiKey');

      // فقط إذا كان التطبيق مُعدّ بالفعل (يوجد jobNumber و apiKey)
      if (jobNumber != null && apiKey != null) {
        debugPrint('🛑 [App] App is closing, sending stop status...');
        // استخدام timeout قصير لإرسال سريع
        await LocationApiService.sendStopStatusWithRetry(
          jobNumber: jobNumber,
          apiKey: apiKey,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⏱️ [App] Stop status timeout, but continuing...');
            return false;
          },
        );
        debugPrint('✅ [App] Stop status sent successfully');
      }
    } catch (e) {
      debugPrint('❌ [App] Error sending stop status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = LanguageService.instance.isArabic;

    // خط عربي أنيق - Cairo مع معالجة الأخطاء
    // استخدام خط افتراضي حتى يتم تحميل Cairo
    final arabicFont =
        _cairoFont ??
        const TextStyle(
          fontFamily: 'Noto Sans Arabic',
          fontFamilyFallback: ['Cairo', 'Tajawal', 'Arial', 'Roboto'],
        );

    // خط إنجليزي
    final englishFont = const TextStyle(
      fontFamily: 'Roboto',
      fontFamilyFallback: ['Arial', 'Helvetica', 'sans-serif'],
    );

    final textTheme = isArabic
        ? (_cairoTextTheme?.apply(
                bodyColor: Colors.black87,
                displayColor: Colors.black87,
              ) ??
              ThemeData.light().textTheme.apply(
                fontFamily: 'Noto Sans Arabic',
                fontFamilyFallback: ['Cairo', 'Tajawal', 'Arial', 'Roboto'],
                bodyColor: Colors.black87,
                displayColor: Colors.black87,
              ))
        : ThemeData.light().textTheme.apply(
            fontFamily: 'Roboto',
            fontFamilyFallback: ['Arial', 'Helvetica', 'sans-serif'],
            bodyColor: Colors.black87,
            displayColor: Colors.black87,
          );

    return MaterialApp(
      title: 'Nuzum Tracker',
      locale: LanguageService.instance.currentLocale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        // تطبيق الخط العربي على جميع النصوص
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
          titleTextStyle: (isArabic ? arabicFont : englishFont).copyWith(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          elevation: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            textStyle: (isArabic ? arabicFont : englishFont).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
