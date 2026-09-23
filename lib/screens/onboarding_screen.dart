import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/asset_photo.dart';
import '../widgets/foodlink_logo.dart';
import '../widgets/leaf.dart';
import '../widgets/meadow_band.dart';
import '../widgets/pulse_next_button.dart';
import '../widgets/rise_in.dart';
import '../widgets/skip_button.dart';
import '../widgets/soft_backdrop.dart';

/// First onboarding screen: "Good Food Creates Brighter Futures".
///
/// Two layouts share the same animations:
/// - Phones (narrow screens) follow the Figma frame (422 × 920): positions
///   scale with the screen, sizes with the smaller of the two scale factors so
///   nothing can overlap.
/// - Laptops (wide screens) get a two-column page: copy and the next button on
///   the left, the meadow illustration on the right.
///
/// Entrance: the meadow rises in, the headline appears line by line, the leaf
/// drifts in, then the body copy and the next button. Ambient: the meadow's
/// wavy edge undulates, light and particles drift, the leaf sways and the next
/// button pulses.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onNext, this.onSkip});

  /// Called when the next button is tapped.
  final VoidCallback? onNext;

  /// Called when the skip button (top-right) is tapped.
  final VoidCallback? onSkip;

  /// Landscape screens at least this wide use the laptop layout.
  static const double wideBreakpoint = 600;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const double _designWidth = 422;
  static const double _designHeight = 920;

  static const _headline = ['Good Food', 'Creates', 'Brighter', 'Futures'];
  static const _body =
      'Join a growing community that turns excess food into opportunity.';

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  Animation<double> _step(
    double begin,
    double end, [
    Curve curve = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _intro,
    curve: Interval(begin, end, curve: curve),
  );

  late final _band = _step(0.0, 0.50);
  late final _headlineLines = [
    for (var i = 0; i < _headline.length; i++)
      _step(0.10 + i * 0.08, 0.45 + i * 0.08),
  ];
  late final _leaf = _step(0.35, 0.80);
  late final _bodyIn = _step(0.50, 0.82);
  late final _button = _step(0.62, 1.0, Curves.elasticOut);

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
    _intro.dispose();
    _ambient.dispose();
    _photo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backdrop.first,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final wide =
                size.width >= OnboardingScreen.wideBreakpoint &&
                size.width > size.height;
            return Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _ambient,
                    builder: (context, _) => CustomPaint(
                      painter: SoftBackdropPainter(time: _ambient.value),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(painter: DotTexturePainter()),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_intro, _ambient]),
                    builder: (context, _) =>
                        wide ? _buildWide(size) : _buildCompact(size),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone layout
  // ---------------------------------------------------------------------------

  Widget _buildCompact(Size size) {
    final sx = size.width / _designWidth;
    final sy = size.height / _designHeight;
    final s = math.min(sx, sy);
    const buttonCentre = Offset(346, 821);
    final buttonOuter = 88 * s;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _CompactSceneryPainter(
              sx: sx,
              sy: sy,
              time: _ambient.value,
              bandIn: _band.value,
              leafIn: _leaf.value,
              photo: _photo.image,
            ),
          ),
        ),
        Positioned(
          top: 182 * sy,
          left: 42 * sx,
          right: 90 * sx,
          child: _headlineColumn(
            fontSize: 39.5 * s,
            height: 1.33,
            rise: 22 * s,
          ),
        ),
        Positioned(
          top: 416 * sy,
          left: 42 * sx,
          right: 42 * sx,
          child: RiseIn(
            progress: _bodyIn.value,
            distance: 16 * s,
            child: Text(
              'Join a growing community\nthat turns excess food into\nopportunity.',
              style: _bodyStyle(18 * s, 1.83),
            ),
          ),
        ),
        Positioned(
          left: buttonCentre.dx * sx - buttonOuter / 2,
          top: buttonCentre.dy * sy - buttonOuter / 2,
          child: _nextButton(78 * s),
        ),
        Positioned(
          // Below the status bar / notch.
          top: MediaQuery.paddingOf(context).top + 14 * s,
          right: 20 * sx,
          child: _skipButton(s),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Laptop layout
  // ---------------------------------------------------------------------------

  Widget _buildWide(Size size) {
    final s = math.min(size.width / 1280, size.height / 800).clamp(0.7, 1.4);

    return Stack(
      children: [
        // Brand mark, top-left, like a site header.
        Positioned(
          top: 36 * s,
          left: 72 * s,
          child: RiseIn(
            progress: _band.value,
            distance: 10 * s,
            child: Row(
              children: [
                FoodLinkLogo(width: 36 * s),
                SizedBox(width: 12 * s),
                Text(
                  'FoodLink',
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 24 * s,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3 * s,
                    color: AppColors.brandDark,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Lines up with the brand header on the left.
        Positioned(top: 30 * s, right: 72 * s, child: _skipButton(s)),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1240 * s),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 72 * s),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _headlineColumn(
                          fontSize: 60 * s,
                          height: 1.12,
                          rise: 26 * s,
                        ),
                        SizedBox(height: 28 * s),
                        RiseIn(
                          progress: _bodyIn.value,
                          distance: 16 * s,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 430 * s),
                            child: Text(_body, style: _bodyStyle(20 * s, 1.7)),
                          ),
                        ),
                        SizedBox(height: 44 * s),
                        _nextButton(72 * s),
                      ],
                    ),
                  ),
                  SizedBox(width: 48 * s),
                  Expanded(
                    flex: 6,
                    child: AspectRatio(
                      aspectRatio:
                          MeadowBand.designSize.width /
                          MeadowBand.designSize.height,
                      child: CustomPaint(
                        painter: _WideSceneryPainter(
                          time: _ambient.value,
                          bandIn: _band.value,
                          leafIn: _leaf.value,
                          photo: _photo.image,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------------

  Widget _headlineColumn({
    required double fontSize,
    required double height,
    required double rise,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _headline.length; i++)
          RiseIn(
            progress: _headlineLines[i].value,
            distance: rise,
            child: i < _accentFrom
                ? Text(_headline[i], style: _headlineStyle(fontSize, height))
                : ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        const LinearGradient(colors: AppColors.accentGradient)
                            .createShader(bounds),
                    child: Text(
                      _headline[i],
                      style: _headlineStyle(
                        fontSize,
                        height,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
          ),
      ],
    );
  }

  /// Headline lines from this index on ("Brighter Futures") get the italic
  /// green accent.
  static const _accentFrom = 2;

  TextStyle _headlineStyle(double fontSize, double height) => TextStyle(
    fontFamily: AppFonts.display,
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    letterSpacing: -fontSize * 0.01,
    height: height,
    color: AppColors.ink,
  );

  TextStyle _bodyStyle(double fontSize, double height) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    height: height,
    color: AppColors.bodyText,
  );

  Widget _skipButton(double scale) => RiseIn(
    progress: _bodyIn.value,
    distance: -10 * scale,
    child: SkipButton(scale: scale, onPressed: widget.onSkip),
  );

  Widget _nextButton(double diameter) => PulseNextButton(
    diameter: diameter,
    time: _ambient.value,
    appear: _button.value,
    showHalo: _intro.isCompleted,
    onPressed: widget.onNext,
  );
}

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

/// Paints [_leafShape] centred on [target] at [scale], drifting in from the
/// top-right as [leafIn] goes 0 → 1 and then swaying with [time].
void _paintSwayingLeaf(
  Canvas canvas, {
  required Offset target,
  required double scale,
  required double time,
  required double leafIn,
}) {
  if (leafIn <= 0) return;
  final wave = 2 * math.pi * (time * 2 + 0.2);
  final sway = math.sin(wave) * 0.08;
  final bob = Offset(math.cos(wave) * 2, math.sin(wave) * 5);
  final entry = const Offset(60, -50) * (1 - leafIn);
  final spinIn = (1 - leafIn) * 0.8;

  final c = _leafShape.centre;
  final at = target + (bob + entry) * scale;
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(sway + spinIn);
  canvas.translate(-c.dx * scale, -c.dy * scale);
  _leafShape.paint(canvas, scale, opacity: leafIn);
  canvas.restore();
}

/// Phone layout: full-bleed meadow across the lower screen and the leaf at its
/// Figma position.
class _CompactSceneryPainter extends CustomPainter {
  _CompactSceneryPainter({
    required this.sx,
    required this.sy,
    required this.time,
    required this.bandIn,
    required this.leafIn,
    this.photo,
  });

  final double sx;
  final double sy;
  final double time;
  final double bandIn;
  final double leafIn;
  final ui.Image? photo;

  @override
  void paint(Canvas canvas, Size size) {
    MeadowBand.paint(
      canvas,
      Rect.fromLTWH(0, 530 * sy, size.width, MeadowBand.designSize.height * sy),
      time: time,
      reveal: bandIn,
      photo: photo,
      photoAlignment: _photoFocus,
    );
    final c = _leafShape.centre;
    _paintSwayingLeaf(
      canvas,
      target: Offset(c.dx * sx, c.dy * sy),
      scale: math.min(sx, sy),
      time: time,
      leafIn: leafIn,
    );
  }

  @override
  bool shouldRepaint(_CompactSceneryPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.bandIn != bandIn ||
      oldDelegate.leafIn != leafIn ||
      oldDelegate.photo != photo ||
      oldDelegate.sx != sx ||
      oldDelegate.sy != sy;
}

/// Laptop layout: the meadow as an illustration panel, with a larger leaf
/// floating over its top-right corner.
class _WideSceneryPainter extends CustomPainter {
  _WideSceneryPainter({
    required this.time,
    required this.bandIn,
    required this.leafIn,
    this.photo,
  });

  final double time;
  final double bandIn;
  final double leafIn;
  final ui.Image? photo;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final k = size.width / MeadowBand.designSize.width;
    // Round the panel's top corners so it reads as a card, not a cut-out.
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
      time: time,
      reveal: bandIn,
      photo: photo,
      photoAlignment: _photoFocus,
    );
    canvas.restore();
    _paintSwayingLeaf(
      canvas,
      target: rect.topRight + Offset(-70 * k, 10 * k),
      scale: 1.3 * k,
      time: time,
      leafIn: leafIn,
    );
  }

  @override
  bool shouldRepaint(_WideSceneryPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.bandIn != bandIn ||
      oldDelegate.leafIn != leafIn ||
      oldDelegate.photo != photo;
}
