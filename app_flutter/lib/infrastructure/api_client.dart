import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../shared/config.dart';

class ApiException implements Exception {
  final String message;
  final int status;
  const ApiException(this.message, [this.status = 0]);
  @override
  String toString() => message;
}

class ApiClient {
  final http.Client client;
  final String baseUrl;
  String? token;
  String? tenantId;
  void Function()? onUnauthorized;
  ApiClient({http.Client? client, String? baseUrl})
    : baseUrl = baseUrl ?? apiBaseUrl,
      client = client ?? http.Client();

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    final request = http.Request(method, Uri.parse('$baseUrl/v1$path'));
    request.headers.addAll({
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'X-Tenant-ID': ?tenantId,
      'Idempotency-Key': ?idempotencyKey,
    });
    if (body != null) request.body = jsonEncode(body);
    try {
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
      final data = response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 400) {
        if (response.statusCode == 401 && token != null) onUnauthorized?.call();
        throw ApiException(
          data is Map && data['detail'] is String
              ? data['detail']
              : 'Não foi possível concluir a operação.',
          response.statusCode,
        );
      }
      return data;
    } on TimeoutException {
      throw const ApiException(
        'A conexão demorou. Confira os dados antes de tentar novamente.',
      );
    } on http.ClientException {
      throw const ApiException('Sem conexão com o servidor. Tente novamente.');
    } on FormatException {
      throw const ApiException('O servidor retornou uma resposta inválida.');
    }
  }
}
