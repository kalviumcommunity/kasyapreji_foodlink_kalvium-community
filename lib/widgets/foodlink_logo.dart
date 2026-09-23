import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'leaf.dart';

/// The three-leaf FoodLink mark.
///
/// [growth] holds how far each leaf (centre, left, right) has grown, from 0
/// (hidden) to 1 (full size). Values above 1 overshoot, for a springy entrance.
class FoodLinkLogo extends StatelessWidget {
  const FoodLinkLogo({
    super.key,
    this.width = 130,
    this.color = AppColors.brand,
    this.growth = const [1, 1, 1],
  });

  final double width;
  final Color color;
  final List<double> growth;

  static const Size designSize = Size(130, 85);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * designSize.height / designSize.width,
      child: CustomPaint(
        painter: _LogoPainter(color: color, growth: growth),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.color, required this.growth});

  final Color color;
  final List<double> growth;

  List<LeafShape> get _leaves => [
    // Centre leaf
    LeafShape(
      tipA: const Offset(65, 0),
      tipB: const Offset(65, 54),
      bulgeLeft: 10,
      bulgeRight: 10,
      color: color,
    ),
    // Left leaf
    LeafShape(
      tipA: const Offset(0, 20),
      tipB: const Offset(60, 84),
      bulgeLeft: 13,
      bulgeRight: 20,
      color: color,
    ),
    // Right leaf
    LeafShape(
      tipA: const Offset(130, 20),
      tipB: const Offset(70, 84),
      bulgeLeft: 20,
      bulgeRight: 13,
      color: color,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / FoodLinkLogo.designSize.width;
    final leaves = _leaves;
    for (var i = 0; i < leaves.length; i++) {
      final g = growth[i];
      if (g <= 0) continue;
      // Grow each leaf out of its base.
      final base = leaves[i].tipB * scale;
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.scale(g);
      canvas.translate(-base.dx, -base.dy);
      leaves[i].paint(canvas, scale, opacity: g.clamp(0.0, 1.0));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.growth != growth;
}
