class OpenRouterBackendConfig {
  static const String baseUrl =
      String.fromEnvironment('MAIKA_BACKEND_BASE_URL',
          defaultValue: 'http://192.168.0.11:3000');

  static const String aiEndpoint = '/api/ai';

  static String get aiUrl => '$baseUrl$aiEndpoint';
}
