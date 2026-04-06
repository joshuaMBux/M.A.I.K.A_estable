import 'package:flutter/material.dart';

import 'avatar_rasa_service.dart';
import 'avatar_widget.dart';

/// Pantalla de chat alternativa con avatar 2D animado.
/// No modifica la lógica del ChatScreen existente.
class AvatarChatScreen extends StatefulWidget {
  const AvatarChatScreen({super.key});

  @override
  State<AvatarChatScreen> createState() => _AvatarChatScreenState();
}

class _AvatarChatScreenState extends State<AvatarChatScreen>
    with SingleTickerProviderStateMixin {
  final AvatarRasaService _rasa = AvatarRasaService();

  bool _isSpeaking = false;
  bool _isWaitingForBot = false;
  String _currentEmotion = 'neutral';
  final TextEditingController _ctrl = TextEditingController();
  String _botReply =
      '¡Hola! Soy tu avatar anime 🌸\n¿En qué te ayudo hoy?';

  late final AnimationController _animController;
  late final Animation<double> _titleAnimation;
  late final Animation<double> _cardAnimation;
  late final Animation<double> _sendButtonAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _cardAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );
    _sendButtonAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _emotionForUserText(String text) {
    final lower = text.toLowerCase();

    // Intenciones de saludo / despedida
    if (lower.contains('hola') ||
        lower.contains('buenas') ||
        lower.contains('buen d') ||
        lower.contains('hey') ||
        lower.contains('shalom')) {
      return 'feliz';
    }

    if (lower.contains('adi') ||
        lower.contains('nos vemos') ||
        lower.contains('hasta luego') ||
        lower.contains('me voy')) {
      return 'feliz';
    }

    // Estados emocionales del usuario
    if (lower.contains('aburrid')) {
      return 'aburrida';
    }

    if (lower.contains('cansad')) {
      return 'cansada';
    }

    if (lower.contains('nervios') || lower.contains('ansiedad')) {
      return 'nerviosa';
    }

    if (lower.contains('ataque de p') || lower.contains('muy nervioso')) {
      return 'muy_nerviosa';
    }

    if (lower.contains('triste') ||
        lower.contains('muy mal') ||
        lower.contains('solo') ||
        lower.contains('soledad') ||
        lower.contains('miedo')) {
      return 'triste';
    }

    if (lower.contains('gracias') && !lower.contains('no gracias')) {
      return 'aliviada';
    }

    if (lower.contains('te amo maika') ||
        lower.contains('te amo, maika') ||
        lower.contains('me encantas') ||
        lower.contains('eres la mejor ia') ||
        lower.contains('eres mi waifu')) {
      return 'picara_sonrojada';
    }

    if (lower.contains('te quiero') ||
        lower.contains('me caes bien') ||
        lower.contains('me gustas')) {
      return 'sonrojada';
    }

    // Peticiones espirituales / ayuda
    if (lower.contains('oracion') ||
        lower.contains('oración') ||
        lower.contains('orar') ||
        lower.contains('ayuda espiritual') ||
        lower.contains('ayudame') ||
        lower.contains('ayúdame')) {
      return 'triste';
    }

    // Peticiones bíblicas / devocionales
    if (lower.contains('devocional') ||
        lower.contains('versiculo') ||
        lower.contains('versículo') ||
        lower.contains('verso del dia') ||
        lower.contains('verso del día') ||
        lower.contains('historia b') ||
        lower.contains('biblia')) {
      return 'inspirada';
    }

    // Curiosidades / sorpresa
    if (lower.contains('wow') ||
        lower.contains('en serio') ||
        lower.contains('sorprendente') ||
        lower.contains('curiosidad')) {
      return 'sorprendida';
    }

    // Usuario dice que no entiende algo
    if (lower.contains('no entiendo') ||
        lower.contains('no se que hacer') ||
        lower.contains('no sé que hacer')) {
      return 'confundida';
    }

    // Usuario está reflexionando / pensando
    if (lower.contains('pienso que') ||
        lower.contains('he estado pensando')) {
      return 'pensativa';
    }

    // Juegos / quiz / minijuegos
    if (lower.contains('jugar') ||
        lower.contains('quiz') ||
        lower.contains('test') ||
        lower.contains('juego')) {
      return 'orgullosa';
    }

    return 'dudando';
  }

  Future<void> _send(String text) async {
    final message = text.trim();
    if (message.isEmpty) return;

    // Comando de prueba manual para emociones: /test emocion
    if (message.startsWith('/test ')) {
      final emo = message.replaceFirst('/test ', '').trim();
      setState(() {
        _currentEmotion = emo;
        _botReply = 'Cambiando a emoción: $emo';
        _isSpeaking = true;
      });
      _ctrl.clear();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
      return;
    }

    _ctrl.clear();
    setState(() {
      _isWaitingForBot = true;
      _isSpeaking = false;
      _currentEmotion = _emotionForUserText(message);
      _botReply = 'Estoy pensando en la mejor respuesta...';
    });

    final response = await _rasa.sendMessage(message);

    if (!mounted) return;

    setState(() {
      _isWaitingForBot = false;
      _botReply = response.text;
      _currentEmotion = response.emotion;
      _isSpeaking = true;
    });

    // Pequeña animación de "hablar"
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surface = scheme.surface;
    final background = scheme.surface;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _titleAnimation,
          child: const Text('Chat con avatar'),
          builder: (context, child) {
            return Opacity(
              opacity: _titleAnimation.value,
              child: Transform.translate(
                offset: Offset(-16 * (1 - _titleAnimation.value), 0),
                child: child,
              ),
            );
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          return Column(
            children: [
              // Zona scrollable: avatar + mensaje
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 720,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          AvatarWidget(
                            isSpeaking: _isSpeaking,
                            emotion: _currentEmotion,
                          ),
                          const SizedBox(height: 12),
                          FadeTransition(
                            opacity: _cardAnimation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.96, end: 1.0)
                                  .animate(_cardAnimation),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _isWaitingForBot
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.onPrimaryContainer,
                                        ),
                                      )
                                    : Text(
                                        _botReply,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: scheme.onPrimaryContainer,
                                        ),
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                        maxLines: null,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Input fijo abajo
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + bottomInset,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: InputDecoration(
                          hintText: 'Escribe tu mensaje...',
                          filled: true,
                          fillColor: surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: _send,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ScaleTransition(
                      scale: _sendButtonAnimation,
                      child: CircleAvatar(
                        backgroundColor: scheme.primary,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () => _send(_ctrl.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
