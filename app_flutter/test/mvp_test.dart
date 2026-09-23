import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:clinic_app/application/session_controller.dart';
import 'package:clinic_app/domain/money.dart';
import 'package:clinic_app/infrastructure/api_client.dart';
import 'package:clinic_app/main.dart';

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      final font = FontLoader('Roboto')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '../.tools/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '../.tools/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await icons.load();
    }
  });
  test('Dinheiro é convertido em centavos sem arredondamento binário', () {
    expect(parseCents('150,01'), 15001);
    expect(parseCents('0,10'), 10);
    expect(parseCents('12.5'), 1250);
    expect(() => parseCents('1,001'), throwsFormatException);
    expect(() => parseCents('-1'), throwsFormatException);
    expect(() => parseDate('31/02/2026'), throwsFormatException);
  });

  testWidgets('Registra pagamento parcial e atualiza o saldo visível', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var paid = 0;
    String? operationKey;
    final profile = {
      'user': {'id': 'owner', 'name': 'Pessoa Teste'},
      'organization': {'id': 'tenant', 'name': 'Clínica Teste'},
      'role': 'OWNER',
      'subscription': {'tier': 'ESSENTIAL', 'license': 'FOUNDER'},
      'entitlements': [
        'patients',
        'agenda',
        'attendances',
        'finance',
        'whatsapp',
        'dashboard',
        'reports',
      ],
    };
    final api = ApiClient(
      client: MockClient((request) async {
        dynamic data;
        switch (request.url.path) {
          case '/v1/me':
            data = profile;
          case '/v1/patients':
            data = [
              {
                'id': 'patient',
                'name': 'Paciente Teste',
                'phone': '5511999999999',
                'email': '',
                'active': true,
              },
            ];
          case '/v1/professionals':
            data = [
              {
                'id': 'professional',
                'name': 'Profissional',
                'user_id': 'owner',
                'active': true,
              },
            ];
          case '/v1/services':
            data = [
              {
                'id': 'service',
                'name': 'Consulta',
                'default_price_cents': 15000,
                'active': true,
              },
            ];
          case '/v1/appointments':
            data = [];
          case '/v1/attendances':
            data = [
              {
                'id': 'attendance',
                'patient_name': 'Paciente Teste',
                'service_name': 'Consulta',
                'occurred_at': 1800000000,
                'price_cents': 15000,
                'paid_cents': paid,
                'balance_cents': 15000 - paid,
              },
            ];
          case '/v1/dashboard':
            data = {
              'patients': 1,
              'scheduled': 0,
              'paid_cents': paid,
              'balance_cents': 15000 - paid,
            };
          case '/v1/reports/summary':
            data = {
              'attendances': 1,
              'charged_cents': 15000,
              'received_cents': paid,
              'outstanding_total_cents': 15000 - paid,
            };
          case '/v1/payments':
            final body = jsonDecode(request.body);
            expect(body['amount_cents'], 5000);
            expect(body['attendance_id'], 'attendance');
            operationKey = request.headers['Idempotency-Key'];
            paid += body['amount_cents'] as int;
            data = {'id': 'payment'};
          default:
            throw StateError('Unexpected route: ${request.url.path}');
        }
        return http.Response(
          jsonEncode(data),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    api.token = 'test-token';
    api.tenantId = 'tenant';
    final session = SessionController(api)..profile = profile;
    await tester.pumpWidget(ClinicApp(session: session));
    await tester.pumpAndSettle();
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      await expectLater(
        find.byType(ClinicApp),
        matchesGoldenFile('../../.tools/mvp-dashboard.png'),
      );
    }
    await tester.tap(find.text('Financeiro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar pagamento'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor recebido (R\$)'),
      '50,00',
    );
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(operationKey, isNotNull);
    expect(operationKey!.length, greaterThanOrEqualTo(16));
    expect(find.text('Saldo: R\$ 100,00'), findsOneWidget);
    expect(
      find.text('Valor: R\$ 150,00   Recebido: R\$ 50,00'),
      findsOneWidget,
    );
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      await expectLater(
        find.byType(ClinicApp),
        matchesGoldenFile('../../.tools/mvp-finance-desktop.png'),
      );
    }
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      await expectLater(
        find.byType(ClinicApp),
        matchesGoldenFile('../../.tools/mvp-finance-mobile.png'),
      );
    }
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Configurações'), findsOneWidget);
    await tester.tap(find.text('Pacientes'));
    await tester.pumpAndSettle();
    expect(find.text('Novo paciente'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Novo paciente'));
    await tester.pumpAndSettle();
    expect(
      find.text('Cadastro administrativo. Não inclua informações clínicas.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      await expectLater(
        find.byType(ClinicApp),
        matchesGoldenFile('../../.tools/mvp-editor-mobile.png'),
      );
    }
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    for (final page in [
      'Agenda',
      'Relatórios',
      'Configurações',
      'Visão geral',
    ]) {
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(page).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Layout mobile: $page');
      if (const bool.fromEnvironment('CAPTURE_UI')) {
        await expectLater(
          find.byType(ClinicApp),
          matchesGoldenFile(
            '../../.tools/mvp-mobile-${page.replaceAll(' ', '-')}.png',
          ),
        );
      }
    }
  });
}
