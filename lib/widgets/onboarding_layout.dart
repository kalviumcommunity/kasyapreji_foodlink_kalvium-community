import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'foodlink_logo.dart';
import 'pulse_next_button.dart';
import 'rise_in.dart';
import 'skip_button.dart';
import 'soft_backdrop.dart';

/// Animation and layout values handed to an onboarding screen's artwork.
class OnboardingArt {
  const OnboardingArt({
    required this.size,
    required this.sx,
    required this.sy,
    required this.time,
    required this.reveal,
    required this.leafIn,
    required this.accentIn,
  });

  /// Size of the area the artwork fills.
  final Size size;

  /// Design-frame scale factors (phone layout); both 1 for the laptop panel.
  final double sx;
  final double sy;
  double get s => math.min(sx, sy);

  /// Looping 0–1 ambient clock.
  final double time;

  /// Entrance progress (0–1) of the main artwork, its leaves, and any late
  /// accents (such as badges), in that order.
  final double reveal;
  final double leafIn;
  final double accentIn;
}

typedef OnboardingArtBuilder = Widget Function(
  BuildContext context,
  OnboardingArt art,
);

/// Shared frame for onboarding screens, so every page looks and moves alike.
///
/// - Phones follow the Figma frame (422 × 920): positions scale with the
///   screen, sizes with the smaller scale factor so nothing overlaps.
/// - Laptops (landscape, [wideBreakpoint]+ wide) get a two-column page with a
///   brand header: copy and the next button left, artwork right.
///
/// Both share a soft animated backdrop, a Skip button top-right, a headline
/// that rises in line by line (lines from [accentFrom] on are italic green),
/// body copy, and a pulsing next button.
class OnboardingLayout extends StatefulWidget {
  const OnboardingLayout({
    super.key,
    required this.headline,
    required this.accentFrom,
    required this.compactBody,
    required this.wideBody,
    required this.compactHeadlineTop,
    required this.compactBodyTop,
    required this.compactButtonCentre,
    required this.compactArt,
    required this.wideArt,
    this.wideArtAspectRatio = 1,
    this.backdrop = SoftBackdropPalette.sage,
    this.onNext,
    this.onSkip,
  });

  final List<String> headline;
  final int accentFrom;

  /// Body copy with hand-placed line breaks for phones, and as one paragraph
  /// for laptops.
  final String compactBody;
  final String wideBody;

  /// Phone layout positions in design-frame units.
  final double compactHeadlineTop;
  final double compactBodyTop;
  final Offset compactButtonCentre;

  /// Artwork behind the phone layout (fills the screen) and inside the
  /// laptop layout's right column.
  final OnboardingArtBuilder compactArt;
  final OnboardingArtBuilder wideArt;
  final double wideArtAspectRatio;

  final SoftBackdropPalette backdrop;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;

  /// Landscape screens at least this wide use the laptop layout.
  static const double wideBreakpoint = 600;

  static const double designWidth = 422;
  static const double designHeight = 920;

  @override
  State<OnboardingLayout> createState() => _OnboardingLayoutState();
}

class _OnboardingLayoutState extends State<OnboardingLayout>
    with TickerProviderStateMixin {
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

  late final _art = _step(0.0, 0.50);
  late final _headlineLines = [
    for (var i = 0; i < widget.headline.length; i++)
      _step(0.10 + i * 0.08, 0.45 + i * 0.08),
  ];
  late final _leaf = _step(0.35, 0.80);
  late final _bodyIn = _step(0.50, 0.82);
  late final _accent = _step(0.55, 0.95, Curves.elasticOut);
  late final _button = _step(0.62, 1.0, Curves.elasticOut);

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  OnboardingArt _artValues(Size size, double sx, double sy) => OnboardingArt(
    size: size,
    sx: sx,
    sy: sy,
    time: _ambient.value,
    reveal: _art.value,
    leafIn: _leaf.value,
    accentIn: _accent.value,
  );

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
        backgroundColor: widget.backdrop.base.first,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final wide =
                size.width >= OnboardingLayout.wideBreakpoint &&
                size.width > size.height;
            return Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _ambient,
                    builder: (context, _) => CustomPaint(
                      painter: SoftBackdropPainter(
                        time: _ambient.value,
                        palette: widget.backdrop,
                      ),
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
    final sx = size.width / OnboardingLayout.designWidth;
    final sy = size.height / OnboardingLayout.designHeight;
    final s = math.min(sx, sy);
    final button = widget.compactButtonCentre;
    final buttonOuter = 88 * s;

    return Stack(
      children: [
        Positioned.fill(
          child: widget.compactArt(context, _artValues(size, sx, sy)),
        ),
        Positioned(
          top: widget.compactHeadlineTop * sy,
          left: 42 * sx,
          right: 90 * sx,
          child: _headlineColumn(
            fontSize: 39.5 * s,
            height: 1.33,
            rise: 22 * s,
          ),
        ),
        Positioned(
          top: widget.compactBodyTop * sy,
          left: 42 * sx,
          right: 42 * sx,
          child: RiseIn(
            progress: _bodyIn.value,
            distance: 16 * s,
            child: Text(widget.compactBody, style: _bodyStyle(18 * s, 1.83)),
          ),
        ),
        Positioned(
          left: button.dx * sx - buttonOuter / 2,
          top: button.dy * sy - buttonOuter / 2,
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
            progress: _art.value,
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
                            child: Text(
                              widget.wideBody,
                              style: _bodyStyle(20 * s, 1.7),
                            ),
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
                      aspectRatio: widget.wideArtAspectRatio,
                      child: LayoutBuilder(
                        builder: (context, box) => widget.wideArt(
                          context,
                          _artValues(box.biggest, 1, 1),
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
        for (var i = 0; i < widget.headline.length; i++)
          RiseIn(
            progress: _headlineLines[i].value,
            distance: rise,
            child: i < widget.accentFrom
                ? Text(
                    widget.headline[i],
                    style: _headlineStyle(fontSize, height),
                  )
                : ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        const LinearGradient(colors: AppColors.accentGradient)
                            .createShader(bounds),
                    child: Text(
                      widget.headline[i],
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
