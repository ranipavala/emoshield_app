import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/level_catalog.dart';
import '../models/level_progress.dart';

class GameProgressService {
  const GameProgressService();

  String _parentId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Parent user is not authenticated.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _childRef(String childId) {
    return FirebaseFirestore.instance
        .collection('parents')
        .doc(_parentId())
        .collection('children')
        .doc(childId);
  }

  DocumentReference<Map<String, dynamic>> _levelRef({
    required String childId,
    required int levelNumber,
  }) {
    return _childRef(childId)
        .collection('gameProgress')
        .doc(LevelCatalog.levelId(levelNumber));
  }

  CollectionReference<Map<String, dynamic>> _sessionsRef(String childId) {
    return _childRef(childId).collection('gameSessions');
  }

  Future<LevelProgress> ensureLevelProgress({
    required String childId,
    required int levelNumber,
  }) async {
    final totalGames = LevelCatalog.totalGames(levelNumber);
    final ref = _levelRef(childId: childId, levelNumber: levelNumber);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      final initial = LevelProgress.initial();
      await ref.set({
        'levelNumber': levelNumber,
        'currentLevel': levelNumber,
        'currentGameIndex': initial.currentGameIndex,
        'completedGameIndices': initial.completedGameIndices,
        'completedGames': initial.completedGameIndices,
        'unlockedGames': const [0],
        'gameScores': initial.gameScores,
        'gameResults': <String, dynamic>{},
        'isCompleted': initial.isCompleted,
        'totalScore': initial.totalScore,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'totalGames': totalGames,
      }, SetOptions(merge: true));
      return initial;
    }

    return LevelProgress.fromMap(snapshot.data());
  }

  Future<LevelProgress> loadLevelProgress({
    required String childId,
    required int levelNumber,
  }) async {
    final snapshot =
        await _levelRef(childId: childId, levelNumber: levelNumber).get();
    return LevelProgress.fromMap(snapshot.data());
  }

  Future<void> saveGameResult({
    required String childId,
    required int levelNumber,
    required int gameIndex,
    required String gameKey,
    required String selectedAnswer,
    required String correctAnswer,
    required int score,
    required String gameTitle,
    required int totalQuestions,
    bool recordSession = true,
    String? sessionId,
  }) async {
    final totalGames = LevelCatalog.totalGames(levelNumber);
    final ref = _levelRef(childId: childId, levelNumber: levelNumber);
    final current = await ensureLevelProgress(
      childId: childId,
      levelNumber: levelNumber,
    );

    final completed = {...current.completedGameIndices, gameIndex}.toList()..sort();
    final scores = Map<String, int>.from(current.gameScores)..[gameKey] = score;
    final isCompleted = completed.length >= totalGames;
    final nextGameIndex =
        isCompleted ? totalGames : _firstIncomplete(completed, totalGames);
    final totalScore = scores.values.fold<int>(0, (sum, value) => sum + value);
    final isCorrect = selectedAnswer == correctAnswer;
    final unlockedGames = _buildUnlockedGames(
      nextGameIndex: nextGameIndex,
      isCompleted: isCompleted,
      totalGames: totalGames,
    );

    await ref.set({
      'levelNumber': levelNumber,
      'currentLevel': levelNumber,
      'currentGameIndex': nextGameIndex,
      'completedGameIndices': completed,
      'completedGames': completed,
      'unlockedGames': unlockedGames,
      'gameScores': scores,
      'gameResults': {
        gameKey: {
          'selectedAnswer': selectedAnswer,
          'correctAnswer': correctAnswer,
          'isCorrect': isCorrect,
          'scoreAwarded': score,
          'gameIndex': gameIndex,
          'level': levelNumber,
          'submittedAt': FieldValue.serverTimestamp(),
          'sessionId': sessionId,
        },
      },
      'isCompleted': isCompleted,
      'totalScore': totalScore,
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
      'totalGames': totalGames,
    }, SetOptions(merge: true));

    if (recordSession) {
      await _sessionsRef(childId).add({
        'levelName': 'Level $levelNumber',
        'levelNumber': levelNumber,
        'gameId': gameKey,
        'gameTitle': gameTitle,
        'score': score,
        'totalQuestions': totalQuestions,
        'playedAt': FieldValue.serverTimestamp(),
        'sessionId': sessionId,
      });
    } else if (sessionId != null) {
      await _sessionsRef(childId).doc(sessionId).set({
        'score': score,
        'totalQuestions': totalQuestions,
        'playedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await _childRef(childId).set({
      'currentLevel': levelNumber,
      'currentGameIndex': nextGameIndex,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<LevelProgress> ensureLevelOneProgress(String childId) {
    return ensureLevelProgress(childId: childId, levelNumber: 1);
  }

  Future<LevelProgress> loadLevelOneProgress(String childId) {
    return loadLevelProgress(childId: childId, levelNumber: 1);
  }

  List<int> _buildUnlockedGames({
    required int nextGameIndex,
    required bool isCompleted,
    required int totalGames,
  }) {
    if (isCompleted) {
      return List<int>.generate(totalGames, (index) => index);
    }

    final unlockedCount = (nextGameIndex + 1).clamp(1, totalGames);
    return List<int>.generate(unlockedCount, (index) => index);
  }

  int _firstIncomplete(List<int> completed, int totalGames) {
    for (var index = 0; index < totalGames; index++) {
      if (!completed.contains(index)) {
        return index;
      }
    }
    return totalGames;
  }
}