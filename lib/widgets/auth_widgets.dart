import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Small pieces shared by the sign-in and sign-up screens.

/// Shows a floating green notice, for actions that aren't wired up yet.
void showAuthNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brandDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.logoOnDark,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Round, frosted tap target (the back button). [onDark] is the glassy white
/// variant for use over photos.
class AuthIconButton extends StatelessWidget {
  const AuthIconButton({
    super.key,
    required this.label,
    required this.scale,
    required this.onTap,
    required this.child,
    this.onDark = false,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;
  final Widget child;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final d = 40 * scale;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onDark
                  ? AppColors.white.withValues(alpha: 0.18)
                  : AppColors.surface.withValues(alpha: 0.75),
              border: Border.all(
                color: onDark
                    ? AppColors.white.withValues(alpha: 0.35)
                    : AppColors.ink.withValues(alpha: 0.08),
              ),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Profile placeholder in the top-right, as in the designs.
class AuthAvatar extends StatelessWidget {
  const AuthAvatar({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final d = 40 * scale;
    return Semantics(
      label: 'Profile',
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.avatar,
          ),
          border: Border.all(color: AppColors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.earthDark.withValues(alpha: 0.25),
              blurRadius: 10 * scale,
              offset: Offset(0, 3 * scale),
            ),
          ],
        ),
        child: Icon(
          Icons.person_rounded,
          size: 24 * scale,
          color: const Color(0xFFF3E4D6),
        ),
      ),
    );
  }
}

/// Green, bold text link that underlines on hover.
class AuthTextLink extends StatefulWidget {
  const AuthTextLink({
    super.key,
    required this.label,
    required this.scale,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final double scale;
  final double fontSize;
  final VoidCallback onTap;

  @override
  State<AuthTextLink> createState() => _AuthTextLinkState();
}

class _AuthTextLinkState extends State<AuthTextLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize * widget.scale,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
              decoration: _hovered ? TextDecoration.underline : null,
              decorationColor: AppColors.brand,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Prompt? Link" line at the foot of a form, e.g. "Already have an account?
/// Sign In". Wraps onto two lines on narrow cards.
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.prompt,
    required this.action,
    required this.scale,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8 * s,
      runSpacing: 4 * s,
      children: [
        Text(
          prompt,
          style: TextStyle(fontSize: 15.5 * s, color: AppColors.bodyText),
        ),
        AuthTextLink(label: action, scale: s, fontSize: 16.5, onTap: onTap),
      ],
    );
  }
}

/// A label between two hairlines, e.g. "or continue with".
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(
        height: 1,
        margin: EdgeInsets.symmetric(horizontal: 14 * scale),
        color: AppColors.ink.withValues(alpha: 0.08),
      ),
    );
    return Row(
      children: [
        line,
        Text(
          label,
          style: TextStyle(fontSize: 15 * scale, color: AppColors.bodyText),
        ),
        line,
      ],
    );
  }
}

/// Light pill for a social sign-in option; lifts on hover, dips on press.
class SocialButton extends StatefulWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.scale,
    required this.onTap,
    required this.child,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    return Semantics(
      button: true,
      label: widget.label,
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
            widget.onTap();
          },
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 126 * s,
              height: 54 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hovered ? AppColors.white : AppColors.socialFill,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.ink.withValues(
                    alpha: _hovered ? 0.10 : 0.04,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(
                      alpha: _hovered ? 0.12 : 0.0,
                    ),
                    blurRadius: 16 * s,
                    offset: Offset(0, 6 * s),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded green checkbox with a label; the whole row is tappable. [error]
/// outlines the box in red (e.g. terms not accepted).
class AuthCheckbox extends StatelessWidget {
  const AuthCheckbox({
    super.key,
    required this.value,
    required this.scale,
    required this.semanticsLabel,
    required this.label,
    required this.onChanged,
    this.error = false,
  });

  final bool value;
  final double scale;
  final String semanticsLabel;
  final Widget label;
  final ValueChanged<bool> onChanged;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Semantics(
      checked: value,
      label: semanticsLabel,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(!value);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22 * s,
                height: 22 * s,
                decoration: BoxDecoration(
                  color: value ? AppColors.brand : AppColors.white,
                  borderRadius: BorderRadius.circular(6 * s),
                  border: Border.all(
                    color: error
                        ? AppColors.error
                        : value
                        ? AppColors.brand
                        : AppColors.fieldBorder,
                    width: 1.5,
                  ),
                ),
                child: AnimatedScale(
                  scale: value ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    Icons.check_rounded,
                    size: 16 * s,
                    color: AppColors.white,
                  ),
                ),
              ),
              SizedBox(width: 10 * s),
              Flexible(child: label),
            ],
          ),
        ),
      ),
    );
  }
}
