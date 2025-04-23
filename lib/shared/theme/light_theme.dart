import 'package:flutter/material.dart';

ThemeData get getLightTheme => ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xffff4f00),
    secondary: Color(0xff000000),
    onSecondary: Colors.white,
    tertiary: Colors.deepPurple,
    onTertiary: Colors.white,
    error: Colors.red,
  )
);
