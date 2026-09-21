import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:clinic_app/application/session_controller.dart';
import 'package:clinic_app/infrastructure/api_client.dart';
import 'package:clinic_app/main.dart';

void main() {
  testWidgets('Valida formulário antes de enviar', (tester) async {
    await tester.pumpWidget(const ClinicApp());
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Preencha este campo'), findsNWidgets(2));
    await tester.tap(find.text('Criar uma conta'));
    await tester.pump();
    expect(find.text('Nome da clínica'), findsOneWidget);
  });

  test('Sessão utiliza tenant e limpa token quando revogada', () async {
    late SessionController session;
    final api = ApiClient(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          return http.Response(
            jsonEncode({
              'access_token': 'token',
              'organizations': [
                {'id': 'tenant', 'name': 'Clinic'},
              ],
            }),
            200,
          );
        }
        expect(request.headers['Authorization'], 'Bearer token');
        expect(request.headers['X-Tenant-ID'], 'tenant');
        return http.Response(jsonEncode({'detail': 'Sessão expirada'}), 401);
      }),
    );
    session = SessionController(api);
    await expectLater(
      session.authenticate(false, {
        'email': 'x@example.com',
        'password': 'test',
      }),
      throwsA(isA<ApiException>()),
    );
    expect(api.token, isNull);
    expect(session.authenticated, isFalse);
  });
}
