import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryTeal = Color(0xFF09637E);
  static const Color lightTeal = Color(0xFF1597AF);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFF757575);
  static const Color textBlack = Color(0xFF212121);
  static const Color textFieldBg = Color(0xFFF5F5F5);
  static const Color buttonGray = Color(0xFFE0E0E0);

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      primaryTeal,
      lightTeal,
    ],
  );
}
