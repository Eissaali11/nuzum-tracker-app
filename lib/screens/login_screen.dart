import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../screens/main_navigation_screen.dart';
import '../services/auth_service.dart';
import '../utils/safe_preferences.dart';

/// ============================================
/// 🔐 صفحة تسجيل الدخول - Login Screen
/// تصميم احترافي مع خلفية داكنة ونمط سداسي
/// ============================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _nationalIdController = TextEditingController();
  bool _isLoading = false;
  bool _obscureNationalId = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // خط عربي أنيق
  TextStyle get arabicFont {
    return const TextStyle(
      fontFamily: 'Noto Sans Arabic',
      fontFamilyFallback: ['Cairo', 'Tajawal', 'Arial', 'Roboto'],
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _employeeIdController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // تسجيل الدخول باستخدام AuthService (national_id بدلاً من password)
      final result = await AuthService.login(
        employeeId: _employeeIdController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
      );

      if (result['success'] == true) {
        // حفظ بيانات إضافية للتوافق مع النظام القديم
        await SafePreferences.setString(
          'jobNumber',
          _employeeIdController.text.trim(),
        );
        await SafePreferences.setString('apiKey', 'test_location_key_2025');
        // حفظ nationalId للتحقق من حالة تسجيل الدخول
        await SafePreferences.setString(
          'nationalId',
          _nationalIdController.text.trim(),
        );

        // الانتقال للشاشة الرئيسية
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'فشل تسجيل الدخول'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تسجيل الدخول: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628), // Dark blue
              Color(0xFF1A2744), // Medium dark blue
              Color(0xFF0F1B2E), // Dark blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Hexagonal pattern overlay
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: HexagonalPatternPainter(),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: size.height * 0.05),
                                  
                                  // نص "نظم" في الزاوية العلوية اليمنى
                                  _buildTopRightText(),

                                  SizedBox(height: size.height * 0.03),

                                  // الشعار
                                  _buildLogo(),

                                  SizedBox(height: size.height * 0.06),

                                  // بطاقة تسجيل الدخول الشفافة
                                  _buildLoginCard(),

                                  SizedBox(height: size.height * 0.05),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopRightText() {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Text(
          'نظم',
          style: arabicFont.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4FC3F7), // Light cyan
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/app_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                    const Color(0xFF29B6F6).withValues(alpha: 0.3),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_rounded,
                size: 80,
                color: Color(0xFF4FC3F7),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1), // Transparent white
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF4FC3F7).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عنوان الصفحة
            Text(
              'تسجيل الدخول',
              style: arabicFont.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4FC3F7), // Light cyan
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'أدخل بياناتك للوصول إلى حسابك',
              style: arabicFont.copyWith(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // حقل رقم الموظف
            _buildTextField(
              controller: _employeeIdController,
              label: 'رقم الموظف',
              hint: 'أدخل رقم الموظف',
              icon: Icons.person,
              obscureText: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال رقم الموظف';
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // حقل الهوية الوطنية
            _buildTextField(
              controller: _nationalIdController,
              label: 'الهوية الوطنية',
              hint: 'أدخل الهوية الوطنية',
              icon: Icons.badge_rounded,
              obscureText: _obscureNationalId,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNationalId
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _obscureNationalId = !_obscureNationalId;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال الهوية الوطنية';
                }
                if (value.length != 10) {
                  return 'الهوية الوطنية يجب أن تكون 10 أرقام';
                }
                return null;
              },
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            // زر تسجيل الدخول
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'تسجيل الدخول',
                            style: arabicFont.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4FC3F7).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: arabicFont.copyWith(
          fontSize: 16,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: arabicFont.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          hintStyle: arabicFont.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF4FC3F7),
            size: 24,
          ),
          suffixIcon: suffixIcon != null
              ? IconTheme(
                  data: const IconThemeData(
                    color: Color(0xFF4FC3F7),
                  ),
                  child: suffixIcon,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF4FC3F7),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for hexagonal pattern background
class HexagonalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const hexSize = 40.0;
    final hexHeight = hexSize * math.sqrt(3);
    final hexWidth = hexSize * 2;

    // Draw hexagonal grid
    for (double y = -hexHeight; y < size.height + hexHeight; y += hexHeight * 0.75) {
      for (double x = -hexWidth; x < size.width + hexWidth; x += hexWidth * 0.75) {
        final offsetX = (y / (hexHeight * 0.75)).round() % 2 == 0
            ? x
            : x + hexWidth * 0.375;
        
        _drawHexagon(canvas, Offset(offsetX, y), hexSize, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
