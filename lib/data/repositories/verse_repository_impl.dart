import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/verse.dart';
import '../../domain/repositories/verse_repository.dart';
import '../models/verse_model.dart';

class VerseRepositoryImpl implements VerseRepository {
  @override
  Future<List<Verse>> searchVerses(String query) async {
    // Simulación de búsqueda de versículos
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      VerseModel(
        id: '1',
        book: 'Juan',
        chapter: 3,
        verse: 16,
        text:
            'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.',
        translation: 'RVR1960',
        tags: ['amor', 'salvación', 'vida eterna'],
      ),
      VerseModel(
        id: '2',
        book: 'Salmos',
        chapter: 23,
        verse: 1,
        text: 'El Señor es mi pastor, nada me faltará.',
        translation: 'RVR1960',
        tags: ['confianza', 'provisión', 'cuidado'],
      ),
    ];
  }

  @override
  Future<List<Verse>> getVersesByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      VerseModel(
        id: '3',
        book: 'Proverbios',
        chapter: 3,
        verse: 5,
        text:
            'Confía en el Señor con todo tu corazón, y no te apoyes en tu propia prudencia.',
        translation: 'RVR1960',
        tags: ['confianza', 'sabiduría'],
      ),
    ];
  }

  @override
  Future<List<Verse>> getFavoriteVerses() async {
    // Simular versículos favoritos
    return [
      VerseModel(
        id: '1',
        book: 'Juan',
        chapter: 3,
        verse: 16,
        text:
            'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.',
        translation: 'RVR1960',
        tags: ['amor', 'salvación', 'vida eterna'],
        isFavorite: true,
      ),
    ];
  }

  @override
  Future<void> toggleFavorite(String verseId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorite_verses') ?? [];

    if (favorites.contains(verseId)) {
      favorites.remove(verseId);
    } else {
      favorites.add(verseId);
    }

    await prefs.setStringList('favorite_verses', favorites);
  }

  @override
  Future<List<String>> getCategories() async {
    return [
      'Amor',
      'Fe',
      'Esperanza',
      'Sabiduría',
      'Salvación',
      'Gratitud',
      'Perdón',
      'Paz',
    ];
  }

  @override
  Future<Verse?> getVerseOfTheDay() async {
    // Por ahora devolver Juan 3:16 como versículo del día
    return VerseModel(
      id: '1',
      book: 'Juan',
      chapter: 3,
      verse: 16,
      text:
          'Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.',
      translation: 'RVR1960',
      tags: ['amor', 'salvación', 'vida eterna'],
      isFavorite: false,
    );
  }
}
