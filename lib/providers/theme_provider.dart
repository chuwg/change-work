import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';

const _themeModeKey = 'theme_mode';

/// Light / dark / follow-the-system, persisted across launches.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  /// Re-read the stored mode, e.g. after a backup restore rewrote it.
  Future<void> reload() => _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_themeModeKey);
      state = _parse(stored) ?? ThemeMode.dark;
    } catch (_) {
      // Keep the default; the app must still start without preferences.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (_) {}
  }

  static ThemeMode? _parse(String? value) {
    for (final mode in ThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

/// Resolve [mode] against the platform setting and publish the matching
/// palette to [AppTheme].
///
/// The app reads colours from AppTheme's static getters rather than
/// `Theme.of(context)`, so the palette has to be in place before the widgets
/// below build — doing it here, at the root, guarantees that ordering.
AppPalette applyPalette(BuildContext context, ThemeMode mode) {
  final platformIsDark =
      MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  final useDark = switch (mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system => platformIsDark,
  };
  final palette = useDark ? AppPalette.dark : AppPalette.light;
  AppTheme.palette = palette;
  return palette;
}
