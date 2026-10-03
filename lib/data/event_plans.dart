import 'package:flutter/foundation.dart';

/// Events the volunteer has joined or saved, by title, kept in memory until
/// accounts exist. Event lists and the details page listen, so a join shows
/// everywhere at once.
class EventPlans {
  EventPlans._();

  static final ValueNotifier<Set<String>> joined = ValueNotifier({});
  static final ValueNotifier<Set<String>> saved = ValueNotifier({});

  static bool hasJoined(String title) => joined.value.contains(title);
  static bool hasSaved(String title) => saved.value.contains(title);

  static void toggleJoined(String title) => _toggle(joined, title);
  static void toggleSaved(String title) => _toggle(saved, title);

  static void _toggle(ValueNotifier<Set<String>> set, String title) {
    final next = {...set.value};
    if (!next.remove(title)) next.add(title);
    set.value = next;
  }

  @visibleForTesting
  static void reset() {
    joined.value = {};
    saved.value = {};
  }
}
