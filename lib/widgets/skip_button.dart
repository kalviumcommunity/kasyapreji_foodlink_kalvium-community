import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Soft frosted pill that reads "Skip ›", for leaving onboarding early.
///
/// [scale] sizes it with the layout; it brightens on hover (web/desktop) and
/// dips slightly when pressed.
class SkipButton extends StatefulWidget {
  const SkipButton({super.key, this.scale = 1, this.onPressed});

  final double scale;
  final VoidCallback? onPressed;

  @override
  State<SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<SkipButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final active = _hovered || _pressed;

    return Semantics(
      button: true,
      label: 'Skip',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) {
            setState(() => _pressed = false);
            HapticFeedback.selectionClick();
            widget.onPressed?.call();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.fromLTRB(18 * s, 9 * s, 12 * s, 9 * s),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: active ? 0.95 : 0.7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: active ? 0.18 : 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(
                      alpha: active ? 0.14 : 0.08,
                    ),
                    blurRadius: 16 * s,
                    offset: Offset(0, 4 * s),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 15 * s,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2 * s,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(width: 2 * s),
                  AnimatedSlide(
                    offset: Offset(active ? 0.15 : 0, 0),
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20 * s,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
