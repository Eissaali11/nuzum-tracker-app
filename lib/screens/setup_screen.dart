import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nuzum_tracker/services/background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_navigation_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobNumberController = TextEditingController();
  final _apiKeyController = TextEditingController(
    text: 'test_location_key_2025',
  );
  bool _isLoading = false;

  Future<void> _startTracking() async {
    // التحقق من صحة المدخلات
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jobNumber', _jobNumberController.text);
      await prefs.setString('apiKey', _apiKeyController.text);

      // بدء تتبع الموقع
      await startLocationTracking();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
            colors: [
              Color(0xFF1A237E), // Deep Indigo
              Color(0xFF0D47A1), // Deep Blue
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, // يضمن أن الشكل دائري
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/icons/app_logo.png', // مسار الصورة
                              width: 150, // تأكد من أن العرض يساوي الارتفاع
                              height: 150, // تأكد من أن الارتفاع يساوي العرض
                              fit: BoxFit.contain,
                              // لضمان أن الصورة تملأ الشكل الدائري بشكل صحيح
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1A237E,
                                    ), // لون خلفية في حالة وجود خطأ
                                    shape: BoxShape
                                        .circle, // الحفاظ على الشكل الدائري
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    size: 150,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 32),
                          const Text(
                            'مرحباً بك في نظام التتبع',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'يرجى إدخال بياناتك لبدء تتبع الموقع تلقائياً.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _jobNumberController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'الرقم الوظيفي',
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                prefixIcon: Icon(
                                  Icons.badge_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال الرقم الوظيفي';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: TextFormField(
                              controller: _apiKeyController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'رمز المصادقة',
                                labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                prefixIcon: Icon(
                                  Icons.vpn_key_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              readOnly: true,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF64B5F6), Color(0xFF2196F3)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2196F3,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _startTracking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'بدء التتبع',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _jobNumberController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}
