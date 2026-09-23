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

  // Splash: deep green base shown under (and before) the full-screen photo.
  static const List<Color> splashGradient = [
    Color(0xFF2C4634),
    Color(0xFF1F3326),
    Color(0xFF152219),
  ];
  static const List<double> splashGradientStops = [0.0, 0.55, 1.0];

  /// Film laid over the splash photo so light text stays readable.
  static const Color splashScrim = Color(0xFF0E1F15);
  static const Color logoOnDark = Color(0xFFCDEBC0);
  static const Color taglineOnDark = Color(0xFFD6EDCC);

  // Onboarding
  static const Color background = Color(0xFFF2F3EE);
  static const Color surface = Color(0xFFFBFAF6);

  /// Soft page backdrop: warm cream to pale sage, with drifting colour glows.
  static const List<Color> backdrop = [Color(0xFFF8F5EC), Color(0xFFEDF2E6)];
  static const Color glowMint = Color(0xFFCDE6C0);
  static const Color glowPeach = Color(0xFFF6DFC2);
  static const Color glowSage = Color(0xFFD9E9CF);
  static const List<Color> backdropWarm = [
    Color(0xFFF6F2EB),
    Color(0xFFECE5DB),
  ];
  static const Color glowSand = Color(0xFFEBDAC4);

  // Impact page: warm earth tones around the photo circle.
  static const Color earthLight = Color(0xFFC9A27A);
  static const Color earthDark = Color(0xFF5A3E2A);

  /// Deep forest green for headlines; body copy is a muted green-grey.
  static const Color ink = Color(0xFF163826);
  static const Color bodyText = Color(0xFF5B675F);
  static const List<Color> accentGradient = [
    Color(0xFF2D6A45),
    Color(0xFF6A9A51),
  ];
  static const Color onboardingLeaf = Color(0xFF7BA35B);
  static const List<Color> onboardingBand = [
    Color(0xFFE6E9E2),
    Color(0xFFB5C1AB),
    Color(0xFF5E7F48),
    Color(0xFF4F7539),
    Color(0xFF7EA05F),
    Color(0xFF9DBB80),
    Color(0xFFB2CB99),
  ];
  static const List<double> onboardingBandStops = [
    0.0,
    0.11,
    0.29,
    0.39,
    0.55,
    0.81,
    1.0,
  ];

  // Splash effects
  static const Color glow = Color(0xFFDCEBD5);
  static const Color particle = Color(0xFFF4F9E8);

  static const Color white = Color(0xFFFFFFFF);
}
