import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../navigation/transitions.dart';
import '../theme/app_colors.dart';
import '../widgets/asset_photo.dart';
import '../widgets/leaf.dart';
import '../widgets/onboarding_layout.dart';
import '../widgets/soft_backdrop.dart';
import 'change_screen.dart';
import 'onboarding_screen.dart' show onboardingAutoAdvance;

/// Second onboarding screen: "Real Food. Real Impact."
///
/// Artwork: a large circle holding a photo of volunteers packing food bags,
/// framed by a light ring and a slowly turning dotted orbit, with two badges
/// ("Less waste", "More meals") and swaying leaves around it. Warm backdrop
/// tones echo the photo's earthy colours. Next leads to [ChangeScreen].
class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key, this.onSkip});

  /// Called when the skip button (top-right) is tapped.
  final VoidCallback? onSkip;

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  /// Volunteers packing bags of food for distribution.
  final _photo = AssetPhoto('assets/images/impact_packing.jpg');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photo.resolve(context, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _photo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      headline: const ['Real Food.', 'Real Impact.'],
      accentFrom: 1,
      compactBody:
          'Together we reduce food waste\nand support communities\nin need.',
      wideBody:
          'Together we reduce food waste and support communities in need.',
      compactHeadlineTop: 159,
      compactBodyTop: 296,
      compactButtonCentre: const Offset(348, 823),
      backdrop: SoftBackdropPalette.warm,
      compactArt: _buildCompactArt,
      wideArt: _buildWideArt,
      autoAdvanceAfter: onboardingAutoAdvance,
      onNext: () =>
          Navigator.of(context)
              .push(softRoute(const ChangeScreen(), slide: true)),
      onSkip: widget.onSkip,
    );
  }

  Widget _buildCompactArt(BuildContext context, OnboardingArt art) {
    final diameter = 364 * art.s;
    final centre = Offset(242 * art.sx, 600 * art.sy);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _CompactLeavesPainter(art)),
        ),
        Positioned(
          left: centre.dx - diameter / 2,
          top: centre.dy - diameter / 2,
          child: _ImpactCircle(
            diameter: diameter,
            art: art,
            photo: _photo.image,
            badgeScale: art.s,
          ),
        ),
      ],
    );
  }

  Widget _buildWideArt(BuildContext context, OnboardingArt art) {
    final box = art.size;
    final diameter = box.shortestSide * 0.80;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: CustomPaint(painter: _WideLeavesPainter(art))),
        Center(
          child: _ImpactCircle(
            diameter: diameter,
            art: art,
            photo: _photo.image,
            badgeScale: diameter / 400,
          ),
        ),
      ],
    );
  }
}

/// The photo circle with its ring, orbit and floating badges.
class _ImpactCircle extends StatelessWidget {
  const _ImpactCircle({
    required this.diameter,
    required this.art,
    required this.photo,
    required this.badgeScale,
  });

  final double diameter;
  final OnboardingArt art;
  final ui.Image? photo;
  final double badgeScale;

  @override
  Widget build(BuildContext context) {
    final d = diameter;
    final bob = math.sin(art.time * 2 * math.pi * 2);
    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CirclePainter(art: art, photo: photo),
            ),
          ),
          Positioned(
            left: -0.10 * d,
            top: 0.14 * d + 4 * badgeScale * bob,
            child: _Badge(
              icon: Icons.recycling_rounded,
              label: 'Less waste',
              scale: badgeScale,
              appear: art.accentIn,
            ),
          ),
          Positioned(
            left: 0.60 * d,
            top: 0.80 * d - 4 * badgeScale * bob,
            child: _Badge(
              icon: Icons.restaurant_rounded,
              label: 'More meals',
              scale: badgeScale,
              appear: art.accentIn,
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted pill with a round green icon and a short label.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.scale,
    required this.appear,
  });

  final IconData icon;
  final String label;
  final double scale;
  final double appear;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Opacity(
      opacity: appear.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: appear,
        child: Container(
          padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 14 * s, 6 * s),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: AppColors.earthDark.withValues(alpha: 0.16),
                blurRadius: 18 * s,
                offset: Offset(0, 6 * s),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28 * s,
                height: 28 * s,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3A7550), AppColors.brand],
                  ),
                ),
                child: Icon(icon, size: 16 * s, color: AppColors.white),
              ),
              SizedBox(width: 8 * s),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5 * s,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the circle: soft shadow, light ring, the photo (or a warm gradient
/// until it loads) with a gentle warm tint, and a dotted orbit with a small
/// travelling dot.
class _CirclePainter extends CustomPainter {
  _CirclePainter({required this.art, required this.photo});

  final OnboardingArt art;
  final ui.Image? photo;

  @override
  void paint(Canvas canvas, Size size) {
    final reveal = art.reveal.clamp(0.0, 1.0);
    if (reveal <= 0) return;
    final centre = size.center(Offset.zero);
    final r = size.width / 2;
    final u = size.width / 364; // design circle diameter

    canvas.saveLayer(
      Rect.fromCircle(center: centre, radius: r + 40 * u),
      Paint()..color = Color.fromRGBO(0, 0, 0, reveal),
    );
    // Grow in from slightly smaller.
    final grow = 0.88 + 0.12 * Curves.easeOutBack.transform(reveal);
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(grow);
    canvas.translate(-centre.dx, -centre.dy);

    // Dotted orbit, slowly turning, with a travelling dot.
    final orbitR = r + 20 * u;
    final spin = art.time * 2 * math.pi * 0.5;
    final dash = Paint()
      ..color = AppColors.brand.withValues(alpha: 0.28)
      ..strokeWidth = 1.6 * u
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const dashes = 56;
    for (var i = 0; i < dashes; i++) {
      final a = spin + i * 2 * math.pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: orbitR),
        a,
        math.pi / dashes,
        false,
        dash,
      );
    }
    final dotAngle = art.time * 2 * math.pi - math.pi / 2;
    final dot =
        centre + Offset(math.cos(dotAngle), math.sin(dotAngle)) * orbitR;
    canvas.drawCircle(
      dot,
      9 * u,
      Paint()
        ..color = AppColors.leafLight.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * u),
    );
    canvas.drawCircle(dot, 4.5 * u, Paint()..color = AppColors.brand);

    // Soft warm shadow and the light ring.
    canvas.drawCircle(
      centre + Offset(0, 10 * u),
      r + 7 * u,
      Paint()
        ..color = AppColors.earthDark.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 22 * u),
    );
    canvas.drawCircle(centre, r + 7 * u, Paint()..color = AppColors.surface);

    // Photo (or placeholder) clipped to the circle.
    final photoRect = Rect.fromCircle(center: centre, radius: r);
    canvas.save();
    canvas.clipPath(Path()..addOval(photoRect));
    final image = photo;
    if (image == null) {
      canvas.drawRect(
        photoRect,
        Paint()
          ..shader = ui.Gradient.linear(
            photoRect.topCenter,
            photoRect.bottomCenter,
            const [AppColors.earthLight, AppColors.earthDark],
          ),
      );
    } else {
      paintPhotoCover(
        canvas,
        image,
        photoRect,
        alignment: const Alignment(-0.15, 0.2),
        zoom: 1.08 + 0.05 * math.sin(art.time * 2 * math.pi),
      );
      canvas.drawRect(
        photoRect,
        Paint()
          ..shader = ui.Gradient.linear(
            photoRect.topCenter,
            photoRect.bottomCenter,
            [
              AppColors.earthLight.withValues(alpha: 0.10),
              AppColors.earthDark.withValues(alpha: 0.30),
            ],
          ),
      );
    }
    canvas.restore();

    canvas.restore(); // layer
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) => true;
}

