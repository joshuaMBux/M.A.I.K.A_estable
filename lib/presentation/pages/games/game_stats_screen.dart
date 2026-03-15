import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/database/database_helper.dart';

class GameStatsScreen extends StatelessWidget {
  const GameStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1420),
      appBar: AppBar(
        title: const Text('Estadísticas de minijuegos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: kIsWeb
            ? Future.value(<Map<String, dynamic>>[])
            : DatabaseHelper().getGameActivity(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            if (kIsWeb) {
              return const Center(
                child: Text(
                  'Las estadísticas de minijuegos\n'
                  'solo se guardan en Android/iOS.\n'
                  'En web se muestran solo como demo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              );
            } else {
              return const Center(
                child: Text(
                  'Todavía no hay datos de minijuegos.\n'
                  'Juega una partida para ver estadísticas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
          }

          final statsByGame = _aggregateByGame(data);
          final games = statsByGame.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final gameName = games[index];
              final stats = statsByGame[gameName]!;

              final avgSeconds = stats.sessions > 0
                  ? (stats.totalSeconds / stats.sessions).round()
                  : 0;
              final avgFragments = stats.sessions > 0
                  ? (stats.totalFragments / stats.sessions)
                  : 0.0;
              final completionRate = stats.finishedCount > 0
                  ? (stats.completedWins / stats.finishedCount * 100).round()
                  : 0;

              return Card(
                color: const Color(0xFF1A2233),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6B46C1),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          gameName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sesiones jugadas: ${stats.sessions}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Duración media por sesión: ${avgSeconds}s',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Fragmentos promedio por sesión: '
                        '${avgFragments.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Partidas completadas: $completionRate%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, _GameStats> _aggregateByGame(
    List<Map<String, dynamic>> rows,
  ) {
    final Map<String, _GameStats> result = {};

    for (final row in rows) {
      final game = (row['game'] as String?) ?? 'unknown';
      final eventName = row['event_name'] as String? ?? '';
      final stats = result.putIfAbsent(game, () => _GameStats(game: game));

      if (eventName == 'game_session_finished') {
        stats.sessions++;
        final seconds = row['seconds_played'] as int? ?? 0;
        final fragments = row['fragments_collected'] as int? ?? 0;
        stats.totalSeconds += seconds;
        stats.totalFragments += fragments;
      } else if (eventName == 'game_finished') {
        stats.finishedCount++;
        final completed = row['completed'] as int? ?? 0;
        if (completed == 1) {
          stats.completedWins++;
        }
      }
    }

    return result;
  }
}

class _GameStats {
  final String game;
  int sessions = 0;
  int totalSeconds = 0;
  int totalFragments = 0;
  int finishedCount = 0;
  int completedWins = 0;

  _GameStats({required this.game});
}

