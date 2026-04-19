import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/openrouter_backend_config.dart';

class AvatarOverclockResponse {
  final String text;
  final String emotion;

  const AvatarOverclockResponse({
    required this.text,
    required this.emotion,
  });
}

class AvatarOverclockService {
  AvatarOverclockService();

  static const String _modelErrorEmotion = 'confundida';

  Map<String, dynamic>? _tryDecodeBody(String rawBody) {
    try {
      final decoded = jsonDecode(rawBody);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _normalizeEmotion(String? emotion) {
    switch (emotion?.trim().toLowerCase()) {
      case 'neutral_cool':
      case 'nerd':
      case 'pensativa':
      case 'feliz_1':
      case 'feliz_2':
      case 'orgullosa':
      case 'asombrada':
      case 'impactada':
      case 'triste_1':
      case 'derrotada':
      case 'enojada_1':
      case 'enojada_2':
      case 'llorando':
      case 'aburrida':
      case 'feliz':
      case 'triste':
      case 'neutral':
      case 'sorprendida':
      case 'confundida':
      case 'cofundida':
        final normalized = emotion!.trim().toLowerCase();
        return normalized == 'cofundida' ? _modelErrorEmotion : normalized;
      default:
        return 'neutral';
    }
  }

  String _extractText(Map<String, dynamic> body) {
    final respuesta = body['respuesta'];
    if (respuesta is String && respuesta.trim().isNotEmpty) {
      return respuesta;
    }

    final error = body['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }

    return '';
  }

  Future<AvatarOverclockResponse> sendMessage(String message) async {
    try {
      final uri = Uri.parse(OpenRouterBackendConfig.aiUrl);

      final res = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 45));

      final body = _tryDecodeBody(res.body);
      if (body != null) {
        final text = _extractText(body);
        final emotion = _normalizeEmotion(body['emocion'] as String?);

        if (text.trim().isNotEmpty) {
          return AvatarOverclockResponse(
            text: text,
            emotion: res.statusCode == 200 ? emotion : _modelErrorEmotion,
          );
        }
      }

      final fallbackText = res.body.isNotEmpty
          ? res.body
          : res.statusCode == 200
              ? 'Lo siento, no entendí eso.'
              : 'Lo siento, hubo un problema al hablar con el modo overclock.';

      return AvatarOverclockResponse(
        text: fallbackText,
        emotion: res.statusCode == 200 ? 'neutral' : _modelErrorEmotion,
      );
    } catch (e) {
      return AvatarOverclockResponse(
        text: 'Error de conexión con el modo overclock: $e',
        emotion: _modelErrorEmotion,
      );
    }
  }
}