const _leafA = LeafShape(
  tipA: Offset(388, 112),
  tipB: Offset(349, 177),
  bulgeLeft: 17,
  bulgeRight: 15,
  color: AppColors.leafLight,
  veinColor: AppColors.leafVein,
);
const _leafB = LeafShape(
  tipA: Offset(410, 325),
  tipB: Offset(386, 404),
  bulgeLeft: 17,
  bulgeRight: 15,
  color: AppColors.onboardingLeaf,
  veinColor: AppColors.leafVein,
);
const _leafC = LeafShape(
  tipA: Offset(34, 738),
  tipB: Offset(50, 823),
  bulgeLeft: 15,
  bulgeRight: 13,
  color: AppColors.leafLight,
  veinColor: AppColors.leafVein,
);
const _leafD = LeafShape(
  tipA: Offset(56, 831),
  tipB: Offset(-1, 857),
  bulgeLeft: 12,
  bulgeRight: 10,
  color: AppColors.onboardingLeaf,
  veinColor: AppColors.leafVein,
);

/// Phone layout: the four leaves at their Figma positions.
class _CompactLeavesPainter extends CustomPainter {
  _CompactLeavesPainter(this.art);

  final OnboardingArt art;

  static const _leaves = [
    (_leafA, Offset(40, -40), 0.1),
    (_leafB, Offset(60, 0), 0.4),
    (_leafC, Offset(-60, 20), 0.7),
    (_leafD, Offset(-60, 30), 0.9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (leaf, entry, phase) in _leaves) {
      final c = leaf.centre;
      paintSwayingLeaf(
        canvas,
        leaf,
        target: Offset(c.dx * art.sx, c.dy * art.sy),
        scale: art.s,
        time: art.time,
        appear: art.leafIn,
        phase: phase,
        entry: entry,
      );
    }
  }

  @override
  bool shouldRepaint(_CompactLeavesPainter oldDelegate) => true;
}

/// Laptop layout: leaves framing the circle in its square panel.
class _WideLeavesPainter extends CustomPainter {
  _WideLeavesPainter(this.art);

  final OnboardingArt art;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 422 * 1.15;
    final placements = [
      (
        _leafA,
        Offset(size.width * 0.92, size.height * 0.08),
        Offset(40, -40),
        0.1,
      ),
      (
        _leafB,
        Offset(size.width * 1.02, size.height * 0.55),
        Offset(60, 0),
        0.4,
      ),
      (
        _leafC,
        Offset(size.width * 0.04, size.height * 0.80),
        Offset(-60, 20),
        0.7,
      ),
      (
        _leafD,
        Offset(size.width * 0.02, size.height * 0.92),
        Offset(-60, 30),
        0.9,
      ),
    ];
    for (final (leaf, target, entry, phase) in placements) {
      paintSwayingLeaf(
        canvas,
        leaf,
        target: target,
        scale: k,
        time: art.time,
        appear: art.leafIn,
        phase: phase,
        entry: entry,
      );
    }
  }

  @override
  bool shouldRepaint(_WideLeavesPainter oldDelegate) => true;
}
