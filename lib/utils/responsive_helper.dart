import 'package:flutter/material.dart';

/// ============================================
/// 📱 مساعد التصميم المتجاوب - Responsive Design Helper
/// ============================================
class ResponsiveHelper {
  // Breakpoints للأجهزة المختلفة
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// الحصول على نوع الجهاز
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// الحصول على عرض الشاشة
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// الحصول على ارتفاع الشاشة
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// التحقق من أن الجهاز هاتف محمول
  static bool isMobile(BuildContext context) {
    return getScreenWidth(context) < mobileBreakpoint;
  }

  /// التحقق من أن الجهاز لوحي
  static bool isTablet(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// التحقق من أن الجهاز سطح مكتب
  static bool isDesktop(BuildContext context) {
    return getScreenWidth(context) >= tabletBreakpoint;
  }

  /// الحصول على padding متجاوب
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(16.0);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  /// الحصول على margin متجاوب
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileBreakpoint) {
      return const EdgeInsets.all(12.0);
    } else if (width < tabletBreakpoint) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  /// الحصول على حجم خط متجاوب
  static double getResponsiveFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = getScreenWidth(context);
    if (width < mobileBreakpoint) {
      return mobile;
    } else if (width < tabletBreakpoint) {
      return tablet ?? mobile * 1.2;
    } else {
      return desktop ?? mobile * 1.5;
    }
  }

  /// الحصول على عدد الأعمدة متجاوب
  static int getResponsiveColumns(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileBreakpoint) {
      return 1;
    } else if (width < tabletBreakpoint) {
      return 2;
    } else {
      return 3;
    }
  }

  /// الحصول على spacing متجاوب
  static double getResponsiveSpacing(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = getScreenWidth(context);
    if (width < mobileBreakpoint) {
      return mobile;
    } else if (width < tabletBreakpoint) {
      return tablet ?? mobile * 1.5;
    } else {
      return desktop ?? mobile * 2;
    }
  }

  /// الحصول على borderRadius متجاوب
  static double getResponsiveBorderRadius(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileBreakpoint) {
      return 16.0;
    } else if (width < tabletBreakpoint) {
      return 20.0;
    } else {
      return 24.0;
    }
  }

  /// الحصول على icon size متجاوب
  static double getResponsiveIconSize(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileBreakpoint) {
      return 24.0;
    } else if (width < tabletBreakpoint) {
      return 28.0;
    } else {
      return 32.0;
    }
  }

  /// الحصول على max width للعناصر
  static double getMaxContentWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileBreakpoint) {
      return width;
    } else if (width < tabletBreakpoint) {
      return 800.0;
    } else {
      return 1200.0;
    }
  }
}

/// ============================================
/// 📱 نوع الجهاز - Device Type
/// ============================================
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

