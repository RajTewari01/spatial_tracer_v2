import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  void toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isOn);
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');
    if (isDark != null) {
      _isDarkMode = isDark;
      notifyListeners();
    } else {
      _isDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      notifyListeners();
    }
  }
}

class AppTheme {
  // Obsidian & Frost Palette
  static CupertinoThemeData get lightTheme {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFFD4AF37), // Metallic Gold
      scaffoldBackgroundColor: const Color(0xFFF1F8E9), // Soft Green
      barBackgroundColor: const Color(0xD9F1F8E9), // Translucent Soft Green
      textTheme: CupertinoTextThemeData(
        textStyle: GoogleFonts.inter(color: const Color(0xFF051911)), // Dark text
        navTitleTextStyle: GoogleFonts.pacifico(
          color: const Color(0xFF051911),
          fontSize: 22,
        ),
      ),
    );
  }

  static CupertinoThemeData get darkTheme {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFFFFFFF), // Pure White for accents
      scaffoldBackgroundColor: const Color(0xFF000000), // Pure OLED Black
      barBackgroundColor: const Color(0xD91C1C1E), // Translucent Surface Gray
      textTheme: CupertinoTextThemeData(
        textStyle: GoogleFonts.inter(color: CupertinoColors.white),
        navTitleTextStyle: GoogleFonts.inter(
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
