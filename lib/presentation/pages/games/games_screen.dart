import 'package:flutter/material.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../widgets/glass_card.dart';
import 'game_stats_screen.dart';
import '../../games/maika_fragmentada/pages/rpg_game_page.dart';

class MiniGame {
  final String title;
  final IconData icon;
  final String image;
  final WidgetBuilder builder;
  final bool isNew;

  const MiniGame({
    required this.title,
    required this.icon,
    required this.image,
    required this.builder,
    this.isNew = false,
  });
}

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  static const List<MiniGame> games = [
    MiniGame(
      title: 'Maika y la Biblia Fragmentada',
      icon: Icons.videogame_asset_rounded,
      image: 'assets/images/maika.png',
      builder: _buildRpgGame,
      isNew: true,
    ),
  ];

  static Widget _buildRpgGame(BuildContext context) {
    return RpgGamePage.prototype();
  }

  void _openGame(BuildContext context, MiniGame game) {
    AnalyticsService().logEvent(
      'game_opened',
      params: {'game': game.title},
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: game.builder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Minijuegos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Ver estadísticas',
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado restaurado al estilo original:
                  // banner ancho con gradiente y texto centrado.
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
                              // Subimos más la imagen para centrar el rostro.
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
                          onTap: () => _openGame(context, game),
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

  void _handleTap() async {
    await _scaleController.reverse();
    if (!mounted) return;
    await _scaleController.forward();
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final game = widget.game;

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
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: Image.asset(
                      game.image,
                      fit: BoxFit.cover,
                    ),
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
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF6B46C1),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
    );
  }
}
