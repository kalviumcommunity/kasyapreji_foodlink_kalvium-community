import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'asset_photo.dart';
import 'light_particles.dart';

/// The green "meadow" band from the onboarding design: a soft gradient (or a
/// green-tinted photo) that fades in from the page at the top, with a wavy
/// lower edge, drifting pools of light and rising particles.
///
/// Its shape is defined in a 422 × 310 design box and stretched to any [Rect],
/// so the same band works full-bleed on phones and as a panel on laptops.
class MeadowBand {
  MeadowBand._();

  static const Size designSize = Size(422, 310);

  /// How strongly the band's gradient tints a photo, per gradient stop. The
  /// photo's own top fade blends it into the page, so the tint starts clear.
  static const _photoTint = [0.0, 0.45, 0.28, 0.18, 0.22, 0.38, 0.55];

  static final _particles = LightParticles(
    top: 40,
    bottom: designSize.height,
    count: 16,
    seed: 11,
  );

  /// The band's outline inside [rect]; its lower edge undulates with [time].
  static Path path(Rect rect, double time) {
    final w = math.sin(time * 2 * math.pi);
    final w2 = math.cos(time * 2 * math.pi);
    final sx = rect.width / designSize.width;
    final sy = rect.height / designSize.height;
    // Design points are relative to the band's top-left corner.
    Offset p(double x, double y) => rect.topLeft + Offset(x * sx, y * sy);

    final a = p(422, 192 + 4 * w);
    final b1 = p(345, 190 + 6 * w2);
    final b2 = p(292, 228 - 6 * w);
    final b = p(236, 270 + 3 * w2);
    final c1 = p(196, 300 + 4 * w);
    final c2 = p(165, 308);
    final c = p(128, 306 - 3 * w);
    final d1 = p(62, 302 + 4 * w2);
    final d2 = p(0, 262);
    final d = p(0, 200 + 5 * w);
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(a.dx, a.dy)
      ..cubicTo(b1.dx, b1.dy, b2.dx, b2.dy, b.dx, b.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, c.dx, c.dy)
      ..cubicTo(d1.dx, d1.dy, d2.dx, d2.dy, d.dx, d.dy)
      ..close();
  }

  /// Paints the band into [rect]. [time] loops 0–1; [reveal] (0–1) fades the
  /// band in while it rises into place. With a [photo], the photo fills the
  /// band under a green tint that still fades into the page at the top.
  static void paint(
    Canvas canvas,
    Rect rect, {
    required double time,
    double reveal = 1,
    ui.Image? photo,
    Alignment photoAlignment = Alignment.center,
  }) {
    if (reveal <= 0) return;
    final sx = rect.width / designSize.width;
    final sy = rect.height / designSize.height;
    final s = math.min(sx, sy);
    final outline = path(rect, time);

    canvas.save();
    canvas.translate(0, (1 - reveal) * 70 * s);
    canvas.saveLayer(
      rect.inflate(20 * s),
      Paint()..color = Colors.black.withValues(alpha: reveal.clamp(0.0, 1.0)),
    );
    canvas.clipPath(outline);

    if (photo == null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            rect.topCenter,
            rect.bottomCenter,
            AppColors.onboardingBand,
            AppColors.onboardingBandStops,
          ),
      );
    } else {
      // A slow zoom keeps the photo alive.
      paintPhotoCover(
        canvas,
        photo,
        rect,
        alignment: photoAlignment,
        zoom: 1.06 + 0.04 * math.sin(time * 2 * math.pi),
        fadeTop: 0.3,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
            for (final (i, c) in AppColors.onboardingBand.indexed)
              c.withValues(alpha: _photoTint[i]),
          ], AppColors.onboardingBandStops),
      );
    }

    // Two soft pools of light drifting slowly across the meadow.
    for (var i = 0; i < 2; i++) {
      final t = (time * (i + 1) + i * 0.5) % 1.0;
      final centre =
          rect.topLeft +
          Offset((-120 + t * 662) * sx, (i == 0 ? 170 : 110) * sy);
      final radius = (i == 0 ? 150 : 110) * s;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(centre, radius, [
            Colors.white.withValues(alpha: i == 0 ? 0.16 : 0.10),
            Colors.white.withValues(alpha: 0),
          ]),
      );
    }

    canvas.save();
    canvas.translate(rect.left, rect.top);
    _particles.paint(canvas, sx: sx, sy: sy, time: time, opacity: reveal);
    canvas.restore();

    // A soft highlight along the wavy edge gives the band some depth.
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * s
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * s),
    );

    canvas.restore(); // layer
    canvas.restore(); // translate
  }
}
