import 'package:flutter_test/flutter_test.dart';
import 'package:vidur/main.dart';

void main() {
  testWidgets('VIDUR smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VidurApp());
    expect(find.text('VIDUR'), findsOneWidget);
  });
}
