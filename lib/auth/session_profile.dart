import '../data/app_session.dart';
import '../data/community.dart';
import '../data/coordinator.dart';
import '../data/event_plans.dart';
import '../data/volunteer_profile.dart';

/// Switches the app to a real account's own data: every sample list
/// (events, plans, past visits, volunteers, beneficiaries, team, alerts,
/// activity, community posts, the sample volunteer's profile) is cleared,
/// and the profile shows the real account's name, email and phone.
///
/// Called after a real sign-in, a real sign-up, and session restore — never
/// for the demo login. `loadRealData` (lib/services/real_data_loader.dart)
/// then fills in whatever is actually stored in Firestore.
void startRealSession({
  required String email,
  required String name,
  String phone = '',
}) {
  AppSession.isDemo = false;
  AppSession.realEvents = const [];
  AppSession.realMonthlyMeals = const [];
  VolunteerProfile.useRealProfile(name: name, email: email, phone: phone);
  EventPlans.useRealPlans(const {});
  CommunityFeed.clearForRealAccount();
  CoordinatorBoard.clearForRealAccount(name: name, email: email);
}

/// Back to the built-in sample content — for the demo login, and after
/// signing out, so nothing from a real account lingers in memory.
void startDemoSession() {
  AppSession.isDemo = true;
  AppSession.realEvents = const [];
  AppSession.realMonthlyMeals = const [];
  VolunteerProfile.useSampleData();
  EventPlans.useSampleData();
  CommunityFeed.useSampleData();
  CoordinatorBoard.useSampleData();
}
