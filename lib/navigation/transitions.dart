import 'package:flutter/material.dart';

/// Fades [page] in while it settles from a slight zoom, or from a short slide
/// to the left when [slide] is set (for stepping forward through onboarding).
Route<T> softRoute<T>(Widget page, {bool slide = false}) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      final moving = slide
          ? SlideTransition(
              position: Tween(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            )
          : ScaleTransition(
              scale: Tween(begin: 1.04, end: 1.0).animate(curved),
              child: child,
            );
      return FadeTransition(opacity: curved, child: moving);
    },
  );
}
