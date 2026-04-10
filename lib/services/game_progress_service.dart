import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  DocumentReference<Map<String, dynamic>> _levelRef(String childId) {
    return _childRef(childId).collection('gameProgress').doc(LevelProgress.levelId);
  }

  CollectionReference<Map<String, dynamic>> _sessionsRef(String childId) {
    return _childRef(childId).collection('gameSessions');
  }

  Future<LevelProgress> ensureLevelOneProgress(String childId) async {
    final ref = _levelRef(childId);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      final initial = LevelProgress.initial();
      await ref.set({
        'levelNumber': 1,
        'currentLevel': 1,
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
      });
      return initial;
    }

    return LevelProgress.fromMap(snapshot.data());
  }

  Future<LevelProgress> loadLevelOneProgress(String childId) async {
    final snapshot = await _levelRef(childId).get();
    return LevelProgress.fromMap(snapshot.data());
  }

  Future<void> saveGameResult({
    required String childId,
    required int gameIndex,
    required String gameKey,
    required String selectedAnswer,
    required String correctAnswer,
    required int score,
    required String gameTitle,
    required int totalQuestions,
  }) async {
    final ref = _levelRef(childId);
    final current = await ensureLevelOneProgress(childId);

    final completed = {...current.completedGameIndices, gameIndex}.toList()..sort();
    final scores = Map<String, int>.from(current.gameScores)..[gameKey] = score;
    final isCompleted = completed.length >= LevelProgress.totalGames;
    final nextGameIndex = isCompleted ? LevelProgress.totalGames : _firstIncomplete(completed);
    final totalScore = scores.values.fold<int>(0, (sum, value) => sum + value);
    final isCorrect = selectedAnswer == correctAnswer;
    final unlockedGames = _buildUnlockedGames(nextGameIndex, isCompleted);

    await ref.set({
      'levelNumber': 1,
      'currentLevel': 1,
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
          'level': 1,
          'submittedAt': FieldValue.serverTimestamp(),
        },
      },
      'isCompleted': isCompleted,
      'totalScore': totalScore,
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));

    await _sessionsRef(childId).add({
      'levelName': 'Level 1',
      'gameId': gameKey,
      'gameTitle': gameTitle,
      'score': score,
      'totalQuestions': totalQuestions,
      'playedAt': FieldValue.serverTimestamp(),
    });
  }

  List<int> _buildUnlockedGames(int nextGameIndex, bool isCompleted) {
    if (isCompleted) {
      return List<int>.generate(LevelProgress.totalGames, (index) => index);
    }

    final unlockedCount = (nextGameIndex + 1).clamp(1, LevelProgress.totalGames);
    return List<int>.generate(unlockedCount, (index) => index);
  }

  int _firstIncomplete(List<int> completed) {
    for (var index = 0; index < LevelProgress.totalGames; index++) {
      if (!completed.contains(index)) {
        return index;
      }
    }
    return LevelProgress.totalGames;
  }
}