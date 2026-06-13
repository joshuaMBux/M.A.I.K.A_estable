import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../models/gamification_models.dart';

class GamificationRepository {
  final DatabaseHelper _dbHelper;
  final StreamController<int?> _updates = StreamController<int?>.broadcast();

  GamificationRepository(this._dbHelper);

  Stream<GamificationDashboard> watchDashboard(int userId) async* {
    yield await getDashboard(userId);
    yield* _updates.stream
        .where(
            (changedUserId) => changedUserId == null || changedUserId == userId)
        .asyncMap((_) => getDashboard(userId));
  }

  Future<GamificationDashboard> getDashboard(int userId) async {
    final db = await _dbHelper.database;
    await _ensureUserProgress(db, userId);

    final progress = await _getUserProgress(db, userId);
    final achievementStatus = await _getAchievementStatuses(db, userId);
    final ranking = await _getRanking(db, userId);

    return GamificationDashboard(
      progress: progress,
      unlockedAchievements:
          achievementStatus.where((item) => item.isUnlocked).toList(),
      lockedAchievements:
          achievementStatus.where((item) => !item.isUnlocked).toList(),
      ranking: ranking,
    );
  }

  Future<RewardGrantResult> rewardFavoriteVerse({
    required int userId,
    required int verseId,
  }) {
    return _grantReward(
      userId: userId,
      eventKey: 'favorite_verse:$userId:$verseId',
      rule: GamificationCatalog.favoriteVerseReward,
      metadata: {'verse_id': verseId},
    );
  }

  Future<RewardGrantResult> rewardReflectionSaved({
    required int userId,
    required int noteId,
    int? verseId,
  }) {
    return _grantReward(
      userId: userId,
      eventKey: 'reflection_saved:$userId:$noteId',
      rule: GamificationCatalog.reflectionReward,
      metadata: {
        'note_id': noteId,
        if (verseId != null) 'verse_id': verseId,
      },
    );
  }

  Future<RewardGrantResult> rewardReadingDayCompleted({
    required int userId,
    required int planId,
    required int day,
  }) {
    return _grantReward(
      userId: userId,
      eventKey: 'reading_day_completed:$userId:$planId:$day',
      rule: GamificationCatalog.readingDayReward,
      metadata: {'plan_id': planId, 'day': day},
    );
  }

  Future<RewardGrantResult> rewardMinigameSession({
    required int userId,
    required String gameKey,
    required String sessionKey,
    int? secondsPlayed,
    int? fragmentsCollected,
  }) {
    return _grantReward(
      userId: userId,
      eventKey: 'minigame_session:$userId:$gameKey:$sessionKey',
      rule: GamificationCatalog.minigameSessionReward,
      metadata: {
        'game_key': gameKey,
        'session_key': sessionKey,
        if (secondsPlayed != null) 'seconds_played': secondsPlayed,
        if (fragmentsCollected != null)
          'fragments_collected': fragmentsCollected,
      },
    );
  }

  Future<RewardGrantResult> rewardMinigameVictory({
    required int userId,
    required String gameKey,
    required String roundKey,
    int? fragmentsCollected,
  }) {
    return _grantReward(
      userId: userId,
      eventKey: 'minigame_victory:$userId:$gameKey:$roundKey',
      rule: GamificationCatalog.minigameVictoryReward,
      metadata: {
        'game_key': gameKey,
        'round_key': roundKey,
        if (fragmentsCollected != null)
          'fragments_collected': fragmentsCollected,
      },
    );
  }

