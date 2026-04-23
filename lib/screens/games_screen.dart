import 'package:flutter/material.dart';

import '../models/level_catalog.dart';
import '../models/level_progress.dart';
import '../services/game_progress_service.dart';
import 'animal_guess_game_screen.dart';
import 'level2_category_sorting_game_screen.dart';
import 'level2_memory_sequence_game_screen.dart';
import 'level3_logic_grid_match_game_screen.dart';
import 'level3_sequence_builder_game_screen.dart';
import 'level3_smart_analogy_challenge_screen.dart';
import 'level_result_screen.dart';
import 'pattern_recognition_game_screen.dart';
import 'shape_match_game_screen.dart';

class GamesScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const GamesScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _progressService = const GameProgressService();
  late Future<_AllLevelsProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadAllLevelsProgress();
  }

  Future<_AllLevelsProgress> _loadAllLevelsProgress() async {
    final level1 = await _progressService.ensureLevelProgress(
      childId: widget.childId,
      levelNumber: 1,
    );
    final level2 = await _progressService.ensureLevelProgress(
      childId: widget.childId,
      levelNumber: 2,
    );
    final level3 = await _progressService.ensureLevelProgress(
      childId: widget.childId,
      levelNumber: 3,
    );

    return _AllLevelsProgress(
      level1: level1,
      level2: level2,
      level3: level3,
    );
  }

  Future<void> _resumeLevel(int levelNumber) async {
    final progress = await _progressService.ensureLevelProgress(
      childId: widget.childId,
      levelNumber: levelNumber,
    );

    if (!mounted) return;

    if (progress.isCompleted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LevelResultScreen(
            childId: widget.childId,
            childName: widget.childName,
            levelNumber: levelNumber,
          ),
        ),
      );
      return;
    }

    switch (levelNumber) {
      case 1:
        _openLevel1(progress.currentGameIndex);
        break;
      case 2:
        _openLevel2(progress.currentGameIndex);
        break;
      case 3:
        _openLevel3(progress.currentGameIndex);
        break;
      default:
        _openLevel1(0);
    }
  }

  void _openLevel1(int gameIndex) {
    switch (gameIndex) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ShapeMatchGameScreen(
              childId: widget.childId,
              childName: widget.childName,
            ),
          ),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnimalGuessGameScreen(
              childId: widget.childId,
              childName: widget.childName,
            ),
          ),
        );
        break;
      case 2:
      default:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatternRecognitionGameScreen(
              childId: widget.childId,
              childName: widget.childName,
            ),
          ),
        );
    }
  }

  void _openLevel2(int gameIndex) {
    switch (gameIndex) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Level2MemorySequenceGameScreen(
              childId: widget.childId,
              childName: widget.childName,
            ),
          ),
        );
        break;
      case 1:
      default:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Level2CategorySortingGameScreen(
              childId: widget.childId,
              childName: widget.childName,
            ),
          ),
        );
    }
  }

  void _openLevel3(int gameIndex) {
    switch (gameIndex) {
      case 0:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Level3LogicGridMatchGameScreen(
              childId: widget.childId,
              childName: widget.childName,
            ),
          ),
        );
        break;
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Level3SequenceBuilderGameScreen(
              childId: widget.childId,
              childName: widget.childName,
            ),
          ),
        );
        break;
      case 2:
      default:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Level3SmartAnalogyChallengeScreen(
              childId: widget.childId,
              childName: widget.childName,
            ),
          ),
        );
    }
  }

  Widget _levelCard({
    required int levelNumber,
    required LevelProgress progress,
    required Color color,
    required String subtitle,
  }) {
    final totalGames = LevelCatalog.totalGames(levelNumber);
    final completed = progress.completedGameIndices.length;
    final nextGame = (progress.currentGameIndex + 1).clamp(1, totalGames);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 6),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Level $levelNumber',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            progress.isCompleted
                ? 'Completed: $completed/$totalGames games'
                : 'Progress: $completed/$totalGames games\nNext game: $nextGame',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total score: ${progress.totalScore}/$totalGames',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4C522),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _resumeLevel(levelNumber),
              child: Text(
                progress.isCompleted ? 'View Result' : 'Play Level $levelNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _level3Preview() {
    const items = [
      '1) Logic Grid Match Game',
      '2) Sequence Builder Game',
      '3) Smart Analogy Challenge',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Level 3 Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F86D6),
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7ECFF),
        elevation: 0,
        title: const Text(
          'IQ Games',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<_AllLevelsProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'Hi ${widget.childName}! Ready for fun IQ challenges?\nStart any level and keep growing your brain power!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2F86D6),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _levelCard(
                  levelNumber: 1,
                  progress: data.level1,
                  color: const Color(0xFF6C7CFF),
                  subtitle: 'Foundations: matching, guessing, and simple pattern logic.',
                ),
                _levelCard(
                  levelNumber: 2,
                  progress: data.level2,
                  color: const Color(0xFF44AA73),
                  subtitle: 'Intermediate: memory, sorting, and visual reasoning.',
                ),
                _levelCard(
                  levelNumber: 3,
                  progress: data.level3,
                  color: const Color(0xFFE85A75),
                  subtitle: 'Advanced: logic-grid, sequence-building, and analogy challenge.',
                ),
                _level3Preview(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AllLevelsProgress {
  final LevelProgress level1;
  final LevelProgress level2;
  final LevelProgress level3;

  const _AllLevelsProgress({
    required this.level1,
    required this.level2,
    required this.level3,
  });
}