import 'package:flutter/material.dart';

import '../application/session_controller.dart';

class AuthScreen extends StatefulWidget {
  final SessionController session;
  const AuthScreen({super.key, required this.session});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final organization = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final code = TextEditingController();
  String mode = 'login';
  String? message;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final reset = Uri.base.queryParameters['reset'];
    if (reset != null) {
      mode = 'reset';
      code.text = reset;
    }
  }

  @override
  void dispose() {
    for (final controller in [name, organization, email, password, code]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (mode == 'forgot') {
        await widget.session.api.request(
          'POST',
          '/auth/password/forgot',
          body: {'email': email.text.trim()},
        );
        if (mounted) {
          setState(() {
            message = 'Se o e-mail estiver cadastrado, enviaremos um código. Confira sua caixa de entrada.';
            mode = 'reset';
          });
        }
      } else if (mode == 'reset') {
        await widget.session.api.request(
          'POST',
          '/auth/password/reset',
          body: {'token': code.text.trim(), 'password': password.text},
        );
        if (mounted) {
          setState(() {
            mode = 'login';
            message = 'Senha atualizada. Entre novamente.';
            password.clear();
          });
        }
      } else {
        await widget.session.authenticate(mode == 'register', {
          'email': email.text.trim(),
          'password': password.text,
          if (mode == 'register') 'name': name.text.trim(),
          if (mode == 'register') 'organization_name': organization.text.trim(),
        });
      }
    } catch (error) {
      if (mounted) setState(() => message = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    String label,
    TextEditingController controller, {
    bool secret = false,
    bool isEmail = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      obscureText: secret,
      enabled: !busy,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      autocorrect: !secret && !isEmail,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Preencha este campo';
        if (secret && value.length < 12) return 'Use pelo menos 12 caracteres';
        if (isEmail && !value.contains('@')) return 'Informe um e-mail válido';
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final title = switch (mode) {
      'register' => 'Crie sua clínica',
      'forgot' => 'Recuperar acesso',
      'reset' => 'Nova senha',
      _ => 'Bem-vindo de volta',
    };
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gestão da clínica',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (mode == 'register') ...[
                    field('Seu nome', name),
                    field('Nome da clínica', organization),
                  ],
                  if (mode != 'reset') field('E-mail', email, isEmail: true),
                  if (mode == 'reset')
                    field('Código recebido por e-mail', code),
                  if (mode != 'forgot') field('Senha', password, secret: true),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(message!, semanticsLabel: message),
                    ),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        busy
                            ? 'Aguarde…'
                            : switch (mode) {
                                'register' => 'Criar conta • 7 dias grátis',
                                'forgot' => 'Enviar código',
                                'reset' => 'Atualizar senha',
                                _ => 'Entrar',
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (mode == 'login') ...[
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              mode = 'register';
                              message = null;
                            }),
                      child: const Text('Criar uma conta'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              mode = 'forgot';
                              message = null;
                            }),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ] else
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              mode = 'login';
                              message = null;
                            }),
                      child: const Text('Voltar para entrar'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
