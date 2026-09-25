import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink/auth/demo_account.dart';
import 'package:foodlink/main.dart';
import 'package:foodlink/screens/change_screen.dart';
import 'package:foodlink/screens/impact_screen.dart';
import 'package:foodlink/screens/onboarding_screen.dart';
import 'package:foodlink/screens/role_screen.dart';
import 'package:foodlink/screens/sign_in_screen.dart';
import 'package:foodlink/screens/sign_up_screen.dart';
import 'package:foodlink/widgets/primary_button.dart';

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
    await settle(tester, 5);
    expect(
      find.textContaining("You're joining as a Volunteer"),
      findsOneWidget,
    );
  });
}
