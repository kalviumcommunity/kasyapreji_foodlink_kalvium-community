import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The four-colour Google "G", drawn in code (Material icons have none).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.19;
    final centre = size.center(Offset.zero);
    final radius = size.width / 2 - stroke / 2;
    final ring = Rect.fromCircle(center: centre, radius: radius);
    double deg(double d) => d * math.pi / 180;

    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Clockwise from the right-hand side; the G opens at the top right.
    canvas.drawArc(ring, deg(0), deg(45), false, arc(_blue));
    canvas.drawArc(ring, deg(45), deg(105), false, arc(_green));
    canvas.drawArc(ring, deg(150), deg(60), false, arc(_yellow));
    canvas.drawArc(ring, deg(210), deg(108), false, arc(_red));

    // The crossbar.
    canvas.drawRect(
      Rect.fromLTRB(
        centre.dx - stroke * 0.05,
        centre.dy - stroke / 2,
        centre.dx + radius + stroke / 2,
        centre.dy + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}
