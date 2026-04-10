import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/emotional_report.dart';
import '../models/game_session.dart';

class ReportingService {
  const ReportingService();

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

  Future<EmotionalReport?> fetchEmotionalReportForDate({
    required String childId,
    required DateTime selectedDate,
  }) async {
    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final end = start.add(const Duration(days: 1));

    final snapshot = await _childrenRef()
        .doc(childId)
        .collection('emotionalReports')
        .where('reportDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('reportDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('reportDate', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return EmotionalReport.fromDoc(snapshot.docs.first);
  }

  Future<Map<String, dynamic>?> fetchLevelProgress(String childId) async {
    final progressDoc = await _childrenRef()
        .doc(childId)
        .collection('gameProgress')
        .doc('level_1')
        .get();

    return progressDoc.data();
  }

  Future<List<GameSession>> fetchRecentGameSessions(String childId) async {
    final snapshot = await _childrenRef()
        .doc(childId)
        .collection('gameSessions')
        .orderBy('playedAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map(GameSession.fromDoc).toList();
  }
}