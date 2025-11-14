import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/theme/theme_extensions.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/entities/verse.dart';
import '../../../domain/repositories/verse_repository.dart';
import '../../../domain/usecases/note/add_note_usecase.dart';
import '../../../domain/usecases/note/get_notes_for_verse_usecase.dart';
import '../../../data/repositories/favorito_repository.dart';
import '../audio_bible/audio_bible_screen.dart';
import '../chat/chat_screen.dart';
import '../devotional/devotional_screen.dart';
import '../explore/explore_screen.dart';
import '../favorites/favorites_screen.dart';
import '../reading_plan/reading_plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Verse? verseOfTheDay;
  bool _isFavorite = false;
  bool _isFavoriteBusy = false;
  bool _isLoadingVerse = true;

  final TextEditingController _reflectionController = TextEditingController();
  int? _cachedUserId;
  List<Note> _recentNotes = const [];

  @override
  void initState() {
    super.initState();
    _loadVerseOfTheDay();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _loadVerseOfTheDay() async {
    setState(() => _isLoadingVerse = true);
    try {
      final repo = di.sl<VerseRepository>();
      final verse = await repo.getVerseOfTheDay();
      bool favorite = false;
      Verse? hydrated = verse;
      if (verse != null) {
        favorite = await _fetchFavoriteFlag(verse);
        hydrated = _copyVerse(verse, favorite: favorite);
        _recentNotes = await _loadNotesForVerse(verse);
      }
      if (!mounted) return;
      setState(() {
        verseOfTheDay = hydrated;
        _isFavorite = favorite;
      });
    } catch (error) {
      if (mounted) {
        _showSnack(
          'No pudimos cargar el versiculo del dia. $error',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingVerse = false);
      }
    }
  }

  Future<List<Note>> _loadNotesForVerse(Verse verse) async {
    final verseId = int.tryParse(verse.id);
    if (verseId == null) return const [];
    try {
      final userId = await _readCurrentUserId();
      return await di.sl<GetNotesForVerseUseCase>().call(
        userId: userId,
        verseId: verseId,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<bool> _fetchFavoriteFlag(Verse verse) async {
    if (!di.sl.isRegistered<FavoritoRepository>()) return verse.isFavorite;
    try {
      final repo = di.sl<FavoritoRepository>();
      final userId = await _readCurrentUserId();
      final verseId = int.tryParse(verse.id);
      if (verseId == null) return verse.isFavorite;
      return await repo.isFavorito(userId, verseId);
    } catch (_) {
      return verse.isFavorite;
    }
  }

  Future<int> _readCurrentUserId() async {
    if (_cachedUserId != null) return _cachedUserId!;
    final prefs = await SharedPreferences.getInstance();
    _cachedUserId = prefs.getInt('user_id') ?? 1;
    return _cachedUserId!;
  }

  Verse _copyVerse(Verse verse, {bool? favorite}) {
    return Verse(
      id: verse.id,
      book: verse.book,
      chapter: verse.chapter,
      verse: verse.verse,
      text: verse.text,
      translation: verse.translation,
      tags: verse.tags,
      isFavorite: favorite ?? verse.isFavorite,
    );
  }

  Future<void> _toggleFavorite() async {
    final verse = verseOfTheDay;
    if (verse == null) return;
    final verseId = int.tryParse(verse.id);
    if (verseId == null) {
      _showSnack('No pudimos identificar este versiculo.', isError: true);
      return;
    }
    if (!di.sl.isRegistered<FavoritoRepository>()) {
      _showSnack('Favoritos no disponible en esta plataforma.', isError: true);
      return;
    }

    setState(() => _isFavoriteBusy = true);
    try {
      final repo = di.sl<FavoritoRepository>();
      final userId = await _readCurrentUserId();
      await repo.toggleFavorito(userId, verseId);
      final updatedFlag = !_isFavorite;
      if (!mounted) return;
      setState(() {
        _isFavorite = updatedFlag;
        verseOfTheDay = _copyVerse(verse, favorite: updatedFlag);
        _isFavoriteBusy = false;
      });
      _showSnack(
        updatedFlag ? 'Aadido a favoritos.' : 'Eliminado de favoritos.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isFavoriteBusy = false);
      _showSnack('No pudimos actualizar favoritos. $error', isError: true);
    }
  }

  Future<void> _openReflectionSheet() async {
    final verse = verseOfTheDay;
    if (verse == null) return;
    final verseId = int.tryParse(verse.id);
    final userId = await _readCurrentUserId();
    List<Note> notes = List.of(_recentNotes);

    _reflectionController.clear();
    bool isSaving = false;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final textPrimary = scheme.textPrimary;
        final textSecondary = scheme.textSecondary;
        final inset = MediaQuery.of(context).viewInsets.bottom;

        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, inset + 16),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: scheme.borderWithOverlay(0.12)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 28,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          color: scheme.overlayOnSurface(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: textPrimary,
                        ),
                        label: Text(
                          'Volver',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [scheme.primary, scheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.self_improvement,
                              color: scheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reflexion guiada',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  verse.reference,
                                  style: TextStyle(
                                    color: scheme.secondaryContainer,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.overlayOnSurface(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: scheme.borderWithOverlay(0.08),
                          ),
                        ),
                        child: Text(
                          '"${verse.text}"',
                          style: TextStyle(
                            color: textPrimary,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Ideas para meditar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _ReflectionPrompt(
                        icon: Icons.favorite_border,
                        text:
                            'Que te muestra este pasaje sobre el caracter de Dios?',
                      ),
                      const SizedBox(height: 8),
                      const _ReflectionPrompt(
                        icon: Icons.explore_outlined,
                        text:
                            'Que paso concreto puedes dar hoy para vivir este mensaje?',
                      ),
                      const SizedBox(height: 8),
                      const _ReflectionPrompt(
                        icon: Icons.handshake_outlined,
                        text:
                            'Con quien podrias compartir esta verdad esta semana?',
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Tus reflexiones',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        ...notes
                            .take(3)
                            .map(
                              (note) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: scheme.overlayOnSurface(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: scheme.borderWithOverlay(0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.text,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatTimestamp(note.createdAt),
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                      const SizedBox(height: 20),
                      TextField(
                        key: const ValueKey('reflection_text_field'),
                        controller: _reflectionController,
                        maxLines: 4,
                        style: TextStyle(color: textPrimary),
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: scheme.overlayOnSurface(0.06),
                          hintText: 'Escribe aqui tu reflexion personal...',
                          hintStyle: TextStyle(color: textSecondary),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final raw = _reflectionController.text.trim();
                                  if (raw.isEmpty) {
                                    _showSnack(
                                      'Toma un momento para escribir tu reflexion personal.',
                                    );
                                    return;
                                  }
                                  modalSetState(() => isSaving = true);
                                  try {
                                    final note = await di
                                        .sl<AddNoteUseCase>()
                                        .call(
                                          userId: userId,
                                          text: raw,
                                          verseId: verseId,
                                        );
                                    _reflectionController.clear();
                                    modalSetState(() {
                                      notes = [note, ...notes];
                                      isSaving = false;
                                    });
                                    if (!mounted) return;
                                    setState(() => _recentNotes = notes);
                                    _showSnack(
                                      'Reflexion guardada. Gracias por dedicar este tiempo.',
                                    );
                                  } catch (error) {
                                    modalSetState(() => isSaving = false);
                                    if (!mounted) return;
                                    _showSnack(
                                      'No pudimos guardar tu reflexion. $error',
                                      isError: true,
                                    );
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text('Guardar reflexion'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shareVerse() async {
    final verse = verseOfTheDay;
    if (verse == null) return;

    final suffix = verse.translation != null ? ' (${verse.translation})' : '';
    final message = '"${verse.text}"\n\n${verse.reference}$suffix';

    try {
      if (kIsWeb) {
        await _copyToClipboard(message);
        _showSnack(
          'Versiculo copiado al portapapeles. Pegalo donde quieras compartirlo.',
        );
        return;
      }

      final result = await Share.shareWithResult(
        message,
        subject: 'Versiculo del dia - ${verse.reference}',
      );
      if (!mounted) return;
      switch (result.status) {
        case ShareResultStatus.success:
          _showSnack('Versiculo compartido exitosamente.');
          break;
        case ShareResultStatus.dismissed:
          _showSnack('Se cancelo la accion de compartir.');
          break;
        case ShareResultStatus.unavailable:
          await _copyToClipboard(message);
          _showSnack(
            'No pudimos abrir el menu de compartir. Copiamos el versiculo al portapapeles.',
          );
          break;
      }
    } catch (error) {
      await _copyToClipboard(message);
      _showSnack(
        'No pudimos compartir el versiculo. Lo copiamos al portapapeles.',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? scheme.error : scheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.textPrimary;
    final textSecondary = scheme.textSecondary;
    final cardBackground = scheme.cardBackground;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [scheme.surface, scheme.surfaceContainerHighest],
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: scheme.primary,
              onRefresh: _loadVerseOfTheDay,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      scheme: scheme,
                      cardBackground: cardBackground,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 20),
                    _MainActions(scheme: scheme, textPrimary: textPrimary),
                    const SizedBox(height: 20),
                    _QuickActions(scheme: scheme, textPrimary: textPrimary),
                    const SizedBox(height: 20),
                    _VerseOfDay(
                      verse: verseOfTheDay,
                      isFavorite: _isFavorite,
                      isProcessingFavorite: _isFavoriteBusy,
                      isLoading: _isLoadingVerse,
                      onFavoriteTap: _toggleFavorite,
                      onReflectTap: _openReflectionSheet,
                      onShareTap: _shareVerse,
                      scheme: scheme,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ColorScheme scheme;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;

  const _Header({
    required this.scheme,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.borderWithOverlay(0.15)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: scheme.tertiary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Maika',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'BETA',
                        style: TextStyle(
                          color: scheme.onSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tu asistente biblico personal',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.overlayOnSurface(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: scheme.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '7',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: scheme.overlayOnSurface(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.notifications_none,
                  color: textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainActions extends StatelessWidget {
  final ColorScheme scheme;
  final Color textPrimary;

  const _MainActions({required this.scheme, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Chat con IA',
            subtitle: 'Pregunta cualquier cosa',
            icon: Icons.chat_bubble_outline,
            color: scheme.primary,
            textPrimary: textPrimary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Explorar',
            subtitle: 'Descubre versiculos',
            icon: Icons.search,
            color: scheme.secondary,
            textPrimary: textPrimary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExploreScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color textPrimary;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(22.5),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: textPrimary.withValues(alpha: 0.65),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final ColorScheme scheme;
  final Color textPrimary;

  const _QuickActions({required this.scheme, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: GridView.count(
        crossAxisCount: 4,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 4,
        children: [
          _QuickAction(
            title: 'Plan de lectura',
            icon: Icons.calendar_today,
            color: scheme.tertiary,
            textPrimary: textPrimary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReadingPlanScreen()),
            ),
          ),
          _QuickAction(
            title: 'Audio Biblia',
            icon: Icons.play_circle_outline,
            color: const Color(0xFFFF6B35),
            textPrimary: textPrimary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AudioBibleScreen()),
            ),
          ),
          _QuickAction(
            title: 'Devocional',
            icon: Icons.flash_on,
            color: scheme.secondary,
            textPrimary: textPrimary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DevotionalScreen()),
            ),
          ),
          _QuickAction(
            title: 'Favoritos',
            icon: Icons.favorite_border,
            color: const Color(0xFFEC4899),
            textPrimary: textPrimary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color textPrimary;
  final VoidCallback onTap;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseOfDay extends StatelessWidget {
  final Verse? verse;
  final bool isFavorite;
  final bool isProcessingFavorite;
  final bool isLoading;
  final VoidCallback onFavoriteTap;
  final VoidCallback onReflectTap;
  final VoidCallback onShareTap;
  final ColorScheme scheme;
  final Color textPrimary;
  final Color textSecondary;

  const _VerseOfDay({
    required this.verse,
    required this.isFavorite,
    required this.isProcessingFavorite,
    required this.isLoading,
    required this.onFavoriteTap,
    required this.onReflectTap,
    required this.onShareTap,
    required this.scheme,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: scheme.primary));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.borderWithOverlay(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(17.5),
                ),
                child: Icon(
                  Icons.book_outlined,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Versiculo del dia',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      verse?.reference ?? 'Juan 3:16',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isProcessingFavorite ? null : onFavoriteTap,
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isFavorite
                          ? const Color(0xFFEC4899).withValues(alpha: 0.18)
                          : scheme.overlayOnSurface(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isFavorite
                            ? const Color(0xFFEC4899).withValues(alpha: 0.55)
                            : scheme.overlayOnSurface(0.18),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: isProcessingFavorite
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation(
                                  Color(0xFFEC4899),
                                ),
                              ),
                            )
                          : Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? const Color(0xFFEC4899)
                                  : textSecondary,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '"${verse?.text ?? 'Porque de tal manera amo Dios al mundo, que ha dado a su Hijo unigenito, para que todo aquel que en el cree, no se pierda, mas tenga vida eterna.'}"',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onReflectTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.secondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.self_improvement,
                            color: scheme.onPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reflexionar',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onShareTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: scheme.overlayOnSurface(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scheme.overlayOnSurface(0.15),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.ios_share_rounded,
                            color: textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Compartir',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReflectionPrompt extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ReflectionPrompt({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = scheme.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.overlayOnSurface(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.borderWithOverlay(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: textColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
