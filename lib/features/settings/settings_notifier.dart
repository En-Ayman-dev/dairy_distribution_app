import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_repository.dart';

class SettingsState {
  final Locale? locale;
  final ThemeMode themeMode;

  SettingsState({required this.locale, required this.themeMode});

  SettingsState copyWith({Locale? locale, ThemeMode? themeMode}) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo)
      : super(SettingsState(locale: null, themeMode: ThemeMode.system)) {
    _load();
  }

  Future<void> _load() async {
    final locale = await _repo.getSavedLocale();
    final theme = await _repo.getSavedThemeMode();
    state = state.copyWith(locale: locale, themeMode: theme);
  }

  Future<void> setLocale(Locale? locale) async {
    await _repo.saveLocale(locale);
    state = state.copyWith(locale: locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repo.saveThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});
