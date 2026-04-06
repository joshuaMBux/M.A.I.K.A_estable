import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/rasa_config.dart';

/// Respuesta simplificada de Rasa para el modo avatar.
class AvatarRasaResponse {
  final String text;
  final String emotion;

  const AvatarRasaResponse({
    required this.text,
    this.emotion = 'neutral',
  });
}

/// Servicio HTTP independiente del BLoC principal.
/// Combina todas las respuestas de Rasa en un solo texto para que
/// el avatar pueda mostrar el bloque completo (como en el chat normal).
class AvatarRasaService {
  AvatarRasaService();

  String get _endpoint => RasaConfig.currentRasaUrl;

  String _inferEmotionFromText(String text) {
    final lower = text.toLowerCase();

    // 1) Respuestas del quiz

    // Incorrecto → nerviosa
    if (lower.contains('incorrect') ||
        lower.contains('no es correcto') ||
        lower.contains('respuesta equivocada') ||
        lower.contains('respuesta incorrecta') ||
        lower.contains('no es la respuesta') ||
        lower.contains('nivel equivocado') ||
        lower.contains('nivel incorrecto')) {
      return 'nerviosa';
    }

    // Correcto / logro → feliz_logro (orgullosa de ti)
    if (lower.contains('respuesta correcta') ||
        lower.contains('es correcto') ||
        lower.contains('correcto!') ||
        lower.startsWith('¡correcto') ||
        lower.contains('muy bien') ||
        lower.contains('¡muy bien') ||
        lower.contains('excelente') ||
        lower.contains('has acertado') ||
        lower.contains('acertaste') ||
        lower.contains('bien hecho') ||
        lower.contains('buen trabajo') ||
        lower.contains('tienes un gran conocimiento bíblico') ||
        lower.contains('progreso espiritual') ||
        lower.contains('estadísticas') ||
        lower.contains('orgullosa de ti') ||
        lower.contains('estoy orgullosa de ti')) {
      return 'feliz_logro';
    }

    // 2) Oración guiada / momentos de oración
    if (lower.contains('oremos juntos') ||
        lower.startsWith('oremos') ||
        lower.contains('vamos a orar') ||
        lower.contains('oración guiada') ||
        lower.contains('oracion guiada')) {
      return 'orando';
    }

    // 3) Mensajes de ánimo / fortaleza (cuando el usuario está cansado)
    if (lower.contains('fortaleza') ||
        lower.contains('momento difícil') ||
        lower.contains('momento dificil') ||
        lower.contains('atravesando un momento difícil') ||
        lower.contains('atravesando un momento dificil') ||
        lower.contains('el señor es mi fortaleza') ||
        lower.contains('el senor es mi fortaleza')) {
      return 'cansada';
    }

    // 4) Agradecimiento / alivio después de ayuda espiritual
    if (lower.contains('me alegra haber podido ayudarte') ||
        lower.contains('me alegra haber podido servirte') ||
        lower.contains('fue de bendición') ||
        lower.contains('fue de bendicion') ||
        lower.contains('me alegra saber que estás bien') ||
        lower.contains('me alegra saber que estas bien')) {
      return 'aliviada';
    }

    // 5) Testimonios, salvación, promesas, consejo bíblico → inspirada
    if (lower.contains('testimonio') ||
        lower.contains('qué decisión tan hermosa') ||
        lower.contains('que decisión tan hermosa') ||
        lower.contains('que decision tan hermosa') ||
        lower.contains('vida eterna') ||
        lower.contains('promesa para hoy') ||
        lower.contains('promesa para ti') ||
        lower.contains('promesas de dios') ||
        lower.contains('las promesas de dios son fieles') ||
        lower.contains('la palabra de dios tiene respuestas')) {
      return 'inspirada';
    }

    // 6) Dudas / no entendió bien → dudando
    if (lower.contains('lo siento') ||
        lower.contains('no entend') ||
        lower.contains('no entiendo bien eso') ||
        lower.contains('no te entendí') ||
        lower.contains('no te entendi') ||
        lower.contains('creo que maika no entendió bien eso') ||
        lower.contains('creo que maika no entendio bien eso') ||
        lower.contains('disculp')) {
      return 'dudando';
    }

    // 7) Mensajes de tristeza / dolor profundo
    if (lower.contains('triste') ||
        lower.contains('difícil') ||
        lower.contains('dificil') ||
        lower.contains('dolor') ||
        lower.contains('no estás solo') ||
        lower.contains('no estas solo') ||
        lower.contains('quebrantado')) {
      return 'triste';
    }

    // 8) Alegría / alabanza general
    if (lower.contains('felicidades') ||
        lower.contains('gloria a dios') ||
        lower.contains('alabado sea dios') ||
        lower.contains('qué hermoso es alabar') ||
        lower.contains('que hermoso es alabar') ||
        lower.contains('me alegra') ||
        lower.contains('me llena de alegría') ||
        lower.contains('me llena de alegria')) {
      return 'feliz';
    }

    // 9) Curiosidad / sorpresa
    if (lower.contains('wow') ||
        lower.contains('sorprendente') ||
        lower.contains('sabías que') ||
        lower.contains('sabias que') ||
        lower.contains('curiosidad bíblica') ||
        lower.contains('curiosidad biblica') ||
        lower.contains('dato bíblico interesante') ||
        lower.contains('dato biblico interesante')) {
      return 'sorprendida';
    }

    // 10) Cariño hacia Maika / aprecio → sonrojada
    if (lower.contains('gracias') ||
        lower.contains('qué lindo') ||
        lower.contains('que lindo') ||
        lower.contains('cariño') ||
        lower.contains('carino') ||
        lower.contains('me caes bien') ||
        lower.contains('me caes muy bien') ||
        lower.contains('te aprecio') ||
        lower.contains('te quiero maika') ||
        lower.contains('te quiero, maika')) {
      return 'sonrojada';
    }

    // 11) Retos / motivación → orgullosa
    if (lower.contains('reto') ||
        lower.contains('valiente') ||
        lower.contains('ánimo') ||
        lower.contains('animo') ||
        lower.contains('puedes lograrlo')) {
      return 'orgullosa';
    }

    // 12) Charla ligera / estado de Maika → picara
    if (lower.contains('modo “me aburro” activado') ||
        lower.contains("modo 'me aburro' activado") ||
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

    if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List && body.isNotEmpty) {
          String emotion = 'neutral';
          final texts = <String>[];

          for (final raw in body) {
            if (raw is! Map<String, dynamic>) continue;

            final fullText = (raw['text'] ?? '') as String;
            if (fullText.trim().isEmpty) continue;

            // 1) Intentar obtener emoción solo del primer mensaje que la tenga
            if (emotion == 'neutral') {
              if (raw['custom'] is Map) {
                final custom = raw['custom'] as Map;
                final customEmotion = custom['emotion'];
                if (customEmotion is String && customEmotion.isNotEmpty) {
                  emotion = customEmotion;
                }
              } else if (raw['json_message'] is Map) {
                final custom = raw['json_message'] as Map;
                final customEmotion = custom['emotion'];
                if (customEmotion is String && customEmotion.isNotEmpty) {
                  emotion = customEmotion;
                }
              }
            }

            // 2) Fallback: extraer emoción desde el texto usando [emocion]
            var cleanText = fullText;
            final regExp = RegExp(r'\[(\w+)\]');
            final match = regExp.firstMatch(fullText);

            if (match != null) {
              final bracketEmotion = match.group(1);
              if (bracketEmotion != null &&
                  bracketEmotion.isNotEmpty &&
                  emotion == 'neutral') {
                emotion = bracketEmotion;
              }
              cleanText = fullText.replaceFirst(regExp, '').trim();
            }

            texts.add(cleanText.isEmpty ? fullText : cleanText);
          }

          final combined = texts.join('\n\n');
          var effectiveEmotion = emotion;
          if (effectiveEmotion == 'neutral') {
            effectiveEmotion = _inferEmotionFromText(combined);
          }

          return AvatarRasaResponse(
            text: combined,
            emotion: effectiveEmotion,
          );
        }
      }

      return const AvatarRasaResponse(
        text: 'Lo siento, no entendí eso.',
        emotion: 'neutral',
      );
    } catch (e) {
      return AvatarRasaResponse(
        text: 'Error de conexión con Rasa: $e',
        emotion: 'enojada',
      );
    }
  }
}
