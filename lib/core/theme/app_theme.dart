import 'package:flutter/material.dart';

class AppColors {
  // Deep space background gradient stops.
  static const bgTop = Color(0xFF07081A);
  static const bgMid = Color(0xFF0B0E2A);
  static const bgBottom = Color(0xFF0A0719);

  static const bg = Color(0xFF080A1C);
  static const surface = Color(0xFF141733);
  static const surfaceAlt = Color(0xFF0E1129);
  static const surfaceHi = Color(0xFF1B1F45);

  // Neon accents.
  static const cyan = Color(0xFF38E1FF);
  static const violet = Color(0xFF8B5CF6);
  static const magenta = Color(0xFFFF2D7E);
  static const accent = Color(0xFF7C5CFF);
  static const accentDim = Color(0xFF5036C8);

  static const userBubbleA = Color(0xFF6E45F2);
  static const userBubbleB = Color(0xFFB14BFF);

  static const border = Color(0x1FFFFFFF);
  static const borderStrong = Color(0x33FFFFFF);
  static const glass = Color(0x14FFFFFF);

  static const textPrimary = Color(0xFFF2F4FF);
  static const textSecondary = Color(0xFF8B90B8);
  static const textTertiary = Color(0xFF5B6086);
  static const danger = Color(0xFFFF5470);
  static const success = Color(0xFF3DD68C);
}

class AppGradients {
  static const scaffold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
    stops: [0.0, 0.55, 1.0],
  );

  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.cyan, AppColors.violet, AppColors.magenta],
  );

  static const accentSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38E1FF), Color(0xFF8B5CF6)],
  );

  static const userBubble = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.userBubbleA, AppColors.userBubbleB],
  );

  static const glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1FFFFFFF), Color(0x08FFFFFF)],
  );
}

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bg,
        primary: AppColors.accent,
        secondary: AppColors.cyan,
        tertiary: AppColors.magenta,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      dividerColor: AppColors.border,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontFamily: 'Roboto',
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glass,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.violet, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceHi,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
