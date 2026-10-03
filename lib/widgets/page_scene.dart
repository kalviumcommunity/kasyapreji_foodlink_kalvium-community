import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';
import 'asset_photo.dart';
import 'leaf.dart';
import 'light_particles.dart';
import 'onboarding_layout.dart';

const _leaf = LeafShape(
  tipA: Offset(52, 6),
  tipB: Offset(14, 70),
  bulgeLeft: 14,
  bulgeRight: 12,
  color: AppColors.onboardingLeaf,
  veinColor: AppColors.leafVein,
);

/// A photo washed into the top of a page (right of the side rail on
/// laptops), with green specks drifting up and a leaf swaying in the corner.
///
/// [reveal] fades the photo in and [appear] brings in the specks and leaf
/// (both 0–1); [time] is the looping ambient clock.
class PageScenePainter extends CustomPainter {
  PageScenePainter({
    required this.photo,
    required this.time,
    required this.reveal,
    required this.appear,
    required this.left,
    required this.scale,
    this.height = 330,
    this.focus = const Alignment(0, -0.2),
  });

  final ui.Image? photo;
  final double time;
  final double reveal;
  final double appear;

  /// Where the photo starts from the left (the side rail's width).
  final double left;
  final double scale;

  /// How far down the page the photo reaches, in design units.
  final double height;

  /// Which part of the photo to keep when it is cropped.
  final Alignment focus;

  static final _specks = LightParticles(
    top: 60,
    bottom: 900,
    count: 14,
    seed: 31,
    color: AppColors.leafLight,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale;
    final image = photo;
    if (image != null && reveal > 0) {
      final rect = Rect.fromLTRB(left, 0, size.width, height * s);
      canvas.saveLayer(rect, Paint());
      // Pale, so dark headings stay easy to read on top.
      paintPhotoCover(
        canvas,
        image,
        rect,
        alignment: focus,
        zoom: 1.05 + 0.04 * math.sin(time * 2 * math.pi),
        opacity: 0.32 * reveal,
      );
      canvas.drawRect(
        rect.inflate(2),
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.linear(
            Offset(rect.center.dx, rect.top + rect.height * 0.2),
            rect.bottomCenter,
            const [Color(0xFF000000), Color(0x00000000)],
          ),
      );
      canvas.restore();
    }

    _specks.paint(
      canvas,
      sx: size.width / OnboardingLayout.designWidth,
      sy: size.height / OnboardingLayout.designHeight,
      time: time,
      opacity: 0.5 * appear,
    );

    paintSwayingLeaf(
      canvas,
      _leaf,
      target: Offset(size.width - 34 * s, 124 * s),
      scale: s * 0.75,
      time: time,
      appear: appear,
    );
  }

  @override
  bool shouldRepaint(PageScenePainter oldDelegate) => true;
}
