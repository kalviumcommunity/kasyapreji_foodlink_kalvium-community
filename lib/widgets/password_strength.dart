import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rates a password 0–4: one point each for length (8+), mixed case, a digit
/// and a symbol. Anything under 8 characters scores at most 1.
int passwordStrength(String password) {
  if (password.isEmpty) return 0;
  var score = 0;
  if (password.length >= 8) score++;
  if (password.contains(RegExp('[a-z]')) &&
      password.contains(RegExp('[A-Z]'))) {
    score++;
  }
  if (password.contains(RegExp(r'\d'))) score++;
  if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
  if (password.length < 8) score = score.clamp(0, 1);
  return score.clamp(1, 4);
}

/// Four-segment meter with a label, shown under a new password.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.password,
    required this.scale,
  });

  final String password;
  final double scale;

  static const _labels = ['Weak', 'Fair', 'Good', 'Strong'];
  static const _colors = [
    AppColors.error,
    Color(0xFFD98A2B),
    Color(0xFF8DB04A),
    AppColors.brand,
  ];

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final score = passwordStrength(password);
    final color = score == 0 ? AppColors.fieldBorder : _colors[score - 1];

    return Semantics(
      label: score == 0 ? null : 'Password strength: ${_labels[score - 1]}',
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 5 * s,
                decoration: BoxDecoration(
                  color: i < score ? color : AppColors.fieldBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            if (i < 3) SizedBox(width: 6 * s),
          ],
          SizedBox(width: 12 * s),
          SizedBox(
            width: 52 * s,
            child: Text(
              score == 0 ? '' : _labels[score - 1],
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5 * s,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
