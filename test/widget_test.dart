import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink/auth/demo_account.dart';
import 'package:foodlink/data/community.dart';
import 'package:foodlink/data/event_plans.dart';
import 'package:foodlink/data/sample_events.dart';
import 'package:foodlink/main.dart';
import 'package:foodlink/data/join_options.dart';
import 'package:foodlink/screens/change_screen.dart';
import 'package:foodlink/screens/community_screen.dart';
import 'package:foodlink/screens/confirm_join_screen.dart';
import 'package:foodlink/screens/event_details_screen.dart';
import 'package:foodlink/screens/explore_screen.dart';
import 'package:foodlink/screens/my_events_screen.dart';
import 'package:foodlink/screens/impact_screen.dart';
import 'package:foodlink/screens/notifications_screen.dart';
import 'package:foodlink/screens/onboarding_screen.dart';
import 'package:foodlink/screens/role_screen.dart';
import 'package:foodlink/screens/sign_in_screen.dart';
import 'package:foodlink/screens/sign_up_screen.dart';
import 'package:foodlink/screens/story_screen.dart';
import 'package:foodlink/screens/volunteer_home_screen.dart';
import 'package:foodlink/widgets/primary_button.dart';

VolunteerEvent _event(String title) =>
    sampleEvents.firstWhere((event) => event.title == title);

