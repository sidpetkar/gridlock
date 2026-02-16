import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const Color bg = Colors.white;
    const Color text = Color(0xFF111111);

    final TextTheme serif = ThemeData().textTheme.apply(
      fontFamily: 'SourceSerif4',
      bodyColor: text,
      displayColor: text,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        surface: bg,
        primary: text,
        onPrimary: Colors.white,
        onSurface: text,
      ),
      textTheme: serif,
      dividerColor: const Color(0xFFE5E7EB),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Color(0xFF111111), width: 1.2),
        ),
      ),
      chipTheme: const ChipThemeData(
        selectedColor: Color(0xFF111111),
        backgroundColor: Colors.white,
        secondarySelectedColor: Color(0xFF111111),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(color: Color(0xFF111111)),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        side: BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }
}
