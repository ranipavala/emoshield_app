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
    final snapshot = await _childrenRef()
        .doc(childId)
        .collection('gameProgress')
        .doc('level_1')
        .get();

    return snapshot.data();
  }

  Future<List<GameSession>> loadRecentSessions(String childId) async {
    final snapshot = await _childrenRef()
        .doc(childId)
        .collection('gameSessions')
        .orderBy('playedAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map(GameSession.fromDoc).toList();
  }
}