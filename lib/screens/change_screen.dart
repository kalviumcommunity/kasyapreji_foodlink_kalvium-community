import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/asset_photo.dart';
import '../widgets/leaf.dart';
import '../widgets/onboarding_layout.dart';

/// Last onboarding screen: "Be the Change".
///
/// Artwork: a tall arch holding a photo of a volunteer team, tinted in the
/// design's forest-green-to-steel-blue, with three action badges ("Donate",
/// "Volunteer", "Organize") along its edge. The matching words in the body
/// light up in turn and the badge for the lit word lifts and glows.
class ChangeScreen extends StatefulWidget {
  const ChangeScreen({super.key, this.onNext});

  /// Called when the (white) next button is tapped.
  final VoidCallback? onNext;

  @override
  State<ChangeScreen> createState() => _ChangeScreenState();
}

class _ChangeScreenState extends State<ChangeScreen> {
  /// A volunteer team out working together.
  final _photo = AssetPhoto('assets/images/change_volunteers.jpg');

  static const _actions = ['Donate', 'Volunteer', 'Organize'];

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
      headline: const ['Be the', 'Change'],
      accentFrom: 1,
      compactBody: 'Donate. Volunteer.\nOrganize. Make an impact.',
      wideBody: 'Donate. Volunteer. Organize. Make an impact.',
      highlightWords: _actions,
      compactHeadlineTop: 206,
      compactBodyTop: 350,
      compactButtonCentre: const Offset(349, 823),
      compactButtonLight: true,
      // Last onboarding page: nothing to skip to that next doesn't reach.
      showSkip: false,
      wideArtAspectRatio: 0.86,
      compactArt: _buildCompactArt,
      wideArt: _buildWideArt,
      onNext: widget.onNext,
    );
  }

  Widget _buildCompactArt(BuildContext context, OnboardingArt art) {
    final s = art.s;
    final edgeX = 105 * art.sx;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _CompactArchPainter(art: art, photo: _photo.image),
          ),
        ),
        // Action badges straddling the arch's left edge.
        for (var i = 0; i < _actions.length; i++)
          Positioned(
            left: edgeX - 52 * s,
            top: (585 + i * 88) * art.sy,
            child: _ActionBadge(
              index: i,
              label: _actions[i],
              art: art,
              scale: s,
            ),
          ),
      ],
    );
  }

  Widget _buildWideArt(BuildContext context, OnboardingArt art) {
    final w = art.size.width;
    final s = w / 440;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _WideArchPainter(art: art, photo: _photo.image),
          ),
        ),
        for (var i = 0; i < _actions.length; i++)
          Positioned(
            left: -56 * s,
            top: art.size.height * (0.40 + i * 0.17),
            child: _ActionBadge(
              index: i,
              label: _actions[i],
              art: art,
              scale: s,
            ),
          ),
      ],
    );
  }
}

const _icons = [
  Icons.volunteer_activism_rounded,
  Icons.front_hand_rounded,
  Icons.groups_rounded,
];

/// Frosted pill for one action. It pops in (staggered), bobs gently, and
/// lifts with a stronger glow while its word is lit in the body copy.
class _ActionBadge extends StatelessWidget {
  const _ActionBadge({
    required this.index,
    required this.label,
    required this.art,
    required this.scale,
  });

  final int index;
  final String label;
  final OnboardingArt art;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final appear = (art.accentIn * 1.3 - index * 0.15).clamp(0.0, 1.2);
    final lit = art.highlightOf(index);
    final bob = math.sin((art.time * 2 + index * 0.3) * 2 * math.pi) * 3 * s;

