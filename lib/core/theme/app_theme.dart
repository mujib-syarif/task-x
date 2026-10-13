import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const bgDark = Color(0xFF07090C);
  static const bgLight = Color(0xFFF2F2F7);
  /// Aksen utama Task X (cyan). Nama `blue` dipertahankan agar kode lama tidak berubah.
  static const blue = Color(0xFF06B6D4);
  static const green = Color(0xFF30D158);
  static const orange = Color(0xFFFF9F0A);
  static const red = Color(0xFFFF453A);
  static const purple = Color(0xFFBF5AF2);
  static const teal = Color(0xFF64D2FF);

  /// Warna status berdasarkan tingkat pemakaian (0..1).
  static Color usage(double fraction) {
    if (fraction < 0.6) return green;
    if (fraction < 0.85) return orange;
    return red;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final fg = dark ? Colors.white : const Color(0xFF1C1C1E);
    final muted = dark ? const Color(0xFF9A9AA0) : const Color(0xFF6C6C70);

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8E8E93),
      brightness: brightness,
    ).copyWith(
      primary: fg,
      onPrimary: dark ? Colors.black : Colors.white,
      surface: dark ? const Color(0xFF121215) : Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: fg.withValues(alpha: 0.08),
      iconTheme: IconThemeData(size: 22, color: fg),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(size: 22, color: fg),
        actionsIconTheme: IconThemeData(size: 22, color: fg),
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.blue.withValues(alpha: dark ? 0.22 : 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(size: 22, color: selected ? fg : muted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? fg : muted,
          );
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: fg,
        textColor: fg,
        subtitleTextStyle: TextStyle(color: muted, fontSize: 12.5),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.blue),
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.blue,
        labelColor: fg,
        unselectedLabelColor: muted,
        dividerColor: fg.withValues(alpha: 0.08),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.green : null,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: fg.withValues(alpha: 0.12)),
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.blue.withValues(alpha: 0.22),
        labelStyle: TextStyle(color: fg, fontSize: 13),
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(color: fg.withValues(alpha: 0.08), space: 1, thickness: 0.6),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get fg => Theme.of(this).colorScheme.primary;
  Color get muted => isDark ? const Color(0xFF9A9AA0) : const Color(0xFF6C6C70);
}
