import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Colours for a [SoftBackdropPainter]: a two-stop base gradient and three
/// drifting glows.
class SoftBackdropPalette {
  const SoftBackdropPalette({required this.base, required this.glows});

  final List<Color> base;

  /// colour, alpha, centre (fraction of size), radius (fraction of the larger
  /// side), drift phase.
  final List<(Color, double, Offset, double, double)> glows;

  /// Cream to sage with mint and peach glows (first onboarding page).
  static const sage = SoftBackdropPalette(
    base: AppColors.backdrop,
    glows: [
      (AppColors.glowMint, 0.75, Offset(0.92, 0.10), 0.55, 0.0),
      (AppColors.glowPeach, 0.55, Offset(0.02, 0.42), 0.45, 0.33),
      (AppColors.glowSage, 0.70, Offset(0.75, 0.62), 0.50, 0.66),
    ],
  );

  /// Warmer linen tones with peach, sand and sage glows, to sit with earthy
  /// photography.
  static const warm = SoftBackdropPalette(
    base: AppColors.backdropWarm,
    glows: [
      (AppColors.glowPeach, 0.70, Offset(0.95, 0.08), 0.55, 0.0),
      (AppColors.glowSage, 0.65, Offset(0.00, 0.30), 0.45, 0.33),
      (AppColors.glowSand, 0.60, Offset(0.80, 0.80), 0.55, 0.66),
    ],
  );
}

/// A calm, living page background: a soft base gradient with large colour
/// glows that drift slowly. Keeps light pages from looking flat while staying
/// quiet behind dark text. Pair with [DotTexturePainter].
class SoftBackdropPainter extends CustomPainter {
  const SoftBackdropPainter({
    required this.time,
    this.palette = SoftBackdropPalette.sage,
  });

  /// Looping 0–1 value that drives the drift.
  final double time;
  final SoftBackdropPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          palette.base,
        ),
    );

    final longest = math.max(size.width, size.height);
    for (final (color, alpha, anchor, radius, phase) in palette.glows) {
      final a = 2 * math.pi * (time + phase);
      final centre = Offset(
        (anchor.dx + 0.04 * math.sin(a)) * size.width,
        (anchor.dy + 0.03 * math.cos(a)) * size.height,
      );
      final r = radius * longest;
      canvas.drawCircle(
        centre,
        r,
        Paint()
          ..shader = ui.Gradient.radial(centre, r, [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0),
          ]),
      );
    }
  }

  @override
  bool shouldRepaint(SoftBackdropPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.palette != palette;
}

/// A faint dot grid for a hint of paper-like texture. It never changes, so
/// wrap it in a [RepaintBoundary] to keep it out of per-frame repaints.
class DotTexturePainter extends CustomPainter {
  const DotTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = AppColors.brand.withValues(alpha: 0.045);
    final step = math.max(18.0, math.max(size.width, size.height) / 60);
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 0.9, dot);
      }
    }
  }

  @override
  bool shouldRepaint(DotTexturePainter oldDelegate) => false;
}
