import 'package:flutter_test/flutter_test.dart';
import 'package:frutgo/main.dart';

void main() {
  testWidgets(
    'Frutgo app loads successfully',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const FrutgoApp(),
      );

      await tester.pumpAndSettle();

      // Login screen should be the initial screen.
      expect(
        find.byType(FrutgoApp),
        findsOneWidget,
      );
    },
  );
}