import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A single leaf drawn between two tip points.
///
/// [bulgeLeft] and [bulgeRight] are the widest half-widths of the leaf on each
/// side of the line from [tipA] to [tipB] (left/right as seen walking A → B).
/// [tipB] is treated as the leaf's base (where it grows from).
class LeafShape {
  const LeafShape({
    required this.tipA,
    required this.tipB,
    required this.bulgeLeft,
    required this.bulgeRight,
    required this.color,
    this.veinColor,
  });

  final Offset tipA;
  final Offset tipB;
  final double bulgeLeft;
  final double bulgeRight;
  final Color color;
  final Color? veinColor;

  Offset get centre => (tipA + tipB) / 2;

  Path path(double scale) {
    final a = tipA * scale;
    final b = tipB * scale;
    final dir = b - a;
    final normal = Offset(-dir.dy, dir.dx) / dir.distance;
    // A cubic's peak deflection is 0.75× its control-point offset.
    final left = normal * (bulgeLeft * scale / 0.75);
    final right = normal * (-bulgeRight * scale / 0.75);
    Offset along(double t) => a + dir * t;

    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(
        (along(0.25) + left).dx, (along(0.25) + left).dy,
        (along(0.75) + left).dx, (along(0.75) + left).dy,
        b.dx, b.dy,
      )
      ..cubicTo(
        (along(0.75) + right).dx, (along(0.75) + right).dy,
        (along(0.25) + right).dx, (along(0.25) + right).dy,
        a.dx, a.dy,
      )
      ..close();
  }

  /// Paints the leaf with a soft side-to-side shade, plus a midrib and side
  /// veins when [veinColor] is set.
  void paint(Canvas canvas, double scale, {double opacity = 1}) {
    if (opacity <= 0) return;
    final a = tipA * scale;
    final b = tipB * scale;
    final dir = b - a;
    final unit = dir / dir.distance;
    final normal = Offset(-unit.dy, unit.dx);
    final mid = (a + b) / 2;

    final light = Color.lerp(color, Colors.white, 0.18)!;
    final dark = Color.lerp(color, Colors.black, 0.12)!;
    canvas.drawPath(
      path(scale),
      Paint()
        ..shader = ui.Gradient.linear(
          mid + normal * bulgeLeft * scale,
          mid - normal * bulgeRight * scale,
          [
            light.withValues(alpha: opacity),
            dark.withValues(alpha: opacity),
          ],
        ),
    );

    final vein = veinColor;
    if (vein == null) return;
    final midrib = Paint()
      ..color = vein.withValues(alpha: 0.9 * opacity)
      ..strokeWidth = 1.2 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a + unit * 2 * scale, b, midrib);

    final side = Paint()
      ..color = vein.withValues(alpha: 0.45 * opacity)
      ..strokeWidth = 0.8 * scale
      ..strokeCap = StrokeCap.round;
    for (final t in const [0.3, 0.5, 0.7]) {
      final p = a + dir * t;
      // Side veins angle back toward the base, like a real leaf.
      canvas.drawLine(
        p,
        p + (normal * 0.62 - unit * 0.45) * bulgeLeft * scale,
        side,
      );
      canvas.drawLine(
        p,
        p + (-normal * 0.62 - unit * 0.45) * bulgeRight * scale,
        side,
      );
    }
  }
}
