import '../data/app_session.dart';
import '../data/coordinator.dart';
import '../data/event_plans.dart';
import '../data/join_options.dart';
import '../data/sample_events.dart';
import 'campaign_models.dart';
import 'campaign_service.dart';

/// Fills a real account's screens from Firestore, after `startRealSession`
/// has cleared all the sample data. Awaited before a real account's home
/// screen opens, so it never shows sample content in the meantime.
///
/// Every step is best-effort: anything that can't be read (offline, say)
/// simply stays empty rather than blocking sign-in. Does nothing for the
/// demo login.
Future<void> loadRealData({required String uid, required String? role}) async {
  if (AppSession.isDemo) return;

  var events = const <RealEvent>[];
  try {
    events = await CampaignService.fetchEvents();
  } catch (_) {}
  AppSession.realEvents = [for (final real in events) real.event];

  try {
    AppSession.realMonthlyMeals =
        await CampaignService.computeMonthlyMealTotals(monthsBack: 9);
  } catch (_) {}

  if (role == 'coordinator') {
    await _loadCoordinator(events);
  } else {
    await _loadVolunteer(uid, events);
  }
}

/// The coordinator's real events, with the real people on each roster,
/// plus their real beneficiaries and team.
Future<void> _loadCoordinator(List<RealEvent> events) async {
  var roster = const <VolunteerParticipation>[];
  try {
    roster = await CampaignService.watchAllRosterEntries();
  } catch (_) {}
  CoordinatorBoard.useRealRoster(
    realEvents: [
      for (final real in events)
        ManagedEvent(
          event: real.event,
          roster: [
            for (final entry in roster)
              if (entry.eventId == real.id)
                RosterEntry(
                  name: entry.name,
                  role: _roleNamed(real.event, entry.role),
                  colors:
                      avatarColors[entry.volunteerId.hashCode.abs() %
                          avatarColors.length],
                ),
          ],
          status:
              EventStatus.values.asNameMap()[real.status] ??
              EventStatus.upcoming,
          mealsSoFar: real.mealsSoFar,
        ),
    ],
    roster: roster,
    eventTitles: {for (final real in events) real.id: real.event.title},
  );
  await CoordinatorBoard.loadPartnerOrganizationsFromFirestore();
  await CoordinatorBoard.loadTeamFromFirestore();
}

/// The volunteer's own plans: the real events they actually have a roster
/// entry for. Each is a plain read of their own entry, which the rules
/// allow; reading other volunteers' entries is never needed or allowed.
Future<void> _loadVolunteer(String uid, List<RealEvent> events) async {
  final entries = await Future.wait([
    for (final real in events)
      CampaignService.fetchMyRosterEntry(
        eventId: real.id,
        volunteerId: uid,
      ).catchError((_) => null),
  ]);
  EventPlans.useRealPlans({
    for (final (i, entry) in entries.indexed)
      if (entry != null)
        events[i].event.title: JoinDetails(
          role: _roleNamed(events[i].event, entry.role),
          slot: timeSlotsFor(events[i].event).first,
        ),
  });
}

EventRole _roleNamed(VolunteerEvent event, String name) {
  final roles = rolesFor(event);
  return roles.firstWhere((role) => role.name == name, orElse: () => roles.first);
}
