import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Every colour that differs between the light and dark themes.
///
/// The app reads colours through [AppTheme]'s static getters rather than
/// `Theme.of(context)`, so switching themes means swapping the palette behind
/// those getters and rebuilding. Anything that does *not* change between
/// themes (gradient stops for a specific card, say) stays on [AppTheme].
class AppPalette {
  final Brightness brightness;

  // Surfaces
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color card;
  final Color divider;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Brand
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color accent;

  /// Drawn *on top of* [primary] — near-black on the amber in both themes.
  final Color onPrimary;

  // Shift types
  final Color shiftDay;
  final Color shiftEvening;
  final Color shiftNight;
  final Color shiftOff;

  // Status
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  /// Tint used for the frosted cards that make up most of the UI.
  final Color glassFill;
  final Color glassBorder;

  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.card,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.onPrimary,
    required this.shiftDay,
    required this.shiftEvening,
    required this.shiftNight,
    required this.shiftOff,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.glassFill,
    required this.glassBorder,
  });

  /// The original warm-charcoal theme.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF1A1512),
    surface: Color(0xFF241F1B),
    surfaceElevated: Color(0xFF302924),
    card: Color(0xFF2A2320),
    divider: Color(0xFF3A312B),
    textPrimary: Color(0xFFF5EDE4),
    textSecondary: Color(0xFFB8A99A),
    textTertiary: Color(0xFF7A6E63),
    primary: Color(0xFFE8985A),
    primaryLight: Color(0xFFF2B882),
    primaryDark: Color(0xFFCC7A3A),
    secondary: Color(0xFFE07B7B),
    accent: Color(0xFFF4A261),
    onPrimary: Color(0xFF1A1512),
    shiftDay: Color(0xFFE8B94A),
    shiftEvening: Color(0xFFE07B7B),
    shiftNight: Color(0xFF8B7EC8),
    shiftOff: Color(0xFF7CB88A),
    success: Color(0xFF7CB88A),
    warning: Color(0xFFE8B94A),
    error: Color(0xFFD4675A),
    info: Color(0xFF8BB8CC),
    glassFill: Color(0xB3302924),
    glassBorder: Color(0x0FFFFFFF),
  );

  /// Warm daylight theme. The hues match the dark palette so the app still
  /// looks like itself; saturation and depth are raised because the same
  /// pastel that reads as "soft" on charcoal washes out on white.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFDF8F3),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF6EEE5),
    card: Color(0xFFFFFFFF),
    divider: Color(0xFFEADFD3),
    textPrimary: Color(0xFF2A211B),
    textSecondary: Color(0xFF6E5D4E),
    textTertiary: Color(0xFF9C8B7B),
    primary: Color(0xFFD9803A),
    primaryLight: Color(0xFFF0A867),
    primaryDark: Color(0xFFB2611F),
    secondary: Color(0xFFD25F5F),
    accent: Color(0xFFE08A33),
    onPrimary: Color(0xFFFFFFFF),
    shiftDay: Color(0xFFD9A01F),
    shiftEvening: Color(0xFFD25F5F),
    shiftNight: Color(0xFF6E5FB8),
    shiftOff: Color(0xFF4E9E68),
    success: Color(0xFF4E9E68),
    warning: Color(0xFFD9A01F),
    error: Color(0xFFC2452F),
    info: Color(0xFF3F87A6),
    glassFill: Color(0xFFFFFFFF),
    glassBorder: Color(0x14000000),
  );
}

class AppTheme {
  AppTheme._();

  static AppPalette _palette = AppPalette.dark;

  static AppPalette get palette => _palette;

  /// Swap the active palette. The caller is responsible for rebuilding —
  /// [ThemeScope] in app.dart does this before the first frame of each build.
  static set palette(AppPalette value) => _palette = value;

  static bool get isDark => _palette.brightness == Brightness.dark;

  // --- Surfaces -------------------------------------------------------------
  // The `Dark` suffixes are historical: these were const dark-theme colours
  // before the light theme existed, and hundreds of call sites use the names.
  static Color get bgDark => _palette.background;
  static Color get surfaceDark => _palette.surface;
  static Color get surfaceDarkElevated => _palette.surfaceElevated;
  static Color get cardDark => _palette.card;
  static Color get divider => _palette.divider;