    return Transform.translate(
      offset: Offset(6 * s * lit, bob),
      child: Transform.scale(
        scale: appear * (1 + 0.06 * lit),
        alignment: Alignment.centerLeft,
        child: Opacity(
          opacity: appear.clamp(0.0, 1.0),
          child: Container(
            padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 16 * s, 6 * s),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Color.lerp(
                  AppColors.ink.withValues(alpha: 0.06),
                  AppColors.leafLight.withValues(alpha: 0.6),
                  lit,
                )!,
                width: 1 + lit,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandDark.withValues(
                    alpha: 0.16 + 0.14 * lit,
                  ),
                  blurRadius: (16 + 10 * lit) * s,
                  offset: Offset(0, 6 * s),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30 * s,
                  height: 30 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                          const Color(0xFF3A7550),
                          AppColors.leafLight,
                          lit,
                        )!,
                        AppColors.brand,
                      ],
                    ),
                  ),
                  child: Icon(
                    _icons[index],
                    size: 17 * s,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(width: 9 * s),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the photo [arch]: it rises in, zooms slowly, carries the design's
/// green–blue tint with a band of light sweeping down it, and has a soft
/// highlight along its edge.
void _paintArch(
  Canvas canvas,
  RRect arch, {
  required OnboardingArt art,
  required ui.Image? photo,
  required double unit,
}) {
  final reveal = art.reveal.clamp(0.0, 1.0);
  if (reveal <= 0) return;
  final rect = arch.outerRect;

  canvas.save();
  canvas.translate(0, (1 - Curves.easeOutCubic.transform(reveal)) * 120 * unit);
  canvas.saveLayer(
    rect.inflate(40 * unit),
    Paint()..color = Color.fromRGBO(0, 0, 0, reveal),
  );

  // Soft shadow under the arch.
  canvas.drawRRect(
    arch.shift(Offset(0, 12 * unit)),
    Paint()
      ..color = AppColors.brandDark.withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 26 * unit),
  );

  canvas.save();
  canvas.clipRRect(arch);
  final image = photo;
  if (image != null) {
    paintPhotoCover(
      canvas,
      image,
      rect,
      alignment: const Alignment(-0.1, 0.0),
      zoom: 1.06 + 0.04 * math.sin(art.time * 2 * math.pi),
    );
  }
  // The design's forest green → steel blue → deep green, as a tint (solid
  // until the photo loads).
  final a = image == null ? 1.0 : 0.0;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        [
          AppColors.archTop.withValues(alpha: math.max(a, 0.45)),
          AppColors.archMid.withValues(alpha: math.max(a, 0.22)),
          AppColors.archBottom.withValues(alpha: math.max(a, 0.72)),
        ],
        const [0.0, 0.5, 1.0],
      ),
  );
  // A band of light slowly sweeping down the arch.
  final sweep = (art.time * 2) % 1.0;
  final y = rect.top + (sweep * 1.4 - 0.2) * rect.height;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.left, y - 90 * unit),
        Offset(rect.left, y + 90 * unit),
        [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0),
        ],
        const [0.0, 0.5, 1.0],
      ),
  );
  canvas.restore();

  // Soft highlight along the rounded top edge.
  canvas.drawRRect(
    arch,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * unit
      ..color = Colors.white.withValues(alpha: 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * unit),
  );

  canvas.restore(); // layer
  canvas.restore(); // translate
}

const _leafTall = LeafShape(
  tipA: Offset(392, 189),
  tipB: Offset(367, 268),
  bulgeLeft: 18,
  bulgeRight: 16,
  color: AppColors.leafLight,
  veinColor: AppColors.leafVein,
);
const _leafFlat = LeafShape(
  tipA: Offset(241, 281),
  tipB: Offset(309, 300),
  bulgeLeft: 11,
  bulgeRight: 9,
  color: AppColors.onboardingLeaf,
  veinColor: AppColors.leafVein,
);

/// Phone layout: the arch rises from the lower right and bleeds off the
/// right and bottom edges, as in the Figma; leaves beside the headline.
class _CompactArchPainter extends CustomPainter {
  _CompactArchPainter({required this.art, this.photo});

  final OnboardingArt art;
  final ui.Image? photo;

  @override
  void paint(Canvas canvas, Size size) {
    final s = art.s;
    final radius = Radius.circular(190 * s);
    final arch = RRect.fromRectAndCorners(
      Rect.fromLTRB(
        105 * art.sx,
        463 * art.sy,
        size.width + 90 * s,
        size.height + 40 * s,
      ),
      topLeft: radius,
      topRight: radius,
    );
    _paintArch(canvas, arch, art: art, photo: photo, unit: s);

    for (final (leaf, entry, phase) in const [
      (_leafTall, Offset(40, -40), 0.1),
      (_leafFlat, Offset(-40, -30), 0.5),
    ]) {
      final c = leaf.centre;
      paintSwayingLeaf(
        canvas,
        leaf,
        target: Offset(c.dx * art.sx, c.dy * art.sy),
        scale: s,
        time: art.time,
        appear: art.leafIn,
        phase: phase,
        entry: entry,
      );
    }
  }

  @override
  bool shouldRepaint(_CompactArchPainter oldDelegate) => true;
}

/// Laptop layout: a free-standing arch card with a round top, leaves around
/// its upper corner.
class _WideArchPainter extends CustomPainter {
  _WideArchPainter({required this.art, this.photo});

  final OnboardingArt art;
  final ui.Image? photo;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 440;
    final rect = Offset.zero & size;
    final arch = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(size.width / 2),
      topRight: Radius.circular(size.width / 2),
      bottomLeft: Radius.circular(32 * unit),
      bottomRight: Radius.circular(32 * unit),
    );
    _paintArch(canvas, arch, art: art, photo: photo, unit: unit);

    final k = unit * 1.3;
    for (final (leaf, target, entry, phase) in [
      (
        _leafTall,
        Offset(size.width * 0.92, size.height * 0.06),
        const Offset(40, -40),
        0.1,
      ),
      (
        _leafFlat,
        Offset(size.width * 0.02, size.height * 0.10),
        const Offset(-40, -30),
        0.5,
      ),
    ]) {
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
  bool shouldRepaint(_WideArchPainter oldDelegate) => true;
}
