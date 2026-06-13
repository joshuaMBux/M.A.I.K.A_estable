import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../data/models/gamification_models.dart';
import '../../../data/repositories/gamification_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'avatar_rasa_service.dart';
import 'avatar_widget.dart';
import 'avatar_overclock_service.dart';

const List<Color> _neonBorderColors = [
  Color(0xFF9114FF),
  Color(0xFF6B1B9A),
  Color(0xFFE91E63),
  Color(0xFF00E5FF),
  Color(0xFF9114FF),
];

/// Pantalla de chat alternativa con avatar 2D animado.
/// No modifica la lógica del ChatScreen existente.
class AvatarChatScreen extends StatefulWidget {
  const AvatarChatScreen({super.key});

  @override
  State<AvatarChatScreen> createState() => _AvatarChatScreenState();
}

class _AvatarChatScreenState extends State<AvatarChatScreen>
    with TickerProviderStateMixin {
  static const int _overclockUnlockCost = 30;
  static const Duration _overclockWarmupThreshold =
      Duration(milliseconds: 1800);
  static const Duration _overclockLongWaitThreshold = Duration(seconds: 6);

  final AvatarRasaService _rasa = AvatarRasaService();
  final AvatarOverclockService _overclock = AvatarOverclockService();

  int _currentUserId = 0;
  int _availableCoins = 0;
  bool _isOverclockUnlocked = false;
  bool _isOverclockAccessReady = false;
  bool _isUnlockingOverclock = false;
  bool _isOverclockEnabled = false;
  bool _isSpeaking = false;
  bool _isWaitingForBot = false;
  bool _isComposing = false;
  String _currentEmotion = 'neutral';
  final TextEditingController _ctrl = TextEditingController();
  String _botReply = 'Hola, soy M.A.I.K.A.\n¿En qué te ayudo hoy?';

  late final AnimationController _animController;
  late final AnimationController _overclockPulseController;
  late final Animation<double> _titleAnimation;
  late final Animation<double> _cardAnimation;
  late final Animation<double> _overclockPulseAnimation;
  late final Animation<double> _sendButtonAnimation;
  Timer? _thinkingTimer;
  int _animationRunId = 0;

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
    _overclockPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _overclockPulseAnimation = CurvedAnimation(
      parent: _overclockPulseController,
      curve: Curves.easeInOut,
    );
    _ctrl.addListener(_handleInputChanged);
    _animController.forward();
    _loadOverclockAccess();
  }

  @override
  void dispose() {
    _thinkingTimer?.cancel();
    _ctrl.removeListener(_handleInputChanged);
    _ctrl.dispose();
    _overclockPulseController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _syncOverclockPulse(bool isActive) {
    if (isActive) {
      if (!_overclockPulseController.isAnimating) {
        _overclockPulseController.repeat(reverse: true);
      }
      return;
    }

    _overclockPulseController.stop();
    _overclockPulseController.value = 0;
  }

  String _overclockEnabledPrefKey(int userId) =>
      'avatar_overclock_enabled_$userId';

  Future<int> _readCurrentUserId() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      return int.tryParse(authState.user.id) ?? 0;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }

  Future<void> _loadOverclockAccess() async {
    final userId = await _readCurrentUserId();
    if (!di.sl.isRegistered<GamificationRepository>() || userId <= 0) {
      if (!mounted) return;
      setState(() {
        _currentUserId = userId;
        _isOverclockUnlocked = true;
        _isOverclockAccessReady = true;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final repo = di.sl<GamificationRepository>();
    final dashboard = await repo.getDashboard(userId);
    final isUnlocked = await repo.isFeatureUnlocked(
      userId: userId,
      featureKey: GamificationCatalog.overclockFeatureKey,
    );
    final isEnabled =
        isUnlocked && (prefs.getBool(_overclockEnabledPrefKey(userId)) ?? false);

    if (!mounted) return;
    setState(() {
      _currentUserId = userId;
      _availableCoins = dashboard.progress.coins;
      _isOverclockUnlocked = isUnlocked;
      _isOverclockEnabled = isEnabled;
      _isOverclockAccessReady = true;
      _currentEmotion = _restingEmotionForMode(isEnabled);
    });
    _syncOverclockPulse(isEnabled);
  }

  Future<void> _setOverclockEnabled(bool value) async {
    if (!_isOverclockUnlocked) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (_currentUserId > 0) {
      await prefs.setBool(_overclockEnabledPrefKey(_currentUserId), value);
    }

    if (!mounted) return;
    setState(() {
      _isOverclockEnabled = value;
      _currentEmotion = _restingEmotionForMode(value);
    });
    _syncOverclockPulse(value);
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  Future<void> _promptOverclockUnlock() async {
    if (_isUnlockingOverclock || _isOverclockUnlocked) {
      return;
    }

    if (!di.sl.isRegistered<GamificationRepository>() || _currentUserId <= 0) {
      _showSnack(
        'No se pudo validar tu saldo para desbloquear Overclock.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final hasEnoughCoins = _availableCoins >= _overclockUnlockCost;
            return AlertDialog(
              backgroundColor: const Color(0xFF222544),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_open_rounded,
                    color: Color(0xFFFFD54F),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Desbloquear Overclock',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vas a gastar monedas para activar el modo Overclock de Maika.',
                  ),
                  const SizedBox(height: 12),
                  Text('Costo: $_overclockUnlockCost coins'),
                  Text('Tu saldo: $_availableCoins coins'),
                  if (!hasEnoughCoins) ...[
                    const SizedBox(height: 12),
                    Text(
                      'No tienes monedas suficientes todavía.',
                      style: TextStyle(
                        color: Colors.red.shade200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: hasEnoughCoins
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Desbloquear'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _isUnlockingOverclock = true);

    final repo = di.sl<GamificationRepository>();
    final result = await repo.unlockFeature(
      userId: _currentUserId,
      featureKey: GamificationCatalog.overclockFeatureKey,
      costCoins: _overclockUnlockCost,
    );

    if (result.isUnlocked) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_overclockEnabledPrefKey(_currentUserId), true);
    }

    if (!mounted) return;

    setState(() {
      _isUnlockingOverclock = false;
      _availableCoins = result.remainingCoins;
      if (result.isUnlocked) {
        _isOverclockUnlocked = true;
        _isOverclockEnabled = true;
        _currentEmotion = _restingEmotionForMode(true);
      }
    });
    _syncOverclockPulse(result.isUnlocked);

    if (result.purchasedNow) {
      _showSnack('Modo Overclock desbloqueado.');
      return;
    }

    if (result.insufficientCoins) {
      _showSnack(
        'Te faltan monedas para desbloquear Overclock.',
        isError: true,
      );
      return;
    }

    if (result.isUnlocked) {
      _showSnack('El modo Overclock ya estaba desbloqueado.');
    }
  }

  void _handleInputChanged() {
    final composing = _ctrl.text.trim().isNotEmpty;
    if (composing != _isComposing) {
      setState(() => _isComposing = composing);
    }
  }

  int _startAnimationRun() {
    _thinkingTimer?.cancel();
    _thinkingTimer = null;
    _animationRunId++;
    return _animationRunId;
  }

  bool _isAnimationActive(int runId) => mounted && runId == _animationRunId;

  String _restingEmotionForMode(bool useOverclock) {
    return useOverclock ? 'neutral_cool' : 'neutral';
  }

  String _conversationCueForText(String text) {
    final lower = text.toLowerCase();

    if (_isPrayerRequest(text)) {
      return 'prayer';
    }

    if (lower.contains('quiz') ||
        lower.contains('pregunta') ||
        lower.contains('trivia') ||
        lower.contains('respuesta correcta') ||
        lower.contains('respuesta incorrecta') ||
        lower.contains('puntaje') ||
        lower.contains('nivel')) {
      return 'quiz';
    }

    if (lower.contains('curiosidad') ||
        lower.contains('sabias que') ||
        lower.contains('sabías que') ||
        lower.contains('dato interesante') ||
        lower.contains('sorprendente')) {
      return 'curiosity';
    }

    if (lower.contains('hola') ||
        lower.contains('buenas') ||
        lower.contains('hey') ||
        lower.contains('shalom')) {
      return 'greeting';
    }

    if (lower.contains('adios') ||
        lower.contains('adiós') ||
        lower.contains('hasta luego') ||
        lower.contains('nos vemos') ||
        lower.contains('me voy')) {
      return 'farewell';
    }

    if (lower.contains('te quiero') ||
        lower.contains('te amo') ||
        lower.contains('me gustas') ||
        lower.contains('me caes bien') ||
        lower.contains('gracias maika') ||
        lower.contains('aww')) {
      return 'affection';
    }

    if (lower.contains('triste') ||
        lower.contains('solo') ||
        lower.contains('soledad') ||
        lower.contains('miedo') ||
        lower.contains('mal') ||
        lower.contains('ansiedad') ||
        lower.contains('cansad') ||
        lower.contains('ayuda espiritual')) {
      return 'comfort';
    }

    if (lower.contains('devocional') ||
        lower.contains('versiculo') ||
        lower.contains('versículo') ||
        lower.contains('biblia') ||
        lower.contains('promesa') ||
        lower.contains('historia b')) {
      return 'devotional';
    }

    if (lower.contains('felicidades') ||
        lower.contains('logro') ||
        lower.contains('correcto') ||
        lower.contains('orgullosa de ti')) {
      return 'celebration';
    }

    if (lower.contains('no entiendo') ||
        lower.contains('no entendi') ||
        lower.contains('no entendí') ||
        lower.contains('fallo') ||
        lower.contains('falló') ||
        lower.contains('error')) {
      return 'fallback';
    }

    return 'general';
  }

  String _resolveResponseCue({
    required String userCue,
    required String responseText,
    required String finalEmotion,
    required bool holdPrayerPose,
  }) {
    if (holdPrayerPose || finalEmotion == 'orando') {
      return 'prayer';
    }

    final responseCue = _conversationCueForText(responseText);
    if (responseCue != 'general') {
      return responseCue;
    }

    if (finalEmotion == 'feliz_logro' || finalEmotion == 'orgullosa') {
      return 'celebration';
    }
    if (finalEmotion == 'sorprendida') {
      return 'curiosity';
    }
    if (finalEmotion == 'aliviada' || finalEmotion == 'triste') {
      return 'comfort';
    }
    if (finalEmotion == 'sonrojada' || finalEmotion == 'picara_sonrojada') {
      return 'affection';
    }
    if (finalEmotion == 'confundida' || finalEmotion == 'dudando') {
      return 'fallback';
    }
    if (finalEmotion == 'inspirada') {
      return 'devotional';
    }

    return userCue;
  }

  bool _isPrayerRequest(String text) {
    final lower = text.toLowerCase();
    return lower.contains('oracion') ||
        lower.contains('oración') ||
        lower.contains('orar') ||
        lower.contains('oremos') ||
        lower.contains('ayuda espiritual') ||
        lower.contains('ayudame a orar') ||
        lower.contains('ayúdame a orar');
  }

  List<String> _compactSequence(List<String> sequence) {
    final compacted = <String>[];
    for (final emotion in sequence) {
      if (emotion.isEmpty) continue;
      if (compacted.isEmpty || compacted.last != emotion) {
        compacted.add(emotion);
      }
    }
    return compacted;
  }

  Future<void> _setAvatarState({
    required String emotion,
    bool? speaking,
    bool? waiting,
    String? reply,
  }) async {
    if (!mounted) return;
    setState(() {
      _currentEmotion = emotion;
      if (speaking != null) {
        _isSpeaking = speaking;
      }
      if (waiting != null) {
        _isWaitingForBot = waiting;
      }
      if (reply != null) {
        _botReply = reply;
      }
    });
  }

  int _overclockThinkingStage(Duration elapsed) {
    if (elapsed < _overclockWarmupThreshold) {
      return 0;
    }
    if (elapsed < _overclockLongWaitThreshold) {
      return 1;
    }
    return 2;
  }

  Duration _overclockThinkingInterval(Duration elapsed) {
    switch (_overclockThinkingStage(elapsed)) {
      case 0:
        return const Duration(milliseconds: 520);
      case 1:
        return const Duration(milliseconds: 1100);
      default:
        return const Duration(milliseconds: 1900);
    }
  }

  String _overclockWaitingReply(Duration elapsed) {
    switch (_overclockThinkingStage(elapsed)) {
      case 0:
        return 'Activando modo overclock...';
      case 1:
        return 'Maika sigue procesando tu respuesta...';
      default:
        return 'Maika está pensando con calma...';
    }
  }

  List<String> _buildOverclockThinkingSequenceForElapsed({
    required String cue,
    required Duration elapsed,
  }) {
    switch (_overclockThinkingStage(elapsed)) {
      case 0:
        return _buildThinkingSequence(
          useOverclock: true,
          anticipatedEmotion: 'neutral_cool',
          isPrayerRequest: false,
          cue: cue,
        );
      case 1:
        switch (cue) {
          case 'curiosity':
            return const ['pensativa', 'asombrada', 'neutral_cool'];
          case 'quiz':
          case 'celebration':
            return const ['pensativa', 'nerd', 'neutral_cool'];
          case 'affection':
            return const ['neutral_cool', 'feliz_1'];
          case 'fallback':
            return const ['pensativa', 'confundida'];
          default:
            return const ['pensativa', 'neutral_cool'];
        }
      default:
        switch (cue) {
          case 'fallback':
            return const ['pensativa', 'confundida'];
          case 'curiosity':
            return const ['pensativa', 'asombrada'];
          default:
            return const ['pensativa', 'neutral_cool'];
        }
    }
  }

  void _startThinkingLoop({
    required int runId,
    required bool useOverclock,
    required String anticipatedEmotion,
    required bool isPrayerRequest,
    required String cue,
  }) {
    final startedAt = DateTime.now();
    var stage = -1;
    var sequence = <String>[];
    var index = 0;
    var nextTransitionAt = startedAt;
    var overclockWarmupCompleted = false;

    _thinkingTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_isAnimationActive(runId) || !_isWaitingForBot) {
        _thinkingTimer?.cancel();
        _thinkingTimer = null;
        return;
      }

      final now = DateTime.now();
      final elapsed = now.difference(startedAt);

      if (useOverclock) {
        final computedStage = _overclockThinkingStage(elapsed);
        final newStage =
            overclockWarmupCompleted && computedStage == 0 ? 1 : computedStage;
        if (newStage != stage || sequence.isEmpty) {
          stage = newStage;
          sequence = _buildOverclockThinkingSequenceForElapsed(
            cue: cue,
            elapsed: stage == 1 && computedStage == 0
                ? _overclockWarmupThreshold
                : elapsed,
          );
          index = 0;
          nextTransitionAt = now.add(
            _overclockThinkingInterval(
              stage == 1 && computedStage == 0
                  ? _overclockWarmupThreshold
                  : elapsed,
            ),
          );
          setState(() {
            _currentEmotion = sequence.first;
            final waitingReply = _overclockWaitingReply(
              stage == 1 && computedStage == 0
                  ? _overclockWarmupThreshold
                  : elapsed,
            );
            if (_botReply != waitingReply) {
              _botReply = waitingReply;
            }
          });
          return;
        }

        if (now.isBefore(nextTransitionAt) || sequence.length <= 1) {
          return;
        }

        if (stage == 0 && index == sequence.length - 1) {
          overclockWarmupCompleted = true;
          nextTransitionAt = now;
          return;
        }

        index = (index + 1) % sequence.length;
        nextTransitionAt = now.add(_overclockThinkingInterval(elapsed));
        setState(() {
          _currentEmotion = sequence[index];
        });
        return;
      }

      if (sequence.isEmpty) {
        sequence = _buildThinkingSequence(
          useOverclock: useOverclock,
          anticipatedEmotion: anticipatedEmotion,
          isPrayerRequest: isPrayerRequest,
          cue: cue,
        );
        if (sequence.length <= 1) {
          _thinkingTimer?.cancel();
          _thinkingTimer = null;
          return;
        }
        nextTransitionAt = now.add(const Duration(milliseconds: 520));
        return;
      }

      if (now.isBefore(nextTransitionAt)) {
        return;
      }

      index = (index + 1) % sequence.length;
      nextTransitionAt = now.add(const Duration(milliseconds: 520));
      setState(() {
        _currentEmotion = sequence[index];
      });
    });
  }

  Future<void> _playSequence({
    required int runId,
    required List<String> sequence,
    required Duration stepDuration,
    required bool speaking,
  }) async {
    final compacted = _compactSequence(sequence);
    if (compacted.isEmpty) return;

    for (var index = 0; index < compacted.length; index++) {
      if (!_isAnimationActive(runId)) return;

      await _setAvatarState(
        emotion: compacted[index],
        speaking: speaking,
      );

      if (index < compacted.length - 1) {
        await Future.delayed(stepDuration);
      }
    }
  }

  List<String> _buildThinkingSequence({
    required bool useOverclock,
    required String anticipatedEmotion,
    required bool isPrayerRequest,
    required String cue,
  }) {
    if (useOverclock) {
      switch (cue) {
        case 'quiz':
          return const ['neutral_cool', 'nerd', 'pensativa'];
        case 'curiosity':
          return const ['neutral_cool', 'asombrada', 'pensativa'];
        case 'comfort':
        case 'prayer':
          return const ['neutral_cool', 'pensativa', 'triste_1'];
        case 'affection':
          return const ['neutral_cool', 'feliz_1', 'pensativa'];
        case 'greeting':
          return const ['neutral_cool', 'feliz_1', 'pensativa'];
        case 'fallback':
          return const ['pensativa', 'impactada', 'confundida'];
        default:
          return const ['neutral_cool', 'nerd', 'pensativa'];
      }
    }

    if (isPrayerRequest) {
      return const ['triste', 'pensativa', 'orando', 'pensativa'];
    }

    switch (cue) {
      case 'quiz':
        return const ['pensativa', 'orgullosa', 'pensativa'];
      case 'curiosity':
        return const ['sorprendida', 'pensativa', 'sorprendida'];
      case 'comfort':
        return const ['triste', 'pensativa', 'aliviada'];
      case 'greeting':
        return const ['feliz', 'pensativa', 'feliz'];
      case 'affection':
        return const ['sonrojada', 'picara_sonrojada', 'sonrojada'];
      case 'devotional':
        return const ['inspirada', 'pensativa', 'inspirada'];
      case 'farewell':
        return const ['feliz', 'sonrojada', 'feliz'];
      case 'fallback':
        return const ['dudando', 'pensativa', 'confundida'];
    }

    switch (anticipatedEmotion) {
      case 'inspirada':
        return const ['inspirada', 'pensativa', 'inspirada'];
      case 'sonrojada':
      case 'picara':
      case 'picara_sonrojada':
        return const ['sonrojada', 'picara', 'sonrojada'];
      case 'nerviosa':
      case 'muy_nerviosa':
      case 'confundida':
      case 'dudando':
        return const ['dudando', 'pensativa', 'confundida'];
      case 'triste':
      case 'cansada':
        return const ['triste', 'pensativa', 'triste'];
      case 'orgullosa':
      case 'feliz':
        return const ['orgullosa', 'pensativa', 'feliz'];
      case 'sorprendida':
        return const ['sorprendida', 'pensativa', 'sorprendida'];
      default:
        return const ['pensativa', 'dudando', 'pensativa'];
    }
  }

  List<String> _buildResponseSequence({
    required bool useOverclock,
    required String finalEmotion,
    required bool holdPrayerPose,
    required String cue,
  }) {
    if (useOverclock) {
      switch (cue) {
        case 'celebration':
          return const ['feliz_1', 'feliz_2', 'orgullosa'];
        case 'quiz':
          return const ['nerd', 'feliz_1', 'orgullosa'];
        case 'curiosity':
          return const ['asombrada', 'impactada', 'neutral_cool'];
        case 'comfort':
          return const ['pensativa', 'triste_1', 'neutral_cool'];
        case 'greeting':
          return const ['feliz_1', 'feliz_2', 'neutral_cool'];
        case 'affection':
          return const ['feliz_1', 'feliz_2', 'neutral_cool'];
        case 'farewell':
          return const ['feliz_2', 'neutral_cool'];
        case 'fallback':
          return const ['impactada', 'confundida'];
      }

      switch (finalEmotion) {
        case 'feliz':
        case 'feliz_1':
        case 'feliz_2':
        case 'orgullosa':
          return const ['feliz_1', 'feliz_2', 'orgullosa'];
        case 'sorprendida':
        case 'asombrada':
          return const ['asombrada', 'impactada'];
        case 'impactada':
        case 'confundida':
        case 'cofundida':
          return const ['impactada', 'confundida'];
        case 'triste':
        case 'triste_1':
        case 'llorando':
        case 'derrotada':
          return const ['triste_1', 'derrotada'];
        case 'enojada':
        case 'enojada_1':
        case 'enojada_2':
          return const ['enojada_1', 'enojada_2'];
        case 'aburrida':
          return const ['aburrida', 'neutral_cool'];
        case 'nerd':
        case 'pensativa':
          return const ['nerd', 'pensativa'];
        case 'neutral':
        case 'neutral_cool':
        default:
          return const ['pensativa', 'neutral_cool'];
      }
    }

    if (holdPrayerPose || finalEmotion == 'orando') {
      return const ['pensativa', 'orando'];
    }

    switch (cue) {
      case 'celebration':
        return const ['feliz', 'feliz_logro', 'orgullosa'];
      case 'quiz':
        return const ['pensativa', 'feliz_logro', 'orgullosa'];
      case 'curiosity':
        return const ['sorprendida', 'pensativa', 'sorprendida'];
      case 'comfort':
        return const ['triste', 'aliviada'];
      case 'greeting':
        return const ['feliz', 'sonrojada'];
      case 'affection':
        return const ['sonrojada', 'picara_sonrojada', 'sonrojada'];
      case 'devotional':
        return const ['inspirada', 'pensativa', 'inspirada'];
      case 'farewell':
        return const ['feliz', 'sonrojada', 'neutral'];
      case 'fallback':
        return const ['dudando', 'confundida'];
    }

    switch (finalEmotion) {
      case 'feliz_logro':
        return const ['feliz', 'feliz_logro', 'orgullosa'];
      case 'feliz':
      case 'orgullosa':
        return const ['feliz', 'orgullosa'];
      case 'inspirada':
        return const ['inspirada', 'pensativa', 'inspirada'];
      case 'aliviada':
        return const ['triste', 'aliviada'];
      case 'triste':
      case 'cansada':
        return const ['pensativa', 'triste'];
      case 'sorprendida':
        return const ['sorprendida', 'pensativa'];
      case 'sonrojada':
      case 'picara_sonrojada':
        return const ['sonrojada', 'picara_sonrojada'];
      case 'picara':
        return const ['picara', 'sonrojada'];
      case 'nerviosa':
      case 'muy_nerviosa':
        return const ['nerviosa', 'pensativa'];
      case 'confundida':
      case 'dudando':
        return const ['dudando', 'confundida'];
      case 'aburrida':
        return const ['aburrida', 'pensativa'];
      case 'enojada':
        return const ['enojada', 'pensativa'];
      case 'neutral':
      default:
        return const ['pensativa', 'neutral'];
    }
  }

  Future<void> _animateResponseFlow({
    required int runId,
    required bool useOverclock,
    required String finalEmotion,
    required bool holdPrayerPose,
    required String cue,
  }) async {
    final responseSequence = _buildResponseSequence(
      useOverclock: useOverclock,
      finalEmotion: finalEmotion,
      holdPrayerPose: holdPrayerPose,
      cue: cue,
    );

    await _playSequence(
      runId: runId,
      sequence: responseSequence,
      stepDuration: const Duration(milliseconds: 320),
      speaking: true,
    );

    if (!_isAnimationActive(runId)) return;

    await Future.delayed(
      holdPrayerPose
          ? const Duration(milliseconds: 1600)
          : const Duration(milliseconds: 1200),
    );

    if (!_isAnimationActive(runId)) return;

    if (holdPrayerPose) {
      await _setAvatarState(
        emotion: 'orando',
        speaking: false,
      );
      return;
    }

    final restingEmotion = useOverclock && finalEmotion == 'confundida'
        ? 'confundida'
        : _restingEmotionForMode(useOverclock);

    await _setAvatarState(
      emotion: restingEmotion,
      speaking: false,
    );
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
    if (lower.contains('pienso que') || lower.contains('he estado pensando')) {
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

    final useOverclock = _isOverclockEnabled;
    final isPrayerRequest = !useOverclock && _isPrayerRequest(message);
    final userCue = _conversationCueForText(message);
    final anticipatedEmotion = useOverclock
        ? _restingEmotionForMode(true)
        : _emotionForUserText(message);
    final runId = _startAnimationRun();

    _ctrl.clear();
    setState(() {
      _isWaitingForBot = true;
      _isSpeaking = false;
      _currentEmotion = anticipatedEmotion;
      _botReply = useOverclock
          ? 'Activando modo overclock...'
          : 'Estoy pensando en la mejor respuesta...';
    });
    _startThinkingLoop(
      runId: runId,
      useOverclock: useOverclock,
      anticipatedEmotion: anticipatedEmotion,
      isPrayerRequest: isPrayerRequest,
      cue: userCue,
    );

    try {
      if (useOverclock) {
        final response = await _overclock.sendMessage(message);

        if (!_isAnimationActive(runId)) return;

        _thinkingTimer?.cancel();
        _thinkingTimer = null;

        await _setAvatarState(
          emotion: _currentEmotion,
          waiting: false,
          speaking: true,
          reply: response.text,
        );
        final responseCue = _resolveResponseCue(
          userCue: userCue,
          responseText: response.text,
          finalEmotion: response.emotion,
          holdPrayerPose: false,
        );
        await _animateResponseFlow(
          runId: runId,
          useOverclock: true,
          finalEmotion: response.emotion,
          holdPrayerPose: false,
          cue: responseCue,
        );
      } else {
        final response = await _rasa.sendMessage(message);

        if (!_isAnimationActive(runId)) return;

        _thinkingTimer?.cancel();
        _thinkingTimer = null;

        final holdPrayerPose = isPrayerRequest || response.emotion == 'orando';
        await _setAvatarState(
          emotion: _currentEmotion,
          waiting: false,
          speaking: true,
          reply: response.text,
        );
        final responseCue = _resolveResponseCue(
          userCue: userCue,
          responseText: response.text,
          finalEmotion: holdPrayerPose ? 'orando' : response.emotion,
          holdPrayerPose: holdPrayerPose,
        );
        await _animateResponseFlow(
          runId: runId,
          useOverclock: false,
          finalEmotion: holdPrayerPose ? 'orando' : response.emotion,
          holdPrayerPose: holdPrayerPose,
          cue: responseCue,
        );
      }
    } catch (error) {
      _thinkingTimer?.cancel();
      _thinkingTimer = null;
      if (!_isAnimationActive(runId)) return;

      await _setAvatarState(
        emotion: 'confundida',
        waiting: false,
        speaking: true,
        reply: useOverclock
            ? 'Lo siento, el modo overclock falló al responder: $error'
            : 'Lo siento, Rasa falló al responder: $error',
      );
      await _animateResponseFlow(
        runId: runId,
        useOverclock: useOverclock,
        finalEmotion: 'confundida',
        holdPrayerPose: false,
        cue: 'fallback',
      );
    }

    // Pequeña animación de "hablar"
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
          child: const Text('M.A.I.K.A'),
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
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Overclock',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 64,
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _overclockPulseAnimation,
                      builder: (context, child) {
                        final pulse = _isOverclockEnabled
                            ? _overclockPulseAnimation.value
                            : 0.0;
                        return Container(
                          width: 60,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: _isOverclockEnabled
                                ? LinearGradient(
                                    colors: [
                                      Color.lerp(
                                        const Color(0xFF5B21B6),
                                        const Color(0xFF8B5CF6),
                                        pulse,
                                      )!,
                                      Color.lerp(
                                        const Color(0xFF2563EB),
                                        const Color(0xFF22D3EE),
                                        pulse,
                                      )!,
                                    ],
                                  )
                                : null,
                            color: _isOverclockEnabled
                                ? null
                                : Colors.white.withValues(alpha: 0.05),
                            boxShadow: _isOverclockEnabled
                                ? [
                                    BoxShadow(
                                      color: Color.lerp(
                                        const Color(0x554F46E5),
                                        const Color(0xAA22D3EE),
                                        pulse,
                                      )!,
                                      blurRadius: 12 + (pulse * 10),
                                      spreadRadius: 1 + (pulse * 1.5),
                                    ),
                                  ]
                                : const [],
                          ),
                          child: child,
                        );
                      },
                      child: Opacity(
                        opacity: _isOverclockUnlocked ? 1 : 0.9,
                        child: IgnorePointer(
                          ignoring:
                              !_isOverclockUnlocked || !_isOverclockAccessReady,
                          child: Switch(
                            value: _isOverclockEnabled,
                            onChanged: _isOverclockUnlocked
                                ? _setOverclockEnabled
                                : null,
                          ),
                        ),
                      ),
                    ),
                    if (!_isOverclockUnlocked)
                      Positioned(
                        right: 4,
                        child: GestureDetector(
                          onTap:
                              _isOverclockAccessReady && !_isUnlockingOverclock
                                  ? _promptOverclockUnlock
                                  : null,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: _isUnlockingOverclock ? 0.65 : 1,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0x66FBC02D),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFD54F),
                                  width: 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x55FFC107),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: _isUnlockingOverclock
                                  ? const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Color(0xFFFFF3B0),
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.lock_rounded,
                                      size: 13,
                                      color: Color(0xFFFFD54F),
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
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
                            useOverclockAssets: _isOverclockEnabled,
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
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
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
                      child: _buildNeonBorder(
                        borderRadius: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: TextField(
                            controller: _ctrl,
                            decoration: const InputDecoration(
                              hintText: 'Escribe tu mensaje...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                            ),
                            onSubmitted: (value) {
                              if (_isComposing && !_isWaitingForBot) {
                                _send(value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ScaleTransition(
                      scale: _sendButtonAnimation,
                      child: GestureDetector(
                        onTap: (_isComposing && !_isWaitingForBot)
                            ? () => _send(_ctrl.text)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isComposing && !_isWaitingForBot
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6B46C1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.1),
                                      Colors.white.withValues(alpha: 0.05),
                                    ],
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B4DFF).withValues(
                                  alpha: (_isComposing && !_isWaitingForBot)
                                      ? 0.6
                                      : 0.0,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isWaitingForBot
                                ? Icons.hourglass_top
                                : Icons.send_rounded,
                            color: Colors.white,
                          ),
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

Widget _buildNeonBorder({
  required double borderRadius,
  required Widget child,
}) {
  // Este helper simple se basa en un AnimationController global
  // almacenado en un InheritedWidget implícito: usamos una instancia
  // local de AnimationController para el borde del input.
  return _NeonBorderWrapper(
    borderRadius: borderRadius,
    child: child,
  );
}

class _NeonBorderWrapper extends StatefulWidget {
  const _NeonBorderWrapper({
    required this.borderRadius,
    required this.child,
  });

  final double borderRadius;
  final Widget child;

  @override
  State<_NeonBorderWrapper> createState() => _NeonBorderWrapperState();
}

class _NeonBorderWrapperState extends State<_NeonBorderWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: NeonGlowBorderPainter(
                  colors: _neonBorderColors,
                  rotationAngle: _controller.value * 2 * math.pi,
                  borderWidth: 3.0,
                  glowWidth: 12.0,
                  borderRadius: widget.borderRadius,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(3.0),
              child: widget.child,
            ),
          ],
        );
      },
    );
  }
}

class NeonGlowBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double rotationAngle;
  final double borderWidth;
  final double glowWidth;
  final double borderRadius;

  NeonGlowBorderPainter({
    required this.colors,
    required this.rotationAngle,
    required this.borderWidth,
    required this.glowWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowWidth / 2);

    glowPaint.color = colors.first.withOpacity(0.25);
    canvas.drawRRect(rrect, glowPaint);

    final borderGradient = SweepGradient(
      center: Alignment.center,
      colors: colors,
      stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      transform: GradientRotation(rotationAngle),
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = borderGradient.createShader(Offset.zero & size);

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant NeonGlowBorderPainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.borderRadius != borderRadius;
  }
}
