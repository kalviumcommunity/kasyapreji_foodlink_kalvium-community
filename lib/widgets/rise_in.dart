import 'package:flutter/widgets.dart';

/// Fades [child] in while sliding it up by [distance], driven by [progress]
/// (0 = hidden and lowered, 1 = fully shown in place).
class RiseIn extends StatelessWidget {
  const RiseIn({
    super.key,
    required this.progress,
    required this.distance,
    required this.child,
  });

  final double progress;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * distance),
        child: child,
      ),
    );
  }
}
