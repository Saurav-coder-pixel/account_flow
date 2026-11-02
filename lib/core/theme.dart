import 'package:flutter/material.dart';

const _seedColor = Color(0xFF4F6AF5); // indigo-blue seed

ThemeData lightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seedColor,
    brightness: Brightness.light,
  );
}

ThemeData darkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: _seedColor,
    brightness: Brightness.dark,
  );
}
