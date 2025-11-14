import 'dart:convert';
import 'dart:developer' as developer;
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
        developer.log('API request to: $url', name: 'ApiClient');
        developer.log('Request body: ${jsonEncode(body)}', name: 'ApiClient');
      }

      final response = await _client
          .post(
            Uri.parse(url),
            headers: {...RasaConfig.defaultHeaders, ...?headers},
            body: jsonEncode(body),
          )
          .timeout(RasaConfig.responseTimeout);

      if (RasaConfig.enableLogging && RasaConfig.logResponses) {
        developer.log(
          'Response status: ${response.statusCode}',
          name: 'ApiClient',
        );
        developer.log('Response body: ${response.body}', name: 'ApiClient');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'HTTP Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (error) {
      if (RasaConfig.enableLogging && RasaConfig.logErrors) {
        developer.log('API Error: $error', name: 'ApiClient', error: error);
      }
      throw Exception('Network Error: $error');
    }
  }

  Future<List<Map<String, dynamic>>> sendMessageToRasa(
    String message,
    String sender, {
    String? customUrl,
  }) async {
    final url = customUrl ?? RasaConfig.currentRasaUrl;

    if (!RasaConfig.isValidRasaUrl(url)) {
      throw Exception('URL de Rasa invalida: $url');
    }

    final response = await post(
      url,
      body: {'sender': sender, 'message': message},
    );

    if (response is List) {
      return response
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } else {
      return [response as Map<String, dynamic>];
    }
  }

  Future<bool> testRasaConnection({String? customUrl}) async {
    try {
      final url = customUrl ?? RasaConfig.currentRasaUrl;
      await sendMessageToRasa('test', 'test_user', customUrl: url);
      return true;
    } catch (_) {
      return false;
    }
  }

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
