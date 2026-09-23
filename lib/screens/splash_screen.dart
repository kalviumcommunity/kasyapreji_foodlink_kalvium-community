import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../widgets/foodlink_logo.dart';
import '../widgets/leaf.dart';

/// Splash / app bootstrap screen.
///
/// Layout values come from the Figma frame (422 × 920) and are scaled to the
/// device: horizontal values and sizes by width, vertical positions by height.
///
/// Plays a one-off entrance (logo leaves grow in, text rises, leaves drift in),
/// then loops ambient motion (leaves sway, light particles rise, loader pulses).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const double _designWidth = 422;
  static const double _designHeight = 920;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  Animation<double> _step(double begin, double end, [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _intro, curve: Interval(begin, end, curve: curve));

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

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
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
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final sx = constraints.maxWidth / _designWidth;
            final sy = constraints.maxHeight / _designHeight;

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
                        ),
                      ),
                    ),
                    _buildGlow(sx, sy),
                    _buildLogo(sx, sy),
                    _buildTitle(sx, sy),
                    _buildBottomMessage(sx, sy),
                    _buildLoader(sx, sy),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlow(double sx, double sy) {
    final size = 300 * sx;
    final pulse = 1 + 0.05 * math.sin(_ambient.value * 2 * math.pi * 2);
    return Positioned(
      top: 268 * sy - size / 2,
      left: (_designWidth * sx - size) / 2,
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
                  Colors.white.withValues(alpha: 0.85),
                  AppColors.glow.withValues(alpha: 0.35),
                  AppColors.glow.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(double sx, double sy) {
    // Gentle breathing once the logo has settled.
    final breathe = 1 + 0.02 * math.sin(_ambient.value * 2 * math.pi * 2);
    return Positioned(
      top: 225 * sy,
      left: 0,
      right: 0,
      child: Center(
        child: Transform.scale(
          scale: _intro.isCompleted ? breathe : 1,
          alignment: Alignment.bottomCenter,
          child: FoodLinkLogo(
            width: 130 * sx,
            growth: [for (final leaf in _logoLeaves) leaf.value],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(double sx, double sy) {
    return Positioned(
      top: 336 * sy,
      left: 16,
      right: 16,
      child: Column(
        children: [
          _rise(
            _title.value,
            20 * sy,
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.brandDark, AppColors.brand, AppColors.brandDark],
                stops: [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: Text(
                'FoodLink',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 38 * sx,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6 * sx,
                  height: 1.2,
                  shadows: [
                    Shadow(
                      color: AppColors.brandDark.withValues(alpha: 0.18),
                      offset: Offset(0, 3 * sx),
                      blurRadius: 10 * sx,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16 * sy),
          _rise(
            _tagline.value,
            14 * sy,
            Text(
              'Good Food\nBrighter Futures',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19 * sx,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2 * sx,
                color: AppColors.brandText,
                height: 1.68,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMessage(double sx, double sy) {
    return Positioned(
      top: 780 * sy,
      left: 16,
      right: 16,
      child: _rise(
        _bottom.value,
        16 * sy,
        Text(
          'A Hunger-Free Tomorrow\nStarts With You',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19 * sx,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
            height: 1.72,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: Offset(0, 2 * sx),
                blurRadius: 8 * sx,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Three dots that pulse in turn while the app loads.
  Widget _buildLoader(double sx, double sy) {
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
              Builder(builder: (context) {
                final t = (beat - i * 0.18) % 1.0;
                final pulse = math.max(0.0, math.sin(t * math.pi));
                final d = (6 + 3 * pulse) * sx;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4 * sx),
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.35 + 0.65 * pulse),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Fades [child] in while sliding it up by [distance].
  Widget _rise(double t, double distance, Widget child) {
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - t) * distance),
        child: child,
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
  });

  final double sx;
  final double sy;
  final double time;
  final double leavesIn;
  final double particlesIn;

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
  static const _entryOffsets = [Offset(-40, -60), Offset(-60, 30), Offset(50, 60)];
  static const _phases = [0.0, 0.33, 0.66];

  static final List<_Particle> _particles = () {
    final rnd = math.Random(7);
    return List.generate(18, (_) {
      return _Particle(
        x: rnd.nextDouble() * 422,
        radius: 1.2 + rnd.nextDouble() * 1.8,
        speed: 1 + rnd.nextInt(2).toDouble(),
        offset: rnd.nextDouble(),
        maxAlpha: 0.25 + rnd.nextDouble() * 0.35,
      );
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    _paintParticles(canvas);
    _paintLeaves(canvas);
  }

  void _paintLeaves(Canvas canvas) {
    for (var i = 0; i < _leaves.length; i++) {
      final leaf = _leaves[i];
      final wave = 2 * math.pi * (time * 2 + _phases[i]);
      final sway = math.sin(wave) * 0.07;
      final bob = Offset(math.cos(wave) * 3, math.sin(wave) * 6);
      final entry = _entryOffsets[i] * (1 - leavesIn);
      final spinIn = (1 - leavesIn) * 0.6 * (i.isEven ? -1 : 1);

      // Leaf centre in screen space: x follows width, y follows height.
      final c = leaf.centre;
      final target = Offset(c.dx * sx, c.dy * sy) + (bob + entry) * sx;

      canvas.save();
      canvas.translate(target.dx, target.dy);
      canvas.rotate(sway + spinIn);
      canvas.translate(-c.dx * sx, -c.dy * sx);
      leaf.paint(canvas, sx, opacity: leavesIn);
      canvas.restore();
    }
  }

  void _paintParticles(Canvas canvas) {
    if (particlesIn <= 0) return;
    const top = 470.0;
    const bottom = 920.0;
    for (final p in _particles) {
      final progress = (time * p.speed + p.offset) % 1.0;
      final y = bottom - progress * (bottom - top);
      final x = p.x + math.sin(progress * 2 * math.pi * 1.5 + p.offset * 6) * 8;
      final alpha = math.sin(progress * math.pi) * p.maxAlpha * particlesIn;
      final centre = Offset(x * sx, y * sy);
      canvas.drawCircle(
        centre,
        p.radius * 3 * sx,
        Paint()
          ..color = AppColors.particle.withValues(alpha: alpha * 0.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * sx),
      );
      canvas.drawCircle(
        centre,
        p.radius * sx,
        Paint()..color = AppColors.particle.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.leavesIn != leavesIn ||
      oldDelegate.particlesIn != particlesIn ||
      oldDelegate.sx != sx ||
      oldDelegate.sy != sy;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.radius,
    required this.speed,
    required this.offset,
    required this.maxAlpha,
  });

  final double x;
  final double radius;
  final double speed;
  final double offset;
  final double maxAlpha;
}
