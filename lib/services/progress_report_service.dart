import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/level_catalog.dart';

class ProgressReportService {
  const ProgressReportService();

  String _parentId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Parent user is not authenticated.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _childrenRef() {
    return FirebaseFirestore.instance
        .collection('parents')
        .doc(_parentId())
        .collection('children');
  }

  Future<List<Map<String, String>>> fetchChildren() async {
    final snapshot = await _childrenRef().orderBy('createdAt').get();

    return snapshot.docs
        .map(
          (doc) => {
            'id': doc.id,
            'name': (doc.data()['name'] ?? 'Child').toString(),
          },
        )
        .toList();
  }

  Future<ChildProgressBundle> loadChildProgressBundle(String childId) async {
    final childSnap = await _childrenRef().doc(childId).get();
    final childData = childSnap.data() ?? <String, dynamic>{};

    final currentLevel = _toInt(childData['currentLevel'], fallback: 1);
    final currentGameIndex = _toInt(childData['currentGameIndex']);

    final progressSnapshot =
        await _childrenRef().doc(childId).collection('gameProgress').get();

    final byLevelNumber = <int, Map<String, dynamic>>{};
    for (final doc in progressSnapshot.docs) {
      final data = doc.data();
      final levelNum = _extractLevelNumber(doc.id, data);
      byLevelNumber[levelNum] = data;
    }

    const maxLevels = 3;
    final levels = <LevelReviewData>[];

    for (var level = 1; level <= maxLevels; level++) {
      final data = byLevelNumber[level];
      final totalGames = _toInt(data?['totalGames'], fallback: LevelCatalog.totalGames(level));
      final gameResults = _parseGameResults(data?['gameResults']);

      final isCompleted = (data?['isCompleted'] as bool?) ?? false;
      final completedCount = _extractCompletedCount(data);
      final levelScore = _toInt(data?['totalScore']);

      final status = _statusForLevel(
        level: level,
        hasDoc: data != null,
        isCompleted: isCompleted,
        currentLevel: currentLevel,
      );

      levels.add(
        LevelReviewData(
          levelNumber: level,
          status: status,
          score: levelScore,
          totalGames: totalGames,
          completedCount: completedCount,
          gameReviews: gameResults,
          updatedAt: _toDate(data?['updatedAt']),
        ),
      );
    }

    final completedLevels = levels.where((l) => l.status == LevelStatus.completed).length;
    final totalScore = levels.fold<int>(0, (sum, l) => sum + l.score);

    return ChildProgressBundle(
      currentLevel: currentLevel,
      currentGameIndex: currentGameIndex,
      completedLevels: completedLevels,
      totalLevels: maxLevels,
      totalScore: totalScore,
      levels: levels,
    );
  }

  LevelStatus _statusForLevel({
    required int level,
    required bool hasDoc,
    required bool isCompleted,
    required int currentLevel,
  }) {
    if (isCompleted) return LevelStatus.completed;
    if (hasDoc) return LevelStatus.inProgress;

    if (level <= currentLevel) {
      return LevelStatus.inProgress;
    }
    return LevelStatus.locked;
  }

  int _extractLevelNumber(String docId, Map<String, dynamic>? data) {
    final field = _toInt(data?['levelNumber']);
    if (field > 0) return field;

    final match = RegExp(r'level_(\d+)').firstMatch(docId);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 1;
    }
    return 1;
  }

  int _extractCompletedCount(Map<String, dynamic>? data) {
    final completed =
        data?['completedGames'] ?? data?['completedGameIndices'] ?? const [];
    if (completed is List) return completed.length;
    return 0;
  }

  List<GameReviewItem> _parseGameResults(dynamic raw) {
    if (raw is! Map) return const [];

    final items = <GameReviewItem>[];
    for (final entry in raw.entries) {
      final gameKey = entry.key.toString();
      final value = entry.value;
      if (value is! Map) continue;

      final selected = (value['selectedAnswer'] ?? '-').toString();
      final correct = (value['correctAnswer'] ?? '-').toString();
      final isCorrect = (value['isCorrect'] as bool?) ?? (selected == correct);
      final index = _toInt(value['gameIndex']);
      final score = _toInt(value['scoreAwarded']);
      final submittedAt = _toDate(value['submittedAt']);

      items.add(
        GameReviewItem(
          gameKey: gameKey,
          gameTitle: _prettyGameTitle(gameKey),
          selectedAnswer: selected,
          correctAnswer: correct,
          isCorrect: isCorrect,
          gameIndex: index,
          scoreAwarded: score,
          submittedAt: submittedAt,
        ),
      );
    }

    items.sort((a, b) => a.gameIndex.compareTo(b.gameIndex));
    return items;
  }

  String _prettyGameTitle(String key) {
    const map = <String, String>{
      'shape_match': 'Shape Match Game',
      'animal_guess': 'Animal Guess Game',
      'pattern_recognition': 'Pattern Recognition Game',
      'category_sorting': 'Category Sorting Game',
      'memory_sequence': 'Memory Sequence Game',
      'reasoning_choice': 'Reasoning Choice Game',
      'logic_grid_match': 'Logic Grid Match Game',
      'smart_analogy_challenge': 'Smart Analogy Challenge',
      'visual_logic_completion': 'Visual Logic Completion',
    };

    if (map.containsKey(key)) return map[key]!;
    return key
        .split('_')
        .where((s) => s.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}

enum LevelStatus { completed, inProgress, locked }

class ChildProgressBundle {
  final int currentLevel;
  final int currentGameIndex;
  final int completedLevels;
  final int totalLevels;
  final int totalScore;
  final List<LevelReviewData> levels;

  const ChildProgressBundle({
    required this.currentLevel,
    required this.currentGameIndex,
    required this.completedLevels,
    required this.totalLevels,
    required this.totalScore,
    required this.levels,
  });
}

class LevelReviewData {
  final int levelNumber;
  final LevelStatus status;
  final int score;
  final int totalGames;
  final int completedCount;
  final List<GameReviewItem> gameReviews;
  final DateTime? updatedAt;

  const LevelReviewData({
    required this.levelNumber,
    required this.status,
    required this.score,
    required this.totalGames,
    required this.completedCount,
    required this.gameReviews,
    required this.updatedAt,
  });
}

class GameReviewItem {
  final String gameKey;
  final String gameTitle;
  final String selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final int gameIndex;
  final int scoreAwarded;
  final DateTime? submittedAt;

  const GameReviewItem({
    required this.gameKey,
    required this.gameTitle,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.gameIndex,
    required this.scoreAwarded,
    required this.submittedAt,
  });
}