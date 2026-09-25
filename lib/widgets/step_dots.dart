import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Progress dots for a multi-step flow: earlier steps soft green, the
/// [current] one a brand-green pill with a gentle breathing glow, later steps
/// pale.
///
/// [appear] (0–1) pops the dots in one after another; [time] (looping 0–1)
/// drives the glow.
class StepDots extends StatelessWidget {
  const StepDots({
    super.key,
    required this.count,
    required this.current,
    required this.scale,
    this.time = 0,
    this.appear = 1,
  });

  final int count;
  final int current;
  final double scale;
  final double time;
  final double appear;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final d = 12 * s;
    final breathe = 0.5 + 0.5 * math.sin(time * 2 * math.pi * 4);
    return Semantics(
      label: 'Step ${current + 1} of $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4 * s),
              child: Transform.scale(
                scale: Curves.easeOutBack.transform(
                  ((appear * (count + 2) - i) / 3).clamp(0.0, 1.0),
                ),
                child: Container(
                  width: i == current ? d * 1.9 : d,
                  height: d,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(d),
                    gradient: i == current
                        ? const LinearGradient(
                            colors: [Color(0xFF3A7550), AppColors.brand],
                          )
                        : null,
                    color: i == current
                        ? null
                        : i < current
                        ? AppColors.stepDone
                        : AppColors.stepTodo,
                    boxShadow: i == current
                        ? [
                            BoxShadow(
                              color: AppColors.brand.withValues(
                                alpha: 0.18 + 0.22 * breathe,
                              ),
                              blurRadius: (6 + 6 * breathe) * s,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
