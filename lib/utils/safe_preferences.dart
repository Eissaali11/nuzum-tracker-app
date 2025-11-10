import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================
/// 🔒 استخدام آمن لـ SharedPreferences
/// ============================================
class SafePreferences {
  /// الحصول على SharedPreferences بشكل آمن مع إعادة المحاولة
  static Future<SharedPreferences?> getInstance({int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        // إعطاء وقت للـ platform channels للتهيئة
        if (i > 0) {
          await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
        }
        
        final prefs = await SharedPreferences.getInstance();
        return prefs;
      } catch (e) {
        debugPrint('⚠️ [SafePreferences] Attempt ${i + 1} failed: $e');
        
        if (i == retries - 1) {
          debugPrint('❌ [SafePreferences] All attempts failed');
          return null;
        }
      }
    }
    return null;
  }

  /// الحصول على قيمة String بشكل آمن
  static Future<String?> getString(String key) async {
    final prefs = await getInstance();
    if (prefs == null) return null;
    
    try {
      return prefs.getString(key);
    } catch (e) {
      debugPrint('❌ [SafePreferences] Error getting string: $e');
      return null;
    }
  }

  /// حفظ قيمة String بشكل آمن
  static Future<bool> setString(String key, String value) async {
    final prefs = await getInstance();
    if (prefs == null) return false;
    
    try {
      return await prefs.setString(key, value);
    } catch (e) {
      debugPrint('❌ [SafePreferences] Error setting string: $e');
      return false;
    }
  }

  /// الحصول على قيمة bool بشكل آمن
  static Future<bool?> getBool(String key) async {
    final prefs = await getInstance();
    if (prefs == null) return null;
    
    try {
      return prefs.getBool(key);
    } catch (e) {
      debugPrint('❌ [SafePreferences] Error getting bool: $e');
      return null;
    }
  }

  /// حفظ قيمة bool بشكل آمن
  static Future<bool> setBool(String key, bool value) async {
    final prefs = await getInstance();
    if (prefs == null) return false;
    
    try {
      return await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('❌ [SafePreferences] Error setting bool: $e');
      return false;
    }
  }

  /// مسح جميع البيانات بشكل آمن
  static Future<bool> clear() async {
    final prefs = await getInstance();
    if (prefs == null) return false;
    
    try {
      return await prefs.clear();
    } catch (e) {
      debugPrint('❌ [SafePreferences] Error clearing: $e');
      return false;
    }
  }
}

