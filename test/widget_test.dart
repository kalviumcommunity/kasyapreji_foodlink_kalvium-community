import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink/main.dart';
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
}
