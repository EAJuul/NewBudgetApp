import 'package:flutter/material.dart';

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2E7D32),
      brightness: Brightness.light,
    );

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2E7D32),
      brightness: Brightness.dark,
    );
