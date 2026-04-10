import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/level_progress.dart';

class GameProgressService {
  const GameProgressService();

  DocumentReference<Map<String, dynamic>> _levelRef(String childId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Parent user is not authenticated.');
    }

    return FirebaseFirestore.instance
        .collection('parents')
        .doc(user.uid)
        .collection('children')
        .doc(childId)
        .collection('gameProgress')
        .doc(LevelProgress.levelId);
  }

  Future<LevelProgress> ensureLevelOneProgress(String childId) async {
    final ref = _levelRef(childId);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      final initial = LevelProgress.initial();
      await ref.set({
        'levelNumber': 1,
        'currentGameIndex': initial.currentGameIndex,
        'completedGameIndices': initial.completedGameIndices,
        'gameScores': initial.gameScores,
        'isCompleted': initial.isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
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
    required int score,
  }) async {
    final ref = _levelRef(childId);
    final current = await ensureLevelOneProgress(childId);

    final completed = {...current.completedGameIndices, gameIndex}.toList()..sort();
    final scores = Map<String, int>.from(current.gameScores)..[gameKey] = score;
    final isCompleted = completed.length >= LevelProgress.totalGames;
    final nextGameIndex = isCompleted ? LevelProgress.totalGames : _firstIncomplete(completed);

    await ref.set({
      'levelNumber': 1,
      'currentGameIndex': nextGameIndex,
      'completedGameIndices': completed,
      'gameScores': scores,
      'isCompleted': isCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));
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
