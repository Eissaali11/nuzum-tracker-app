import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nuzum_tracker/screens/splash_screen.dart';
import 'package:nuzum_tracker/services/api_service.dart';
import 'package:nuzum_tracker/services/background_service.dart';
import 'package:nuzum_tracker/services/location_service.dart';
import 'package:nuzum_tracker/utils/safe_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // إعطاء وقت للـ platform channels للتهيئة
  // تأخير أطول لضمان جاهزية path_provider
  await Future.delayed(const Duration(milliseconds: 300));

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

    // محاولة بدء التتبع تلقائياً إذا كان التطبيق مُعدّ
    try {
      final jobNumber = await SafePreferences.getString('jobNumber');
      final apiKey = await SafePreferences.getString('apiKey');
      
      if (jobNumber != null && apiKey != null && jobNumber.isNotEmpty && apiKey.isNotEmpty) {
        debugPrint('🚀 [Main] Auto-starting location tracking...');
        // تأخير بسيط قبل البدء
        Future.delayed(const Duration(seconds: 2), () async {
          try {
            await startLocationTracking();
            debugPrint('✅ [Main] Location tracking auto-started successfully');
          } catch (e) {
            debugPrint('⚠️ [Main] Could not auto-start tracking: $e');
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
    debugPrint('❌ [Main] Error during initialization: $e');
    debugPrint('❌ [Main] Stack trace: $stackTrace');

    // حتى في حالة الخطأ، حاول تشغيل التطبيق لعرض رسالة خطأ للمستخدم
    runApp(
      MaterialApp(
        title: 'Nuzum Tracker',
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'حدث خطأ أثناء بدء التطبيق',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الخطأ: $e',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
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

    // عند إغلاق التطبيق أو إيقافه
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // إرسال حالة التوقف بشكل غير متزامن (لا ننتظر)
      _sendStopStatusIfNeeded();
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
      
      if (jobNumber != null && apiKey != null && jobNumber.isNotEmpty && apiKey.isNotEmpty) {
        final isActive = await isTrackingActive();
        if (!isActive) {
          debugPrint('🔄 [App] Tracking is not active, restarting...');
          await startLocationTracking();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [App] Could not ensure tracking is active: $e');
    }
  }

  @override
  void dispose() {
    // إرسال حالة التوقف عند إغلاق التطبيق
    _sendStopStatusIfNeeded();
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
    // خط عربي أنيق - Cairo مع معالجة الأخطاء
    // استخدام خط افتراضي حتى يتم تحميل Cairo
    final arabicFont =
        _cairoFont ??
        const TextStyle(
          fontFamily: 'Noto Sans Arabic',
          fontFamilyFallback: ['Cairo', 'Tajawal', 'Arial', 'Roboto'],
        );

    final textTheme =
        _cairoTextTheme?.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ) ??
        ThemeData.light().textTheme.apply(
          fontFamily: 'Noto Sans Arabic',
          fontFamilyFallback: ['Cairo', 'Tajawal', 'Arial', 'Roboto'],
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        );

    return MaterialApp(
      title: 'Nuzum Tracker',
      locale: const Locale('ar'),
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
          titleTextStyle: arabicFont.copyWith(
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
            textStyle: arabicFont.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
