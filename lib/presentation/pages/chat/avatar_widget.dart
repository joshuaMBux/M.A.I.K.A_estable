import 'package:flutter/material.dart';

/// Widget del avatar 2D usado en el modo "chat con avatar".
/// Reutiliza exactamente el stack de imágenes de `assets/emociones`.
class AvatarWidget extends StatefulWidget {
  final bool isSpeaking;
  final String emotion;

  const AvatarWidget({
    super.key,
    required this.isSpeaking,
    this.emotion = 'neutral',
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  String _getAvatarAsset() {
    switch (widget.emotion) {
      case 'aburrida':
        return 'assets/emociones/Aburrida esperando aburrida.png';
      case 'aliviada':
        return 'assets/emociones/Aliviada.png';
      case 'cansada':
        return 'assets/emociones/Cansada.png';
      case 'confundida':
        return 'assets/emociones/Confundida simpática confundida.png';
      case 'inspirada':
        return 'assets/emociones/Inspirada admirada.png';
      case 'nerviosa':
        return 'assets/emociones/Nerviosa.png';
      case 'muy_nerviosa':
        return 'assets/emociones/muy nerviosa.png';
      case 'feliz_logro':
        return 'assets/emociones/Orgullosa de ti celebrando feliz_logro.png';
      case 'pensativa':
        return 'assets/emociones/pensativa.png';
      case 'picara':
        return 'assets/emociones/Picara.png';
      case 'picara_sonrojada':
        return 'assets/emociones/picara sonrojada.png';
      case 'orando':
        return 'assets/emociones/Seria reverente orando.png';
      case 'feliz':
        return 'assets/emociones/feliz.png';
      case 'triste':
        return 'assets/emociones/triste.png';
      case 'enojada':
        return 'assets/emociones/enojada.png';
      case 'dudando':
        return 'assets/emociones/dudando.png';
      case 'sorprendida':
        return 'assets/emociones/sorprendida.png';
      case 'sonrojada':
        return 'assets/emociones/sonrojada.png';
      case 'orgullosa':
        return 'assets/emociones/orgullosa.png';
      case 'neutral':
      default:
        return 'assets/emociones/neutral.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final speakingPulse = widget.isSpeaking ? (0.7 + 0.3 * _blink.value) : 0.0;
    final opacity = widget.isSpeaking ? 1.0 : (0.9 + 0.1 * _blink.value);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow:
            widget.isSpeaking
                ? [
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(
                      alpha: 0.3 + 0.2 * speakingPulse,
                    ),
                    blurRadius: 40 * speakingPulse,
                    spreadRadius: 4 * speakingPulse,
                  ),
                ]
                : [],
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Image.asset(
            _getAvatarAsset(),
            key: ValueKey(widget.emotion),
            height: 280,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
