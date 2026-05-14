import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 日系簡約配色 — 以「生成り（kinari，未漂白棉布）」為底，
/// 低彩度藍墨色為主調，弱化陰影與裝飾。
class AppPalette {
  // light
  static const bg = Color(0xFFF4F2EC); // 生成り
  static const surface = Color(0xFFFCFBF7);
  static const surfaceAlt = Color(0xFFEFEDE5);
  static const ink = Color(0xFF3D3A34); // 墨色
  static const inkSoft = Color(0xFF6E6A60);
  static const line = Color(0xFFE2DFD5);
  static const primary = Color(0xFF5C6B7A); // 藍鼠（あいねず）
  static const expense = Color(0xFFB57C70); // 弁柄っぽい赤
  static const income = Color(0xFF7C9070); // 苔色っぽい緑

  // dark
  static const dBg = Color(0xFF1F1E1B);
  static const dSurface = Color(0xFF272622);
  static const dSurfaceAlt = Color(0xFF302E29);
  static const dInk = Color(0xFFE8E5DC);
  static const dInkSoft = Color(0xFFA8A498);
  static const dLine = Color(0xFF3A3833);
  static const dPrimary = Color(0xFF8A9AAC);
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: isDark ? AppPalette.dPrimary : AppPalette.primary,
      onPrimary: isDark ? AppPalette.dBg : Colors.white,
      secondary: isDark ? AppPalette.dPrimary : AppPalette.primary,
      onSecondary: isDark ? AppPalette.dBg : Colors.white,
      error: AppPalette.expense,
      onError: Colors.white,
      surface: isDark ? AppPalette.dSurface : AppPalette.surface,
      onSurface: isDark ? AppPalette.dInk : AppPalette.ink,
      surfaceContainerLowest: isDark ? AppPalette.dBg : AppPalette.bg,
      surfaceContainerLow: isDark ? AppPalette.dBg : AppPalette.bg,
      surfaceContainer: isDark ? AppPalette.dSurface : AppPalette.surface,
      surfaceContainerHigh:
          isDark ? AppPalette.dSurfaceAlt : AppPalette.surfaceAlt,
      surfaceContainerHighest:
          isDark ? AppPalette.dSurfaceAlt : AppPalette.surfaceAlt,
      outline: isDark ? AppPalette.dLine : AppPalette.line,
      outlineVariant: isDark ? AppPalette.dLine : AppPalette.line,
      onSurfaceVariant: isDark ? AppPalette.dInkSoft : AppPalette.inkSoft,
      primaryContainer: isDark ? AppPalette.dSurfaceAlt : AppPalette.surfaceAlt,
      onPrimaryContainer: isDark ? AppPalette.dInk : AppPalette.ink,
    );

    final baseText = isDark
        ? GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.notoSansTextTheme();
    final ink = scheme.onSurface;
    final inkSoft = scheme.onSurfaceVariant;

    final textTheme = baseText.copyWith(
      headlineLarge: baseText.headlineLarge
          ?.copyWith(color: ink, fontWeight: FontWeight.w300, letterSpacing: 1),
      headlineMedium: baseText.headlineMedium
          ?.copyWith(color: ink, fontWeight: FontWeight.w400),
      titleLarge: baseText.titleLarge
          ?.copyWith(color: ink, fontWeight: FontWeight.w500),
      titleMedium: baseText.titleMedium
          ?.copyWith(color: ink, fontWeight: FontWeight.w500),
      bodyLarge: baseText.bodyLarge?.copyWith(color: ink),
      bodyMedium: baseText.bodyMedium?.copyWith(color: ink),
      bodySmall: baseText.bodySmall?.copyWith(color: inkSoft),
      labelLarge: baseText.labelLarge
          ?.copyWith(color: ink, fontWeight: FontWeight.w500),
      labelSmall: baseText.labelSmall?.copyWith(color: inkSoft),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      canvasColor: scheme.surfaceContainerLowest,
      textTheme: textTheme,
      hintColor: inkSoft,
      // 日系：柔和的淡入轉場
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      dividerColor: scheme.outline,
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outline),
        ),
        margin: EdgeInsets.zero,
      ),
      // 日系：弱化按鈕、扁平、細邊框
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        isDense: true,
        hintStyle: TextStyle(color: inkSoft),
        labelStyle: TextStyle(color: inkSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6)),
        labelStyle: TextStyle(color: ink, fontSize: 12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.surfaceContainerHighest,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.all(
            TextStyle(fontSize: 11, color: inkSoft)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
              color: selected ? scheme.primary : inkSoft, size: 22);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: scheme.surface),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: inkSoft,
        textColor: ink,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle:
              WidgetStateProperty.all(const TextStyle(fontSize: 12)),
          side: WidgetStateProperty.all(
              BorderSide(color: scheme.outline)),
        ),
      ),
    );
  }
}
