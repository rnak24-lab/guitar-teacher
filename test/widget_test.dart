import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_teacher/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const GuitarTeacherApp());
    expect(find.text('Guitar Teacher 🎸'), findsOneWidget);
  });
}
