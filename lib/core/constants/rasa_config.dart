class RasaConfig {
  // URLs de Rasa para diferentes entornos
  static const String localRasaUrl =
      'http://localhost:5005/webhooks/rest/webhook';
  static const String dockerRasaUrl =
      'http://localhost:5005/webhooks/rest/webhook';
  static const String cloudRasaUrl =
      'https://your-rasa-instance.com/webhooks/rest/webhook';

  // URL actual que se está usando
  static const String currentRasaUrl = localRasaUrl;

  // Configuración de timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration responseTimeout = Duration(seconds: 30);

  // Configuración de reintentos
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Mensajes de prueba predefinidos
  static const List<String> testMessages = [
    'hola',
    '¿cómo estás?',
    'cuéntame sobre la biblia',
    '¿qué versículos conoces?',
    'gracias por tu ayuda',
    '¿puedes ayudarme con un versículo?',
    'explica Juan 3:16',
    '¿qué dice la biblia sobre el amor?',
  ];

  // Configuración de logging
  static const bool enableLogging = true;
  static const bool logRequests = true;
  static const bool logResponses = true;
  static const bool logErrors = true;

  // Configuración de debugging
  static const bool enableDebugMode = true;
  static const bool showRawResponses = false;

  // Método para obtener la URL de Rasa según el entorno
  static String getRasaUrl({String? environment}) {
    switch (environment?.toLowerCase()) {
      case 'local':
        return localRasaUrl;
      case 'docker':
        return dockerRasaUrl;
      case 'cloud':
        return cloudRasaUrl;
      default:
        return currentRasaUrl;
    }
  }

  // Método para validar si la URL de Rasa es válida
  static bool isValidRasaUrl(String url) {
    return url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://')) &&
        url.contains('/webhooks/rest/webhook');
  }

  // Método para obtener información de configuración
  static Map<String, dynamic> getConfigInfo() {
    return {
      'currentUrl': currentRasaUrl,
      'connectionTimeout': connectionTimeout.inSeconds,
      'responseTimeout': responseTimeout.inSeconds,
      'maxRetries': maxRetries,
      'enableLogging': enableLogging,
      'enableDebugMode': enableDebugMode,
    };
  }
}
