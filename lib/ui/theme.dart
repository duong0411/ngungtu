import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// STEM lab look: cool mist + copper accent (không dùng purple/cream mặc định AI)
class NgungTuTheme {
  static const Color deep = Color(0xFF071820);
  static const Color panel = Color(0xFF0E2A33);
  static const Color mist = Color(0xFF1A4A57);
  static const Color aqua = Color(0xFF2EC4B6);
  static const Color ice = Color(0xFF9BE7FF);
  static const Color copper = Color(0xFFE07A3D);
  static const Color soft = Color(0xFFD7F0F2);

  static ThemeData dark() {
    final display = GoogleFonts.syneTextTheme();
    final body = GoogleFonts.dmSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deep,
      colorScheme: const ColorScheme.dark(
        primary: aqua,
        secondary: copper,
        surface: panel,
        onPrimary: deep,
        onSecondary: deep,
        onSurface: soft,
      ),
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: soft,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: soft,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: soft,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: display.titleLarge?.copyWith(
          color: soft,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: body.bodyLarge?.copyWith(color: soft),
        bodyMedium: body.bodyMedium?.copyWith(color: soft.withValues(alpha: 0.88)),
        labelLarge: body.labelLarge?.copyWith(
          color: soft,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
