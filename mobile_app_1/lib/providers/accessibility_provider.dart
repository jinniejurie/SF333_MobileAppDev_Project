import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider extends ChangeNotifier {
  bool _highContrastMode = false;
  bool _ttsEnabled = false;
  double _fontScale = 1.0;

  bool get highContrastMode => _highContrastMode;
  bool get ttsEnabled => _ttsEnabled;
  double get fontScale => _fontScale;

  AccessibilityProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _highContrastMode = prefs.getBool('high_contrast_mode') ?? false;
    _ttsEnabled = prefs.getBool('tts_enabled') ?? false;
    final savedFontScale = prefs.getDouble('font_scale') ?? 1.0;
    // Clamp font scale to valid range (0.8 - 1.5) to prevent slider errors
    _fontScale = savedFontScale.clamp(0.8, 1.5);
    // If the saved value was outside the range, update it
    if (savedFontScale != _fontScale) {
      await prefs.setDouble('font_scale', _fontScale);
    }
    notifyListeners();
  }

  Future<void> setHighContrastMode(bool value) async {
    _highContrastMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast_mode', value);
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', value);
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_scale', value);
    notifyListeners();
  }

  ThemeData getTheme(BuildContext context, {bool? highContrast}) {
    final useHighContrast = highContrast ?? _highContrastMode;
    
    if (useHighContrast) {
      // High Contrast Mode - Black and White
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.black,
          surface: Colors.white,
          background: Colors.white,
          error: Colors.black,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
          onBackground: Colors.black,
          onError: Colors.white,
        ),
        textTheme: _getTextTheme(context),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black, width: 3), // Thick border
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 3), // Thick border
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 3), // Thick border
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black, width: 3), // Thick border
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.black, width: 3), // Thick border for cards
          ),
        ),
      );
    } else {
      // Normal Mode
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF90CAF9),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF90CAF9),
          secondary: const Color(0xFF90CAF9),
          surface: Colors.white,
          background: const Color(0xFFD6F0FF),
        ),
        textTheme: _getTextTheme(context),
      );
    }
  }

  TextTheme _getTextTheme(BuildContext context) {
    final baseScale = MediaQuery.of(context).textScaleFactor;
    final customScale = _fontScale;
    final finalScale = baseScale * customScale;

    return TextTheme(
      displayLarge: TextStyle(fontSize: 57 * finalScale, fontWeight: FontWeight.w400),
      displayMedium: TextStyle(fontSize: 45 * finalScale, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(fontSize: 36 * finalScale, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(fontSize: 32 * finalScale, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(fontSize: 28 * finalScale, fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(fontSize: 24 * finalScale, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(fontSize: 22 * finalScale, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(fontSize: 16 * finalScale, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 14 * finalScale, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16 * finalScale, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14 * finalScale, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 12 * finalScale, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 14 * finalScale, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 12 * finalScale, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11 * finalScale, fontWeight: FontWeight.w500),
    );
  }
}

