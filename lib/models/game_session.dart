import 'package:cloud_firestore/cloud_firestore.dart';

class GameSession {
  final String id;
  final String levelName;
  final String gameId;
  final String gameTitle;
  final int score;
  final int totalQuestions;
  final DateTime? playedAt;

  const GameSession({
    required this.id,
    required this.levelName,
    required this.gameId,
    required this.gameTitle,
    required this.score,
    required this.totalQuestions,
    required this.playedAt,
  });

  factory GameSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return GameSession(
      id: doc.id,
      levelName: (data['levelName'] ?? 'Level 1').toString(),
      gameId: (data['gameId'] ?? '').toString(),
      gameTitle: (data['gameTitle'] ?? 'Game').toString(),
      score: _toInt(data['score']),
      totalQuestions: _toInt(data['totalQuestions']),
      playedAt: data['playedAt'] is Timestamp ? (data['playedAt'] as Timestamp).toDate() : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}