import 'package:flutter_test/flutter_test.dart';
import 'package:tally/main.dart';

void main() {
  testWidgets('Tally app starts', (tester) async {
    await tester.pumpWidget(const TallyApp());

    expect(find.text('Tally'), findsOneWidget);
  });
}
