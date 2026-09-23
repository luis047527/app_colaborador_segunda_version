import 'package:flutter/material.dart';

abstract final class LumibellColors {
  static const navy = Color(0xFF102650);
  static const navySoft = Color(0xFF526986);
  static const copper = Color(0xFF8D3517);
  static const copperDark = Color(0xFF672713);
  static const peach = Color(0xFFF4DDCB);
  static const peachSoft = Color(0xFFFFF2E8);
  static const canvas = Color(0xFFFFFCF9);
  static const surface = Colors.white;
  static const border = Color(0xFFECE7E2);
  static const field = Color(0xFFF3F6FA);
  static const success = Color(0xFF149B58);
  static const successSoft = Color(0xFFE6F8ED);
  static const danger = Color(0xFFE84343);
  static const dangerSoft = Color(0xFFFFEBEC);
  static const warning = Color(0xFFF47B20);
  static const warningSoft = Color(0xFFFFF0E4);
  static const info = Color(0xFF2677E8);
  static const infoSoft = Color(0xFFEAF3FF);
  static const violet = Color(0xFF7654D8);
  static const violetSoft = Color(0xFFF0EAFF);
}

abstract final class LumibellSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const screen = 20.0;
}

abstract final class LumibellRadii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
}

ThemeData buildLumibellTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: LumibellColors.copper,
    brightness: Brightness.light,
    primary: LumibellColors.copper,
    onPrimary: Colors.white,
    secondary: LumibellColors.navy,
    onSecondary: Colors.white,
    surface: LumibellColors.surface,
    error: LumibellColors.danger,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  const outline = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(LumibellRadii.md)),
    borderSide: BorderSide(color: LumibellColors.border),
  );

  return base.copyWith(
    scaffoldBackgroundColor: LumibellColors.canvas,
    colorScheme: scheme,
    textTheme: base.textTheme.copyWith(
      headlineLarge: const TextStyle(color: LumibellColors.navy, fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
      headlineMedium: const TextStyle(color: LumibellColors.navy, fontSize: 24, fontWeight: FontWeight.w800, height: 1.15),
      titleLarge: const TextStyle(color: LumibellColors.navy, fontSize: 20, fontWeight: FontWeight.w800),
      titleMedium: const TextStyle(color: LumibellColors.navy, fontSize: 16, fontWeight: FontWeight.w700),
      bodyLarge: const TextStyle(color: LumibellColors.navy, fontSize: 16, height: 1.35),
      bodyMedium: const TextStyle(color: LumibellColors.navySoft, fontSize: 14, height: 1.35),
      labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LumibellColors.canvas,
      foregroundColor: LumibellColors.navy,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: LumibellColors.navy, fontSize: 19, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LumibellRadii.lg),
        side: const BorderSide(color: LumibellColors.border),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: TextStyle(color: Color(0xFF8A9AAF), fontSize: 14),
      labelStyle: TextStyle(color: LumibellColors.navySoft),
      border: outline,
      enabledBorder: outline,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(LumibellRadii.md)),
        borderSide: BorderSide(color: LumibellColors.copper, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(LumibellRadii.md)),
        borderSide: BorderSide(color: LumibellColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(LumibellRadii.md)),
        borderSide: BorderSide(color: LumibellColors.danger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LumibellColors.copper,
        foregroundColor: Colors.white,
        disabledBackgroundColor: LumibellColors.peach,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumibellRadii.md)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LumibellColors.copper,
        side: const BorderSide(color: LumibellColors.copper),
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumibellRadii.md)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: LumibellColors.peachSoft,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        color: states.contains(WidgetState.selected) ? LumibellColors.copper : LumibellColors.navy,
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
      )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
        color: states.contains(WidgetState.selected) ? LumibellColors.copper : LumibellColors.navy,
        size: 25,
      )),
    ),
    dividerTheme: const DividerThemeData(color: LumibellColors.border, thickness: 1),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: LumibellColors.navy,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}

