import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../navigation/transitions.dart';
import '../theme/app_colors.dart';
import '../widgets/asset_photo.dart';
import '../widgets/leaf.dart';
import '../widgets/meadow_band.dart';
import '../widgets/onboarding_layout.dart';
import 'impact_screen.dart';

/// First onboarding screen: "Good Food Creates Brighter Futures".
///
/// Artwork: the green meadow band (holding a community meal photo) with a
/// wavy, undulating edge, and a swaying leaf beside the headline. On laptops
/// the meadow becomes a rounded photo card. Next leads to [ImpactScreen].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onSkip});

  /// Called when the skip button (top-right) is tapped.
  final VoidCallback? onSkip;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Community meal photo shown inside the meadow band.
  final _photo = AssetPhoto('assets/images/onboarding_community_meal.jpg');

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
      headline: const ['Good Food', 'Creates', 'Brighter', 'Futures'],
      accentFrom: 2,
      compactBody:
          'Join a growing community\nthat turns excess food into\nopportunity.',
      wideBody:
          'Join a growing community that turns excess food into opportunity.',
      compactHeadlineTop: 182,
      compactBodyTop: 416,
      compactButtonCentre: const Offset(346, 821),
      wideArtAspectRatio:
          MeadowBand.designSize.width / MeadowBand.designSize.height,
      compactArt: (context, art) => CustomPaint(
        painter: _CompactSceneryPainter(art: art, photo: _photo.image),
      ),
      wideArt: (context, art) => CustomPaint(
        painter: _WideSceneryPainter(art: art, photo: _photo.image),
      ),
      autoAdvanceAfter: onboardingAutoAdvance,
      onNext: () =>
          Navigator.of(context)
              .push(softRoute(const ImpactScreen(), slide: true)),
      onSkip: widget.onSkip,
    );
  }
}

/// How long each onboarding page waits (after its entrance) before moving on
/// by itself.
const onboardingAutoAdvance = Duration(seconds: 5);

/// The swaying leaf shown beside the headline.
const _leafShape = LeafShape(
  tipA: Offset(384, 278),
  tipB: Offset(343, 377),
  bulgeLeft: 24,
  bulgeRight: 21,
  color: AppColors.onboardingLeaf,
  veinColor: AppColors.leafVein,
);

/// Keeps the child receiving a meal in view when the photo is cropped.
const _photoFocus = Alignment(0.2, 0.1);

/// Phone layout: full-bleed meadow across the lower screen and the leaf at its
/// Figma position.
class _CompactSceneryPainter extends CustomPainter {
  _CompactSceneryPainter({required this.art, this.photo});

  final OnboardingArt art;
  final ui.Image? photo;

  @override
  void paint(Canvas canvas, Size size) {
    MeadowBand.paint(
      canvas,
      Rect.fromLTWH(
        0,
        530 * art.sy,
        size.width,
        MeadowBand.designSize.height * art.sy,
      ),
      time: art.time,
      reveal: art.reveal,
      photo: photo,
      photoAlignment: _photoFocus,
    );
    final c = _leafShape.centre;
    paintSwayingLeaf(
      canvas,
      _leafShape,
      target: Offset(c.dx * art.sx, c.dy * art.sy),
      scale: art.s,
      time: art.time,
      appear: art.leafIn,
    );
  }

  @override
  bool shouldRepaint(_CompactSceneryPainter oldDelegate) => true;
}

/// Laptop layout: the meadow as a rounded photo card, with a larger leaf
/// floating over its top-right corner.
class _WideSceneryPainter extends CustomPainter {
  _WideSceneryPainter({required this.art, this.photo});

  final OnboardingArt art;
  final ui.Image? photo;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final k = size.width / MeadowBand.designSize.width;
    // Round the card's top corners so it reads as a card, not a cut-out.
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom + 80 * k),
        topLeft: Radius.circular(36 * k),
        topRight: Radius.circular(36 * k),
      ),
    );
    MeadowBand.paint(
      canvas,
      rect,
      time: art.time,
      reveal: art.reveal,
      photo: photo,
      photoAlignment: _photoFocus,
    );
    canvas.restore();
    paintSwayingLeaf(
      canvas,
      _leafShape,
      target: rect.topRight + Offset(-70 * k, 10 * k),
      scale: 1.3 * k,
      time: art.time,
      appear: art.leafIn,
    );
  }

  @override
  bool shouldRepaint(_WideSceneryPainter oldDelegate) => true;
}
