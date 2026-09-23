import 'package:flutter/material.dart';

import '../domain/money.dart';

class EditField {
  final String keyName;
  final String label;
  final String initial;
  final bool required;
  final String kind;
  final Map<String, String>? choices;
  const EditField(
    this.keyName,
    this.label, {
    this.initial = '',
    this.required = true,
    this.kind = 'text',
    this.choices,
  });
}

Future<bool> editDialog(
  BuildContext context,
  String title,
  List<EditField> fields,
  Future<void> Function(Map<String, String>) save, {
  String? help,
}) async {
  final controllers = {
    for (final field in fields)
      field.keyName: TextEditingController(text: field.initial),
  };
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => PopScope(
        canPop: !busy,
        child: AlertDialog(
          icon: const Icon(Icons.edit_note_rounded),
          title: Text(title),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (help != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(help),
                      ),
                    for (final field in fields)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: field.choices != null
                            ? DropdownButtonFormField<String>(
                                initialValue: field.initial.isEmpty
                                    ? null
                                    : field.initial,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: field.label,
                                ),
                                items: field.choices!.entries
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(
                                          e.value,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: busy
                                    ? null
                                    : (value) =>
                                          controllers[field.keyName]!.text =
                                              value ?? '',
                                validator: (_) =>
                                    controllers[field.keyName]!.text.isEmpty &&
                                        field.required
                                    ? 'Selecione uma opção'
                                    : null,
                              )
                            : TextFormField(
                                controller: controllers[field.keyName],
                                enabled: !busy,
                                maxLines: field.kind == 'message' ? 4 : 1,
                                keyboardType: field.kind == 'money'
                                    ? const TextInputType.numberWithOptions(
                                        decimal: true,
                                      )
                                    : TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: field.label,
                                ),
                                validator: (value) {
                                  final text = value?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return field.required
                                        ? 'Preencha este campo'
                                        : null;
                                  }
                                  try {
                                    if (field.kind == 'money') parseCents(text);
                                    if (field.kind == 'date') parseDate(text);
                                    if (field.kind == 'time') {
                                      parseDate('01/01/2026', text);
                                    }
                                    if (field.kind == 'phone' &&
                                        !RegExp(r'^[1-9][0-9]{9,14}$')
                                            .hasMatch(text)) {
                                      return 'Use país + DDD + número, somente dígitos';
                                    }
                                  } catch (_) {
                                    return 'Confira o formato informado';
                                  }
                                  return null;
                                },
                              ),
                      ),
                    if (error != null)
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      setState(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await save({
                          for (final entry in controllers.entries)
                            entry.key: entry.value.text.trim(),
                        });
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setState(() {
                            busy = false;
                            error = '$e';
                          });
                        }
                      }
                    },
              child: Text(busy ? 'Aguarde…' : 'Confirmar'),
            ),
          ],
        ),
      ),
    ),
  );
  // Dispose after the dialog's exit animation has detached its text fields.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  for (final c in controllers.values) {
    c.dispose();
  }
  return result ?? false;
}
