import '../entities/verse.dart';

abstract class VerseRepository {
  Future<List<Verse>> searchVerses(String query);
  Future<List<Verse>> getVersesByCategory(String category);
  Future<List<Verse>> getFavoriteVerses();
  Future<void> toggleFavorite(String verseId);
  Future<List<String>> getCategories();
}