  Future<bool> isFeatureUnlocked({
    required int userId,
    required String featureKey,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'user_unlock',
      columns: ['id'],
      where: 'user_id = ? AND feature_key = ?',
      whereArgs: [userId, featureKey],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<FeatureUnlockResult> unlockFeature({
    required int userId,
    required String featureKey,
    required int costCoins,
  }) async {
    final db = await _dbHelper.database;
    var result = const FeatureUnlockResult(
      isUnlocked: false,
      purchasedNow: false,
      insufficientCoins: false,
      remainingCoins: 0,
    );

    await db.transaction((txn) async {
      await _ensureUserProgress(txn, userId);

      final existingUnlock = await txn.query(
        'user_unlock',
        columns: ['id'],
        where: 'user_id = ? AND feature_key = ?',
        whereArgs: [userId, featureKey],
        limit: 1,
      );

      final currentProgress = await _getUserProgress(txn, userId);
      if (existingUnlock.isNotEmpty) {
        result = FeatureUnlockResult(
          isUnlocked: true,
          purchasedNow: false,
          insufficientCoins: false,
          remainingCoins: currentProgress.coins,
        );
        return;
      }

      if (currentProgress.coins < costCoins) {
        result = FeatureUnlockResult(
          isUnlocked: false,
          purchasedNow: false,
          insufficientCoins: true,
          remainingCoins: currentProgress.coins,
        );
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final updatedCoins = currentProgress.coins - costCoins;
      final eventKey = 'feature_unlock:$userId:$featureKey';

      await txn.insert(
        'user_unlock',
        {
          'user_id': userId,
          'feature_key': featureKey,
          'spent_coins': costCoins,
          'unlocked_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await txn.insert(
        'reward_transaction',
        {
          'user_id': userId,
          'event_key': eventKey,
          'action_type': GamificationCatalog.featureUnlockAction,
          'xp_delta': 0,
          'coins_delta': -costCoins,
          'metadata_json': jsonEncode({
            'feature_key': featureKey,
            'cost_coins': costCoins,
          }),
          'created_at': now,
        },
      );

      await txn.update(
        'user_progress',
        {
          'coins': updatedCoins,
          'updated_at': now,
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      result = FeatureUnlockResult(
        isUnlocked: true,
        purchasedNow: true,
        insufficientCoins: false,
        remainingCoins: updatedCoins,
      );
    });

    if (result.purchasedNow) {
      _updates.add(userId);
    }

    return result;
  }

  Future<RewardGrantResult> _grantReward({
    required int userId,
    required String eventKey,
    required RewardRule rule,
    Map<String, Object?> metadata = const {},
  }) async {
    final db = await _dbHelper.database;
    RewardGrantResult result = const RewardGrantResult(
      granted: false,
      xpGranted: 0,
      coinsGranted: 0,
    );

    await db.transaction((txn) async {
      await _ensureUserProgress(txn, userId);

      final existing = await txn.query(
        'reward_transaction',
        columns: ['id'],
        where: 'event_key = ?',
        whereArgs: [eventKey],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return;
      }

      final currentProgress = await _getUserProgress(txn, userId);
      final updatedXp = currentProgress.xpTotal + rule.xp;
      final updatedCoins = currentProgress.coins + rule.coins;
      final computedLevel = _computeLevel(updatedXp);
      final now = DateTime.now().millisecondsSinceEpoch;

      await txn.insert('reward_transaction', {
        'user_id': userId,
        'event_key': eventKey,
        'action_type': rule.actionType,
        'xp_delta': rule.xp,
        'coins_delta': rule.coins,
        'metadata_json': metadata.isEmpty ? null : jsonEncode(metadata),
        'created_at': now,
      });

      await txn.insert(
        'user_progress',
        {
          'user_id': userId,
          'xp_total': updatedXp,
          'level': computedLevel,
          'coins': updatedCoins,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final newlyUnlocked = await _syncAchievements(txn, userId, now);
      result = RewardGrantResult(
        granted: true,
        xpGranted: rule.xp,
        coinsGranted: rule.coins,
        newlyUnlocked: newlyUnlocked,
      );
    });

    if (result.granted) {
      _updates.add(userId);
    }

    return result;
  }

  Future<void> _ensureUserProgress(DatabaseExecutor db, int userId) async {
    final rows = await db.query(
      'user_progress',
      columns: ['user_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return;
    }

    await db.insert(
      'user_progress',
      {
        'user_id': userId,
        'xp_total': 0,
        'level': 1,
        'coins': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<GamificationUserProgress> _getUserProgress(
    DatabaseExecutor db,
    int userId,
  ) async {
    final rows = await db.query(
      'user_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    final row = rows.isNotEmpty
        ? rows.first
        : {
            'user_id': userId,
            'xp_total': 0,
            'level': 1,
            'coins': 0,
            'updated_at': null,
          };

    final xpTotal = (row['xp_total'] as num?)?.toInt() ?? 0;
    final level = (row['level'] as num?)?.toInt() ?? _computeLevel(xpTotal);
    final currentLevelBaseXp = _xpRequiredToReachLevel(level);
    final nextLevelBaseXp = _xpRequiredToReachLevel(level + 1);

    return GamificationUserProgress(
      userId: userId,
      xpTotal: xpTotal,
      level: level,
      coins: (row['coins'] as num?)?.toInt() ?? 0,
      currentLevelXp: xpTotal - currentLevelBaseXp,
      xpForNextLevel: nextLevelBaseXp - currentLevelBaseXp,
      updatedAt: row['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (row['updated_at'] as num).toInt(),
            ),
    );
  }

  Future<List<AchievementStatus>> _getAchievementStatuses(
    DatabaseExecutor db,
    int userId,
  ) async {
    final rows = await db.query(
      'user_achievement',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final unlockedMap = <String, DateTime?>{
      for (final row in rows)
        row['achievement_key'] as String: row['unlocked_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (row['unlocked_at'] as num).toInt(),
              ),
    };

    return GamificationCatalog.achievements
        .map(
          (definition) => AchievementStatus(
            definition: definition,
            unlockedAt: unlockedMap[definition.key],
          ),
        )
        .toList();
  }

  Future<List<AchievementStatus>> _syncAchievements(
    DatabaseExecutor db,
    int userId,
    int unlockedAt,
  ) async {
    final metrics = await _buildMetrics(db, userId);
    final currentStatuses = await _getAchievementStatuses(db, userId);
    final existing = {
      for (final status in currentStatuses.where((item) => item.isUnlocked))
        status.definition.key: status,
    };

    final newlyUnlocked = <AchievementStatus>[];
    for (final definition in GamificationCatalog.achievements) {
      final metricValue = metrics[definition.metricKey] ?? 0;
      if (metricValue < definition.threshold ||
          existing.containsKey(definition.key)) {
        continue;
      }

      await db.insert(
        'user_achievement',
        {
          'user_id': userId,
          'achievement_key': definition.key,
          'unlocked_at': unlockedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      newlyUnlocked.add(
        AchievementStatus(
          definition: definition,
          unlockedAt: DateTime.fromMillisecondsSinceEpoch(unlockedAt),
        ),
      );
    }

    return newlyUnlocked;
  }

  Future<Map<String, int>> _buildMetrics(
      DatabaseExecutor db, int userId) async {
    final rows = await db.rawQuery(
      '''
      SELECT action_type, COUNT(*) AS total
      FROM reward_transaction
      WHERE user_id = ?
      GROUP BY action_type
      ''',
      [userId],
    );

    final metrics = <String, int>{
      GamificationCatalog.totalRewardsMetric: 0,
    };

    var totalRewards = 0;
    for (final row in rows) {
      final actionType = row['action_type'] as String;
      final total = (row['total'] as num?)?.toInt() ?? 0;
      metrics[actionType] = total;
      totalRewards += total;
    }

    metrics[GamificationCatalog.totalRewardsMetric] = totalRewards;
    return metrics;
  }

  Future<List<LocalRankingEntry>> _getRanking(
    DatabaseExecutor db,
    int currentUserId,
  ) async {
    final rows = await db.rawQuery(
      '''
      SELECT
        u.id_usuario AS user_id,
        u.nombre AS user_name,
        COALESCE(up.xp_total, 0) AS xp_total,
        COALESCE(up.level, 1) AS level,
        COALESCE(up.coins, 0) AS coins
      FROM usuario u
      LEFT JOIN user_progress up ON up.user_id = u.id_usuario
      ORDER BY xp_total DESC, coins DESC, user_name COLLATE NOCASE ASC
      ''',
    );

    return List<LocalRankingEntry>.generate(rows.length, (index) {
      final row = rows[index];
      final userId = (row['user_id'] as num?)?.toInt() ?? 0;
      return LocalRankingEntry(
        position: index + 1,
        userId: userId,
        userName: (row['user_name'] as String?) ?? 'Usuario',
        xpTotal: (row['xp_total'] as num?)?.toInt() ?? 0,
        level: (row['level'] as num?)?.toInt() ?? 1,
        coins: (row['coins'] as num?)?.toInt() ?? 0,
        isCurrentUser: userId == currentUserId,
      );
    });
  }

  int _computeLevel(int totalXp) {
    var level = 1;
    while (totalXp >= _xpRequiredToReachLevel(level + 1)) {
      level++;
    }
    return level;
  }

  int _xpRequiredToReachLevel(int level) {
    if (level <= 1) return 0;

    var total = 0;
    for (var currentLevel = 1; currentLevel < level; currentLevel++) {
      total += 100 + ((currentLevel - 1) * 40);
    }
    return total;
  }
}
