import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:versee/theme.dart' as appTheme;

/// Serviço para gerenciar temas da aplicação
class ThemeService with ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Carrega o tema salvo das preferências
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      switch (savedTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar tema: $e');
    }
  }

  /// Salva o tema nas preferências
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString;
      
      switch (_themeMode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
        default:
          themeString = 'system';
          break;
      }
      
      await prefs.setString(_themeKey, themeString);
    } catch (e) {
      debugPrint('Erro ao salvar tema: $e');
    }
  }

  /// Define o tema como claro
  Future<void> setLightTheme() async {
    _themeMode = ThemeMode.light;
    notifyListeners();
    await _saveTheme();
  }

  /// Define o tema como escuro
  Future<void> setDarkTheme() async {
    _themeMode = ThemeMode.dark;
    notifyListeners();
    await _saveTheme();
  }

  /// Define o tema como sistema (automático)
  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    notifyListeners();
    await _saveTheme();
  }

  /// Alterna entre claro e escuro
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setLightTheme();
    } else {
      await setDarkTheme();
    }
  }

  /// Temas personalizados para a aplicação
  static ThemeData get lightTheme {
    // Usar o tema light do theme.dart
    return appTheme.lightTheme.copyWith(
      appBarTheme: appTheme.lightTheme.appBarTheme.copyWith(
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    // Usar o tema dark do theme.dart
    return appTheme.darkTheme.copyWith(
      appBarTheme: appTheme.darkTheme.appBarTheme.copyWith(
        centerTitle: true,
        scrolledUnderElevation: 1,
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}