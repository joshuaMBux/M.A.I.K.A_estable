import 'dart:async';

import '../../core/network/api_client.dart';

class RasaApi {
  RasaApi(this._apiClient);

  final ApiClient _apiClient;

  final _connectionController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream;

  Future<List<Map<String, dynamic>>> sendMessage({
    required String message,
    required String sender,
  }) async {
    try {
      final response = await _apiClient.sendMessageToRasa(message, sender);
      _connectionController.add(true);
      return response;
    } catch (error) {
      _connectionController.add(false);
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    final healthy = await _apiClient.testRasaConnection();
    _connectionController.add(healthy);
    return healthy;
  }

  void dispose() {
    _connectionController.close();
  }
}
