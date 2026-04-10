import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/game_session.dart';

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

  Future<Map<String, dynamic>?> loadLevelProgress(String childId) async {
    // Prefer highest available completed/in-progress level
    for (final levelId in ['level_3', 'level_2', 'level_1']) {
      final snapshot = await _childrenRef()
          .doc(childId)
          .collection('gameProgress')
          .doc(levelId)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data();
      }
    }
    return null;
  }

  Future<List<GameSession>> loadRecentSessions(String childId) async {
    final snapshot = await _childrenRef()
        .doc(childId)
        .collection('gameSessions')
        .orderBy('playedAt', descending: true)
        .limit(30)
        .get();

    return snapshot.docs.map(GameSession.fromDoc).toList();
  }
}