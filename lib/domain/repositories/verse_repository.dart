import '../entities/verse.dart';

abstract class VerseRepository {
  Future<List<Verse>> searchVerses(String query);
  Future<List<Verse>> getVersesByCategory(String category);
  Future<List<Verse>> getChapter(String book, int chapter);
  Future<List<Verse>> getFavoriteVerses();
  Future<void> toggleFavorite(String verseId);
  Future<List<String>> getCategories();
  Future<Verse?> getVerseOfTheDay();
}
