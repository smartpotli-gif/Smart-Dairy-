import 'package:flutter/material.dart';

class C {
  static const green = Color(0xFF173F35);
  static const gold = Color(0xFFC9A227);
  static const softGold = Color(0xFFE4D39A);
  static const cream = Color(0xFFF8F5ED);
  static const surface = Color(0xFFFFFDF8);
  static const red = Color(0xFFC0392B);
  static const wa = Color(0xFF25D366);
  static const aiA = Color(0xFF6B4FD8);
  static const aiB = Color(0xFFC94F9B);
  static const meetingL = Color(0xFFE8EFF7);
  static const meetingD = Color(0xFF1E2A35);
  static const tripL = Color(0xFFEEF5EA);
  static const tripD = Color(0xFF1D2B1F);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: C.green, brightness: b);
  final bg = dark ? const Color(0xFF121A17) : C.cream;
  final surface = dark ? const Color(0xFF1B2521) : C.surface;
  final border = dark ? const Color(0xFF2C3833) : const Color(0xFFE6E0D3);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0),
    cardTheme: CardTheme(
      color: surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: border)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
    ),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: surface, indicatorColor: dark ? const Color(0xFF5A4D1E) : C.softGold),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: bg),
  );
}

Color headColor(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? const Color(0xFF8FD1B8) : C.green;
