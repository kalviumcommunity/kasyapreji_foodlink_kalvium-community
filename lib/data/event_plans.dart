import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/campaign_service.dart';
import 'join_options.dart';
import 'my_events.dart';

/// Events the volunteer has joined or saved, by title, kept in memory until
/// accounts exist. Event lists and the details page listen, so a join shows
/// everywhere at once. It starts with the [initialPlans] the volunteer had
/// already made.
class EventPlans {
  EventPlans._();

  /// The role, time slot and notes chosen for each joined event.
  static final Map<String, JoinDetails> _details = initialPlans();

  static final ValueNotifier<Set<String>> joined = ValueNotifier({
    ..._details.keys,
  });
  static final ValueNotifier<Set<String>> saved = ValueNotifier({});

  static bool hasJoined(String title) => joined.value.contains(title);
  static bool hasSaved(String title) => saved.value.contains(title);
  static JoinDetails? detailsFor(String title) => _details[title];

  static void join(String title, JoinDetails details) {
    _details[title] = details;
    joined.value = {...joined.value, title};
    // Best-effort persistence: the volunteer's own roster entry for
    // this event, so a coordinator can see and confirm it. Skipped for
    // the demo login (no real Firebase user), and guarded in case
    // Firebase itself somehow isn't ready — neither should ever block
    // what the screen already applied above.
    final user = _currentUser();
    if (user == null) return;
    unawaited(
      CampaignService.findEventIdByTitle(title).then((eventId) {
        if (eventId == null) return null;
        return CampaignService.joinEvent(
          eventId: eventId,
          volunteerId: user.uid,
          name: user.displayName ?? user.email ?? 'Volunteer',
          role: details.role.name,
        );
      }).catchError((_) {
        // Already reflected locally; a future retry can sync it later.
      }),
    );
  }

  static void leave(String title) {
    _details.remove(title);
    joined.value = {...joined.value}..remove(title);
    final user = _currentUser();
    if (user == null) return;
    unawaited(
      CampaignService.findEventIdByTitle(title).then((eventId) {
        if (eventId == null) return null;
        return CampaignService.leaveEvent(eventId: eventId, volunteerId: user.uid);
      }).catchError((_) {}),
    );
  }

  static User? _currentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  static void toggleSaved(String title) {
    final next = {...saved.value};
    if (!next.remove(title)) next.add(title);
    saved.value = next;
  }

  @visibleForTesting
  static void reset() => useSampleData();

  /// Back to the sample plans — for the demo login.
  static void useSampleData() {
    _details
      ..clear()
      ..addAll(initialPlans());
    joined.value = {..._details.keys};
    saved.value = {};
  }

  /// A real account's own plans: exactly the events it has a roster entry
  /// for in Firestore (see `loadRealData`), and nothing from the samples.
  static void useRealPlans(Map<String, JoinDetails> plans) {
    _details
      ..clear()
      ..addAll(plans);
    joined.value = {...plans.keys};
    saved.value = {};
  }
}
