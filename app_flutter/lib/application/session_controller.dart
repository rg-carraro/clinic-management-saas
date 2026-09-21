import 'package:flutter/foundation.dart';

import '../infrastructure/api_client.dart';

class SessionController extends ChangeNotifier {
  final ApiClient api;
  Map<String, dynamic>? profile;
  List<dynamic> organizations = [];
  SessionController(this.api) {
    api.onUnauthorized = clear;
  }
  bool get authenticated => profile != null;
  List<String> get features =>
      List<String>.from(profile?['entitlements'] ?? []);

  Future<void> authenticate(bool register, Map<String, dynamic> fields) async {
    final data = await api.request(
      'POST',
      register ? '/auth/register' : '/auth/login',
      body: fields,
    );
    api.token = data['access_token'];
    organizations = data['organizations'];
    if (organizations.isEmpty) {
      clear();
      throw const ApiException('Nenhuma organização disponível.');
    }
    api.tenantId = organizations.first['id'];
    try {
      await reload();
    } catch (_) {
      clear();
      rethrow;
    }
  }

  Future<void> reload() async {
    profile = Map<String, dynamic>.from(await api.request('GET', '/me'));
    notifyListeners();
  }

  Future<void> switchTenant(String id) async {
    final old = api.tenantId;
    api.tenantId = id;
    try {
      await reload();
    } catch (_) {
      api.tenantId = old;
      rethrow;
    }
  }

  Future<void> logout() async {
    await api.request('POST', '/auth/logout');
    clear();
  }

  void clear() {
    api.token = null;
    api.tenantId = null;
    profile = null;
    organizations = [];
    notifyListeners();
  }
}
