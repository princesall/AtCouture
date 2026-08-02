import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_color_palette.dart';

/// Contrôle le thème clair/sombre de l'app et mémorise le choix de
/// l'utilisateur d'une session à l'autre (SharedPreferences).
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'isDarkMode';

  bool _isDarkMode = false;
  bool _isLoaded = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  AppColorPalette get colors => _isDarkMode ? const AppColorsDark() : const AppColorsLight();

  Future<void> initialize() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_prefsKey) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, _isDarkMode);
  }
}
