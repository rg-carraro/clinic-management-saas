import 'package:flutter/material.dart';

void main() => runApp(const ClinicApp());

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gestão da clínica',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF126B62),
      useMaterial3: true,
    ),
    home: const Scaffold(body: Center(child: Text('Gestão da clínica'))),
  );
}
