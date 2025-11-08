import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nuzum_tracker/screens/splash_screen.dart';
import 'package:nuzum_tracker/services/background_service.dart';
import 'package:nuzum_tracker/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();
  await initializeDateFormatting('ar', null);

  await initializeService();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      final prefs = await SharedPreferences.getInstance();
      final jobNumber = prefs.getString('jobNumber');
      final apiKey = prefs.getString('apiKey');
      
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
    return MaterialApp(
      title: 'Nuzum Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
          titleTextStyle: TextStyle(
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
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
