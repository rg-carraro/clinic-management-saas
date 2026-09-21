import 'package:flutter/material.dart';

import 'application/session_controller.dart';
import 'infrastructure/api_client.dart';
import 'presentation/auth_screen.dart';
import 'presentation/home_screen.dart';
import 'shared/config.dart';

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
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF126B62),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F9FA),
    ),
    home: ListenableBuilder(
      listenable: session,
      builder: (context, _) => session.authenticated
          ? HomeScreen(key: ValueKey(session.api.tenantId), session: session)
          : AuthScreen(session: session),
    ),
  );
}
