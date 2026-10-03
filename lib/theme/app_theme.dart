import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../motion/app_motion.dart';
import 'app_colors.dart';

class AppTheme {
  static final SystemUiOverlayStyle systemUi = SystemUiOverlayStyle(
    statusBarColor: AppColors.light.background,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.light.background,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: const Color(0x00000000),
  );

  static ThemeData light() {
    const colors = AppColors.light;
    final scheme = ColorScheme.light(
      primary: colors.primary,
      onPrimary: colors.surface,
      secondary: colors.secondary,
      onSecondary: colors.ink,
      surface: colors.surface,
      onSurface: colors.ink,
    );

    final display = GoogleFonts.soraTextTheme();
    final body = GoogleFonts.plusJakartaSansTextTheme();
    final text = body.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: display.displayMedium?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      displaySmall: display.displaySmall?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        fontSize: 32,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 24,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleLarge: body.titleLarge?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
      titleMedium: body.titleMedium?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: body.titleSmall?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        color: colors.ink,
        fontSize: 16,
        height: 1.4,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        color: colors.ink,
        fontSize: 14,
        height: 1.4,
      ),
      bodySmall: body.bodySmall?.copyWith(
        color: colors.muted,
        fontSize: 13,
        height: 1.35,
      ),
      labelLarge: body.labelLarge?.copyWith(
        color: colors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    ).apply(bodyColor: colors.ink, displayColor: colors.ink);

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: AppMotion.pageTransitions,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: text,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colors.background,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: systemUi,
        titleTextStyle: text.titleLarge,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.line, thickness: 1, space: 1),
    );
  }
}
