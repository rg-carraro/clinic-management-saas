import 'package:flutter/material.dart';

import '../application/session_controller.dart';

class HomeScreen extends StatelessWidget {
  final SessionController session;
  const HomeScreen({super.key, required this.session});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(session.profile!['organization']['name']),
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await session.logout();
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$error')));
              }
            }
          },
          child: const Text('Sair'),
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, ${session.profile!['user']['name']}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text('Perfil: ${session.profile!['role']}'),
          Text('Plano: ${session.profile!['subscription']['tier']}'),
          const SizedBox(height: 16),
          Text(
            session.features.isEmpty
                ? 'Seu acesso ao plano está inativo. Procure o administrador.'
                : 'Sua clínica está pronta. Recursos disponíveis:',
          ),
          Wrap(
            spacing: 8,
            children: session.features
                .map((feature) => Chip(label: Text(feature)))
                .toList(),
          ),
        ],
      ),
    ),
  );
}
