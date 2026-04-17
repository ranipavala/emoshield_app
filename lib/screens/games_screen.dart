import 'package:flutter/material.dart';

import '../models/level_catalog.dart';
import '../models/level_progress.dart';
import '../services/game_progress_service.dart';
import 'animal_guess_game_screen.dart';
import 'level2_category_sorting_game_screen.dart';
import 'level2_memory_sequence_game_screen.dart';
import 'level2_visual_logic_completion_game_screen.dart';
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
  late Future<_LevelsProgressBundle> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadLevelsProgress();
  }

  Future<_LevelsProgressBundle> _loadLevelsProgress() async {
    final level1 = await _progressService.ensureLevelProgress(
      childId: widget.childId,
      levelNumber: 1,
    );
    final level2 = await _progressService.ensureLevelProgress(
      childId: widget.childId,
      levelNumber: 2,
    );
    return _LevelsProgressBundle(level1: level1, level2: level2);
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

    if (levelNumber == 1) {
      _openLevel1Game(progress.currentGameIndex);
      return;
    }

    if (levelNumber == 2) {
      _openLevel2Game(progress.currentGameIndex);
      return;
    }
  }

  void _openLevel1Game(int gameIndex) {
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

  void _openLevel2Game(int gameIndex) {
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Level2CategorySortingGameScreen(
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
            builder: (_) => Level2VisualLogicCompletionGameScreen(
              childId: widget.childId,
              childName: widget.childName,
            ),
          ),
        );
    }
  }

  Widget _buildLevelCard({
    required int levelNumber,
    required LevelProgress progress,
    required Color cardColor,
    required String subtitle,
  }) {
    final totalGames = LevelCatalog.totalGames(levelNumber);
    final completedGames = progress.completedGameIndices.length;
    final nextGame = (progress.currentGameIndex + 1).clamp(1, totalGames);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
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
          const SizedBox(height: 12),
          Text(
            progress.isCompleted
                ? 'Completed: $completedGames/$totalGames games'
                : 'Progress: $completedGames/$totalGames games\nNext game: $nextGame',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Total score: ${progress.totalScore}/$totalGames',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevel2GameList() {
    const games = [
      '1. Memory Sequence Game',
      '2. Category Sorting Game',
      '3. Visual Logic Completion Game',
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
            'Level 2 Games',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F86D6),
            ),
          ),
          const SizedBox(height: 10),
          ...games.map(
            (title) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<_LevelsProgressBundle>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final levels = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'Hi ${widget.childName}! Choose a level and keep building your IQ skills 🚀',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2F86D6),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    children: [
                      _buildLevelCard(
                        levelNumber: 1,
                        progress: levels.level1,
                        cardColor: const Color(0xFF6C7CFF),
                        subtitle: 'Foundations: matching, guessing, and simple pattern logic.',
                      ),
                      const SizedBox(height: 12),
                      _buildLevelCard(
                        levelNumber: 2,
                        progress: levels.level2,
                        cardColor: const Color(0xFF44AA73),
                        subtitle: 'Advanced: memory, category reasoning, and visual logic.',
                      ),
                      const SizedBox(height: 12),
                      _buildLevel2GameList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LevelsProgressBundle {
  final LevelProgress level1;
  final LevelProgress level2;

  const _LevelsProgressBundle({
    required this.level1,
    required this.level2,
  });
}