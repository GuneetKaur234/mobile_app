import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider with ChangeNotifier {
  bool _isDarkMode = true;
  double _fontSize = 16.0;
  String _languageCode = 'en';

  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);

  PreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _fontSize = prefs.getDouble('fontSize') ?? 16.0;
    _languageCode = prefs.getString('languageCode') ?? 'en';
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _languageCode = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', langCode); // <- use same key everywhere
    notifyListeners();
  }
}
