import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/theme/theme_extensions.dart';
import 'game_metrics.dart';

class GameStatsScreen extends StatelessWidget {
  const GameStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Estadisticas de minijuegos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: scheme.pageGradient,
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Las estadisticas de minijuegos\n'
                        'solo se guardan en Android/iOS.\n'
                        'En web se muestran solo como demo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.textSecondary),
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Todavia no hay datos de minijuegos.\n'
                        'Juega una partida para ver estadisticas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.textSecondary),
                      ),
                    ),
                  );
                }
              }

              final statsByGame = _aggregateByGame(data);
              final games = statsByGame.keys.toList()
                ..sort((a, b) {
                  final aStats = statsByGame[a]!;
                  final bStats = statsByGame[b]!;
                  final sessionsCompare = bStats.sessions.compareTo(aStats.sessions);
                  if (sessionsCompare != 0) {
                    return sessionsCompare;
                  }
                  return trackedGameTitle(a).compareTo(trackedGameTitle(b));
                });
              final overall = _OverallStats.from(statsByGame.values);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _SectionLabel(
                    title: 'Resumen general',
                    subtitle: 'Vista rapida de tu actividad en minijuegos',
                  ),
                  const SizedBox(height: 14),
                  _OverviewGrid(overall: overall),
                  const SizedBox(height: 24),
                  Text(
                    'Por juego',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...games.map((gameName) {
                    final stats = statsByGame[gameName]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _GameStatsCard(stats: stats),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, _GameStats> _aggregateByGame(
    List<Map<String, dynamic>> rows,
  ) {
    final Map<String, _GameStats> result = {};

    for (final row in rows) {
      final eventName = row['event_name'] as String? ?? '';
      if (eventName != 'game_session_finished' && eventName != 'game_finished') {
        continue;
      }

      final game = normalizeTrackedGameKey(
        (row['game'] as String?) ?? 'unknown',
      );
      final stats = result.putIfAbsent(game, () => _GameStats(game: game));
      final createdAt = (row['created_at'] as num?)?.toInt();
      if (createdAt != null) {
        stats.lastPlayedAt = stats.lastPlayedAt == null
            ? createdAt
            : (createdAt > stats.lastPlayedAt! ? createdAt : stats.lastPlayedAt);
      }

      if (eventName == 'game_session_finished') {
        stats.sessions++;
        final seconds = (row['seconds_played'] as num?)?.toInt() ?? 0;
        final fragments = (row['fragments_collected'] as num?)?.toInt() ?? 0;
        stats.totalSeconds += seconds;
        stats.totalFragments += fragments;
        if (seconds > stats.bestSessionSeconds) {
          stats.bestSessionSeconds = seconds;
        }
        if (fragments > stats.bestFragments) {
          stats.bestFragments = fragments;
        }
      } else if (eventName == 'game_finished') {
        stats.finishedCount++;
        final completed = (row['completed'] as num?)?.toInt() ?? 0;
        if (completed == 1) {
          stats.completedWins++;
        }
      }
    }

    return result;
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: scheme.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  final _OverallStats overall;

  const _OverviewGrid({required this.overall});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _OverviewTile(
          icon: Icons.sports_esports_rounded,
          label: 'Sesiones',
          value: '${overall.sessions}',
          accent: const Color(0xFF8B5CF6),
        ),
        _OverviewTile(
          icon: Icons.timer_rounded,
          label: 'Tiempo total',
          value: _formatDuration(overall.totalSeconds),
          accent: const Color(0xFF22C55E),
        ),
        _OverviewTile(
          icon: Icons.auto_awesome_rounded,
          label: 'Fragmentos',
          value: '${overall.totalFragments}',
          accent: const Color(0xFFF59E0B),
        ),
        _OverviewTile(
          icon: Icons.emoji_events_rounded,
          label: 'Tasa de victoria',
          value: '${overall.completionRate}%',
          accent: const Color(0xFF60A5FA),
        ),
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _OverviewTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.borderWithOverlay(0.06, lightAlpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: scheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: scheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameStatsCard extends StatelessWidget {
  final _GameStats stats;

  const _GameStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avgSeconds = stats.sessions > 0
        ? (stats.totalSeconds / stats.sessions).round()
        : 0;
    final avgFragments = stats.sessions > 0
        ? (stats.totalFragments / stats.sessions)
        : 0.0;
    final completionRate = stats.finishedCount > 0
        ? (stats.completedWins / stats.finishedCount * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.borderWithOverlay(0.06, lightAlpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6B46C1),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.videogame_asset_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trackedGameTitle(stats.game),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: scheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.lastPlayedAt == null
                            ? 'Sin actividad reciente'
                            : 'Ultima actividad: ${_formatTimestamp(stats.lastPlayedAt!)}',
                        style: TextStyle(
                          color: scheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricChip(
                  scheme: scheme,
                  label: 'Sesiones',
                  value: '${stats.sessions}',
                  accent: const Color(0xFF8B5CF6),
                ),
                _MetricChip(
                  scheme: scheme,
                  label: 'Tiempo total',
                  value: _formatDuration(stats.totalSeconds),
                  accent: const Color(0xFF22C55E),
                ),
                _MetricChip(
                  scheme: scheme,
                  label: 'Tasa de victoria',
                  value: '$completionRate%',
                  accent: const Color(0xFF60A5FA),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DetailTile(
                    scheme: scheme,
                    label: 'Promedio por sesion',
                    value: _formatDuration(avgSeconds),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailTile(
                    scheme: scheme,
                    label: 'Fragmentos promedio',
                    value: avgFragments.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DetailTile(
                    scheme: scheme,
                    label: 'Mejor sesion',
                    value: _formatDuration(stats.bestSessionSeconds),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailTile(
                    scheme: scheme,
                    label: 'Maximo fragmentos',
                    value: '${stats.bestFragments}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final String value;
  final Color accent;

  const _MetricChip({
    required this.scheme,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: scheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: scheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final ColorScheme scheme;
  final String label;
  final String value;

  const _DetailTile({
    required this.scheme,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.overlayOnSurface(0.04, lightAlpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.borderWithOverlay(0.05, lightAlpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: scheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallStats {
  final int sessions;
  final int totalSeconds;
  final int totalFragments;
  final int finishedCount;
  final int completedWins;

  const _OverallStats({
    required this.sessions,
    required this.totalSeconds,
    required this.totalFragments,
    required this.finishedCount,
    required this.completedWins,
  });

  factory _OverallStats.from(Iterable<_GameStats> stats) {
    var sessions = 0;
    var totalSeconds = 0;
    var totalFragments = 0;
    var finishedCount = 0;
    var completedWins = 0;

    for (final item in stats) {
      sessions += item.sessions;
      totalSeconds += item.totalSeconds;
      totalFragments += item.totalFragments;
      finishedCount += item.finishedCount;
      completedWins += item.completedWins;
    }

    return _OverallStats(
      sessions: sessions,
      totalSeconds: totalSeconds,
      totalFragments: totalFragments,
      finishedCount: finishedCount,
      completedWins: completedWins,
    );
  }

  int get completionRate {
    if (finishedCount <= 0) {
      return 0;
    }
    return (completedWins / finishedCount * 100).round();
  }
}

class _GameStats {
  final String game;
  int sessions = 0;
  int totalSeconds = 0;
  int totalFragments = 0;
  int finishedCount = 0;
  int completedWins = 0;
  int bestSessionSeconds = 0;
  int bestFragments = 0;
  int? lastPlayedAt;

  _GameStats({required this.game});
}

String _formatDuration(int seconds) {
  if (seconds <= 0) {
    return '0s';
  }

  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${remainingSeconds}s';
  }
  return '${remainingSeconds}s';
}

String _formatTimestamp(int millis) {
  final date = DateTime.fromMillisecondsSinceEpoch(millis);
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;

  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  if (isToday) {
    return 'Hoy, $hh:$mm';
  }

  final dd = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$dd/$month $hh:$mm';
}
