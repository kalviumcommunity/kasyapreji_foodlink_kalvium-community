import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink/auth/session_profile.dart';
import 'package:foodlink/data/app_session.dart';
import 'package:foodlink/data/coordinator.dart';
import 'package:foodlink/data/event_plans.dart';
import 'package:foodlink/data/sample_events.dart';
import 'package:foodlink/screens/community_screen.dart';
import 'package:foodlink/screens/confirm_join_screen.dart';
import 'package:foodlink/screens/coordinator/event_details_screen.dart';
import 'package:foodlink/screens/event_details_screen.dart';
import 'package:foodlink/screens/coordinator/beneficiaries_screen.dart';
import 'package:foodlink/screens/coordinator/create_event_screen.dart';
import 'package:foodlink/screens/coordinator/events_screen.dart';
import 'package:foodlink/screens/coordinator/profile_screen.dart';
import 'package:foodlink/screens/coordinator/reports_screen.dart';
import 'package:foodlink/screens/coordinator/volunteers_screen.dart';
import 'package:foodlink/screens/coordinator_home_screen.dart';
import 'package:foodlink/screens/explore_screen.dart';
import 'package:foodlink/screens/my_events_screen.dart';
import 'package:foodlink/screens/profile_pages.dart';
import 'package:foodlink/screens/profile_screen.dart';
import 'package:foodlink/screens/volunteer_home_screen.dart';

/// A brand-new real account has no events, volunteers, history, posts or
/// anything else — every list the sample data used to fill is empty. These
/// open each main screen in exactly that state, so a screen that assumes
/// sample data exists (and crashes without it) fails here instead of on a
/// phone.
void main() {
  setUp(() {
    startRealSession(
      email: 'new.user@example.com',
      name: 'New User',
      phone: '',
    );
  });

  tearDown(startDemoSession);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  final screens = <String, Widget Function()>{
    // Volunteer
    'Volunteer home': () => const VolunteerHomeScreen(),
    'Explore': () => const ExploreScreen(),
    'My Events (upcoming)': () => const MyEventsScreen(),
    'My Events (past)': () => const MyEventsScreen(showPast: true),
    'Profile': () => const ProfileScreen(),
    'Personal information': () => const PersonalInfoScreen(),
    'Interests': () => const InterestsScreen(),
    'Certificates': () => const CertificatesScreen(),
    'Settings': () => const SettingsScreen(),
    'Community': () => const CommunityScreen(),
    // Coordinator
    'Coordinator home': () => const CoordinatorHomeScreen(),
    'Coordinator events': () => const CoordinatorEventsScreen(),
    'Create event': () => const CreateEventScreen(),
    'Volunteers': () => const CoordinatorVolunteersScreen(),
    'Beneficiaries': () => const BeneficiariesScreen(),
    'Reports': () => const ImpactReportsScreen(),
    'Coordinator profile': () => const CoordinatorProfileScreen(),
    'Team management': () => const TeamManagementScreen(),
    'Organization details': () => const OrganizationDetailsScreen(),
    'Coordinator settings': () => const CoordinatorSettingsScreen(),
  };

  test('A real account starts with no sample data', () {
    expect(CoordinatorBoard.events.value, isEmpty);
    expect(CoordinatorBoard.beneficiaries.value, isEmpty);
    expect(volunteerContacts, isEmpty);
    expect(coordinatorAlerts, isEmpty);
    expect(EventPlans.joined.value, isEmpty);
    expect(CoordinatorBoard.team.value.single.name, 'New User');
  });

  for (final MapEntry(key: name, value: build) in screens.entries) {
    for (final (label, size) in [
      ('phone', const Size(390, 844)),
      ('laptop', const Size(1440, 900)),
    ]) {
      testWidgets('$name opens with no data on a $label', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(home: build()));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }

  // An event document saved before events were stored in full has only a
  // title — every other field comes back blank or zero (no date, place,
  // capacity, meals or volunteers). Real accounts can have exactly that, so
  // every screen must cope with it, including the event's own pages.
  group('with a sparse real event', () {
    final sparse = VolunteerEvent.fromMap({'title': 'Old Event'});

    setUp(() {
      AppSession.realEvents = [sparse];
      CoordinatorBoard.events.value = [
        ManagedEvent(event: sparse, roster: const []),
      ];
    });

    final withEvent = <String, Widget Function()>{
      ...screens,
      'Event details': () => EventDetailsScreen(event: sparse),
      'Join event': () => ConfirmJoinScreen(event: sparse),
      'Coordinator event details': () =>
          const CoordinatorEventDetailsScreen(title: 'Old Event'),
    };

    for (final MapEntry(key: name, value: build) in withEvent.entries) {
      testWidgets('$name opens with a sparse event', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(home: build()));
        await settle(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
