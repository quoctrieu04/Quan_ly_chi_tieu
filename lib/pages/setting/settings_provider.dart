// lib/setting/settings_provider.dart
import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  // ================================
  // Ngôn ngữ (Locale)
  // ================================
  Locale _locale = const Locale('vi'); // mặc định: Tiếng Việt
  Locale get locale => _locale;

  void setLocale(Locale v) {
    _locale = v;
    notifyListeners();
  }

  // ================================
  // ThemeMode (Sáng / Tối)
  // ================================
  ThemeMode _themeMode = ThemeMode.light; // mặc định: Light mode
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isLight) {
    _themeMode = isLight ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // ================================
  // Màu chủ đạo (Seed Color)
  // ================================
  MaterialColor _seed = Colors.amber; // mặc định: vàng
  MaterialColor get seed => _seed;

  void setSeed(MaterialColor c) {
    _seed = c;
    notifyListeners();
  }

  // ================================
  // Cỡ chữ (Text Scale Factor)
  // ================================
  double _textScale = 1.0; // small=0.9, normal=1.0, large=1.15
  double get textScale => _textScale;

  void setTextScale(double v) {
    _textScale = v;
    notifyListeners();
  }
}
