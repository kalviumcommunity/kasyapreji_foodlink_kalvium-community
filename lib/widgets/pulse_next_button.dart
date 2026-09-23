import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Round "next" button: green with a light ring, or white ([light]) for use
/// over dark photos.
///
/// Driven by its parent's animations: [appear] scales it in (values above 1
/// overshoot for a springy pop), [time] (looping 0–1) drives the arrow nudge
/// and, when [showHalo] is set, an expanding halo that invites a tap. A
/// non-null [progress] (0–1) draws a ring filling around it, as a countdown.
class PulseNextButton extends StatefulWidget {
  const PulseNextButton({
    super.key,
    required this.diameter,
    required this.time,
    this.appear = 1,
    this.showHalo = true,
    this.light = false,
    this.progress,
    this.onPressed,
  });

  /// Diameter of the green button; the light ring adds ~13% around it.
  final double diameter;
  final double time;
  final double appear;
  final bool showHalo;
  final bool light;
  final double? progress;
  final VoidCallback? onPressed;

  @override
  State<PulseNextButton> createState() => _PulseNextButtonState();
}

class _PulseNextButtonState extends State<PulseNextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 260),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inner = widget.diameter;
    final outer = inner * 88 / 78;
    final unit = inner / 78;
    final wave = widget.time * 4 % 1.0; // one pulse every 2 seconds
    final nudge =
        math.sin(widget.time * 2 * math.pi * 4).clamp(0.0, 1.0) * 3 * unit;
    final light = widget.light;
    final accent = light ? AppColors.white : AppColors.brand;
    final progress = widget.progress;

    return SizedBox(
      width: outer,
      height: outer,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, _) => Transform.scale(
          scale: widget.appear * (1 - 0.08 * _press.value),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (widget.showHalo)
                Container(
                  width: inner * (1 + 0.45 * wave),
                  height: inner * (1 + 0.45 * wave),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.35 * (1 - wave)),
                      width: 2 * unit,
                    ),
                  ),
                ),
              // Light ring that separates the button from what's behind it.
              Container(
                width: outer,
                height: outer,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: light
                      ? AppColors.white.withValues(alpha: 0.28)
                      : AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.14),
                      blurRadius: 24 * unit,
                      offset: Offset(0, 4 * unit),
                    ),
                  ],
                ),
              ),
              if (progress != null)
                SizedBox(
                  width: outer,
                  height: outer,
                  child: CustomPaint(
                    painter: _CountdownPainter(
                      progress: progress,
                      color: accent,
                      width: 3 * unit,
                    ),
                  ),
                ),
              Semantics(
                button: true,
                label: 'Next',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTapDown: (_) => _press.forward(),
                    onTapCancel: () => _press.reverse(),
                    onTapUp: (_) {
                      _press.reverse();
                      HapticFeedback.lightImpact();
                      widget.onPressed?.call();
                    },
                    child: Container(
                      width: inner,
                      height: inner,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: light
                              ? const [AppColors.white, AppColors.surface]
                              : const [Color(0xFF3A7550), AppColors.brand],
                        ),
                      ),
                      child: Transform.translate(
                        offset: Offset(nudge, 0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: light ? AppColors.brand : AppColors.white,
                          size: 30 * unit,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin ring that fills clockwise from the top as [progress] goes 0 → 1.
class _CountdownPainter extends CustomPainter {
  _CountdownPainter({
    required this.progress,
    required this.color,
    required this.width,
  });

  final double progress;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = (Offset.zero & size).deflate(width / 2);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_CountdownPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.width != width;
}
