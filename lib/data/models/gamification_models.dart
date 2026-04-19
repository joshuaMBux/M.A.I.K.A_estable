class GamificationUserProgress {
  final int userId;
  final int xpTotal;
  final int level;
  final int coins;
  final int currentLevelXp;
  final int xpForNextLevel;
  final DateTime? updatedAt;

  const GamificationUserProgress({
    required this.userId,
    required this.xpTotal,
    required this.level,
    required this.coins,
    required this.currentLevelXp,
    required this.xpForNextLevel,
    required this.updatedAt,
  });

  double get xpProgress {
    if (xpForNextLevel <= 0) return 1;
    return (currentLevelXp / xpForNextLevel).clamp(0, 1);
  }
}

class AchievementDefinition {
  final String key;
  final String title;
  final String description;
  final String metricKey;
  final int threshold;

  const AchievementDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.metricKey,
    required this.threshold,
  });
}

class AchievementStatus {
  final AchievementDefinition definition;
  final DateTime? unlockedAt;

  const AchievementStatus({
    required this.definition,
    required this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;
}

class LocalRankingEntry {
  final int position;
  final int userId;
  final String userName;
  final int xpTotal;
  final int level;
  final int coins;
  final bool isCurrentUser;

  const LocalRankingEntry({
    required this.position,
    required this.userId,
    required this.userName,
    required this.xpTotal,
    required this.level,
    required this.coins,
    required this.isCurrentUser,
  });
}

class GamificationDashboard {
  final GamificationUserProgress progress;
  final List<AchievementStatus> unlockedAchievements;
  final List<AchievementStatus> lockedAchievements;
  final List<LocalRankingEntry> ranking;

  const GamificationDashboard({
    required this.progress,
    required this.unlockedAchievements,
    required this.lockedAchievements,
    required this.ranking,
  });

  int get unlockedCount => unlockedAchievements.length;
}

class RewardGrantResult {
  final bool granted;
  final int xpGranted;
  final int coinsGranted;
  final List<AchievementStatus> newlyUnlocked;

  const RewardGrantResult({
    required this.granted,
    required this.xpGranted,
    required this.coinsGranted,
    this.newlyUnlocked = const [],
  });
}

class RewardRule {
  final String actionType;
  final int xp;
  final int coins;

  const RewardRule({
    required this.actionType,
    required this.xp,
    required this.coins,
  });
}

class GamificationCatalog {
  static const String totalRewardsMetric = 'total_rewards';
  static const String favoriteVerseMetric = 'favorite_verse';
  static const String reflectionSavedMetric = 'reflection_saved';
  static const String readingDayMetric = 'reading_day_completed';
  static const String minigameSessionMetric = 'minigame_session';
  static const String minigameVictoryMetric = 'minigame_victory';

  static const RewardRule minigameSessionReward = RewardRule(
    actionType: minigameSessionMetric,
    xp: 12,
    coins: 4,
  );

  static const RewardRule minigameVictoryReward = RewardRule(
    actionType: minigameVictoryMetric,
    xp: 40,
    coins: 12,
  );

  static const RewardRule readingDayReward = RewardRule(
    actionType: readingDayMetric,
    xp: 25,
    coins: 8,
  );

  static const RewardRule favoriteVerseReward = RewardRule(
    actionType: favoriteVerseMetric,
    xp: 8,
    coins: 4,
  );

  static const RewardRule reflectionReward = RewardRule(
    actionType: reflectionSavedMetric,
    xp: 18,
    coins: 6,
  );

  static const List<AchievementDefinition> achievements = [
    AchievementDefinition(
      key: 'primer_paso',
      title: 'Primer paso',
      description: 'Recibe tu primera recompensa local.',
      metricKey: totalRewardsMetric,
      threshold: 1,
    ),
    AchievementDefinition(
      key: 'guardian_del_versiculo',
      title: 'Guardian del versiculo',
      description: 'Guarda tu primer versiculo en favoritos.',
      metricKey: favoriteVerseMetric,
      threshold: 1,
    ),
    AchievementDefinition(
      key: 'coleccionista_fiel',
      title: 'Coleccionista fiel',
      description: 'Guarda 5 versiculos en favoritos.',
      metricKey: favoriteVerseMetric,
      threshold: 5,
    ),
    AchievementDefinition(
      key: 'corazon_reflexivo',
      title: 'Corazon reflexivo',
      description: 'Guarda tu primera reflexion.',
      metricKey: reflectionSavedMetric,
      threshold: 1,
    ),
    AchievementDefinition(
      key: 'escriba_constante',
      title: 'Escriba constante',
      description: 'Guarda 5 reflexiones personales.',
      metricKey: reflectionSavedMetric,
      threshold: 5,
    ),
    AchievementDefinition(
      key: 'lector_constante',
      title: 'Lector constante',
      description: 'Completa 3 dias del plan de lectura.',
      metricKey: readingDayMetric,
      threshold: 3,
    ),
    AchievementDefinition(
      key: 'discipulo_persistente',
      title: 'Discipulo persistente',
      description: 'Completa 7 dias del plan de lectura.',
      metricKey: readingDayMetric,
      threshold: 7,
    ),
    AchievementDefinition(
      key: 'explorador_fragmentos',
      title: 'Explorador de fragmentos',
      description: 'Juega tu primera sesion del minijuego.',
      metricKey: minigameSessionMetric,
      threshold: 1,
    ),
    AchievementDefinition(
      key: 'vencedor_fragmentado',
      title: 'Vencedor fragmentado',
      description: 'Completa 3 partidas del minijuego.',
      metricKey: minigameVictoryMetric,
      threshold: 3,
    ),
  ];
}
