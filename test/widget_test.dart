import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink/main.dart';
import 'package:foodlink/screens/change_screen.dart';
import 'package:foodlink/screens/impact_screen.dart';
import 'package:foodlink/screens/onboarding_screen.dart';

void main() {
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
}
