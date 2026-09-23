import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Full-width green pill button with a soft shadow, a gentle light sweep
/// driven by [time] (looping 0–1), a pressed dip, and a spinner while
/// [loading].
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.scale = 1,
    this.time = 0,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double scale;
  final double time;
  final bool loading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final enabled = widget.onPressed != null && !widget.loading;
    // A light sweep crosses the button once every 4 seconds.
    final sweep = (widget.time * 2) % 1.0;

    return Semantics(
      button: true,
      label: widget.label,
      enabled: enabled,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: enabled
              ? (_) {
                  setState(() => _pressed = false);
                  HapticFeedback.lightImpact();
                  widget.onPressed!();
                }
              : null,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 68 * s,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _hovered
                      ? const [Color(0xFF3F7E57), AppColors.brand]
                      : const [Color(0xFF356B48), AppColors.brand],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(
                      alpha: _pressed ? 0.14 : 0.24,
                    ),
                    blurRadius: (_pressed ? 14 : 30) * s,
                    spreadRadius: -6 * s,
                    offset: Offset(0, (_pressed ? 6 : 14) * s),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (enabled)
                      Positioned.fill(
                        child: CustomPaint(painter: _SweepPainter(sweep)),
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: widget.loading
                          ? SizedBox.square(
                              key: const ValueKey('loading'),
                              dimension: 24 * s,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              widget.label,
                              key: const ValueKey('label'),
                              style: TextStyle(
                                fontSize: 19 * s,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2 * s,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft diagonal band of light crossing the button.
class _SweepPainter extends CustomPainter {
  const _SweepPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Only visible during the first 40% of the cycle.
    if (t > 0.4) return;
    final x = (t / 0.4) * (size.width + 160) - 80;
    canvas.save();
    canvas.translate(x, size.height / 2);
    canvas.rotate(math.pi / 8);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 60, height: size.height * 3),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00FFFFFF), Color(0x33FFFFFF), Color(0x00FFFFFF)],
        ).createShader(const Rect.fromLTWH(-30, 0, 60, 1)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) => oldDelegate.t != t;
}
