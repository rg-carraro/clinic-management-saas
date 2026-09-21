String money(num cents) =>
    'R\$ ${(cents ~/ 100)},${(cents.toInt().abs() % 100).toString().padLeft(2, '0')}';

int parseCents(String value) {
  final clean = value.trim().replaceAll('.', ',');
  if (!RegExp(r'^\d{1,7}(,\d{1,2})?$').hasMatch(clean)) {
    throw const FormatException('Informe um valor como 150,00');
  }
  final parts = clean.split(',');
  final cents =
      int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  if (cents > 100000000) throw const FormatException('Valor acima do limite');
  return cents;
}

String decimalCents(int cents) =>
    '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';
String dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String timeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
DateTime fromEpoch(dynamic seconds) =>
    DateTime.fromMillisecondsSinceEpoch((seconds as int) * 1000);
DateTime parseDate(String date, [String time = '00:00']) {
  final d = date.split('/').map(int.parse).toList();
  final t = time.split(':').map(int.parse).toList();
  if (d.length != 3 || t.length != 2) {
    throw const FormatException('Data ou horário inválido');
  }
  final result = DateTime(d[2], d[1], d[0], t[0], t[1]);
  if (result.year != d[2] ||
      result.month != d[1] ||
      result.day != d[0] ||
      result.hour != t[0] ||
      result.minute != t[1]) {
    throw const FormatException('Data ou horário inválido');
  }
  return result;
}
