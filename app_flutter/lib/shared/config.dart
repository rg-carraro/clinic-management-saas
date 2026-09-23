import 'package:flutter/foundation.dart';

const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
final apiBaseUrl = _configuredApiBaseUrl.isNotEmpty
    ? _configuredApiBaseUrl
    : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
    ? 'http://10.0.2.2:8000'
    : 'http://localhost:8000';
const appEnvironment = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

void validateConfiguration() {
  final uri = Uri.parse(apiBaseUrl);
  if (!uri.hasAuthority || (appEnvironment != 'dev' && uri.scheme != 'https')) {
    throw StateError('Configure uma API HTTPS para este ambiente.');
  }
}
