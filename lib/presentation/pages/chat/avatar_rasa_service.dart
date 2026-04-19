import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/rasa_config.dart';

class AvatarRasaResponse {
  final String text;
  final String emotion;

  const AvatarRasaResponse({
    required this.text,
    this.emotion = 'neutral',
  });
}

class AvatarRasaService {
  AvatarRasaService();

  static const String _modelErrorEmotion = 'confundida';

  String get _endpoint => RasaConfig.currentRasaUrl;

  String _normalizeEmotion(String? emotion) {
    switch (emotion?.trim().toLowerCase()) {
      case 'aburrida':
      case 'aliviada':
      case 'cansada':
      case 'confundida':
      case 'cofundida':
      case 'dudando':
      case 'enojada':
      case 'feliz':
      case 'feliz_logro':
      case 'inspirada':
      case 'muy_nerviosa':
      case 'nerviosa':
      case 'neutral':
      case 'orando':
      case 'orgullosa':
      case 'pensativa':
      case 'picara':
      case 'picara_sonrojada':
      case 'sonrojada':
      case 'sorprendida':
      case 'triste':
        final normalized = emotion!.trim().toLowerCase();
        return normalized == 'cofundida' ? _modelErrorEmotion : normalized;
      default:
        return 'neutral';
    }
  }

  AvatarRasaResponse _errorResponse(String text) {
    final message = text.trim().isEmpty
        ? 'Lo siento, hubo un problema al obtener la respuesta de Rasa.'
        : text;

    return AvatarRasaResponse(
      text: message,
      emotion: _modelErrorEmotion,
    );
  }

  String _inferEmotionFromText(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('incorrect') ||
        lower.contains('no es correcto') ||
        lower.contains('respuesta equivocada') ||
        lower.contains('respuesta incorrecta') ||
        lower.contains('no es la respuesta') ||
        lower.contains('nivel equivocado') ||
        lower.contains('nivel incorrecto')) {
      return 'nerviosa';
    }

    if (lower.contains('respuesta correcta') ||
        lower.contains('es correcto') ||
        lower.contains('correcto!') ||
        lower.contains('muy bien') ||
        lower.contains('excelente') ||
        lower.contains('has acertado') ||
        lower.contains('acertaste') ||
        lower.contains('bien hecho') ||
        lower.contains('buen trabajo') ||
        lower.contains('tienes un gran conocimiento biblico') ||
        lower.contains('progreso espiritual') ||
        lower.contains('estadisticas') ||
        lower.contains('orgullosa de ti') ||
        lower.contains('estoy orgullosa de ti')) {
      return 'feliz_logro';
    }

    if (lower.contains('oremos juntos') ||
        lower.startsWith('oremos') ||
        lower.contains('vamos a orar') ||
        lower.contains('oracion guiada')) {
      return 'orando';
    }

    if (lower.contains('fortaleza') ||
        lower.contains('momento dificil') ||
        lower.contains('atravesando un momento dificil') ||
        lower.contains('el senor es mi fortaleza')) {
      return 'cansada';
    }

    if (lower.contains('me alegra haber podido ayudarte') ||
        lower.contains('me alegra haber podido servirte') ||
        lower.contains('fue de bendicion') ||
        lower.contains('me alegra saber que estas bien')) {
      return 'aliviada';
    }

    if (lower.contains('testimonio') ||
        lower.contains('que decision tan hermosa') ||
        lower.contains('vida eterna') ||
        lower.contains('promesa para hoy') ||
        lower.contains('promesa para ti') ||
        lower.contains('promesas de dios') ||
        lower.contains('las promesas de dios son fieles') ||
        lower.contains('la palabra de dios tiene respuestas')) {
      return 'inspirada';
    }

    if (lower.contains('lo siento') ||
        lower.contains('no entend') ||
        lower.contains('no entiendo bien eso') ||
        lower.contains('no te entendi') ||
        lower.contains('creo que maika no entendio bien eso') ||
        lower.contains('disculp')) {
      return 'dudando';
    }

