import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Round green "next" button with a light ring around it.
///
/// Driven by its parent's animations: [appear] scales it in (values above 1
/// overshoot for a springy pop), [time] (looping 0–1) drives the arrow nudge
/// and, when [showHalo] is set, an expanding halo that invites a tap.
class PulseNextButton extends StatefulWidget {
  const PulseNextButton({
    super.key,
    required this.diameter,
    required this.time,
    this.appear = 1,
    this.showHalo = true,
    this.onPressed,
  });

  /// Diameter of the green button; the light ring adds ~13% around it.
  final double diameter;
  final double time;
  final double appear;
  final bool showHalo;
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
                      color: AppColors.brand.withValues(
                        alpha: 0.35 * (1 - wave),
                      ),
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
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.14),
                      blurRadius: 24 * unit,
                      offset: Offset(0, 4 * unit),
                    ),
                  ],
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
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF3A7550), AppColors.brand],
                        ),
                      ),
                      child: Transform.translate(
                        offset: Offset(nudge, 0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.white,
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