void main() {
  setUp(() {
    EventPlans.reset();
    CommunityFeed.reset();
  });

  testWidgets('Splash screen shows brand name and taglines', (tester) async {
    await tester.pumpWidget(const FoodLinkApp());

    expect(find.text('FoodLink'), findsOneWidget);
    expect(find.text('Good Food\nBrighter Futures'), findsOneWidget);
    expect(
      find.text('A Hunger-Free Tomorrow\nStarts With You'),
      findsOneWidget,
    );
  });

  testWidgets('Splash moves on to onboarding automatically', (tester) async {
    await tester.pumpWidget(const FoodLinkApp());

    // Entrance (2.6s) + hold (1.4s) + transition (0.9s).
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Good Food\nBrighter Futures'), findsNothing);
    expect(find.text('Good Food'), findsOneWidget);
    expect(find.bySemanticsLabel('Next'), findsOneWidget);
    expect(find.bySemanticsLabel('Skip'), findsOneWidget);
  });

  testWidgets('Next on onboarding opens the impact screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.bySemanticsLabel('Next'));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(ImpactScreen), findsOneWidget);
    expect(find.text('Real Food.'), findsOneWidget);
    expect(find.text('Real Impact.'), findsOneWidget);
    expect(find.text('Less waste'), findsOneWidget);
    expect(find.text('More meals'), findsOneWidget);
  });

  testWidgets('Next on the impact screen opens Be the Change', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ImpactScreen()));
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.bySemanticsLabel('Next'));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(ChangeScreen), findsOneWidget);
    expect(find.text('Be the'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    for (final action in ['Donate', 'Volunteer', 'Organize']) {
      expect(find.text(action), findsOneWidget);
    }
    // Last onboarding page has no Skip.
    expect(find.bySemanticsLabel('Skip'), findsNothing);
  });

  testWidgets('Onboarding pages move on by themselves', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    // Entrance (2.2s) + countdown (5s) + transition (0.9s).
    for (var i = 0; i < 85; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ImpactScreen), findsOneWidget);

    for (var i = 0; i < 85; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ChangeScreen), findsOneWidget);
  });

  testWidgets('Touching the screen restarts the countdown', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    // Keep touching the headline every 2s for 10s: no auto-advance.
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (i % 20 == 0) await tester.tap(find.text('Good Food'));
    }
    expect(find.byType(ImpactScreen), findsNothing);
  });

  /// Scrolls [finder] into view, then taps it.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  Future<void> settle(WidgetTester tester, [int steps = 20]) async {
    for (var i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('Next on Be the Change opens Sign In', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChangeScreen()));
    await settle(tester, 25);
    await tester.tap(find.bySemanticsLabel('Next'));
    await settle(tester, 15);

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Good to see you again!'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
  });

  testWidgets('Skip on onboarding opens Sign In', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await settle(tester, 25);
    await tester.tap(find.bySemanticsLabel('Skip'));
    await settle(tester, 15);

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('Sign In validates its fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    await settle(tester);

    await tester.tap(find.bySemanticsLabel('Sign In'));
    await settle(tester, 5);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextField).at(1), '123');
    await tester.tap(find.bySemanticsLabel('Sign In'));
    await settle(tester, 5);
    expect(find.text("That email doesn't look right"), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);

    // Typing clears the error.
    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await settle(tester, 3);
    expect(find.text("That email doesn't look right"), findsNothing);
  });

  testWidgets('Password eye toggles visibility', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    await settle(tester);

    TextField password() =>
        tester.widget<TextField>(find.byType(TextField).at(1));
    expect(password().obscureText, isTrue);
    await tester.tap(find.bySemanticsLabel('Show password'));
    await settle(tester, 3);
    expect(password().obscureText, isFalse);
    await tester.tap(find.bySemanticsLabel('Hide password'));
    await settle(tester, 3);
    expect(password().obscureText, isTrue);
  });

  testWidgets('Sign in refuses logins other than the demo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    await settle(tester);

    await tester.enterText(
      find.byType(TextField).at(0),
      'volunteer@foodlink.org',
    );
    await tester.enterText(find.byType(TextField).at(1), 'secret123');
    await tester.tap(find.bySemanticsLabel('Sign In'));
    await settle(tester, 15);

    expect(find.text('Incorrect email or password'), findsOneWidget);
    expect(find.byType(RoleScreen), findsNothing);
  });

  testWidgets('Demo account signs in and opens the role screen', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    await settle(tester);

    await tapVisible(tester, find.bySemanticsLabel('Use demo account'));
    await settle(tester, 3);
    expect(find.text(DemoAccount.email), findsOneWidget);

    await tapVisible(tester, find.bySemanticsLabel('Sign In'));
    await settle(tester, 25);
    expect(find.byType(RoleScreen), findsOneWidget);
  });

  testWidgets('Remember me toggles', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    await settle(tester);

    final remember = find.bySemanticsLabel('Remember me');
    expect(tester.getSemantics(remember), isSemantics(isChecked: true));
    await tester.tap(remember);
    await settle(tester, 3);
    expect(tester.getSemantics(remember), isSemantics(isChecked: false));
  });

  testWidgets('Sign In and Sign Up links swap between the screens', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    await settle(tester);

    await tapVisible(tester, find.bySemanticsLabel('Sign Up'));
    await settle(tester, 15);
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.text('Create Account'), findsWidgets);

    await tapVisible(tester, find.bySemanticsLabel('Sign In'));
    await settle(tester, 15);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(SignUpScreen), findsNothing);
  });

  testWidgets('Sign Up validates every field and the terms', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
    await settle(tester);

    await tapVisible(tester, find.byType(PrimaryButton));
    await settle(tester, 5);
    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your phone number'), findsOneWidget);
    expect(find.text('Please create a password'), findsOneWidget);
    expect(find.text('Please accept the Terms & Conditions'), findsOneWidget);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Asha Rao');
    await tester.enterText(fields.at(1), 'asha@foodlink.org');
    await tester.enterText(fields.at(2), '12');
    await tester.enterText(fields.at(3), 'short');
    await tapVisible(tester, find.byType(PrimaryButton));
    await settle(tester, 5);
    expect(find.text("That phone number doesn't look right"), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    // Ticking the box clears the terms error.
    final terms = find.bySemanticsLabel('I agree to the Terms & Conditions');
    expect(tester.getSemantics(terms), isSemantics(isChecked: false));
    await tapVisible(tester, terms);
    await settle(tester, 3);
    expect(tester.getSemantics(terms), isSemantics(isChecked: true));
    expect(find.text('Please accept the Terms & Conditions'), findsNothing);

    await tester.enterText(fields.at(2), '+91 98765 43210');
    await tester.enterText(fields.at(3), 'Harvest#2026');
    await tapVisible(tester, find.byType(PrimaryButton));
    await settle(tester, 25);
    expect(find.byType(RoleScreen), findsOneWidget);
  });

  testWidgets('Password strength meter reacts to the password', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));
    await settle(tester);

    final password = find.byType(TextField).at(3);
    await tester.enterText(password, 'abc');
    await settle(tester, 3);
    expect(find.text('Weak'), findsOneWidget);

    await tester.enterText(password, 'Harvest#2026');
    await settle(tester, 3);
    expect(find.text('Strong'), findsOneWidget);
  });

  testWidgets('Role screen switches roles and continues', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoleScreen()));
    await settle(tester, 25);

    expect(find.bySemanticsLabel('I am a...'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 3 of 5'), findsOneWidget);
    final volunteer = find.bySemanticsLabel(RegExp('^Volunteer'));
    final coordinator = find.bySemanticsLabel(RegExp('^Coordinator'));
    // Volunteer is chosen to start, as in the design.
    expect(tester.getSemantics(volunteer), isSemantics(isSelected: true));
    expect(tester.getSemantics(coordinator), isSemantics(isSelected: false));
    expect(find.text('Find food drives near you'), findsOneWidget);

    await tester.tap(coordinator);
    await settle(tester, 6);
    expect(tester.getSemantics(coordinator), isSemantics(isSelected: true));
    expect(tester.getSemantics(volunteer), isSemantics(isSelected: false));
    expect(find.text('Set up distribution events'), findsOneWidget);
    expect(find.text('Find food drives near you'), findsNothing);

    // Arrow keys switch back.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await settle(tester, 6);
    expect(tester.getSemantics(volunteer), isSemantics(isSelected: true));

    await tester.tap(find.bySemanticsLabel('Next'));
    await settle(tester, 15);
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);
  });

  testWidgets('Notifications screen allows notifications', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    await settle(tester, 25);

    expect(find.bySemanticsLabel('Stay in the Loop'), findsOneWidget);
    expect(find.bySemanticsLabel('Step 4 of 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Notification bell'), findsOneWidget);
    expect(find.text('Maybe Later'), findsOneWidget);

    await tapVisible(tester, find.bySemanticsLabel('Allow Notifications'));
    await settle(tester, 15);
    expect(find.text('Notifications On'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.bySemanticsLabel('Notifications on'), findsOneWidget);
    expect(find.textContaining("You're in the loop"), findsOneWidget);
    expect(find.byType(VolunteerHomeScreen), findsNothing);
  });

  testWidgets('Maybe Later skips notifications', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    await settle(tester, 25);

    await tapVisible(tester, find.bySemanticsLabel('Maybe Later'));
    await settle(tester, 30);
    expect(find.byType(VolunteerHomeScreen), findsOneWidget);
  });

  testWidgets('Continue after allowing opens the volunteer home', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    await settle(tester, 25);

    await tapVisible(tester, find.bySemanticsLabel('Allow Notifications'));
    await settle(tester, 15);
    await tapVisible(tester, find.bySemanticsLabel('Continue'));
    await settle(tester, 30);
    expect(find.byType(VolunteerHomeScreen), findsOneWidget);
  });

  testWidgets('Coordinators do not get the volunteer home', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoleScreen()));
    await settle(tester, 25);

    await tester.tap(find.bySemanticsLabel(RegExp('^Coordinator')));
    await settle(tester, 6);
    await tester.tap(find.bySemanticsLabel('Next'));
    await settle(tester, 30);
    await tapVisible(tester, find.bySemanticsLabel('Maybe Later'));
    await settle(tester, 15);

    expect(find.byType(VolunteerHomeScreen), findsNothing);
    expect(find.text('The coordinator home is coming soon.'), findsOneWidget);
  });

  testWidgets('Volunteer home shows greeting, numbers and events', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: VolunteerHomeScreen()));
    await settle(tester, 25);

    expect(find.text('Agnibha!'), findsOneWidget);
    expect(find.textContaining('Good '), findsOneWidget);
    expect(find.bySemanticsLabel('12 Events'), findsOneWidget);
    expect(find.bySemanticsLabel('36 Hours'), findsOneWidget);
    expect(find.bySemanticsLabel('5 Communities'), findsOneWidget);
    expect(find.text('Upcoming Events'), findsOneWidget);
    expect(find.text('Community Food Drive'), findsOneWidget);
    expect(find.text('Riverside Center'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Home tab')),
      isSemantics(isSelected: true),
    );

    await tapVisible(tester, find.bySemanticsLabel('Events tab'));
    await settle(tester, 25);
    expect(find.byType(MyEventsScreen), findsOneWidget);
  });

  testWidgets('Explore tab opens Explore, and Home comes back', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VolunteerHomeScreen()));
    await settle(tester, 25);

    await tapVisible(tester, find.bySemanticsLabel('Explore tab'));
    await settle(tester, 25);
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Explore tab')),
      isSemantics(isSelected: true),
    );

    await tapVisible(tester, find.bySemanticsLabel('Home tab'));
    await settle(tester, 15);
    expect(find.byType(ExploreScreen), findsNothing);
    expect(find.byType(VolunteerHomeScreen), findsOneWidget);
  });

  testWidgets('View All on the home opens Explore; Back returns', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: VolunteerHomeScreen()));
    await settle(tester, 25);

    await tapVisible(tester, find.bySemanticsLabel('View All'));
    await settle(tester, 25);
    expect(find.byType(ExploreScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester, 15);
    expect(find.byType(ExploreScreen), findsNothing);
  });

  testWidgets('Explore filters by category', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    await settle(tester, 25);

    expect(find.bySemanticsLabel('Explore'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('All filter')),
      isSemantics(isSelected: true),
    );
    expect(find.text('Community Food Drive'), findsOneWidget);
    expect(find.text('Urban Garden Setup'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Education filter'));
    await settle(tester, 6);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Education filter')),
      isSemantics(isSelected: true),
    );
    expect(find.text('Healthy Eating Workshop'), findsOneWidget);
    expect(find.text('Community Food Drive'), findsNothing);

    await tester.tap(find.bySemanticsLabel('All filter'));
    await settle(tester, 6);
    expect(find.text('Community Food Drive'), findsOneWidget);
  });

  testWidgets('Explore search narrows the list and can be cleared', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    await settle(tester, 25);

    await tester.enterText(find.byType(TextField), 'riverside');
    await settle(tester, 6);
    expect(find.text('Community Food Drive'), findsOneWidget);
    expect(find.text('Food Safety Basics'), findsOneWidget);
    expect(find.text('Urban Garden Setup'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await settle(tester, 6);
    expect(find.text('No events found'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Clear filters'));
    await settle(tester, 6);
    expect(find.text('No events found'), findsNothing);
    expect(find.text('Urban Garden Setup'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('Explore fits a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    await settle(tester, 25);

    expect(find.text('Search events, locations...'), findsOneWidget);
    expect(find.text('Weekend Meal Distribution'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explore fits a laptop', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    await settle(tester, 25);

    expect(find.text('FoodLink'), findsOneWidget);
    expect(find.text('14 events'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping an event in Explore opens its details', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
    await settle(tester, 25);

    await tapVisible(tester, find.text('Urban Garden Setup'));
    await settle(tester, 25);
    expect(find.byType(EventDetailsScreen), findsOneWidget);
    expect(find.text('Sun, 28 Sep 2026'), findsOneWidget);
    expect(find.text('Greenfield Park, Salt Lake'), findsOneWidget);
    expect(find.bySemanticsLabel('30 Beds'), findsOneWidget);
    // Already joined, in the sample plans.
    expect(find.text("You're Going"), findsOneWidget);
    expect(find.text('Setup Crew · First Half'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester, 15);
    expect(find.byType(EventDetailsScreen), findsNothing);
    expect(find.byType(ExploreScreen), findsOneWidget);
  });

  testWidgets('Events on the home open their details', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VolunteerHomeScreen()));
    await settle(tester, 25);

    await tapVisible(tester, find.text('Weekend Meal Packing'));
    await settle(tester, 25);
    expect(find.byType(EventDetailsScreen), findsOneWidget);
    expect(find.text('Hope Kitchen, Kolkata'), findsOneWidget);
  });

  testWidgets('Joining an event counts you in, and you can leave', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailsScreen(event: _event('Weekend Meal Packing')),
      ),
    );
    await settle(tester, 25);

    expect(find.bySemanticsLabel('28 Volunteers'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^28 of 30 spots')), findsOneWidget);

    await tapVisible(tester, find.bySemanticsLabel('Join Event'));
    await settle(tester, 20);
    expect(find.byType(ConfirmJoinScreen), findsOneWidget);
    expect(find.text('Confirm Your Details'), findsOneWidget);
    expect(EventPlans.hasJoined('Weekend Meal Packing'), isFalse);

    await tapVisible(tester, find.bySemanticsLabel('Confirm & Join'));
    await settle(tester, 25);
    expect(find.text('You’re in!'), findsOneWidget);
    expect(EventPlans.hasJoined('Weekend Meal Packing'), isTrue);

    await tapVisible(tester, find.bySemanticsLabel('Back to Event'));
    await settle(tester, 15);
    expect(find.byType(ConfirmJoinScreen), findsNothing);
    expect(find.text("You're Going"), findsOneWidget);
    expect(find.text('Food Packing · Full Event'), findsOneWidget);
    expect(find.bySemanticsLabel('29 Volunteers'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^29 of 30 spots')), findsOneWidget);
    expect(EventPlans.hasJoined('Weekend Meal Packing'), isTrue);

    await tapVisible(tester, find.bySemanticsLabel('Leave event'));
    await settle(tester, 15);
    expect(find.bySemanticsLabel('Join Event'), findsOneWidget);
    expect(find.bySemanticsLabel('28 Volunteers'), findsOneWidget);
    expect(EventPlans.hasJoined('Weekend Meal Packing'), isFalse);
  });

  testWidgets('Confirm Your Details keeps the chosen role, slot and notes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: ConfirmJoinScreen(event: sampleEvents.first)),
    );
    await settle(tester, 20);
    expect(find.bySemanticsLabel('Role: Food Packing'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Time Slot: Full Event (10 AM – 2 PM)'),
      findsOneWidget,
    );

    await tapVisible(tester, find.bySemanticsLabel('Role: Food Packing'));
    await settle(tester, 5);
    await tapVisible(tester, find.bySemanticsLabel('Distribution'));
    await settle(tester, 5);
    expect(find.bySemanticsLabel('Role: Distribution'), findsOneWidget);

    await tapVisible(
      tester,
      find.bySemanticsLabel('Time Slot: Full Event (10 AM – 2 PM)'),
    );
    await settle(tester, 5);
    await tapVisible(
      tester,
      find.bySemanticsLabel('Second Half (12 PM – 2 PM)'),
    );
    await settle(tester, 5);

    await tapVisible(tester, find.bySemanticsLabel('Coming with a friend'));
    await settle(tester, 3);
    await tapVisible(tester, find.bySemanticsLabel('Remind me the day before'));
    await settle(tester, 3);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.bySemanticsLabel('Confirm & Join'));
    await settle(tester, 25);
    final details = EventPlans.detailsFor('Community Food Drive')!;
    expect(details.role.name, 'Distribution');
    expect(details.slot.name, 'Second Half');
    expect(details.notes, 'Coming with a friend');
    expect(details.remind, isFalse);
    expect(tester.takeException(), isNull);
  });

  test('Time slots split each event into halves', () {
    for (final event in sampleEvents) {
      final slots = timeSlotsFor(event);
      expect(slots.map((slot) => slot.name), [
        'Full Event',
        'First Half',
        'Second Half',
      ], reason: event.title);
    }
    expect(
      timeSlotsFor(_event('Food Safety Basics')).map((slot) => slot.range),
      ['2 PM – 4:30 PM', '2 PM – 3:30 PM', '3:30 PM – 4:30 PM'],
    );
  });

  testWidgets('Confirm Your Details fits a laptop', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: ConfirmJoinScreen(event: sampleEvents[5])),
    );
    await settle(tester, 20);
    expect(find.text('What happens next'), findsOneWidget);
    await tapVisible(tester, find.bySemanticsLabel('Role: Participant'));
    await settle(tester, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('The heart saves an event', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EventDetailsScreen(event: sampleEvents.first)),
    );
    await settle(tester, 25);

    await tester.tap(find.bySemanticsLabel('Save event'));
    await settle(tester, 5);
    expect(EventPlans.hasSaved('Community Food Drive'), isTrue);
    expect(find.bySemanticsLabel('Remove from saved'), findsOneWidget);
  });

  testWidgets('Event details fit a phone, for every event', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final event in sampleEvents) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(event.title),
          home: EventDetailsScreen(event: event),
        ),
      );
      await settle(tester, 25);
      expect(find.text(event.title), findsWidgets);
      expect(find.text('What to bring'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Scroll to the end: the title bar takes over from the photo.
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -900),
      );
      await settle(tester, 10);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Event details fit a laptop, and Home leaves them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: VolunteerHomeScreen()));
    await settle(tester, 25);

    await tapVisible(tester, find.bySemanticsLabel('Explore tab'));
    await settle(tester, 25);
    await tapVisible(tester, find.text('Food Safety Basics'));
    await settle(tester, 25);
    expect(find.byType(EventDetailsScreen), findsOneWidget);
    expect(find.text('Organised by'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.bySemanticsLabel('Home tab'));
    await settle(tester, 25);
    expect(find.byType(EventDetailsScreen), findsNothing);
    expect(find.byType(ExploreScreen), findsNothing);
    expect(find.byType(VolunteerHomeScreen), findsOneWidget);
  });

  testWidgets('Volunteer home fits a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: VolunteerHomeScreen()));
    await settle(tester, 25);

    for (final tab in ['Home', 'Explore', 'Community', 'Profile']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(find.text('12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Notifications screen fits a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    await settle(tester, 25);

    expect(find.text('New events'), findsOneWidget);
    expect(find.text('Impact stories'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Events lists upcoming and past events on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MyEventsScreen()));
    await settle(tester, 25);

    expect(find.text('My Events'), findsOneWidget);
    expect(find.bySemanticsLabel('Upcoming events'), findsOneWidget);
    for (final title in [
      'Community Food Drive',
      'Urban Garden Setup',
      'Weekend Meal Distribution',
    ]) {
      expect(find.text(title), findsWidgets);
    }
    expect(find.text('Next up'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Events tab')),
      isSemantics(isSelected: true),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('Past events'));
    await settle(tester, 20);
    expect(find.text('Your impact so far'), findsOneWidget);
    expect(find.bySemanticsLabel('12 Events'), findsOneWidget);
    expect(find.bySemanticsLabel('36 Hours'), findsOneWidget);
    expect(find.text('Monsoon Relief Kits'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Scroll through every past event.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -3000),
    );
    await settle(tester, 10);
    expect(find.text('Environment Day Planting'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A past event opens its recap and certificate', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: MyEventsScreen(showPast: true)),
    );
    await settle(tester, 25);

    await tapVisible(tester, find.text('Seed Swap & Garden Talk'));
    await settle(tester, 10);
    expect(find.text('Attended'), findsOneWidget);
    expect(find.text('— Green Roots Collective'), findsOneWidget);
    await tapVisible(tester, find.bySemanticsLabel('View'));
    await settle(tester, 5);
    expect(find.text('CERTIFICATE OF PARTICIPATION'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The barrier behind the recap is labelled Close too.
    await tester.tap(find.bySemanticsLabel('Close').last);
    await settle(tester, 10);
    expect(find.text('Attended'), findsNothing);
  });

  testWidgets('Leaving an event takes it off My Events', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyEventsScreen()));
    await settle(tester, 25);
    expect(find.text('Shelter Dinner Service'), findsOneWidget);

    await tapVisible(tester, find.text('Shelter Dinner Service'));
    await settle(tester, 25);
    expect(find.byType(EventDetailsScreen), findsOneWidget);
    await tapVisible(tester, find.bySemanticsLabel('Leave event'));
    await settle(tester, 5);
    await tapVisible(tester, find.bySemanticsLabel('Back'));
    await settle(tester, 15);

    expect(find.byType(MyEventsScreen), findsOneWidget);
    expect(find.text('Shelter Dinner Service'), findsNothing);
  });

  testWidgets('My Events fits a laptop', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MyEventsScreen()));
    await settle(tester, 25);
    expect(find.text('FoodLink'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('Past events'));
    await settle(tester, 20);
    await tapVisible(tester, find.text('Kitchen Hygiene Workshop'));
    await settle(tester, 10);
    expect(find.text('Certificate earned'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Community tab opens Community from the home', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VolunteerHomeScreen()));
    await settle(tester, 25);
    await tapVisible(tester, find.bySemanticsLabel('Community tab'));
    await settle(tester, 25);
    expect(find.byType(CommunityScreen), findsOneWidget);
    expect(find.text('Riya Sharma'), findsWidgets);
  });

  testWidgets('Community posts can be liked, commented on and shared', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));
    await settle(tester, 25);
    expect(find.bySemanticsLabel('Posts tab'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Like the first post.
    await tapVisible(tester, find.bySemanticsLabel('Like, 124').first);
    await settle(tester, 5);
    expect(find.bySemanticsLabel('Unlike, 125'), findsOneWidget);
    expect(CommunityFeed.hasLiked('riya-1'), isTrue);

    // Comment on it.
    await tapVisible(tester, find.bySemanticsLabel('Comments, 12').first);
    await settle(tester, 10);
    expect(
      find.text('Such a great team today. Same time next week?'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).last, 'See you there!');
    await tester.tap(find.bySemanticsLabel('Send comment'));
    await settle(tester, 10);
    expect(find.text('See you there!'), findsOneWidget);
    expect(CommunityFeed.byId('riya-1')!.commentCount, 13);
    await tester.tapAt(const Offset(195, 40));
    await settle(tester, 10);

    // Share a post of our own.
    await tapVisible(tester, find.bySemanticsLabel('Share a moment'));
    await settle(tester, 10);
    await tester.enterText(find.byType(TextField).last, 'My first post!');
    await tester.pump();
    await tapVisible(tester, find.bySemanticsLabel('Share post'));
    await settle(tester, 15);
    expect(CommunityFeed.posts.value.first.text, 'My first post!');
    expect(find.text('My first post!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Community stories and impact fit a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));
    await settle(tester, 25);

    await tester.tap(find.bySemanticsLabel('Impact tab'));
    await settle(tester, 25);
    expect(find.bySemanticsLabel('48,250 meals shared'), findsOneWidget);
    expect(find.text('Top volunteers this month'), findsOneWidget);
    await tapVisible(tester, find.bySemanticsLabel('Jun: 5,900 meals'));
    await settle(tester, 5);
    expect(find.text('meals in Jun'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.bySemanticsLabel('Stories tab'));
    await settle(tester, 15);
    await tapVisible(
      tester,
      find.bySemanticsLabel('Story: What I learned in my first 10 events'),
    );
    await settle(tester, 20);
    expect(find.byType(StoryScreen), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -2000),
    );
    await settle(tester, 10);
    expect(find.text('Did this story inspire you?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Community fits a laptop on every tab', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));
    await settle(tester, 25);
    expect(find.text('FoodLink'), findsWidgets);
    expect(find.text('Top volunteers this month'), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final tab in ['Stories tab', 'Impact tab']) {
      await tapVisible(tester, find.bySemanticsLabel(tab));
      await settle(tester, 20);
      expect(tester.takeException(), isNull);
    }
  });
}
