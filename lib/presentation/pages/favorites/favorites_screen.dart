import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.textPrimary;
    final textSecondary = scheme.textSecondary;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('Favoritos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FavoritesHero(
              scheme: scheme,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _FavoriteCard(
                    scheme: scheme,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    title:
                        _sampleFavorites[index %
                            _sampleFavorites.length]['reference']!,
                    body:
                        _sampleFavorites[index %
                            _sampleFavorites.length]['text']!,
                    category:
                        _sampleFavorites[index %
                            _sampleFavorites.length]['category']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, String>> _sampleFavorites = [
    {
      'text':
          'Porque de tal manera amo Dios al mundo, que ha dado a su Hijo unigenito, para que todo aquel que en el cree, no se pierda, mas tenga vida eterna.',
      'reference': 'Juan 3:16',
      'category': 'Amor',
    },
    {
      'text': 'El Senor es mi pastor, nada me faltara.',
      'reference': 'Salmo 23:1',
      'category': 'Cuidado',
    },
    {
      'text':
          'Confia en el Senor con todo tu corazon, y no te apoyes en tu propia prudencia.',
      'reference': 'Proverbios 3:5',
      'category': 'Sabiduria',
    },
  ];
}

class _FavoritesHero extends StatelessWidget {
  final ColorScheme scheme;
  final Color textPrimary;
  final Color textSecondary;

  const _FavoritesHero({
    required this.scheme,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.favorite, color: scheme.onPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus versiculos guardados',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Regresa a ellos cuando necesites animo.',
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: scheme.onPrimary.withValues(alpha: 0.8),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final ColorScheme scheme;
  final Color textPrimary;
  final Color textSecondary;
  final String title;
  final String body;
  final String category;

  const _FavoriteCard({
    required this.scheme,
    required this.textPrimary,
    required this.textSecondary,
    required this.title,
    required this.body,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.borderWithOverlay(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.favorite, color: const Color(0xFFEC4899), size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: TextStyle(color: textPrimary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: scheme.primary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
