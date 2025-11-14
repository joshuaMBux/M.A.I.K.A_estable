import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/libro_model.dart';
import '../../../data/repositories/audio_bible_repository.dart';
import 'audio_chapters_screen.dart';

class AudioBibleScreen extends StatefulWidget {
  const AudioBibleScreen({super.key});

  @override
  State<AudioBibleScreen> createState() => _AudioBibleScreenState();
}

class _AudioBibleScreenState extends State<AudioBibleScreen> {
  final _repo = AudioBibleRepository();
  late Future<List<Libro>> _futureBooks;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _futureBooks = _repo.getLibros();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.textPrimary;
    final textSecondary = scheme.textSecondary;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('Audio Biblia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const ValueKey('search_audio_bible_books'),
              decoration: InputDecoration(
                hintText: 'Buscar libro...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              autofillHints: const [AutofillHints.name],
              onChanged: (text) => setState(() => _query = text),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Libro>>(
                future: _futureBooks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar libros',
                        style: TextStyle(color: scheme.error),
                      ),
                    );
                  }
                  final books = (snapshot.data ?? const <Libro>[])
                      .where((b) =>
                          _query.isEmpty ||
                          b.nombre.toLowerCase().contains(_query.toLowerCase()) ||
                          (b.abreviatura ?? '')
                              .toLowerCase()
                              .contains(_query.toLowerCase()))
                      .toList();
                  if (books.isEmpty) {
                    return Center(
                      child: Text(
                        'Sin resultados',
                        style: TextStyle(color: textSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: scheme.borderWithOverlay(0.1),
                          ),
                        ),
                        tileColor: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.9),
                        leading: CircleAvatar(
                          backgroundColor: scheme.primary,
                          child: Text(
                            (book.abreviatura ?? book.nombre.substring(0, 2))
                                .toUpperCase(),
                            style: TextStyle(color: scheme.onPrimary),
                          ),
                        ),
                        title: Text(book.nombre, style: TextStyle(color: textPrimary)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AudioChaptersScreen(book: book),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
