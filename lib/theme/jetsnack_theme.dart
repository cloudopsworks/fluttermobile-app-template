import 'package:flutter/material.dart';

class JetsnackColors {
  static const Color primary = Color(0xFFFF5252);
  static const Color primaryVariant = Color(0xFFD32F2F);
  static const Color secondary = Color(0xFF7B1FA2);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}

final ThemeData jetsnackTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: JetsnackColors.primary,
    primary: JetsnackColors.primary,
    secondary: JetsnackColors.secondary,
    surface: JetsnackColors.surface,
    background: JetsnackColors.background,
  ),
  scaffoldBackgroundColor: JetsnackColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: JetsnackColors.surface,
    foregroundColor: JetsnackColors.textPrimary,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    clipBehavior: Clip.antiAlias,
  ),
);
