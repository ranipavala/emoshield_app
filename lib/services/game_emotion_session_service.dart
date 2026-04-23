import 'dart:async';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'emotion_inference_service.dart';

class EmotionSessionStartResult {
  final bool started;
  final String sessionId;
  final String? warning;

  const EmotionSessionStartResult({
    required this.started,
    required this.sessionId,
    this.warning,
  });
}

class GameEmotionSessionService {
  GameEmotionSessionService({EmotionInferenceService? inferenceService})
      : _inferenceService = inferenceService ?? EmotionInferenceService();

  final EmotionInferenceService _inferenceService;

  CameraController? _cameraController;
  Timer? _samplingTimer;
  bool _isSampling = false;

  String? _sessionId;
  String? _childId;
  int? _levelNumber;
  String? _gameId;
  String? _gameTitle;

  final Map<String, int> _emotionCounts = <String, int>{
    for (final label in EmotionInferenceService.labels) label: 0,
  };
  int _totalReadings = 0;

  String? get sessionId => _sessionId;

  String _parentId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Parent user is not authenticated.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _sessionRef() {
    return FirebaseFirestore.instance
        .collection('parents')
        .doc(_parentId())
        .collection('children')
        .doc(_childId)
        .collection('gameSessions')
        .doc(_sessionId);
  }

  CollectionReference<Map<String, dynamic>> _emotionalReportsRef() {
    return FirebaseFirestore.instance
        .collection('parents')
        .doc(_parentId())
        .collection('children')
        .doc(_childId)
        .collection('emotionalReports');
  }

