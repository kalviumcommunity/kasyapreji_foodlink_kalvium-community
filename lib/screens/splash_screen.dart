import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/asset_photo.dart';
import '../widgets/foodlink_logo.dart';
import '../widgets/leaf.dart';
import '../widgets/light_particles.dart';
import '../widgets/rise_in.dart';
import 'onboarding_screen.dart';

/// Splash / app bootstrap screen.
///
/// Layout values come from the Figma frame (422 × 920) and are scaled to the
/// device: horizontal values and sizes by width, vertical positions by height.
///
/// Plays a one-off entrance (logo leaves grow in, text rises, leaves drift in),
/// then loops ambient motion (leaves sway, light particles rise, loader pulses).
/// Moves on to onboarding [holdAfterIntro] after the entrance finishes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.holdAfterIntro = const Duration(milliseconds: 1400),
  });

  final Duration holdAfterIntro;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const double _designWidth = 422;
  static const double _designHeight = 920;

  late final AnimationController _intro =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2600),
        )
        ..addStatusListener(_onIntroStatus)
        ..forward();

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

  late final _glow = _step(0.0, 0.40);
  late final _logoLeaves = [
    _step(0.05, 0.42, Curves.elasticOut),
    _step(0.15, 0.52, Curves.elasticOut),
    _step(0.22, 0.59, Curves.elasticOut),
  ];
  late final _title = _step(0.34, 0.60);
  late final _tagline = _step(0.46, 0.72);
  late final _floatingLeaves = _step(0.30, 0.78);
  late final _bottom = _step(0.60, 0.86);
  late final _loader = _step(0.80, 1.0);
  late final _photoIn = _step(0.20, 0.75);

  /// Volunteer handing fresh food to an elder, shown in the lower half.
  final _photo = AssetPhoto('assets/images/splash_giving.jpg');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photo.resolve(context, () {
      if (mounted) setState(() {});
    });
  }

  Timer? _leaveTimer;

  void _onIntroStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _leaveTimer = Timer(widget.holdAfterIntro, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, _, _) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: 1.04, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _leaveTimer?.cancel();
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
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final sx = constraints.maxWidth / _designWidth;
            final sy = constraints.maxHeight / _designHeight;
            // Sizes use the smaller scale so text never overlaps on wide or
            // short screens; positions still follow each axis.
            final s = math.min(sx, sy);

            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppColors.splashGradient,
                  stops: AppColors.splashGradientStops,
                ),
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([_intro, _ambient]),
                builder: (context, _) => Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AmbientPainter(
                          sx: sx,
                          sy: sy,
                          time: _ambient.value,
                          leavesIn: _floatingLeaves.value,
                          particlesIn: _bottom.value,
                          photo: _photo.image,
                          photoIn: _photoIn.value,
                        ),
                      ),
                    ),
                    _buildGlow(s, sy, constraints.maxWidth),
                    _buildLogo(s, sy),
                    _buildTitle(s, sy),
                    _buildBottomMessage(s, sy),
                    _buildLoader(s, sy),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlow(double s, double sy, double width) {
    final size = 300 * s;
    final pulse = 1 + 0.05 * math.sin(_ambient.value * 2 * math.pi * 2);
    return Positioned(
      top: 268 * sy - size / 2,
      left: (width - size) / 2,
      child: Opacity(
        opacity: _glow.value,
        child: Transform.scale(
          scale: pulse,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.logoOnDark.withValues(alpha: 0.30),
                  AppColors.logoOnDark.withValues(alpha: 0.10),
                  AppColors.logoOnDark.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(double s, double sy) {
    // Gentle breathing, eased in as the entrance finishes.
    final breathe =
        1 + 0.02 * _loader.value * math.sin(_ambient.value * 2 * math.pi * 2);
    return Positioned(
      top: 225 * sy,
      left: 0,
      right: 0,
      child: Center(
        child: Transform.scale(
          scale: breathe,
          alignment: Alignment.bottomCenter,
          child: FoodLinkLogo(
            width: 130 * s,
            color: AppColors.logoOnDark,
            growth: [for (final leaf in _logoLeaves) leaf.value],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(double s, double sy) {
    return Positioned(
      top: 336 * sy,
      left: 16,
      right: 16,
      child: Column(
        children: [
          RiseIn(
            progress: _title.value,
            distance: 20 * sy,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  AppColors.white,
                  AppColors.logoOnDark,
                  AppColors.white,
                ],
                stops: [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: Text(
                'FoodLink',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.display,
                  fontSize: 42 * s,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4 * s,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      offset: Offset(0, 3 * s),
                      blurRadius: 14 * s,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16 * sy),
          RiseIn(
            progress: _tagline.value,
            distance: 14 * sy,
            child: Text(
              'Good Food\nBrighter Futures',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19 * s,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2 * s,
                color: AppColors.taglineOnDark,
                height: 1.68,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    offset: Offset(0, 2 * s),
                    blurRadius: 10 * s,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMessage(double s, double sy) {
    return Positioned(
      top: 780 * sy,
      left: 16,
      right: 16,
      child: RiseIn(
        progress: _bottom.value,
        distance: 16 * sy,
        child: Text(
          'A Hunger-Free Tomorrow\nStarts With You',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19 * s,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
            height: 1.72,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: Offset(0, 2 * s),
                blurRadius: 8 * s,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Three dots that pulse in turn while the app loads.
  Widget _buildLoader(double s, double sy) {
    final beat = _ambient.value * 8; // one pulse per second
    return Positioned(
      top: 870 * sy,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: _loader.value,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(
                builder: (context) {
                  final t = (beat - i * 0.18) % 1.0;
                  final pulse = math.max(0.0, math.sin(t * math.pi));
                  final d = (6 + 3 * pulse) * s;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4 * s),
                    width: d,
                    height: d,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withValues(
                        alpha: 0.35 + 0.65 * pulse,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Paints the floating leaves (drifting in, then swaying) and the light
/// particles rising through the lower half of the screen.
class _AmbientPainter extends CustomPainter {
  _AmbientPainter({
    required this.sx,
    required this.sy,
    required this.time,
    required this.leavesIn,
    required this.particlesIn,
    this.photo,
    this.photoIn = 1,
  });

  final double sx;
  final double sy;
  final double time;
  final double leavesIn;
  final double particlesIn;
  final ui.Image? photo;
  final double photoIn;

  /// Film over the full-screen photo, by height: darker behind the logo and
  /// title, lighter where the hands and apples are, and darkest at the bottom
  /// for the closing message.
  static const _scrimAlpha = [0.72, 0.58, 0.50, 0.28, 0.30, 0.62, 0.90];
  static const _scrimStops = [0.0, 0.22, 0.45, 0.60, 0.72, 0.85, 1.0];

  static const _leaves = [
    // Upper-left leaf
    LeafShape(
      tipA: Offset(49, 446),
      tipB: Offset(76, 545),
      bulgeLeft: 24,
      bulgeRight: 21,
      color: AppColors.leafDark,
      veinColor: AppColors.leafVein,
    ),
    // Lower-left leaf, partly off-screen
    LeafShape(
      tipA: Offset(-2, 621),
      tipB: Offset(76, 573),
      bulgeLeft: 20,
      bulgeRight: 15,
      color: AppColors.leafMid,
      veinColor: AppColors.leafVein,
    ),
    // Centre-right leaf
    LeafShape(
      tipA: Offset(176, 627),
      tipB: Offset(245, 532),
      bulgeLeft: 29,
      bulgeRight: 24,
      color: AppColors.leafLight,
      veinColor: AppColors.leafVein,
    ),
  ];

  // Where each leaf drifts in from, and its sway phase.
  static const _entryOffsets = [
    Offset(-40, -60),
    Offset(-60, 30),
    Offset(50, 60),
  ];
  static const _phases = [0.0, 0.33, 0.66];

  static final _particles = LightParticles(top: 120, bottom: 920);

  @override
  void paint(Canvas canvas, Size size) {
    _paintPhoto(canvas, size);
    _particles.paint(canvas, sx: sx, sy: sy, time: time, opacity: particlesIn);
    _paintLeaves(canvas, size);
  }

  void _paintLeaves(Canvas canvas, Size size) {
    for (var i = 0; i < _leaves.length; i++) {
      final leaf = _leaves[i];
      final wave = 2 * math.pi * (time * 2 + _phases[i]);
      final sway = math.sin(wave) * 0.07;
      final bob = Offset(math.cos(wave) * 3, math.sin(wave) * 6);
      final entry = _entryOffsets[i] * (1 - leavesIn);
      final spinIn = (1 - leavesIn) * 0.6 * (i.isEven ? -1 : 1);

      // Leaf centre in screen space: x follows width, y follows height.
      final c = leaf.centre;
      final s = math.min(sx, sy);
      // On wide screens the leaves hug the left edge (and are mirrored onto
      // the right) instead of stretching across the middle.
      final wide = size.width > size.height;
      final x = wide ? c.dx * s * 1.5 + size.width * 0.05 : c.dx * sx;
      final target = Offset(x, c.dy * sy) + (bob + entry) * s;

      for (final mirrored in [false, if (wide) true]) {
        canvas.save();
        if (mirrored) {
          canvas.translate(size.width, 0);
          canvas.scale(-1, 1);
        }
        canvas.translate(target.dx, target.dy);
        canvas.rotate(sway + spinIn);
        canvas.translate(-c.dx * s, -c.dy * s);
        leaf.paint(canvas, s, opacity: leavesIn);
        canvas.restore();
      }
    }
  }

  void _paintPhoto(Canvas canvas, Size size) {
    final image = photo;
    if (image == null || photoIn <= 0) return;
    final rect = Offset.zero & size;
    final s = math.min(sx, sy);
    // Keep the hands and apples centred whatever the crop.
    paintPhotoCover(
      canvas,
      image,
      rect,
      alignment: const Alignment(-0.05, 0.1),
      zoom: 1.05 + 0.04 * math.sin(time * 2 * math.pi),
      opacity: photoIn,
    );
    final fade = photoIn.clamp(0.0, 1.0);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          for (final a in _scrimAlpha)
            AppColors.splashScrim.withValues(alpha: a * fade),
        ], _scrimStops),
    );
    // Extra shade behind the logo and title.
    final titleCentre = Offset(size.width / 2, 330 * sy);
    final radius = 280 * s;
    canvas.drawCircle(
      titleCentre,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(titleCentre, radius, [
          AppColors.splashScrim.withValues(alpha: 0.58 * fade),
          AppColors.splashScrim.withValues(alpha: 0),
        ]),
    );
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.leavesIn != leavesIn ||
      oldDelegate.particlesIn != particlesIn ||
      oldDelegate.photo != photo ||
      oldDelegate.photoIn != photoIn ||
      oldDelegate.sx != sx ||
      oldDelegate.sy != sy;
}
