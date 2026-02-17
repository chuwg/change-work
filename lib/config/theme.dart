import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // Brand Colors — Warm Amber / Coral tone
  static const Color primary = Color(0xFFE8985A);       // Warm amber
  static const Color primaryLight = Color(0xFFF2B882);   // Light peach
  static const Color primaryDark = Color(0xFFCC7A3A);    // Deep amber

  static const Color secondary = Color(0xFFE07B7B);      // Soft coral
  static const Color accent = Color(0xFFF4A261);         // Sandy gold

  // Dark Theme Colors — Warm undertone
  static const Color bgDark = Color(0xFF1A1512);         // Warm charcoal
  static const Color surfaceDark = Color(0xFF241F1B);    // Warm dark brown
  static const Color surfaceDarkElevated = Color(0xFF302924); // Warm elevated
  static const Color cardDark = Color(0xFF2A2320);       // Warm card

  // Text Colors
  static const Color textPrimary = Color(0xFFF5EDE4);    // Warm white
  static const Color textSecondary = Color(0xFFB8A99A);  // Warm grey
  static const Color textTertiary = Color(0xFF7A6E63);   // Warm muted

  // Shift Colors — softer warm palette
  static const Color shiftDay = Color(0xFFE8B94A);       // Golden yellow
  static const Color shiftEvening = Color(0xFFE07B7B);   // Coral
  static const Color shiftNight = Color(0xFF8B7EC8);     // Soft lavender
  static const Color shiftOff = Color(0xFF7CB88A);       // Sage green

  // Status Colors
  static const Color success = Color(0xFF7CB88A);        // Sage green
  static const Color warning = Color(0xFFE8B94A);        // Warm yellow
  static const Color error = Color(0xFFD4675A);          // Terra cotta
  static const Color info = Color(0xFF8BB8CC);           // Dusty blue

  // Sleep Quality Colors
  static const List<Color> sleepGradient = [
    Color(0xFF2A1F3D),
    Color(0xFF3D2E52),
    Color(0xFF4F3D66),
    Color(0xFF6B5A80),
    Color(0xFF897A9A),
  ];

  // Circadian Rhythm Colors
  static const Color circadianAlert = Color(0xFFE8B94A);    // Golden
  static const Color circadianDrowsy = Color(0xFFE07B7B);   // Coral
  static const Color circadianSleep = Color(0xFF6B5A80);    // Muted purple
  static const Color circadianWaking = Color(0xFF7CB88A);   // Sage

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surfaceDark,
      error: error,
      onPrimary: Color(0xFF1A1512),
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primary,
      unselectedItemColor: textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: const Color(0xFF1A1512),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDarkElevated,
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
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: textTertiary),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3A312B),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceDarkElevated,
      selectedColor: primary.withValues(alpha: 0.3),
      labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceDarkElevated,
      contentTextStyle: const TextStyle(color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary.withValues(alpha: 0.3);
        }
        return surfaceDarkElevated;
      }),
    ),
  );

  // Gradient decorations
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFF2B882)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surfaceDark, cardDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sleep card gradient — warm night tones
  static const LinearGradient sleepCardGradient = LinearGradient(
    colors: [Color(0xFF2A1F3D), Color(0xFF3D2E52)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Health card gradient — warm amber/burgundy
  static const LinearGradient healthCardGradient = LinearGradient(
    colors: [Color(0xFF3D2020), Color(0xFF4A2A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Energy card gradient — warm amber/gold
  static const LinearGradient energyCardGradient = LinearGradient(
    colors: [Color(0xFF3D2A1A), Color(0xFF4A3520)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Salary card gradient — deep forest green
  static const LinearGradient salaryCardGradient = LinearGradient(
    colors: [Color(0xFF1A3D2A), Color(0xFF243D2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Salary colors
  static const Color salaryGreen = Color(0xFF5DB882);

  static BoxDecoration get glassCard => BoxDecoration(
        color: surfaceDarkElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      );
}
