import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  ThemeData get theme => _isDark ? AppTheme.darkTheme() : AppTheme.lightTheme();
  bool get isDark => _isDark;

  ThemeProvider() {
    _isDark = StorageService.getThemeMode();
  }

  void toggleTheme() {
    _isDark = !_isDark;
    StorageService.setThemeMode(_isDark);
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDark = value;
    StorageService.setThemeMode(_isDark);
    notifyListeners();
  }
}
