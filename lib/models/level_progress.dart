class LevelProgress {
  static const String levelId = 'level_1';
  static const int totalGames = 3;

  final int currentGameIndex;
  final List<int> completedGameIndices;
  final Map<String, int> gameScores;
  final bool isCompleted;

  const LevelProgress({
    required this.currentGameIndex,
    required this.completedGameIndices,
    required this.gameScores,
    required this.isCompleted,
  });

  factory LevelProgress.initial() {
    return const LevelProgress(
      currentGameIndex: 0,
      completedGameIndices: <int>[],
      gameScores: <String, int>{},
      isCompleted: false,
    );
  }

  factory LevelProgress.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return LevelProgress.initial();
    }

    final rawCompleted = (data['completedGameIndices'] as List<dynamic>? ?? [])
        .map((value) => value as int)
        .toList()
      ..sort();
    final rawScores =
        Map<String, dynamic>.from(data['gameScores'] as Map<String, dynamic>? ?? {});

    return LevelProgress(
      currentGameIndex: (data['currentGameIndex'] as int?) ?? 0,
      completedGameIndices: rawCompleted,
      gameScores: rawScores.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      isCompleted: (data['isCompleted'] as bool?) ?? false,
    );
  }

  int get totalScore => gameScores.values.fold(0, (sum, score) => sum + score);
}