    if (lower.contains('triste') ||
        lower.contains('dificil') ||
        lower.contains('dolor') ||
        lower.contains('no estas solo') ||
        lower.contains('quebrantado')) {
      return 'triste';
    }

    if (lower.contains('felicidades') ||
        lower.contains('gloria a dios') ||
        lower.contains('alabado sea dios') ||
        lower.contains('que hermoso es alabar') ||
        lower.contains('me alegra') ||
        lower.contains('me llena de alegria')) {
      return 'feliz';
    }

    if (lower.contains('wow') ||
        lower.contains('sorprendente') ||
        lower.contains('sabias que') ||
        lower.contains('curiosidad biblica') ||
        lower.contains('dato biblico interesante')) {
      return 'sorprendida';
    }

    if (lower.contains('gracias') ||
        lower.contains('que lindo') ||
        lower.contains('carino') ||
        lower.contains('me caes bien') ||
        lower.contains('me caes muy bien') ||
        lower.contains('te aprecio') ||
        lower.contains('te quiero maika') ||
        lower.contains('te quiero, maika')) {
      return 'sonrojada';
    }

    if (lower.contains('reto') ||
        lower.contains('valiente') ||
        lower.contains('animo') ||
        lower.contains('puedes lograrlo')) {
      return 'orgullosa';
    }

    if (lower.contains("modo 'me aburro' activado") ||
        lower.contains('modo me aburro activado') ||
        lower.contains('me encanta platicar') ||
        lower.contains('lista para la charla') ||
        lower.contains('este tiempito contigo') ||
        lower.contains('me gusta este tiempito contigo')) {
      return 'picara';
    }

    return 'neutral';
  }

  Future<AvatarRasaResponse> sendMessage(String message) async {
    try {
      final uri = Uri.parse(_endpoint);
      final res = await http
          .post(
            uri,
            headers: RasaConfig.defaultHeaders,
            body: jsonEncode({
              'sender': 'avatar_user',
              'message': message,
            }),
          )
          .timeout(RasaConfig.responseTimeout);

      if (res.statusCode != 200) {
        return _errorResponse('Rasa respondio con error ${res.statusCode}.');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List || decoded.isEmpty) {
        return _errorResponse(
          'Rasa no devolvio una respuesta valida para el avatar.',
        );
      }

      String emotion = 'neutral';
      final texts = <String>[];

      for (final raw in decoded) {
        if (raw is! Map<String, dynamic>) {
          continue;
        }

        if (emotion == 'neutral') {
          if (raw['custom'] is Map) {
            final custom = raw['custom'] as Map;
            emotion = _normalizeEmotion(custom['emotion'] as String?);
          } else if (raw['json_message'] is Map) {
            final jsonMessage = raw['json_message'] as Map;
            emotion = _normalizeEmotion(jsonMessage['emotion'] as String?);
          }
        }

        final fullText = (raw['text'] ?? '') as String? ?? '';
        if (fullText.trim().isEmpty) {
          continue;
        }

        var cleanText = fullText;
        final match = RegExp(r'\[(\w+)\]').firstMatch(fullText);
        if (match != null) {
          if (emotion == 'neutral') {
            emotion = _normalizeEmotion(match.group(1));
          }
          cleanText = fullText.replaceFirst(RegExp(r'\[(\w+)\]'), '').trim();
        }

        texts.add(cleanText.isEmpty ? fullText : cleanText);
      }

      if (texts.isEmpty) {
        return _errorResponse(
          'Rasa respondio sin texto util para mostrar en el avatar.',
        );
      }

      final combined = texts.join('\n\n');
      var effectiveEmotion = _normalizeEmotion(emotion);
      if (effectiveEmotion == 'neutral') {
        effectiveEmotion = _normalizeEmotion(_inferEmotionFromText(combined));
      }

      return AvatarRasaResponse(
        text: combined,
        emotion: effectiveEmotion,
      );
    } catch (e) {
      return AvatarRasaResponse(
        text: 'Error de conexion con Rasa: $e',
        emotion: _modelErrorEmotion,
      );
    }
  }
}
