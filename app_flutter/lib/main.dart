import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'application/session_controller.dart';
import 'infrastructure/api_client.dart';
import 'presentation/auth_screen.dart';
import 'presentation/home_screen.dart';
import 'shared/config.dart';
import 'presentation/design/app_theme.dart';

void main() {
  validateConfiguration();
  runApp(const ClinicApp());
}

class ClinicApp extends StatefulWidget {
  final SessionController? session;
  const ClinicApp({super.key, this.session});
  @override
  State<ClinicApp> createState() => _ClinicAppState();
}

class _ClinicAppState extends State<ClinicApp> {
  late final SessionController session =
      widget.session ?? SessionController(ApiClient());
  @override
  void dispose() {
    if (widget.session == null) {
      session.api.client.close();
      session.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gestão da clínica',
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    debugShowCheckedModeBanner: false,
    theme: AppBrand.theme,
    home: ListenableBuilder(
      listenable: session,
      builder: (context, _) => session.authenticated
          ? HomeScreen(key: ValueKey(session.api.tenantId), session: session)
          : AuthScreen(session: session),
    ),
  );
}
