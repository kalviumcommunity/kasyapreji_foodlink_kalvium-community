import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A calm, living page background: a warm cream-to-sage gradient with large,
/// soft colour glows that drift slowly. Keeps light pages from looking flat
/// while staying quiet behind dark text. Pair with [DotTexturePainter].
class SoftBackdropPainter extends CustomPainter {
  const SoftBackdropPainter({required this.time});

  /// Looping 0–1 value that drives the drift.
  final double time;

  static const _glows = [
    // colour, alpha, centre (fraction of size), radius (fraction of the
    // larger side), drift phase
    (AppColors.glowMint, 0.75, Offset(0.92, 0.10), 0.55, 0.0),
    (AppColors.glowPeach, 0.55, Offset(0.02, 0.42), 0.45, 0.33),
    (AppColors.glowSage, 0.70, Offset(0.75, 0.62), 0.50, 0.66),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          AppColors.backdrop,
        ),
    );

    final longest = math.max(size.width, size.height);
    for (final (color, alpha, anchor, radius, phase) in _glows) {
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
      oldDelegate.time != time;
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
