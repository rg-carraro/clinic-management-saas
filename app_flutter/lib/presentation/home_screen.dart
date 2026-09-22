import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/clinic_repository.dart';
import '../application/session_controller.dart';
import '../domain/money.dart';
import 'editor.dart';

class HomeScreen extends StatefulWidget {
  final SessionController session;
  const HomeScreen({super.key, required this.session});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final repository = ClinicRepository(widget.session.api);
  int selected = 0;
  bool loading = true;
  String? error;
  String search = '';
  DateTime day = DateTime.now();
  List<Map<String, dynamic>> patients = [],
      appointments = [],
      attendances = [],
      professionals = [],
      services = [],
      members = [];
  Map<String, dynamic> dashboard = {}, report = {};
  DateTime reportStart = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime reportEnd = DateTime(DateTime.now().year, DateTime.now().month + 1);
  final labels = [
    'Visão geral',
    'Pacientes',
    'Agenda',
    'Financeiro',
    'Relatórios',
    'Configurações',
  ];
  final icons = [
    Icons.dashboard_outlined,
    Icons.people_outline,
    Icons.calendar_month_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.bar_chart,
    Icons.settings_outlined,
  ];
  SessionController get session => widget.session;
  bool get manager => ['OWNER', 'ADMIN'].contains(session.profile?['role']);
  bool get canComplete =>
      ['OWNER', 'ADMIN', 'PROFESSIONAL'].contains(session.profile?['role']);
  bool has(String feature) => session.features.contains(feature);
  int epoch(DateTime date) => date.millisecondsSinceEpoch ~/ 1000;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await session.reload();
      if (!mounted) return;
      final start = DateTime(day.year, day.month, day.day);
      final data = await Future.wait<dynamic>([
        has('patients')
            ? repository.all('/patients')
            : Future.value(<Map<String, dynamic>>[]),
        has('agenda')
            ? repository.all(
                '/appointments?start=${epoch(start)}&end=${epoch(start.add(const Duration(days: 1)))}',
              )
            : Future.value(<Map<String, dynamic>>[]),
        has('finance')
            ? repository.all('/attendances')
            : Future.value(<Map<String, dynamic>>[]),
        has('agenda')
            ? session.api.request('GET', '/professionals')
            : Future.value([]),
        has('agenda')
            ? session.api.request('GET', '/services')
            : Future.value([]),
        has('dashboard')
            ? session.api.request('GET', '/dashboard')
            : Future.value(<String, dynamic>{}),
        has('reports')
            ? session.api.request(
                'GET',
                '/reports/summary?start=${epoch(reportStart)}&end=${epoch(reportEnd)}',
              )
            : Future.value(<String, dynamic>{}),
        has('team') && manager
            ? session.api.request('GET', '/members')
            : Future.value([]),
      ]);
      if (!mounted) return;
      setState(() {
        patients = List<Map<String, dynamic>>.from(data[0]);
        appointments = List<Map<String, dynamic>>.from(data[1]);
        attendances = List<Map<String, dynamic>>.from(data[2]);
        professionals = List<Map<String, dynamic>>.from(data[3]);
        services = List<Map<String, dynamic>>.from(data[4]);
        dashboard = Map<String, dynamic>.from(data[5]);
        report = Map<String, dynamic>.from(data[6]);
        members = List<Map<String, dynamic>>.from(data[7]);
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> action(Future<void> Function() work) async {
    try {
      await work();
      if (mounted) await load();
    } catch (e) {
      notice('$e');
    }
  }

  Future<void> edit(
    String title,
    List<EditField> fields,
    Future<void> Function(Map<String, String>) save, {
    String? help,
  }) async {
    final saved = await editDialog(context, title, fields, save, help: help);
    if (saved && mounted) await load();
  }

  Future<void> patientEditor([Map<String, dynamic>? patient]) => edit(
    patient == null ? 'Novo paciente' : 'Editar cadastro',
    [
      EditField('name', 'Nome', initial: patient?['name'] ?? ''),
      EditField(
        'phone',
        'WhatsApp (ex.: 5511999999999)',
        initial: patient?['phone'] ?? '',
        required: false,
        kind: 'phone',
      ),
      EditField(
        'email',
        'E-mail',
        initial: patient?['email'] ?? '',
        required: false,
      ),
      if (patient != null)
        EditField(
          'active',
          'Cadastro',
          initial: '${patient['active']}',
          choices: const {'true': 'Ativo', 'false': 'Arquivado'},
        ),
    ],
    (values) async {
      await session.api.request(
        patient == null ? 'POST' : 'PATCH',
        patient == null ? '/patients' : '/patients/${patient['id']}',
        body: {
          'name': values['name'],
          'phone': values['phone'],
          'email': values['email'],
          'active': values['active'] != 'false',
        },
      );
    },
    help: 'Cadastro administrativo. Não inclua informações clínicas.',
  );

  Future<void> serviceEditor([Map<String, dynamic>? service]) => edit(
    service == null ? 'Novo serviço' : 'Editar serviço',
    [
      EditField('name', 'Nome do serviço', initial: service?['name'] ?? ''),
      EditField(
        'price',
        'Valor padrão (R\$)',
        initial: decimalCents(service?['default_price_cents'] ?? 0),
        kind: 'money',
      ),
      if (service != null)
        EditField(
          'active',
          'Disponibilidade',
          initial: '${service['active']}',
          choices: const {'true': 'Ativo', 'false': 'Arquivado'},
        ),
    ],
    (v) async {
      await session.api.request(
        service == null ? 'POST' : 'PATCH',
        service == null ? '/services' : '/services/${service['id']}',
        body: {
          'name': v['name'],
          'default_price_cents': parseCents(v['price']!),
          'active': v['active'] != 'false',
        },
      );
    },
    help: 'Alterar o padrão não modifica valores de agendamentos e atendimentos existentes.',
  );

  Future<void> professionalEditor() => edit(
    'Cadastrar profissional',
    [
      const EditField('name', 'Nome do profissional'),
      if (has('team'))
        EditField(
          'user_id',
          'Conta vinculada',
          initial: session.profile!['user']['id'],
          choices: {
            for (final m in members.where(
              (m) => m['active'] == true && m['role'] != 'STAFF',
            ))
              m['user_id']: m['name'],
          },
        ),
    ],
    (v) async {
      await session.api.request(
        'POST',
        '/professionals',
        body: {
          'name': v['name'],
          if (v['user_id'] != null) 'user_id': v['user_id'],
        },
      );
    },
    help: 'O Essencial permite uma agenda. Múltiplas agendas exigem Pro.',
  );

  Future<void> appointmentEditor([Map<String, dynamic>? item]) async {
    final activePatients = patients.where((p) => p['active'] == true).toList();
    final activeServices = services.where((p) => p['active'] == true).toList();
    final allowedProfessionals = professionals
        .where(
          (p) =>
              p['active'] == true &&
              (session.profile!['role'] != 'PROFESSIONAL' ||
                  p['user_id'] == session.profile!['user']['id']),
        )
        .toList();
    if (activePatients.isEmpty ||
        activeServices.isEmpty ||
        allowedProfessionals.isEmpty) {
      notice(
        'Cadastre um paciente, um serviço e um profissional em Configurações.',
      );
      return;
    }
    final start = item == null
        ? DateTime(day.year, day.month, day.day, 9)
        : fromEpoch(item['starts_at']);
    final end = item == null
        ? start.add(const Duration(hours: 1))
        : fromEpoch(item['ends_at']);
    await edit(
      item == null ? 'Novo agendamento' : 'Reagendar',
      [
        EditField(
          'patient_id',
          'Paciente',
          initial: item?['patient_id'] ?? activePatients.first['id'],
          choices: {for (final p in activePatients) p['id']: p['name']},
        ),
        EditField(
          'professional_id',
          'Profissional',
          initial: item?['professional_id'] ?? allowedProfessionals.first['id'],
          choices: {for (final p in allowedProfessionals) p['id']: p['name']},
        ),
        EditField(
          'service_id',
          'Serviço',
          initial: item?['service_id'] ?? activeServices.first['id'],
          choices: {
            for (final s in activeServices)
              s['id']: '${s['name']} • ${money(s['default_price_cents'])}',
          },
        ),
        EditField(
          'date',
          'Data (DD/MM/AAAA)',
          initial: dateLabel(start),
          kind: 'date',
        ),
        EditField(
          'start',
          'Início (HH:MM)',
          initial: timeLabel(start),
          kind: 'time',
        ),
        EditField('end', 'Fim (HH:MM)', initial: timeLabel(end), kind: 'time'),
        EditField(
          'price',
          'Valor individual (R\$)',
          initial: item == null ? '' : decimalCents(item['price_cents']),
          kind: 'money',
          required: false,
        ),
      ],
      (v) async {
        await session.api.request(
          item == null ? 'POST' : 'PATCH',
          item == null ? '/appointments' : '/appointments/${item['id']}',
          body: {
            'patient_id': v['patient_id'],
            'professional_id': v['professional_id'],
            'service_id': v['service_id'],
            'starts_at': parseDate(
              v['date']!,
              v['start']!,
            ).toUtc().toIso8601String(),
            'ends_at': parseDate(
              v['date']!,
              v['end']!,
            ).toUtc().toIso8601String(),
            if (v['price']!.isNotEmpty) 'price_cents': parseCents(v['price']!),
          },
        );
      },
      help: 'Deixe o valor vazio para usar o padrão do serviço. Horários no fuso deste dispositivo.',
    );
  }

  Future<void> complete(Map<String, dynamic> item) => edit(
    'Concluir atendimento',
    [
      EditField(
        'price',
        'Valor deste atendimento (R\$)',
        initial: decimalCents(item['price_cents']),
        kind: 'money',
      ),
    ],
    (v) async {
      await session.api.request(
        'POST',
        '/appointments/${item['id']}/complete',
        body: {'price_cents': parseCents(v['price']!)},
      );
    },
    help: 'O valor ficará no histórico financeiro. Confira antes de confirmar.',
  );

  Future<void> receive(Map<String, dynamic> record) async {
    final key = List.generate(
      24,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await edit(
      'Registrar pagamento',
      [
        EditField(
          'amount',
          'Valor recebido (R\$)',
          initial: decimalCents(record['balance_cents']),
          kind: 'money',
        ),
        const EditField(
          'method',
          'Forma de pagamento',
          initial: 'PIX',
          choices: {
            'PIX': 'Pix',
            'CASH': 'Dinheiro',
            'CARD': 'Cartão',
            'TRANSFER': 'Transferência',
          },
        ),
      ],
      (v) async {
        await session.api.request(
          'POST',
          '/payments',
          body: {
            'attendance_id': record['id'],
            'amount_cents': parseCents(v['amount']!),
            'method': v['method'],
          },
          idempotencyKey: key,
        );
      },
      help:
          'Saldo: ${money(record['balance_cents'])}. Registre apenas pagamentos efetivamente recebidos.',
    );
  }

  Future<void> showPayments(Map<String, dynamic> record) async {
    try {
      final rows = List<Map<String, dynamic>>.from(
        await session.api.request(
          'GET',
          '/payments?attendance_id=${record['id']}',
        ),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pagamentos registrados'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: rows.isEmpty
                    ? [const Text('Nenhum pagamento registrado.')]
                    : rows
                          .map(
                            (p) => ListTile(
                              title: Text(money(p['amount_cents'])),
                              subtitle: Text(
                                '${p['method']} • ${dateLabel(fromEpoch(p['received_at']))}',
                              ),
                            ),
                          )
                          .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      notice('$e');
    }
  }

  Future<void> whatsapp(Map<String, dynamic> patient, String kind) async {
    try {
      final data = await session.api.request(
        'GET',
        '/patients/${patient['id']}/whatsapp?kind=$kind',
      );
      if (!mounted) return;
      await editDialog(
        context,
        'Preparar WhatsApp',
        [
          EditField(
            'message',
            'Mensagem',
            initial: data['message'],
            kind: 'message',
          ),
        ],
        (v) async {
          final uri = Uri.https('wa.me', '/${data['phone']}', {
            'text': v['message']!,
          });
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            throw Exception('Não foi possível abrir o WhatsApp.');
          }
        },
        help: 'Revise a mensagem. Não inclua dados clínicos. O envio será feito manualmente por você no WhatsApp.',
      );
    } catch (e) {
      notice('$e');
    }
  }

  Widget heading(String title, {String? subtitle, Widget? action}) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null) Text(subtitle),
          ],
        ),
        ?action,
      ],
    ),
  );
  Widget empty(String text) => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(child: Text(text, textAlign: TextAlign.center)),
  );
  Widget tileCard(Widget child) => SizedBox(
    width: double.infinity,
    child: Card(margin: const EdgeInsets.only(bottom: 12), child: child),
  );
  Widget metric(String title, String value, IconData icon) => SizedBox(
    width: 240,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(title),
          ],
        ),
      ),
    ),
  );

  Widget overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Sua clínica, em dia',
        subtitle: 'Resumo administrativo e financeiro',
      ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          metric(
            'Pacientes ativos',
            '${dashboard['patients'] ?? 0}',
            Icons.people_outline,
          ),
          metric(
            'Agendamentos futuros',
            '${dashboard['scheduled'] ?? 0}',
            Icons.event_outlined,
          ),
          metric(
            'Recebido acumulado',
            money(dashboard['paid_cents'] ?? 0),
            Icons.payments_outlined,
          ),
          metric(
            'Saldo em aberto',
            money(dashboard['balance_cents'] ?? 0),
            Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
      const SizedBox(height: 24),
      tileCard(
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Comece por Configurações: cadastre seu profissional e os serviços. Depois, cadastre pacientes e organize a agenda. Concluir um atendimento gera o valor a receber.',
          ),
        ),
      ),
    ],
  );

  Widget patientPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Pacientes',
        subtitle: 'Cadastro administrativo',
        action: FilledButton.icon(
          onPressed: () => patientEditor(),
          icon: const Icon(Icons.add),
          label: const Text('Novo paciente'),
        ),
      ),
      TextField(
        decoration: const InputDecoration(
          labelText: 'Buscar pelo nome',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (v) => setState(() => search = v),
      ),
      const SizedBox(height: 20),
      if (patients.isEmpty) empty('Cadastre o primeiro paciente para começar.'),
      for (final p in patients.where(
        (p) =>
            (p['name'] as String).toLowerCase().contains(search.toLowerCase()),
      ))
        tileCard(
          ListTile(
            leading: CircleAvatar(
              child: Text((p['name'] as String).substring(0, 1).toUpperCase()),
            ),
            title: Text(p['name']),
            subtitle: Text(
              '${p['active'] ? 'Ativo' : 'Arquivado'} • ${p['phone'].isEmpty ? 'Sem telefone' : p['phone']}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (choice) {
                if (choice == 'edit') {
                  patientEditor(p);
                } else {
                  whatsapp(p, choice);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Editar / arquivar'),
                ),
                if (has('whatsapp')) ...[
                  const PopupMenuItem(
                    value: 'balance',
                    child: Text('WhatsApp: saldo'),
                  ),
                  const PopupMenuItem(
                    value: 'reminder',
                    child: Text('WhatsApp: lembrete'),
                  ),
                ],
              ],
            ),
          ),
        ),
    ],
  );

  Widget agendaPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Agenda',
        subtitle: 'Horários no fuso do dispositivo',
        action: FilledButton.icon(
          onPressed: () => appointmentEditor(),
          icon: const Icon(Icons.add),
          label: const Text('Agendar'),
        ),
      ),
      Row(
        children: [
          IconButton(
            onPressed: () {
              day = day.subtract(const Duration(days: 1));
              load();
            },
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Dia anterior',
          ),
          TextButton(
            onPressed: () async {
              final chosen = await showDatePicker(
                context: context,
                initialDate: day,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (chosen != null) {
                day = chosen;
                await load();
              }
            },
            child: Text(dateLabel(day)),
          ),
          IconButton(
            onPressed: () {
              day = day.add(const Duration(days: 1));
              load();
            },
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próximo dia',
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (appointments.isEmpty) empty('Nenhum agendamento neste dia.'),
      for (final a in appointments)
        tileCard(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${timeLabel(fromEpoch(a['starts_at']))} – ${timeLabel(fromEpoch(a['ends_at']))} • ${a['patient_name']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${a['service_name']} • ${a['professional_name']} • ${money(a['price_cents'])}',
                ),
                Text(
                  const {
                    'SCHEDULED': 'Agendado',
                    'COMPLETED': 'Concluído',
                    'CANCELED': 'Cancelado',
                  }[a['status']]!,
                ),
                if (a['status'] == 'SCHEDULED')
                  Wrap(
                    spacing: 8,
                    children: [
                      if (canComplete)
                        FilledButton.tonal(
                          onPressed: () => complete(a),
                          child: const Text('Concluir atendimento'),
                        ),
                      TextButton(
                        onPressed: () => appointmentEditor(a),
                        child: const Text('Reagendar'),
                      ),
                      TextButton(
                        onPressed: () => edit('Cancelar agendamento', [], (
                          _,
                        ) async {
                          await session.api.request(
                            'POST',
                            '/appointments/${a['id']}/cancel',
                          );
                        }, help: 'Confirma o cancelamento deste agendamento?'),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget financePage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Financeiro',
        subtitle: 'Valores históricos e pagamentos por atendimento',
      ),
      if (attendances.isEmpty)
        empty(
          'Conclua um atendimento na agenda para registrar valores e pagamentos.',
        ),
      for (final a in attendances)
        tileCard(
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a['patient_name'],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${dateLabel(fromEpoch(a['occurred_at']))} • ${a['service_name']}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Valor: ${money(a['price_cents'])}   Recebido: ${money(a['paid_cents'])}',
                ),
                Text(
                  'Saldo: ${money(a['balance_cents'])}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (a['balance_cents'] > 0)
                      FilledButton.tonal(
                        onPressed: () => receive(a),
                        child: const Text('Registrar pagamento'),
                      ),
                    TextButton(
                      onPressed: () => showPayments(a),
                      child: const Text('Ver pagamentos'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget reportsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Relatório básico',
        subtitle:
            '${dateLabel(reportStart)} até ${dateLabel(reportEnd.subtract(const Duration(days: 1)))}',
        action: OutlinedButton(
          onPressed: () => edit(
            'Período do relatório',
            [
              EditField(
                'start',
                'Início (DD/MM/AAAA)',
                initial: dateLabel(reportStart),
                kind: 'date',
              ),
              EditField(
                'end',
                'Fim (DD/MM/AAAA)',
                initial: dateLabel(reportEnd.subtract(const Duration(days: 1))),
                kind: 'date',
              ),
            ],
            (v) async {
              final start = parseDate(v['start']!);
              final end = parseDate(v['end']!).add(const Duration(days: 1));
              if (end.difference(start).inDays < 1 ||
                  end.difference(start).inDays > 366) {
                throw Exception('Use um período de até 366 dias.');
              }
              reportStart = start;
              reportEnd = end;
            },
          ),
          child: const Text('Alterar período'),
        ),
      ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          metric(
            'Atendimentos no período',
            '${report['attendances'] ?? 0}',
            Icons.event_available,
          ),
          metric(
            'Valores por data do atendimento',
            money(report['charged_cents'] ?? 0),
            Icons.receipt_long_outlined,
          ),
          metric(
            'Recebido por data do pagamento',
            money(report['received_cents'] ?? 0),
            Icons.payments_outlined,
          ),
          metric(
            'Saldo total (todos os períodos)',
            money(report['outstanding_total_cents'] ?? 0),
            Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: () async {
          final csv =
              'inicio;fim;atendimentos;valores_centavos;recebido_centavos;saldo_total_centavos\n${dateLabel(reportStart)};${dateLabel(reportEnd.subtract(const Duration(days: 1)))};${report['attendances']};${report['charged_cents']};${report['received_cents']};${report['outstanding_total_cents']}';
          await Clipboard.setData(ClipboardData(text: csv));
          notice('Resumo CSV copiado. Cole em uma planilha.');
        },
        icon: const Icon(Icons.copy),
        label: const Text('Copiar resumo CSV'),
      ),
    ],
  );

  Widget settingsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'Configurações',
        subtitle:
            '${session.profile!['role']} • ${session.profile!['subscription']['tier']}',
      ),
      Text(
        session.profile!['subscription']['license'] == 'TRIAL'
            ? 'Trial até ${dateLabel(fromEpoch(session.profile!['subscription']['trial_ends_at']))}'
            : 'Licença: ${session.profile!['subscription']['license']}',
      ),
      const SizedBox(height: 24),
      heading(
        'Profissionais',
        action: manager
            ? OutlinedButton.icon(
                onPressed: professionalEditor,
                icon: const Icon(Icons.add),
                label: const Text('Profissional'),
              )
            : null,
      ),
      if (professionals.isEmpty)
        empty('Cadastre seu profissional para abrir a agenda.'),
      for (final p in professionals)
        tileCard(
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(p['name']),
          ),
        ),
      const SizedBox(height: 24),
      heading(
        'Serviços',
        action: manager
            ? OutlinedButton.icon(
                onPressed: () => serviceEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Serviço'),
              )
            : null,
      ),
      if (services.isEmpty) empty('Cadastre o serviço e seu valor padrão.'),
      for (final s in services)
        tileCard(
          ListTile(
            title: Text(s['name']),
            subtitle: Text(
              '${money(s['default_price_cents'])}${s['active'] ? '' : ' • Arquivado'}',
            ),
            trailing: manager
                ? IconButton(
                    onPressed: () => serviceEditor(s),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar serviço',
                  )
                : null,
          ),
        ),
      if (has('team') && manager) ...[
        const SizedBox(height: 24),
        heading(
          'Equipe',
          action: OutlinedButton(
            onPressed: () => edit(
              'Adicionar acesso',
              [
                const EditField('email', 'E-mail de uma conta existente'),
                EditField(
                  'role',
                  'Perfil',
                  initial: 'PROFESSIONAL',
                  choices: {
                    if (session.profile!['role'] == 'OWNER')
                      'ADMIN': 'Administrador',
                    'PROFESSIONAL': 'Profissional',
                    'STAFF': 'Recepção',
                  },
                ),
              ],
              (v) async {
                await session.api.request(
                  'POST',
                  '/members',
                  body: {'email': v['email'], 'role': v['role']},
                );
              },
            ),
            child: const Text('Adicionar pessoa'),
          ),
        ),
        for (final m in members)
          tileCard(
            ListTile(
              title: Text(m['name']),
              subtitle: Text(
                '${m['role']} • ${m['active'] ? 'Ativo' : 'Inativo'}',
              ),
              trailing: m['role'] != 'OWNER' && m['active'] == true
                  ? IconButton(
                      tooltip: 'Revogar acesso',
                      icon: const Icon(Icons.person_off_outlined),
                      onPressed: () => edit('Revogar acesso', [], (_) async {
                        await session.api.request(
                          'POST',
                          '/members/${m['id']}/deactivate',
                        );
                      }, help: 'Confirma a revogação de acesso à clínica?'),
                    )
                  : null,
            ),
          ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final features = [
      'dashboard',
      'patients',
      'agenda',
      'finance',
      'reports',
      'agenda',
    ];
    final available = [
      for (var i = 0; i < labels.length; i++)
        if (has(features[i])) i,
    ];
    if (!available.contains(selected) && available.isNotEmpty) {
      selected = available.first;
    }
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = [
      overview,
      patientPage,
      agendaPage,
      financePage,
      reportsPage,
      settingsPage,
    ];
    final content = loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: load,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          )
        : available.isEmpty
        ? empty(
            'Seu plano está inativo. Entre em contato com o administrador para continuar.',
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 32 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: pages[selected](),
              ),
            ),
          );
    return Scaffold(
      appBar: AppBar(
        title: Text(session.profile!['organization']['name']),
        actions: [
          if (session.organizations.length > 1)
            PopupMenuButton<String>(
              tooltip: 'Trocar clínica',
              icon: const Icon(Icons.business_outlined),
              onSelected: (id) async {
                try {
                  await session.switchTenant(id);
                } catch (e) {
                  notice('$e');
                }
              },
              itemBuilder: (_) => session.organizations
                  .map(
                    (o) => PopupMenuItem<String>(
                      value: o['id'],
                      child: Text(o['name']),
                    ),
                  )
                  .toList(),
            ),
          IconButton(
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
          TextButton(
            onPressed: () async {
              try {
                await session.logout();
              } catch (e) {
                notice('$e');
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide && available.length > 1)
            NavigationRail(
              extended: true,
              selectedIndex: available.indexOf(selected),
              onDestinationSelected: loading
                  ? null
                  : (index) => setState(() => selected = available[index]),
              destinations: available
                  .map(
                    (i) => NavigationRailDestination(
                      icon: Icon(icons[i]),
                      label: Text(labels[i]),
                    ),
                  )
                  .toList(),
            ),
          Expanded(child: content),
        ],
      ),
      drawer: !wide && available.isNotEmpty
          ? NavigationDrawer(
              selectedIndex: available.indexOf(selected),
              onDestinationSelected: (index) {
                if (loading) return;
                setState(() => selected = available[index]);
                Navigator.pop(context);
              },
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 28, 20, 20),
                  child: Text('Gestão da clínica'),
                ),
                for (final i in available)
                  NavigationDrawerDestination(
                    icon: Icon(icons[i]),
                    label: Text(labels[i]),
                  ),
              ],
            )
          : null,
    );
  }
}
