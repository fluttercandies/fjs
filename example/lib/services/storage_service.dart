import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  ThemeMode _themeMode = ThemeMode.system;

  bool get isInitialized => _isInitialized;
  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize StorageService: $e');
    }
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    final themeIndex = _prefs!.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
  }

  Future<void> _saveSettings() async {
    if (_prefs == null) return;

    try {
      await _prefs!.setInt('theme_mode', _themeMode.index);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;

    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }

  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        setThemeMode(ThemeMode.light);
        break;
    }
  }

  Future<void> saveCodeExample(String name, String code) async {
    if (_prefs == null) return;

    try {
      await _prefs!.setString('code_$name', code);
    } catch (e) {
      debugPrint('Failed to save code example: $e');
    }
  }

  Future<String?> getCodeExample(String name) async {
    if (_prefs == null) return null;

    try {
      return _prefs!.getString('code_$name');
    } catch (e) {
      debugPrint('Failed to load code example: $e');
      return null;
    }
  }

  Future<void> clearAllData() async {
    if (_prefs == null) return;

    try {
      await _prefs!.clear();
      await _loadSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear data: $e');
    }
  }
}
