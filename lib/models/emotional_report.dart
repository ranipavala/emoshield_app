import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionalReport {
  final String id;
  final DateTime? reportDate;
  final int happyPercent;
  final int sadPercent;
  final int angryPercent;
  final int neutralPercent;
  final int surprisePercent;
  final String majorEmotion;
  final String? sessionId;

  const EmotionalReport({
    required this.id,
    required this.reportDate,
    required this.happyPercent,
    required this.sadPercent,
    required this.angryPercent,
    required this.neutralPercent,
    required this.surprisePercent,
    required this.majorEmotion,
    required this.sessionId,
  });

  factory EmotionalReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final reportTimestamp = data['reportDate'];

    return EmotionalReport(
      id: doc.id,
      reportDate: reportTimestamp is Timestamp ? reportTimestamp.toDate() : null,
      happyPercent: _toInt(data['happyPercent']),
      sadPercent: _toInt(data['sadPercent']),
      angryPercent: _toInt(data['angryPercent']),
      neutralPercent: _toInt(data['neutralPercent']),
      surprisePercent: _toInt(data['surprisePercent']),
      majorEmotion: (data['majorEmotion'] ?? 'Unknown').toString(),
      sessionId: data['sessionId']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}