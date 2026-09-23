import 'dart:math' as math;
import 'dart:ui';

import '../theme/app_colors.dart';

/// Soft glowing specks that drift upward between [top] and [bottom].
///
/// Positions are in design-frame units ([designWidth] wide) and scaled at
/// paint time, so the same particles work on any screen size.
class LightParticles {
  LightParticles({
    required this.top,
    required this.bottom,
    int count = 18,
    int seed = 7,
    double designWidth = 422,
    this.color = AppColors.particle,
  }) : _particles = _generate(count, seed, designWidth);

  final double top;
  final double bottom;
  final Color color;
  final List<_Particle> _particles;

  static List<_Particle> _generate(int count, int seed, double width) {
    final rnd = math.Random(seed);
    return List.generate(count, (_) {
      return _Particle(
        x: rnd.nextDouble() * width,
        radius: 1.2 + rnd.nextDouble() * 1.8,
        speed: 1 + rnd.nextInt(2).toDouble(),
        offset: rnd.nextDouble(),
        maxAlpha: 0.25 + rnd.nextDouble() * 0.35,
      );
    });
  }

  /// [time] is a looping 0–1 value; [opacity] fades the whole field in or out.
  /// Positions scale by [sx]/[sy]; particle size scales by the smaller of the
  /// two so specks never balloon on wide or short screens.
  void paint(
    Canvas canvas, {
    required double sx,
    required double sy,
    required double time,
    double opacity = 1,
  }) {
    if (opacity <= 0) return;
    final s = math.min(sx, sy);
    for (final p in _particles) {
      final progress = (time * p.speed + p.offset) % 1.0;
      final y = bottom - progress * (bottom - top);
      final x = p.x + math.sin(progress * 2 * math.pi * 1.5 + p.offset * 6) * 8;
      final alpha = math.sin(progress * math.pi) * p.maxAlpha * opacity;
      final centre = Offset(x * sx, y * sy);
      canvas.drawCircle(
        centre,
        p.radius * 3 * s,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.25)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * s),
      );
      canvas.drawCircle(
        centre,
        p.radius * s,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }
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
