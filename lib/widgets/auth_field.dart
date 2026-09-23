import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Rounded white input used on the sign-in screens.
///
/// It glows green while focused, turns red with a message below when
/// [errorText] is set, and for [obscure] fields shows an eye toggle.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.scale = 1,
    this.obscure = false,
    this.errorText,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final double scale;
  final bool obscure;
  final String? errorText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final focused = _focus.hasFocus;
    final error = widget.errorText;
    final accent = error != null
        ? AppColors.error
        : focused
        ? AppColors.brand
        : AppColors.fieldIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 60 * s,
          padding: EdgeInsets.symmetric(horizontal: 18 * s),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(
              color: error != null
                  ? AppColors.error
                  : focused
                  ? AppColors.brand.withValues(alpha: 0.7)
                  : AppColors.fieldBorder,
              width: focused || error != null ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (error != null ? AppColors.error : AppColors.brand)
                    .withValues(alpha: focused ? 0.14 : 0.04),
                blurRadius: (focused ? 18 : 10) * s,
                offset: Offset(0, 4 * s),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.icon,
                  key: ValueKey(accent),
                  size: 21 * s,
                  color: accent,
                ),
              ),
              SizedBox(width: 14 * s),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.obscure && _hidden,
                  keyboardType: widget.keyboardType,
                  autofillHints: widget.autofillHints,
                  textInputAction: widget.textInputAction,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                  inputFormatters: widget.inputFormatters,
                  textCapitalization: widget.textCapitalization,
                  cursorColor: AppColors.brand,
                  style: TextStyle(
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontSize: 16 * s,
                      fontWeight: FontWeight.w400,
                      color: AppColors.fieldHint,
                    ),
                  ),
                ),
              ),
              if (widget.obscure)
                Semantics(
                  button: true,
                  label: _hidden ? 'Show password' : 'Hide password',
                  excludeSemantics: true,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _hidden = !_hidden),
                      child: Padding(
                        padding: EdgeInsets.all(6 * s),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            _hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            key: ValueKey(_hidden),
                            size: 22 * s,
                            color: focused
                                ? AppColors.brand
                                : AppColors.fieldIcon,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.fromLTRB(6 * s, 8 * s, 6 * s, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 15 * s,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 6 * s),
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(
                            fontSize: 13 * s,
                            fontWeight: FontWeight.w500,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