  Future<EmotionSessionStartResult> startSession({
    required String childId,
    required int levelNumber,
    required String gameId,
    required String gameTitle,
    Duration samplingInterval = const Duration(seconds: 9),
  }) async {
    if (_sessionId != null) {
      return EmotionSessionStartResult(
        started: true,
        sessionId: _sessionId!,
        warning: 'Emotion session already active.',
      );
    }

    _childId = childId;
    _levelNumber = levelNumber;
    _gameId = gameId;
    _gameTitle = gameTitle;

    final sessionDoc = FirebaseFirestore.instance
        .collection('parents')
        .doc(_parentId())
        .collection('children')
        .doc(childId)
        .collection('gameSessions')
        .doc();

    _sessionId = sessionDoc.id;

    await sessionDoc.set({
      'sessionId': sessionDoc.id,
      'childId': childId,
      'parentId': _parentId(),
      'levelNumber': levelNumber,
      'levelName': 'Level $levelNumber',
      'gameId': gameId,
      'gameTitle': gameTitle,
      'status': 'in_progress',
      'startedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'playedAt': null,
      'endedAt': null,
      'emotionMonitoringStatus': 'starting',
    }, SetOptions(merge: true));

    String? warning;

    try {
      await _inferenceService.initialize();
      await _initializeCamera();
      _samplingTimer = Timer.periodic(samplingInterval, (_) => _captureAndInfer());

      await _sessionRef().set({
        'emotionMonitoringStatus': 'active',
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      warning = 'Emotion monitoring is unavailable for this session.';
      debugPrint('Emotion monitor start failure: $error\n$stackTrace');
      await _sessionRef().set({
        'emotionMonitoringStatus': 'unavailable',
        'emotionMonitoringError': error.toString(),
      }, SetOptions(merge: true));
    }

    return EmotionSessionStartResult(
      started: true,
      sessionId: sessionDoc.id,
      warning: warning,
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No device camera available.');
    }

    final selectedCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _cameraController!.initialize();
  }

  Future<void> _captureAndInfer() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isSampling || _sessionId == null) return;

    _isSampling = true;

    try {
      final captured = await controller.takePicture();
      final result = await _inferenceService.inferFromImagePath(captured.path);

      if (result == null) {
        return;
      }

      _totalReadings += 1;
      _emotionCounts[result.emotionLabel] = (_emotionCounts[result.emotionLabel] ?? 0) + 1;

      await _sessionRef().collection('emotionReadings').add({
        'sessionId': _sessionId,
        'childId': _childId,
        'parentId': _parentId(),
        'levelNumber': _levelNumber,
        'gameId': _gameId,
        'gameTitle': _gameTitle,
        'timestamp': FieldValue.serverTimestamp(),
        'emotionLabel': result.emotionLabel,
        'confidenceScore': result.confidenceScore,
        'probabilities': {
          for (var index = 0; index < EmotionInferenceService.labels.length; index++)
            EmotionInferenceService.labels[index]: result.probabilities[index],
        },
      });

      await _sessionRef().set({
        'emotionReadingCount': _totalReadings,
        'lastEmotionLabel': result.emotionLabel,
        'lastEmotionConfidence': result.confidenceScore,
        'lastEmotionAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      debugPrint('Emotion capture skipped: $error\n$stackTrace');
    } finally {
      _isSampling = false;
    }
  }

  Future<void> completeSession({
    required int score,
    required int totalQuestions,
  }) async {
    if (_sessionId == null) return;

    await _disposeCaptureResources();

    final summary = _buildSummary();

    try {
      await _sessionRef().set({
        'score': score,
        'totalQuestions': totalQuestions,
        'status': 'completed',
        'playedAt': FieldValue.serverTimestamp(),
        'endedAt': FieldValue.serverTimestamp(),
        'emotionReadingCount': _totalReadings,
        'emotionSummary': summary,
      }, SetOptions(merge: true));

      await _emotionalReportsRef().doc(_sessionId).set({
        'reportId': _sessionId,
        'sessionId': _sessionId,
        'childId': _childId,
        'parentId': _parentId(),
        'levelNumber': _levelNumber,
        'levelName': 'Level $_levelNumber',
        'gameId': _gameId,
        'gameTitle': _gameTitle,
        'reportDate': FieldValue.serverTimestamp(),
        'happyPercent': summary['happyPercent'],
        'sadPercent': summary['sadPercent'],
        'angryPercent': summary['angryPercent'],
        'neutralPercent': summary['neutralPercent'],
        'surprisePercent': summary['surprisePercent'],
        'majorEmotion': summary['majorEmotion'],
        'readingCount': _totalReadings,
        'score': score,
        'totalQuestions': totalQuestions,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      debugPrint('Emotion session completion write failed: $error\n$stackTrace');
    }

    _resetSessionState();
  }

  Future<void> abandonSession() async {
    if (_sessionId == null) return;

    await _disposeCaptureResources();

    final summary = _buildSummary();
    try {
      await _sessionRef().set({
        'status': 'abandoned',
        'endedAt': FieldValue.serverTimestamp(),
        'emotionReadingCount': _totalReadings,
        'emotionSummary': summary,
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      debugPrint('Emotion session abandon write failed: $error\n$stackTrace');
    }

    _resetSessionState();
  }

  Map<String, dynamic> _buildSummary() {
    if (_totalReadings == 0) {
      return {
        'happyPercent': 0,
        'sadPercent': 0,
        'angryPercent': 0,
        'neutralPercent': 0,
        'surprisePercent': 0,
        'majorEmotion': 'no_data',
      };
    }

    int percent(String emotion) {
      final count = _emotionCounts[emotion] ?? 0;
      return ((count / _totalReadings) * 100).round();
    }

    final ranking = _emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'happyPercent': percent('happy'),
      'sadPercent': percent('sad'),
      'angryPercent': percent('angry'),
      'neutralPercent': percent('neutral'),
      'surprisePercent': percent('surprise'),
      'majorEmotion': ranking.first.value > 0 ? ranking.first.key : 'no_data',
    };
  }

  Future<void> _disposeCaptureResources() async {
    _samplingTimer?.cancel();
    _samplingTimer = null;

    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }
  }

  Future<void> dispose() async {
    await _disposeCaptureResources();
    _inferenceService.dispose();
    _resetSessionState();
  }

  void _resetSessionState() {
    _sessionId = null;
    _childId = null;
    _levelNumber = null;
    _gameId = null;
    _gameTitle = null;
    _totalReadings = 0;

    _emotionCounts
      ..clear()
      ..addAll({for (final label in EmotionInferenceService.labels) label: 0});
  }
}