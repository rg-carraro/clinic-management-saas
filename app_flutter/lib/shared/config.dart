const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
const appEnvironment = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

void validateConfiguration() {
  final uri = Uri.parse(apiBaseUrl);
  if (!uri.hasAuthority || (appEnvironment != 'dev' && uri.scheme != 'https')) {
    throw StateError('Configure uma API HTTPS para este ambiente.');
  }
}
