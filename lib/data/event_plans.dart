import 'package:flutter/foundation.dart';

import 'join_options.dart';

/// Events the volunteer has joined or saved, by title, kept in memory until
/// accounts exist. Event lists and the details page listen, so a join shows
/// everywhere at once.
class EventPlans {
  EventPlans._();

  static final ValueNotifier<Set<String>> joined = ValueNotifier({});
  static final ValueNotifier<Set<String>> saved = ValueNotifier({});

  /// The role, time slot and notes chosen for each joined event.
  static final Map<String, JoinDetails> _details = {};

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
    _details.clear();
    joined.value = {};
    saved.value = {};
  }
}
