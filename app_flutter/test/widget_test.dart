import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_app/main.dart';

void main() {
  testWidgets('Apresenta o aplicativo', (tester) async {
    await tester.pumpWidget(const ClinicApp());
    expect(find.text('Gestão da clínica'), findsOneWidget);
  });
}
