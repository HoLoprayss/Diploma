import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String THEME_KEY = 'is_dark_mode';

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Загружаем тему из SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(THEME_KEY) ?? false;
    notifyListeners();
  }

  // Сохраняем тему в SharedPreferences
  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_KEY, _isDarkMode);
  }

  bool get isDarkMode => _isDarkMode;

  // Основная светлая тема
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF2A9D8F),
    scaffoldBackgroundColor: Color(0xFFF8FAFC),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF2A9D8F),
      primary: Color(0xFF2A9D8F),
      secondary: Color(0xFFE76F51),
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF2A9D8F)),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    iconTheme: IconThemeData(color: Color(0xFF2A9D8F)),
    useMaterial3: true,
  );

  // Основная темная тема
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF2A9D8F),
    scaffoldBackgroundColor: Color(0xFF1A202C),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color(0xFF2A9D8F),
      primary: Color(0xFF2A9D8F),
      secondary: Color(0xFFE76F51),
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF2A9D8F)),
    ),
    cardTheme: CardTheme(
      color: Color(0xFF2D3748),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    iconTheme: IconThemeData(color: Color(0xFF2A9D8F)),
    useMaterial3: true,
  );

  ThemeData getTheme() {
    return _isDarkMode ? darkTheme : lightTheme;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemeToPrefs(); // Сохраняем после переключения
    notifyListeners();
  }
} 