import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/rasa_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();

  Future<dynamic> post(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      if (RasaConfig.enableLogging && RasaConfig.logRequests) {
        print('🌐 API Request to: $url');
        print('📤 Request body: ${jsonEncode(body)}');
      }

      final response = await _client
          .post(
            Uri.parse(url),
            headers: {...RasaConfig.defaultHeaders, ...?headers},
            body: jsonEncode(body),
          )
          .timeout(RasaConfig.responseTimeout);

      if (RasaConfig.enableLogging && RasaConfig.logResponses) {
        print('📥 Response status: ${response.statusCode}');
        print('📥 Response body: ${response.body}');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'HTTP Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (RasaConfig.enableLogging && RasaConfig.logErrors) {
        print('❌ API Error: $e');
      }
      throw Exception('Network Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> sendMessageToRasa(
    String message,
    String sender, {
    String? customUrl,
  }) async {
    final url = customUrl ?? RasaConfig.currentRasaUrl;

    if (!RasaConfig.isValidRasaUrl(url)) {
      throw Exception('URL de Rasa inválida: $url');
    }

    final response = await post(
      url,
      body: {'sender': sender, 'message': message},
    );

    if (response is List) {
      return (response as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } else {
      return [response as Map<String, dynamic>];
    }
  }

  // Método para probar la conexión con Rasa
  Future<bool> testRasaConnection({String? customUrl}) async {
    try {
      final url = customUrl ?? RasaConfig.currentRasaUrl;
      await sendMessageToRasa('test', 'test_user', customUrl: url);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Método para obtener información de la configuración actual
  Map<String, dynamic> getConnectionInfo() {
    return {
      'currentUrl': RasaConfig.currentRasaUrl,
      'configInfo': RasaConfig.getConfigInfo(),
    };
  }

  void dispose() {
    _client.close();
  }
}
