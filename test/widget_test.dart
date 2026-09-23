import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink/main.dart';

void main() {
  testWidgets('Splash screen shows brand name and taglines', (tester) async {
    await tester.pumpWidget(const FoodLinkApp());

    expect(find.text('FoodLink'), findsOneWidget);
    expect(find.text('Good Food\nBrighter Futures'), findsOneWidget);
    expect(find.text('A Hunger-Free Tomorrow\nStarts With You'), findsOneWidget);
  });
}
