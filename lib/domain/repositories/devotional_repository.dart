import '../entities/devotional.dart';

abstract class DevotionalRepository {
  Future<Devotional?> getTodayDevotional();
  Future<List<Devotional>> getRecentDevotionals({int limit = 10});
  Future<Devotional?> getDevotionalById(int id);
}
