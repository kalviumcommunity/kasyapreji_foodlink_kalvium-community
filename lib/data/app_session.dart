import 'sample_events.dart';

/// Whether the app is showing its built-in sample content or a real
/// account's own data.
///
/// Sample content is what the demo login (and every widget test) sees. A
/// real Firebase account starts from an empty slate and only ever sees
/// what's actually stored in Firestore — see `startRealSession` in
/// `lib/auth/session_profile.dart`, and `loadRealData` in
/// `lib/services/real_data_loader.dart`, which fills it in.
class AppSession {
  AppSession._();

  /// `true` until a real account signs in, and again after signing out.
  static bool isDemo = true;

  /// The real events from Firestore, for a real account — what Explore,
  /// My Events and the volunteer home list instead of the sample events.
  static List<VolunteerEvent> realEvents = const [];

  /// Real meals per month, oldest first, for the community impact chart.
  static List<(String, int)> realMonthlyMeals = const [];
}
