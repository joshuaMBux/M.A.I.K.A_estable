import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../blocs/devotional/devotional_bloc.dart';
import '../../blocs/devotional/devotional_event.dart';
import '../../blocs/devotional/devotional_state.dart';
import '../../../domain/entities/devotional.dart';

class DevotionalScreen extends StatelessWidget {
  const DevotionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<DevotionalBloc>()..add(const DevotionalStarted()),
      child: const _DevotionalView(),
    );
  }
}

class _DevotionalView extends StatelessWidget {
  const _DevotionalView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Devocional'),
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<DevotionalBloc, DevotionalState>(
        listener: (context, state) {
          if (state is DevotionalError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DevotionalLoading || state is DevotionalInitial) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
            );
          } else if (state is DevotionalLoaded) {
            return _DevotionalContent(state: state);
          } else if (state is DevotionalError) {
            return _DevotionalErrorView(message: state.message);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DevotionalErrorView extends StatelessWidget {
  final String message;

  const _DevotionalErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el devocional',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<DevotionalBloc>().add(const DevotionalStarted());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DevotionalContent extends StatelessWidget {
  final DevotionalLoaded state;

  const _DevotionalContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DevotionalBloc>();
    final displayDevotional = state.selected ?? state.today;
    final history = state.recent.where((devotional) {
      if (displayDevotional == null) return true;
      return devotional.id != displayDevotional.id;
    }).toList();

    return RefreshIndicator(
      color: const Color(0xFF6B46C1),
      onRefresh: () async => bloc.add(const DevotionalRefreshed()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          if (displayDevotional != null)
            _DevotionalHighlightCard(devotional: displayDevotional),
          if (displayDevotional == null)
            _EmptyDevotionalBanner(
              onTryAgain: () {
                bloc.add(const DevotionalStarted());
              },
            ),
          const SizedBox(height: 24),
          Text(
            'Devocionales recientes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Text(
                'Por ahora no hay mas devocionales disponibles. Vuelve pronto para nuevas reflexiones.',
                style: TextStyle(color: Colors.white70, height: 1.4),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...history.map(
              (devotional) => _DevotionalHistoryTile(
                devotional: devotional,
                isSelected:
                    state.selected != null &&
                    state.selected!.id == devotional.id,
                onTap: () => bloc.add(DevotionalSelected(devotional.id)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DevotionalHighlightCard extends StatelessWidget {
  final Devotional devotional;

  const _DevotionalHighlightCard({required this.devotional});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      devotional.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(devotional.date),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (devotional.verseReference != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    devotional.verseReference!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (devotional.verseText != null &&
                      devotional.verseText!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        devotional.verseText!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (devotional.verseReference != null) const SizedBox(height: 20),
          Text(
            devotional.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          if (devotional.author != null && devotional.author!.isNotEmpty)
            Text(
              'Autor: ${devotional.author}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}

class _DevotionalHistoryTile extends StatelessWidget {
  final Devotional devotional;
  final VoidCallback onTap;
  final bool isSelected;

  const _DevotionalHistoryTile({
    required this.devotional,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6B46C1).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B46C1).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6B46C1).withValues(alpha: 0.4)
                    : const Color(0xFF6B46C1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    devotional.title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(devotional.date),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _EmptyDevotionalBanner extends StatelessWidget {
  final VoidCallback onTryAgain;

  const _EmptyDevotionalBanner({required this.onTryAgain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Devocional no disponible',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Por ahora no encontramos un devocional para hoy. Intenta actualizar para sincronizar nuevamente.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B46C1),
              foregroundColor: Colors.white,
            ),
            onPressed: onTryAgain,
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}
