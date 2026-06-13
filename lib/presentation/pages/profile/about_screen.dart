import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace. '
              'Revisa que tengas un navegador instalado.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Acerca de Maika'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: scheme.pageGradient,
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: scheme.borderWithOverlay(
                              0.25,
                              lightAlpha: 0.12,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'maika.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Maika',
                              style: textTheme.titleMedium?.copyWith(
                                color: scheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Tu asistente bíblico personal',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explora la Biblia con chat de IA, minijuegos y planes de lectura en un solo lugar.',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _InfoRow(
                        icon: Icons.tag,
                        title: 'Versión',
                        subtitle: '1.0.0',
                      ),
                      SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.info_outline,
                        title: 'Descripción',
                        subtitle:
                            'Aplicación offline-first para devocionales, lectura bíblica '
                            'y chat con IA integrada.',
                      ),
                      SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.code,
                        title: 'Tecnología',
                        subtitle:
                            'Flutter, SQLite, arquitectura limpia por capas.',
                      ),
                    ],
                  ),
                ),
                GlassCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Desarrollador',
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _InfoRow(
                        icon: Icons.person,
                        title: 'Autor',
                        subtitle: 'Josue Moya',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openUrl(
                                  context, 'https://github.com/joshuaMBux'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: scheme.textPrimary,
                                side: BorderSide(
                                  color: scheme.borderWithOverlay(
                                    0.6,
                                    lightAlpha: 0.2,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.code),
                              label: const Text('GitHub'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openUrl(
                                context,
                                'https://www.linkedin.com/in/josue-moya-a94299322',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: scheme.textPrimary,
                                side: BorderSide(
                                  color: scheme.borderWithOverlay(
                                    0.6,
                                    lightAlpha: 0.2,
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.business_center_outlined),
                              label: const Text('LinkedIn'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: scheme.overlayOnSurface(0.08, lightAlpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: scheme.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
