import 'package:flutter/material.dart';

class AvatarWidget extends StatefulWidget {
  final bool isSpeaking;
  final String emotion;
  final bool useOverclockAssets;

  const AvatarWidget({
    super.key,
    required this.isSpeaking,
    this.emotion = 'neutral',
    this.useOverclockAssets = false,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  static const String _defaultAsset = 'assets/emociones/neutral.png';
  static const String _defaultErrorAsset =
      'assets/emociones/Confundida simpática confundida.png';
  static const String _defaultOverclockAsset =
      'assets/emociones_overclock/neutral_cool.png';
  static const String _defaultOverclockErrorAsset =
      'assets/emociones_overclock/cofundida.png';

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

  String _fallbackAsset() {
    return widget.useOverclockAssets
        ? _defaultOverclockErrorAsset
        : _defaultErrorAsset;
  }

  String _getAvatarAsset() {
    if (widget.useOverclockAssets) {
      switch (widget.emotion) {
        case 'feliz_1':
        case 'feliz':
          return 'assets/emociones_overclock/feliz_1.png';
        case 'feliz_2':
          return 'assets/emociones_overclock/feliz_2.png';
        case 'orgullosa':
          return 'assets/emociones_overclock/orgullosa.png';
        case 'aleatoria_1':
          return 'assets/emociones_overclock/aleatoria_1.png';
        case 'aleatoria_2':
          return 'assets/emociones_overclock/aleatoria_2.png';
        case 'nerd':
          return 'assets/emociones_overclock/nerd.png';
        case 'triste_1':
        case 'triste':
          return 'assets/emociones_overclock/triste_1.png';
        case 'llorando':
          return 'assets/emociones_overclock/llorando.png';
        case 'derrotada':
          return 'assets/emociones_overclock/derrotada.png';
        case 'aburrida':
          return 'assets/emociones_overclock/aburrida.png';
        case 'pensativa':
          return 'assets/emociones_overclock/pensativa.png';
        case 'cofundida':
        case 'confundida':
          return _defaultOverclockErrorAsset;
        case 'sorprendida':
        case 'asombrada':
          return 'assets/emociones_overclock/asombrada.png';
        case 'Impactada':
        case 'impactada':
          return 'assets/emociones_overclock/Impactada.png';
        case 'enojada':
        case 'enojada_1':
          return 'assets/emociones_overclock/enojada_1.png';
        case 'enojada_2':
          return 'assets/emociones_overclock/enojada_2.png';
        case 'neutral_cool':
        case 'neutral':
          return _defaultOverclockAsset;
        default:
          return _defaultOverclockErrorAsset;
      }
    }

    switch (widget.emotion) {
      case 'aburrida':
        return 'assets/emociones/Aburrida esperando aburrida.png';
      case 'aliviada':
        return 'assets/emociones/Aliviada.png';
      case 'cansada':
        return 'assets/emociones/Cansada.png';
      case 'confundida':
      case 'cofundida':
        return _defaultErrorAsset;
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
        return _defaultAsset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final speakingPulse = widget.isSpeaking ? (0.7 + 0.3 * _blink.value) : 0.0;
    final opacity = widget.isSpeaking ? 1.0 : (0.9 + 0.1 * _blink.value);
    final bobOffset = widget.isSpeaking ? (0.5 - _blink.value) * 6 : 0.0;

    return Transform.translate(
      offset: Offset(0, bobOffset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: widget.isSpeaking
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(
                      alpha: 0.25 * speakingPulse,
                    ),
                    blurRadius: 30 * speakingPulse,
                    spreadRadius: 4 * speakingPulse,
                  ),
                  BoxShadow(
                    color: scheme.secondary.withValues(
                      alpha: 0.20 * speakingPulse,
                    ),
                    blurRadius: 46 * speakingPulse,
                    spreadRadius: 10 * speakingPulse,
                  ),
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(
                      alpha: 0.18 * speakingPulse,
                    ),
                    blurRadius: 64 * speakingPulse,
                    spreadRadius: 16 * speakingPulse,
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
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  _fallbackAsset(),
                  key: ValueKey('${widget.emotion}_fallback'),
                  height: 280,
                  fit: BoxFit.contain,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
