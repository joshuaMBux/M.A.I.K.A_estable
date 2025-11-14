import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/libro_model.dart';
import '../../../data/models/audio_capitulo_model.dart';
import '../../../data/repositories/audio_bible_repository.dart';
import 'audio_player_screen.dart';

class AudioChaptersScreen extends StatefulWidget {
  final Libro book;
  const AudioChaptersScreen({super.key, required this.book});

  @override
  State<AudioChaptersScreen> createState() => _AudioChaptersScreenState();
}

class _AudioChaptersScreenState extends State<AudioChaptersScreen> {
  final _repo = AudioBibleRepository();
  late Future<List<AudioCapitulo>> _futureChapters;

  @override
  void initState() {
    super.initState();
    _futureChapters = _repo.getCapitulosConAudio(widget.book.idLibro!);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.textPrimary;
    final textSecondary = scheme.textSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(widget.book.nombre)),
      body: FutureBuilder<List<AudioCapitulo>>(
        future: _futureChapters,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar capitulos',
                style: TextStyle(color: scheme.error),
              ),
            );
          }
          final chapters = snapshot.data ?? const <AudioCapitulo>[];
          if (chapters.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aún no hay audio disponible para este libro. '
                  'Cuando se agreguen, aparecerán aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, height: 1.4),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) {
              final item = chapters[index];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: scheme.borderWithOverlay(0.1)),
                ),
                tileColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.9,
                ),
                leading: CircleAvatar(
                  backgroundColor: scheme.secondary,
                  child: Text(
                    '${item.capitulo}',
                    style: TextStyle(color: scheme.onSecondary),
                  ),
                ),
                title: Text(
                  'Capítulo ${item.capitulo}',
                  style: TextStyle(color: textPrimary),
                ),
                subtitle: Text(
                  item.duracionSegundos != null
                      ? _formatDuration(item.duracionSegundos!)
                      : (item.url != null ? 'En línea' : 'Archivo local'),
                  style: TextStyle(color: textSecondary),
                ),
                trailing: const Icon(Icons.play_arrow),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AudioPlayerScreen(
                        bookName: widget.book.nombre,
                        idLibro: widget.book.idLibro!,
                        capitulo: item.capitulo,
                      ),
                    ),
                  );
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: chapters.length,
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }
}
