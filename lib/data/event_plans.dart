import 'package:flutter/foundation.dart';

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
  }

  static void leave(String title) {
    _details.remove(title);
    joined.value = {...joined.value}..remove(title);
  }

  static void toggleSaved(String title) {
    final next = {...saved.value};
    if (!next.remove(title)) next.add(title);
    saved.value = next;
  }

  @visibleForTesting
  static void reset() {
    _details
      ..clear()
      ..addAll(initialPlans());
    joined.value = {..._details.keys};
    saved.value = {};
  }
}
