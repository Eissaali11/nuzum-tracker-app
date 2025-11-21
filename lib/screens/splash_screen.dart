import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nuzum_tracker/screens/disclaimer_screen.dart';
import 'package:nuzum_tracker/screens/login_screen.dart';
import 'package:nuzum_tracker/screens/main_navigation_screen.dart';
import 'package:nuzum_tracker/services/auth_service.dart';
import 'package:nuzum_tracker/utils/safe_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // تهيئة Animation Controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Fade Animation للشعار
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Scale Animation للشعار مع نبض
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Slide Animation للنص
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // بدء الأنيميشن
    _animationController.forward();

    // الانتقال للشاشة التالية بعد 3 ثواني
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // تقليل وقت الانتظار إلى ثانيتين
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) {
      debugPrint('⚠️ [Splash] Widget not mounted, skipping navigation');
      return;
    }

    try {
      // جلب البيانات بشكل متوازي لتسريع العملية
      final results = await Future.wait([
        SafePreferences.getBool('disclaimerAccepted'),
        SafePreferences.getString('jobNumber'),
        SafePreferences.getString('nationalId'),
      ], eagerError: false);

      final bool disclaimerAccepted = (results[0] as bool?) ?? false;
      final String? jobNumber = results[1] as String?;
      final String? nationalId = results[2] as String?;

      // التحقق من حالة تسجيل الدخول مع timeout أقصر
      bool isLoggedIn = false;
      if (jobNumber != null && nationalId != null) {
        try {
          isLoggedIn = await AuthService.isLoggedIn()
              .timeout(
            const Duration(seconds: 3), // تقليل timeout إلى 3 ثواني
            onTimeout: () {
              debugPrint('⚠️ [Splash] isLoggedIn timeout, defaulting to false');
              return false;
            },
          );
        } catch (e) {
          debugPrint('⚠️ [Splash] Error checking login status: $e');
          isLoggedIn = false;
        }
      }

      Widget nextScreen;
      if (!disclaimerAccepted) {
        nextScreen = const DisclaimerScreen();
        debugPrint('ℹ️ [Splash] Disclaimer not accepted, proceeding to disclaimer screen');
      } else if (isLoggedIn && jobNumber != null && nationalId != null) {
        nextScreen = const MainNavigationScreen();
        debugPrint('✅ [Splash] User is logged in, proceeding to main screen');
      } else {
        nextScreen = const LoginScreen();
        debugPrint('ℹ️ [Splash] User not logged in, proceeding to login screen');
      }

      if (!mounted) {
        debugPrint('⚠️ [Splash] Widget unmounted before navigation');
        return;
      }

      // استخدام MaterialPageRoute بدلاً من PageRouteBuilder للبساطة والسرعة
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
      
      debugPrint('✅ [Splash] Navigation completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [Splash] Error in navigation: $e');
      debugPrint('❌ [Splash] Stack trace: $stackTrace');
      
      // في حالة الخطأ، ننتقل إلى شاشة تسجيل الدخول
      if (mounted) {
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
          debugPrint('✅ [Splash] Fallback navigation to login screen completed');
        } catch (navError) {
          debugPrint('❌ [Splash] Critical: Navigation failed completely: $navError');
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A237E), // Deep Indigo
              Color(0xFF283593), // Indigo
              Color(0xFF1565C0), // Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الشعار مع Animations محسّنة
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // أنيميشن نبض خفيفة
                    final pulseScale =
                        1.0 +
                        (0.05 *
                            (0.5 -
                                (0.5 - _animationController.value).abs() * 2));

                    return Transform.scale(
                      scale: _scaleAnimation.value * pulseScale,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(
                                  alpha: 0.3 * _fadeAnimation.value,
                                ),
                                blurRadius: 40,
                                spreadRadius: 10,
                                offset: const Offset(0, 0),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.2 * _fadeAnimation.value,
                                ),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/icons/app_logo.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A237E),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    size: 100,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // اسم التطبيق مع Slide Animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          children: [
                            const Text(
                              'Nuzum Tracker',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'نظام تتبع الموظفين',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Loading Indicator مع Rotation Animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: RotationTransition(
                        turns: AlwaysStoppedAnimation(
                          _animationController.value * 2,
                        ),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
