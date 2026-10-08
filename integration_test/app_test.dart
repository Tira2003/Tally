import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tally/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tally app launches successfully', (tester) async {
    await tester.pumpWidget(const TallyApp());
    await tester.pumpAndSettle();

    expect(find.text('Tally'), findsOneWidget);
  });
}
