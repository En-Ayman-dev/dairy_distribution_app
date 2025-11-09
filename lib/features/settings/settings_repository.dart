import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _localeKey = 'settings_locale';
  static const _themeKey = 'settings_theme';

  Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<ThemeMode> getSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_themeKey, value);
  }
}
