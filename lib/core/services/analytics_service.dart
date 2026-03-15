import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

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
  }
}