  // --- Text -----------------------------------------------------------------
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textTertiary => _palette.textTertiary;

  // --- Brand ----------------------------------------------------------------
  static Color get primary => _palette.primary;
  static Color get primaryLight => _palette.primaryLight;
  static Color get primaryDark => _palette.primaryDark;
  static Color get secondary => _palette.secondary;
  static Color get accent => _palette.accent;
  static Color get onPrimary => _palette.onPrimary;

  // --- Shift types ----------------------------------------------------------
  static Color get shiftDay => _palette.shiftDay;
  static Color get shiftEvening => _palette.shiftEvening;
  static Color get shiftNight => _palette.shiftNight;
  static Color get shiftOff => _palette.shiftOff;

  // --- Status ---------------------------------------------------------------
  static Color get success => _palette.success;
  static Color get warning => _palette.warning;
  static Color get error => _palette.error;
  static Color get info => _palette.info;

  // --- Circadian ------------------------------------------------------------
  static Color get circadianAlert => _palette.shiftDay;
  static Color get circadianDrowsy => _palette.secondary;
  static Color get circadianSleep =>
      isDark ? const Color(0xFF6B5A80) : const Color(0xFF6E5FB8);
  static Color get circadianWaking => _palette.success;

  static Color get salaryGreen =>
      isDark ? const Color(0xFF5DB882) : const Color(0xFF2F8F5B);

  static const List<Color> sleepGradient = [
    Color(0xFF2A1F3D),
    Color(0xFF3D2E52),
    Color(0xFF4F3D66),
    Color(0xFF6B5A80),
    Color(0xFF897A9A),
  ];

  // --- Gradients ------------------------------------------------------------
  // The feature cards keep their identity in both themes: the same hue, tinted
  // for a pale background instead of a dark one.
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get cardGradient => LinearGradient(
        colors: [surfaceDark, cardDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get sleepCardGradient => LinearGradient(
        colors: isDark
            ? const [Color(0xFF2A1F3D), Color(0xFF3D2E52)]
            : const [Color(0xFF6E5FB8), Color(0xFF8C7BD6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get healthCardGradient => LinearGradient(
        colors: isDark
            ? const [Color(0xFF3D2020), Color(0xFF4A2A1A)]
            : const [Color(0xFFD25F5F), Color(0xFFE08A5A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get energyCardGradient => LinearGradient(
        colors: isDark
            ? const [Color(0xFF3D2A1A), Color(0xFF4A3520)]
            : const [Color(0xFFE09A3C), Color(0xFFEFB65F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get salaryCardGradient => LinearGradient(
        colors: isDark
            ? const [Color(0xFF1A3D2A), Color(0xFF243D2D)]
            : const [Color(0xFF2F8F5B), Color(0xFF4FAE78)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxDecoration get glassCard => BoxDecoration(
        color: _palette.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _palette.glassBorder),
        boxShadow: isDark
            ? null
            // A flat white card on a warm white background needs a shadow to
            // read as a card at all.
            : [
                BoxShadow(
                  color: const Color(0xFF8A6A4A).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      );

  /// Status bar icon style matching the active palette.
  static SystemUiOverlayStyle get overlayStyle =>
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

  static ThemeData themeFor(AppPalette p) {
    final isDarkPalette = p.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.background,
      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: p.primary,
        onPrimary: p.onPrimary,
        secondary: p.secondary,
        onSecondary: Colors.white,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: p.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDarkPalette
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: p.textTertiary),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceElevated,
        selectedColor: p.primary.withValues(alpha: 0.3),
        labelStyle: TextStyle(color: p.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceElevated,
        contentTextStyle: TextStyle(color: p.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return p.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.primary.withValues(alpha: 0.3);
          }
          return p.surfaceElevated;
        }),
      ),
    );
  }

  static ThemeData get darkTheme => themeFor(AppPalette.dark);
  static ThemeData get lightTheme => themeFor(AppPalette.light);
}
