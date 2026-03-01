import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/versiculo_model.dart';
import '../../../data/repositories/favorito_repository.dart';
import '../../../data/repositories/versiculo_repository.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/chat_repository.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

enum _SavedTab { verses, conversations }

class _FavoritesScreenState extends State<FavoritesScreen> {
  _SavedTab _activeTab = _SavedTab.verses;

  bool _isLoadingVerses = false;
  bool _isLoadingConversations = false;
  String? _errorVerses;
  String? _errorConversations;

  List<Versiculo> _savedVerses = const [];
  List<ChatMessage> _savedMessages = const [];

  @override
  void initState() {
    super.initState();
    _loadVerseFavorites();
    _loadChatFavorites();
  }

  Future<int> _readCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 1;
  }

  Future<void> _loadVerseFavorites() async {
    if (!di.sl.isRegistered<FavoritoRepository>() ||
        !di.sl.isRegistered<VersiculoRepository>()) {
      setState(() {
        _savedVerses = const [];
        _isLoadingVerses = false;
      });
      return;
    }

    setState(() {
      _isLoadingVerses = true;
      _errorVerses = null;
    });

    try {
      final userId = await _readCurrentUserId();
      final favoritoRepo = di.sl<FavoritoRepository>();
      final versiculoRepo = di.sl<VersiculoRepository>();

      final favoritos = await favoritoRepo.getFavoritosByUsuario(userId);

      final verses = <Versiculo>[];
      for (final fav in favoritos) {
        final verse = await versiculoRepo.getVersiculoById(fav.idVersiculo);
        if (verse != null) {
          verses.add(verse);
        }
      }

      if (!mounted) return;
      setState(() {
        _savedVerses = verses;
        _isLoadingVerses = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorVerses =
            'No se pudieron cargar los versiculos guardados. $error';
        _isLoadingVerses = false;
      });
    }
  }

  Future<void> _loadChatFavorites() async {
    setState(() {
      _isLoadingConversations = true;
      _errorConversations = null;
    });

    try {
      final repo = di.sl<ChatRepository>();
      final messages = await repo.getFavoriteMessages();
      if (!mounted) return;
      setState(() {
        _savedMessages = messages;
        _isLoadingConversations = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorConversations =
            'No se pudieron cargar las conversaciones guardadas. $error';
        _isLoadingConversations = false;
      });
    }
  }

  void _onTabChanged(_SavedTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.textPrimary;
    final textSecondary = scheme.textSecondary;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('Guardados')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FavoritesHero(
              scheme: scheme,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 16),
            _GuardadosSegmentedControl(
              activeTab: _activeTab,
              onChanged: _onTabChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _activeTab == _SavedTab.verses
                  ? _buildVersesList(
                      scheme: scheme,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    )
                  : _buildConversationsList(
                      scheme: scheme,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersesList({
    required ColorScheme scheme,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (_isLoadingVerses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorVerses != null) {
      return Center(
        child: Text(
          _errorVerses!,
          style: TextStyle(color: scheme.error, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_savedVerses.isEmpty) {
      return Center(
        child: Text(
          'Todavia no tienes versiculos guardados.\nMarca un versiculo como favorito para verlo aqui.',
          style: TextStyle(color: textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _savedVerses.length,
      itemBuilder: (context, index) {
        final verse = _savedVerses[index];
        return _VerseCard(
          text: verse.texto,
          reference: verse.referencia,
        );
      },
    );
  }

  Widget _buildConversationsList({
    required ColorScheme scheme,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (_isLoadingConversations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorConversations != null) {
      return Center(
        child: Text(
          _errorConversations!,
          style: TextStyle(color: scheme.error, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_savedMessages.isEmpty) {
      return Center(
        child: Text(
          'Todavia no tienes mensajes guardados.\nMarca un mensaje del chat como favorito para verlo aqui.',
          style: TextStyle(color: textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _savedMessages.length,
      itemBuilder: (context, index) {
        final message = _savedMessages[index];
        return _ChatFavoriteCard(
          scheme: scheme,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          message: message,
        );
      },
    );
  }
}

class _GuardadosSegmentedControl extends StatelessWidget {
  final _SavedTab activeTab;
  final ValueChanged<_SavedTab> onChanged;

  const _GuardadosSegmentedControl({
    required this.activeTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.borderWithOverlay(0.08)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabButton(
            context,
            label: 'Versiculos',
            tab: _SavedTab.verses,
          ),
          _buildTabButton(
            context,
            label: 'Conversaciones',
            tab: _SavedTab.conversations,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String label,
    required _SavedTab tab,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                isActive
                    ? scheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isActive
                        ? scheme.primary
                        : scheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
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

class _VerseCard extends StatelessWidget {
  final String text;
  final String reference;

  const _VerseCard({required this.text, required this.reference});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B46C1).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF6B46C1).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Versiculo',
                  style: TextStyle(
                    color: Color(0xFF6B46C1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.favorite,
                color: Color(0xFFEC4899),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reference,
            style: const TextStyle(
              color: Color(0xFF6B46C1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatFavoriteCard extends StatelessWidget {
  final ColorScheme scheme;
  final Color textPrimary;
  final Color textSecondary;
  final ChatMessage message;

  const _ChatFavoriteCard({
    required this.scheme,
    required this.textPrimary,
    required this.textSecondary,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = message.timestamp;
    final dateString = _formatDate(createdAt);
    final hasNote =
        message.favoriteNote != null && message.favoriteNote!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.borderWithOverlay(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_rounded,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                dateString,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.favorite,
                size: 18,
                color: Color(0xFFEC4899),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textPrimary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (hasNote) ...[
            const SizedBox(height: 8),
            Text(
              message.favoriteNote!.trim(),
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final d = dateTime.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }
}
