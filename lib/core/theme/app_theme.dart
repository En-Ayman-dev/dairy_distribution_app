import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A professional, accessible Design System for the app.
/// - Implements both `lightTheme` and `darkTheme`
/// - Uses Cairo font family (Arabic friendly)
/// - Defines colors, typography, shapes and component styles
class AppTheme {
  AppTheme._(); // Private constructor to avoid instantiation

  // ---------------------------
  // Color Palette
  // ---------------------------
  // Primary: Deep Emerald Green (#00695C)
  static const Color _primary = Color(0xFF00695C);

  // Secondary: Golden Amber (#FFC107)
  static const Color _secondary = Color(0xFFFFC107);

  // Dark Surface: Gunmetal Blue (#102027)
  static const Color _darkSurface = Color(0xFF102027);

  // Card colors
  static const Color _cardLight = Color(0xFFFFFFFF); // Pure White
  static const Color _cardDark = Color(0xFF263238); // Charcoal

  // Neutral accents and supportive colors
  static const Color _grey100 = Color(0xFFF5F5F5);
  static const Color _grey300 = Color(0xFFE0E0E0);
  static const Color _onPrimary = Color(0xFFFFFFFF);
  static const Color _onSecondary = Color(0xFF000000);

  // Elevations / Shadows
  static const double _cardElevation = 4.0;
  static const double _buttonElevation = 6.0; // "heavy shadow"

  // Shape Radii
  static const double _cardRadius = 20.0;
  static const double _inputRadius = 15.0;
  static const double _buttonRadius = 15.0;

  // Button height
  static const double _buttonHeight = 54.0;

  // ---------------------------
  // Typography (Cairo)
  // ---------------------------
  static TextTheme _cairoTextTheme(TextTheme base) => GoogleFonts.cairoTextTheme(base);

  // Helper to create a complete TextTheme with clear headings and body styles
  static TextTheme _baseTextTheme(ColorScheme colorScheme) {
    final base = ThemeData.light().textTheme;

    final textTheme = _cairoTextTheme(base).copyWith(
      displayLarge: GoogleFonts.cairo(fontSize: 96, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      displayMedium: GoogleFonts.cairo(fontSize: 60, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      displaySmall: GoogleFonts.cairo(fontSize: 48, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      headlineLarge: GoogleFonts.cairo(fontSize: 34, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      headlineMedium: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      headlineSmall: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      titleLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
      titleMedium: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
      bodyLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
      bodyMedium: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
      labelLarge: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onPrimary),
      bodySmall: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
      labelMedium: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
      labelSmall: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
      titleSmall: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
    );

    return textTheme;
  }

  // ---------------------------
  // Input Decoration Theme
  // ---------------------------
  static InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) => InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.brightness == Brightness.light ? _grey100 : Colors.white10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: _secondary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_inputRadius),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
      );

  // ---------------------------
  // Button Theme (ElevatedButton)
  // ---------------------------
  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colorScheme) => ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) => _primary),
          foregroundColor: WidgetStateProperty.all(_onPrimary),
          elevation: WidgetStateProperty.resolveWith((states) => _buttonElevation),
          fixedSize: WidgetStateProperty.resolveWith((states) => Size.fromHeight(_buttonHeight)),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 22)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
          ),
          shadowColor: WidgetStateProperty.all(Colors.black38),
          textStyle: WidgetStateProperty.all(GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      );

  // ---------------------------
  // Card Theme
  // ---------------------------
  static CardThemeData _cardTheme(ColorScheme colorScheme) => CardThemeData(
        elevation: _cardElevation,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
        color: colorScheme.brightness == Brightness.light ? _cardLight : _cardDark,
      );

  // ---------------------------
  // AppBar Theme
  // ---------------------------
  static AppBarTheme _appBarTheme(ColorScheme colorScheme) => AppBarTheme(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onPrimary),
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      );

  // ---------------------------
  // Light Theme
  // ---------------------------
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.light(
      primary: _primary,
      onPrimary: _onPrimary,
      secondary: _secondary,
      onSecondary: _onSecondary,
      surface: _cardLight,
      onSurface: const Color(0xFF1B1B1B),
    );

    final base = ThemeData.light();

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      textTheme: _baseTextTheme(colorScheme),
      primaryColor: _primary,
      appBarTheme: _appBarTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      dialogTheme: DialogThemeData(backgroundColor: colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: _secondary, foregroundColor: _onSecondary, elevation: 6),
      iconTheme: const IconThemeData(color: Color(0xFF1B1B1B)),
      dividerColor: _grey300,
      snackBarTheme: SnackBarThemeData(backgroundColor: colorScheme.onPrimary, contentTextStyle: GoogleFonts.cairo(color: _onPrimary)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: Colors.white, selectedItemColor: _primary, unselectedItemColor: Colors.black54),
    );
  }

  // ---------------------------
  // Dark Theme
  // ---------------------------
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.dark(
      primary: _primary,
      onPrimary: _onPrimary,
      secondary: _secondary,
      onSecondary: _onSecondary,
      surface: _cardDark,
      onSurface: Colors.white70,
    );

    final base = ThemeData.dark();

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _darkSurface,
      textTheme: _baseTextTheme(colorScheme),
      primaryColor: _primary,
      appBarTheme: _appBarTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      dialogTheme: DialogThemeData(backgroundColor: colorScheme.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: _secondary, foregroundColor: _onSecondary, elevation: 6),
      iconTheme: const IconThemeData(color: Colors.white70),
      dividerColor: Colors.white12,
      snackBarTheme: SnackBarThemeData(backgroundColor: Colors.black87, contentTextStyle: GoogleFonts.cairo(color: Colors.white)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: _darkSurface, selectedItemColor: _secondary, unselectedItemColor: Colors.white70),
    );
  }
}
