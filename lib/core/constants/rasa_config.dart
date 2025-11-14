import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class RasaConfig {
  // URLs de Rasa para diferentes entornos
  static const String localDesktopUrl =
      'http://127.0.0.1:5005/webhooks/rest/webhook';
  static const String androidEmulatorUrl =
      'http://10.0.2.2:5005/webhooks/rest/webhook';
  static const String iosSimulatorUrl =
      'http://127.0.0.1:5005/webhooks/rest/webhook';
  static const String dockerRasaUrl =
      'http://localhost:5005/webhooks/rest/webhook';
  static const String webDebugUrl =
      'http://localhost:5005/webhooks/rest/webhook';
  static const String cloudRasaUrl =
      'https://your-rasa-instance.com/webhooks/rest/webhook';

  // Permite forzar una URL (por ejemplo, desde ajustes o pruebas)
  static String? _overrideUrl;

  // URL actual que se está usando
  static String get currentRasaUrl =>
      _overrideUrl ?? _resolveDefaultUrlForPlatform();

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

  static void overrideRasaUrl(String url) {
    if (!isValidRasaUrl(url)) {
      throw ArgumentError('URL de Rasa inválida: $url');
    }
    _overrideUrl = url;
  }

  static void clearOverride() => _overrideUrl = null;

  // Método para obtener la URL de Rasa según el entorno
  static String getRasaUrl({String? environment}) {
    switch (environment?.toLowerCase()) {
      case 'local':
        return localDesktopUrl;
      case 'android':
        return androidEmulatorUrl;
      case 'ios':
        return iosSimulatorUrl;
      case 'docker':
        return dockerRasaUrl;
      case 'web':
        return webDebugUrl;
      case 'cloud':
        return cloudRasaUrl;
      default:
        return currentRasaUrl;
    }
  }

  static String _resolveDefaultUrlForPlatform() {
    if (kIsWeb) {
      return webDebugUrl;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidEmulatorUrl;
      case TargetPlatform.iOS:
        return iosSimulatorUrl;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return localDesktopUrl;
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
      if (_overrideUrl != null) 'overrideUrl': _overrideUrl,
    };
  }
}
