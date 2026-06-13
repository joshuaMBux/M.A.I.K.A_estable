import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../core/services/analytics_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/repositories/gamification_repository.dart';
import '../../games/maika_fragmentada/pages/rpg_game_page.dart';
import '../../widgets/glass_card.dart';
import 'game_metrics.dart';
import 'game_stats_screen.dart';

enum MiniGameAccess {
  available,
  locked,
}

class MiniGame {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String image;
  final WidgetBuilder? builder;
  final bool isNew;
  final MiniGameAccess access;
  final int unlockCost;

  const MiniGame({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.image,
    this.builder,
    this.isNew = false,
    this.access = MiniGameAccess.available,
    this.unlockCost = 0,
  });

  bool get isLocked => access == MiniGameAccess.locked;
}

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  static const List<MiniGame> games = [
    MiniGame(
      key: maikaFragmentadaGameKey,
      title: 'Maika y la Biblia Fragmentada',
      subtitle: 'Explora y reune fragmentos',
      icon: Icons.videogame_asset_rounded,
      image: 'assets/images/maika.png',
      builder: _buildRpgGame,
      isNew: true,
    ),
    MiniGame(
      key: 'quiz_exodo',
      title: 'Quiz del Exodo',
      subtitle: 'Preguntas y desafios biblicos',
      icon: Icons.quiz_rounded,
      image: 'assets/images/game_fragmentada.jpg',
      access: MiniGameAccess.locked,
      unlockCost: 120,
    ),
    MiniGame(
      key: 'memoria_versiculos',
      title: 'Memoria de Versiculos',
      subtitle: 'Encuentra las parejas correctas',
      icon: Icons.memory_rounded,
      image: 'assets/images/maika.png',
      access: MiniGameAccess.locked,
      unlockCost: 160,
    ),
    MiniGame(
      key: 'desafio_proverbios',
      title: 'Desafio de Proverbios',
      subtitle: 'Responde antes de que acabe el tiempo',
      icon: Icons.auto_awesome_rounded,
      image: 'assets/images/game_fragmentada.jpg',
      access: MiniGameAccess.locked,
      unlockCost: 180,
    ),
    MiniGame(
      key: 'batalla_personajes',
      title: 'Batalla de Personajes',
      subtitle: 'Elige la historia correcta',
      icon: Icons.shield_rounded,
      image: 'assets/images/maika.png',
      access: MiniGameAccess.locked,
      unlockCost: 220,
    ),
    MiniGame(
      key: 'nuevo_testamento_run',
      title: 'Nuevo Testamento Run',
      subtitle: 'Corre y esquiva en el camino',
      icon: Icons.directions_run_rounded,
      image: 'assets/images/game_fragmentada.jpg',
      access: MiniGameAccess.locked,
      unlockCost: 260,
    ),
  ];

  int _availableCoins = 0;

  static Widget _buildRpgGame(BuildContext context) {
    return RpgGamePage.prototype();
  }

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    if (kIsWeb || !di.sl.isRegistered<GamificationRepository>()) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 1;
    final repo = di.sl<GamificationRepository>();
    final dashboard = await repo.getDashboard(userId);

    if (!mounted) return;
    setState(() {
      _availableCoins = dashboard.progress.coins;
    });
  }

  Future<void> _handleGameTap(MiniGame game) async {
    if (game.isLocked) {
      AnalyticsService().logEvent(
        'game_locked_tapped',
        params: {
          'game': game.key,
          'game_key': game.key,
          'unlock_cost': game.unlockCost,
        },
      );
      await _showLockedGameSheet(game);
      return;
    }

    if (game.builder == null) {
      return;
    }

    AnalyticsService().logEvent(
      'game_opened',
      params: {
        'game': game.key,
        'game_key': game.key,
      },
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: game.builder!),
    );
  }

  Future<void> _showLockedGameSheet(MiniGame game) {
    final hasEnoughCoins = _availableCoins >= game.unlockCost;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: scheme.borderWithOverlay(0.08, lightAlpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadowWithOverlay(0.38, lightAlpha: 0.14),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: scheme.overlayOnSurface(0.18, lightAlpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFC107),
                                Color(0xFFFF9800),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Minijuego bloqueado',
                                style: TextStyle(
                                  color: scheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                game.title,
                                style: TextStyle(
                                  color: scheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Este minijuego necesita desbloquearse con monedas antes de poder jugarlo.',
                      style: TextStyle(
                        color: scheme.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Por ahora esta card funciona como adelanto del catalogo de juegos que ira llegando a Maika.',
                      style: TextStyle(
                        color: scheme.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoPill(
                            scheme: scheme,
                            icon: Icons.monetization_on_rounded,
                            label: 'Costo',
                            value: '${game.unlockCost} monedas',
                            accent: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoPill(
                            scheme: scheme,
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Tu saldo',
                            value: '$_availableCoins monedas',
                            accent: hasEnoughCoins
                                ? const Color(0xFF10B981)
                                : const Color(0xFF60A5FA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.overlayOnSurface(0.04, lightAlpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.borderWithOverlay(0.06, lightAlpha: 0.06),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            hasEnoughCoins
                                ? Icons.info_outline_rounded
                                : Icons.lock_clock_rounded,
                            color: scheme.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hasEnoughCoins
                                  ? 'Ya tienes saldo suficiente para cuando activemos este desbloqueo.'
                                  : 'Todavia necesitas reunir mas monedas para este minijuego.',
                              style: TextStyle(
                                color: scheme.textSecondary,
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Entendido'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Minijuegos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Ver estadisticas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GameStatsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: scheme.pageGradient,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.secondary],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(
                            opacity: 0.45,
                            child: Image.asset(
                              'assets/images/game_fragmentada.jpg',
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -1.0),
                            ),
                          ),
                          Center(
                            child: Text(
                              'Maika - Zona de minijuegos',
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(top: 4),
                      itemCount: games.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.86,
                      ),
                      itemBuilder: (context, index) {
                        final game = games[index];
                        return _MiniGameCard(
                          game: game,
                          onTap: () => _handleGameTap(game),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGameCard extends StatefulWidget {
  final MiniGame game;
  final VoidCallback onTap;

  const _MiniGameCard({
    required this.game,
    required this.onTap,
  });

  @override
  State<_MiniGameCard> createState() => _MiniGameCardState();
}

class _MiniGameCardState extends State<_MiniGameCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _scaleController.reverse();
    if (!mounted) return;
    await _scaleController.forward();
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final game = widget.game;
    final isLocked = game.isLocked;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 22,
        onTap: _handleTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                        child: Image.asset(
                          game.image,
                          fit: BoxFit.cover,
                          color: isLocked
                              ? scheme.shadowWithOverlay(0.34, lightAlpha: 0.18)
                              : null,
                          colorBlendMode:
                              isLocked ? BlendMode.darken : null,
                        ),
                      ),
                      if (isLocked)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                scheme.shadowWithOverlay(0.14, lightAlpha: 0.08),
                                scheme.shadowWithOverlay(0.38, lightAlpha: 0.2),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isLocked
                                ? const [
                                    Color(0xFF4B5563),
                                    Color(0xFF6B7280),
                                  ]
                                : const [
                                    Color(0xFF6B46C1),
                                    Color(0xFF8B5CF6),
                                  ],
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(14)),
                        ),
                        child: Icon(
                          game.icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        game.title,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isLocked ? scheme.textSecondary : scheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        game.subtitle,
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (game.isNew)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFFA726),
                        Color(0xFFFF7043),
                      ],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: const Text(
                    'Nuevo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: scheme.shadowWithOverlay(0.32, lightAlpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scheme.borderWithOverlay(0.12, lightAlpha: 0.08),
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            if (isLocked)
              Positioned(
                left: 10,
                right: 10,
                bottom: 92,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF59E0B),
                          Color(0xFFFFC107),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${game.unlockCost} monedas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final ColorScheme scheme;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _InfoPill({
    required this.scheme,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.overlayOnSurface(0.04, lightAlpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.borderWithOverlay(0.06, lightAlpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: scheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: scheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
