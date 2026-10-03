import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/explore_screen.dart';
import '../screens/volunteer_home_screen.dart';
import '../widgets/app_nav.dart';
import '../widgets/auth_widgets.dart';
import 'transitions.dart';

/// Moves from the [from] section to [to] when its tab is tapped.
///
/// Home is the base of the volunteer's sections: other sections open on top
/// of it, and going Home steps back to it. Sections that aren't designed yet
/// answer with a notice.
void openAppTab(BuildContext context, AppTab from, AppTab to) {
  if (from == to) return;
  HapticFeedback.selectionClick();
  final navigator = Navigator.of(context);
  switch (to) {
    case AppTab.home:
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.pushReplacement(softRoute(const VolunteerHomeScreen()));
      }
    case AppTab.explore:
      final page = softRoute<void>(const ExploreScreen());
      if (from == AppTab.home) {
        navigator.push(page);
      } else {
        navigator.pushReplacement(page);
      }
    default:
      showAuthNotice(context, '${to.label} is coming soon.');
  }
}
