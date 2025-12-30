import 'package:flutter/material.dart';

ThemeData get getDarkTheme => ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xffff4f00),
    onPrimary: Colors.white,
    secondary: Colors.deepPurple,
    onSecondary: Colors.white,
    tertiary: Colors.deepPurple,
    onTertiary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: Colors.black,
  ),
  useMaterial3: false,
);
