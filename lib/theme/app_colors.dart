import 'package:flutter/material.dart';

/// Brand colors taken from the FoodLink Figma designs.
class AppColors {
  AppColors._();

  // Greens
  static const Color brandDark = Color(0xFF1E4430);
  static const Color brand = Color(0xFF2D5E3E);
  static const Color brandText = Color(0xFF32684A);
  static const Color leafDark = Color(0xFF4E7B39);
  static const Color leafMid = Color(0xFF5A8944);
  static const Color leafLight = Color(0xFF6A9A51);
  static const Color leafVein = Color(0xFF3B6630);

  // Splash background gradient (top to bottom)
  static const List<Color> splashGradient = [
    Color(0xFFE5EBEE),
    Color(0xFFF1F3EF),
    Color(0xFFE8ECE3),
    Color(0xFFB9C7A9),
    Color(0xFF8DA17C),
    Color(0xFF4E6346),
    Color(0xFF2A3D2D),
    Color(0xFF1D2B20),
  ];
  static const List<double> splashGradientStops = [
    0.0, 0.34, 0.50, 0.61, 0.68, 0.77, 0.88, 1.0,
  ];

  // Splash effects
  static const Color glow = Color(0xFFDCEBD5);
  static const Color particle = Color(0xFFF4F9E8);

  static const Color white = Color(0xFFFFFFFF);
}
