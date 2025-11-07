import 'dart:async';
import 'dart:io'; 

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nuzum_tracker/services/background_service.dart';
import 'package:nuzum_tracker/screens/setup_screen.dart';
import 'package:nuzum_tracker/screens/tracking_screen.dart';

import 'package:nuzum_tracker/services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  HttpOverrides.global = MyHttpOverrides(); 
  await initializeDateFormatting('ar', null);

  await initializeService();

  final prefs = await SharedPreferences.getInstance();
  final bool isConfigured = prefs.getString('jobNumber') != null;

  runApp(MyApp(isConfigured: isConfigured));
}








class MyApp extends StatelessWidget {
  final bool isConfigured;

  const MyApp({super.key, required this.isConfigured});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuzum Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
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
      home: isConfigured ? const TrackingScreen() : const SetupScreen(),
    );
  }
}