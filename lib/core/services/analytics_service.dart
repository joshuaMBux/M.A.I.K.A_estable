import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/gamification_repository.dart';
import '../database/database_helper.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  GamificationRepository? _gamificationRepository;

  void attachGamificationRepository(GamificationRepository repository) {
    _gamificationRepository = repository;
  }

  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? params,
  }) async {
    // Punto centralizado para eventos de analytics.
    // ignore: avoid_print
    print('[Analytics] $name -> $params');

    // En web no usamos SQLite (sqflite no está soportado).
    if (kIsWeb) {
      return;
    }

    final game = (params?['game'] as String?) ?? 'unknown';
    final dynamic completedRaw = params?['completed'];
    int? completed;
    if (completedRaw is bool) {
      completed = completedRaw ? 1 : 0;
    } else if (completedRaw is int) {
      completed = completedRaw;
    }

    await _dbHelper.insertGameActivity(
      eventName: name,
      game: game,
      completed: completed,
      secondsPlayed: params?['seconds_played'] as int?,
      fragmentsCollected: params?['fragments_collected'] as int?,
    );

    await _applyGamificationRewards(name, params: params);
  }

  Future<void> _applyGamificationRewards(
    String name, {
    Map<String, dynamic>? params,
  }) async {
    final repository = _gamificationRepository;
    if (repository == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) {
      return;
    }

    final gameKey = (params?['game_key'] as String?) ??
        ((params?['game'] as String?) ?? 'unknown');
    final completed = params?['completed'];
    final isCompleted = completed == true || completed == 1;

    if (name == 'game_session_finished') {
      final sessionKey = params?['session_key'] as String?;
      if (sessionKey == null || sessionKey.isEmpty) {
        return;
      }
      await repository.rewardMinigameSession(
        userId: userId,
        gameKey: gameKey,
        sessionKey: sessionKey,
        secondsPlayed: params?['seconds_played'] as int?,
        fragmentsCollected: params?['fragments_collected'] as int?,
      );
      return;
    }

    if (name == 'game_finished' && isCompleted) {
      final roundKey = params?['round_key'] as String?;
      if (roundKey == null || roundKey.isEmpty) {
        return;
      }
      await repository.rewardMinigameVictory(
        userId: userId,
        gameKey: gameKey,
        roundKey: roundKey,
        fragmentsCollected: params?['fragments_collected'] as int?,
      );
    }
  }
}
