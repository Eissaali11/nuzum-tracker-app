import 'package:flutter/material.dart';

/// ============================================
/// 🚗 لوحة السيارة السعودية - Saudi Car Plate Widget
/// ============================================
class SaudiPlateWidget extends StatelessWidget {
  final String plateNumberAr; // رقم اللوحة بالعربية
  final String? plateNumberEn; // رقم اللوحة بالإنجليزية
  final double? width;
  final double? height;
  final Color borderColor;
  final bool showShield;

  const SaudiPlateWidget({
    super.key,
    required this.plateNumberAr,
    this.plateNumberEn,
    this.width,
    this.height,
    this.borderColor = const Color(0xFF006633), // اللون الأخضر السعودي
    this.showShield = true,
  });

  @override
  Widget build(BuildContext context) {
    final plateWidth = width ?? 280.0;
    final plateHeight = height ?? 140.0;

    return Container(
      width: plateWidth,
      height: plateHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // خلفية مع نمط خفيف
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.grey.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          // المحتوى
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // شعار الدرع (اختياري)
                if (showShield)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Icon(
                      Icons.shield_rounded,
                      color: borderColor,
                      size: 24,
                    ),
                  ),
                // رقم اللوحة بالعربية
                Text(
                  plateNumberAr,
                  style: TextStyle(
                    fontSize: plateHeight * 0.25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 2,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                // رقم اللوحة بالإنجليزية (إن وجد)
                if (plateNumberEn != null && plateNumberEn!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    plateNumberEn!,
                    style: TextStyle(
                      fontSize: plateHeight * 0.15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      letterSpacing: 3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          // خطوط زخرفية في الزوايا
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor, width: 2),
                  left: BorderSide(color: borderColor, width: 2),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor, width: 2),
                  right: BorderSide(color: borderColor, width: 2),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 2),
                  left: BorderSide(color: borderColor, width: 2),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 2),
                  right: BorderSide(color: borderColor, width: 2),
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

