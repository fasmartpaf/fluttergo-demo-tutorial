import 'package:flutter/material.dart';

/// Mist dawn desk + citrus leaf green — FlutterGo Demo Tutorial.
class AppColors {
  const AppColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.ink,
    required this.muted,
    required this.line,
    required this.success,
  });

  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color ink;
  final Color muted;
  final Color line;
  final Color success;

  static const light = AppColors(
    background: Color(0xFFE8F1F4),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF2A9B6A),
    secondary: Color(0xFFF3C96B),
    ink: Color(0xFF14201C),
    muted: Color(0xFF5A6B64),
    line: Color(0xFFD2E0DC),
    success: Color(0xFF1E8E4E),
  );
}
