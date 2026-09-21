import '../infrastructure/api_client.dart';

class ClinicRepository {
  final ApiClient api;
  ClinicRepository(this.api);

  Future<List<Map<String, dynamic>>> all(String path) async {
    final result = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += 100) {
      final separator = path.contains('?') ? '&' : '?';
      final rows = List<Map<String, dynamic>>.from(
        await api.request('GET', '$path${separator}limit=100&offset=$offset'),
      );
      result.addAll(rows);
      if (rows.length < 100) return result;
    }
  }
}
