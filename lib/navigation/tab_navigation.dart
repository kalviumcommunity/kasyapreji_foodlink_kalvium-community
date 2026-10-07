import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sample_events.dart';
import '../screens/event_details_screen.dart';
import '../screens/community_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/my_events_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/volunteer_home_screen.dart';
import '../widgets/app_nav.dart';
import 'transitions.dart';

/// Moves from the [from] section to [to] when its tab is tapped. [from] is
/// null on pages inside a section, such as an event's details.
///
/// Home is the base of the volunteer's sections: other sections open on top
/// of it, and going Home steps back to it. Opening a section that is already
/// in the history (say Explore, from an event opened there) steps back to it
/// rather than stacking a second copy.
void openAppTab(BuildContext context, AppTab? from, AppTab to) {
  if (from == to) return;
  HapticFeedback.selectionClick();
  final navigator = Navigator.of(context);
  switch (to) {
    case AppTab.home:
      final found = _popBackTo(navigator, VolunteerHomeScreen.routeName);
      if (!found) {
        navigator.pushReplacement(
          softRoute(
            const VolunteerHomeScreen(),
            name: VolunteerHomeScreen.routeName,
          ),
        );
      }
    case AppTab.explore:
      final found = _popBackTo(
        navigator,
        ExploreScreen.routeName,
        orTo: VolunteerHomeScreen.routeName,
      );
      if (!found) {
        navigator.push(
          softRoute(const ExploreScreen(), name: ExploreScreen.routeName),
        );
      }
    case AppTab.events:
      final found = _popBackTo(
        navigator,
        MyEventsScreen.routeName,
        orTo: VolunteerHomeScreen.routeName,
      );
      if (!found) {
        navigator.push(
          softRoute(const MyEventsScreen(), name: MyEventsScreen.routeName),
        );
      }
    case AppTab.community:
      final found = _popBackTo(
        navigator,
        CommunityScreen.routeName,
        orTo: VolunteerHomeScreen.routeName,
      );
      if (!found) {
        navigator.push(
          softRoute(const CommunityScreen(), name: CommunityScreen.routeName),
        );
      }
    case AppTab.profile:
      final found = _popBackTo(
        navigator,
        ProfileScreen.routeName,
        orTo: VolunteerHomeScreen.routeName,
      );
      if (!found) {
        navigator.push(
          softRoute(const ProfileScreen(), name: ProfileScreen.routeName),
        );
      }
  }
}

/// Opens [event]'s details from the [from] section. [heroTag] is the tag of
/// the tapped tile's photo, which grows into the page.
void openEventDetails(
  BuildContext context,
  VolunteerEvent event, {
  required AppTab from,
  required Object heroTag,
}) {
  Navigator.of(context).push(
    softRoute(EventDetailsScreen(event: event, tab: from, heroTag: heroTag)),
  );
}

/// Pops routes until the one named [name] is on top, and says whether it
/// was found. Stops early at a route named [orTo], or at the first route.
bool _popBackTo(NavigatorState navigator, String name, {String? orTo}) {
  var found = false;
  navigator.popUntil((route) {
    final routeName = route.settings.name;
    if (routeName == name) found = true;
    return found || routeName == orTo || route.isFirst;
  });
  return found;
}
