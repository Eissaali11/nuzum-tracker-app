import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// ============================================
/// 🌐 خدمة إدارة اللغة - Language Service
/// ============================================
class LanguageService extends ChangeNotifier {
  static LanguageService? _instance;
  static LanguageService get instance => _instance ??= LanguageService._();
  LanguageService._();

  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('ar'); // اللغة الافتراضية

  /// الحصول على اللغة الحالية
  Locale get currentLocale => _currentLocale;

  /// الحصول على كود اللغة (ar أو en)
  String get currentLanguageCode => _currentLocale.languageCode;

  /// التحقق من أن اللغة عربية
  bool get isArabic => _currentLocale.languageCode == 'ar';

  /// التحقق من أن اللغة إنجليزية
  bool get isEnglish => _currentLocale.languageCode == 'en';

  /// تهيئة الخدمة - جلب اللغة المحفوظة
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      
      if (savedLanguage != null && (savedLanguage == 'ar' || savedLanguage == 'en')) {
        _currentLocale = Locale(savedLanguage);
        debugPrint('✅ [Language] Loaded saved language: $savedLanguage');
      } else {
        // استخدام اللغة الافتراضية للنظام
        final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
        if (systemLocale.languageCode == 'ar' || systemLocale.languageCode == 'en') {
          _currentLocale = Locale(systemLocale.languageCode);
        } else {
          _currentLocale = const Locale('ar'); // افتراضي عربي
        }
        debugPrint('✅ [Language] Using system/default language: ${_currentLocale.languageCode}');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [Language] Error initializing: $e');
      _currentLocale = const Locale('ar'); // افتراضي في حالة الخطأ
    }
  }

  /// تغيير اللغة
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != 'ar' && languageCode != 'en') {
      debugPrint('⚠️ [Language] Invalid language code: $languageCode');
      return;
    }

    if (_currentLocale.languageCode == languageCode) {
      debugPrint('ℹ️ [Language] Language already set to: $languageCode');
      return;
    }

    try {
      _currentLocale = Locale(languageCode);
      
      // حفظ اللغة المختارة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      debugPrint('✅ [Language] Language changed to: $languageCode');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [Language] Error changing language: $e');
    }
  }

  /// تبديل اللغة (عربي ↔ إنجليزي)
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLocale.languageCode == 'ar' ? 'en' : 'ar';
    await changeLanguage(newLanguage);
  }

  /// تعيين اللغة العربية
  Future<void> setArabic() async {
    await changeLanguage('ar');
  }

  /// تعيين اللغة الإنجليزية
  Future<void> setEnglish() async {
    await changeLanguage('en');
  }
}

