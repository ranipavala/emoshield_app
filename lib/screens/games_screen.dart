import 'package:flutter/material.dart';

import '../models/level_catalog.dart';
import '../models/level_progress.dart';
import '../services/game_progress_service.dart';
import 'animal_guess_game_screen.dart';
import 'level2_category_sorting_game_screen.dart';
import 'level2_memory_sequence_game_screen.dart';
import 'level_result_screen.dart';
import 'pattern_recognition_game_screen.dart';
import 'reasoning_choice_game_screen.dart';
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
  final _service = const GameProgressService();
  late Future<_ResumeState> _resumeFuture;

  @override
  void initState() {
    super.initState();
    _resumeFuture = _loadResumeState();
  }

  Future<_ResumeState> _loadResumeState() async {
    for (int level = 1; level <= LevelCatalog.maxLevel; level++) {
      final progress = await _service.ensureLevelProgress(
        childId: widget.childId,
        levelNumber: level,
      );

      if (!progress.isCompleted) {
        return _ResumeState(
          levelNumber: level,
          progress: progress,
          isAllCompleted: false,
        );
      }
    }

    final level3 = await _service.loadLevelProgress(
      childId: widget.childId,
      levelNumber: 3,
    );

    return _ResumeState(
      levelNumber: 3,
      progress: level3,
      isAllCompleted: true,
    );
  }

  void _openGame({
    required int levelNumber,
    required int gameIndex,
  }) {
    Widget screen;

    if (levelNumber == 1) {
      if (gameIndex == 0) {
        screen = ShapeMatchGameScreen(
          childId: widget.childId,
          childName: widget.childName,
        );
      } else if (gameIndex == 1) {
        screen = AnimalGuessGameScreen(
          childId: widget.childId,
          childName: widget.childName,
        );
      } else {
        screen = PatternRecognitionGameScreen(
          childId: widget.childId,
          childName: widget.childName,
        );
      }
    } else if (levelNumber == 2) {
      if (gameIndex == 0) {
        screen = Level2MemorySequenceGameScreen(
          childId: widget.childId,
          childName: widget.childName,
        );
      } else if (gameIndex == 1) {
        screen = Level2CategorySortingGameScreen(
          childId: widget.childId,
          childName: widget.childName,
        );
      } else {
        screen = ReasoningChoiceGameScreen(
          childId: widget.childId,
          childName: widget.childName,
          levelNumber: 2,
          gameIndex: 2,
          gameKey: 'picture_logic',
          gameTitle: 'Picture Logic Game',
          question: 'Which picture best completes the pattern?',
          prompt: '🌞 🌧 🌞 ?',
          options: const ['🌧', '🌙', '⭐', '☁'],
          correctAnswer: '🌧',
          nextRoute: const LevelResultScreen(
            childId: '',
            childName: '',
            levelNumber: 2,
          ),
        );
      }
    } else {
      if (gameIndex == 0) {
        screen = ReasoningChoiceGameScreen(
          childId: widget.childId,
          childName: widget.childName,
          levelNumber: 3,
          gameIndex: 0,
          gameKey: 'number_pattern',
          gameTitle: 'Number Pattern Game',
          question: 'What comes next in the number pattern?',
          prompt: '2, 4, 8, 16, ?',
          options: const ['18', '24', '32', '20'],
          correctAnswer: '32',
          nextRoute: ReasoningChoiceGameScreen(
            childId: widget.childId,
            childName: widget.childName,
            levelNumber: 3,
            gameIndex: 1,
            gameKey: 'analogy_match',
            gameTitle: 'Analogy Match Game',
            question: 'Bird is to Sky as Fish is to ____?',
            prompt: 'Choose the best relation.',
            options: const ['Tree', 'Water', 'Sand', 'Nest'],
            correctAnswer: 'Water',
            nextRoute: ReasoningChoiceGameScreen(
              childId: widget.childId,
              childName: widget.childName,
              levelNumber: 3,
              gameIndex: 2,
              gameKey: 'matrix_reasoning',
              gameTitle: 'Matrix Reasoning Game',
              question: 'Pick the missing tile pattern.',
              prompt: '⬛⬜  ⬜⬛  ?',
              options: const ['⬛⬜', '⬜⬛', '⬛⬛', '⬜⬜'],
              correctAnswer: '⬛⬜',
              nextRoute: LevelResultScreen(
                childId: widget.childId,
                childName: widget.childName,
                levelNumber: 3,
              ),
            ),
          ),
        );
      } else if (gameIndex == 1) {
        screen = ReasoningChoiceGameScreen(
          childId: widget.childId,
          childName: widget.childName,
          levelNumber: 3,
          gameIndex: 1,
          gameKey: 'analogy_match',
          gameTitle: 'Analogy Match Game',
          question: 'Bird is to Sky as Fish is to ____?',
          prompt: 'Choose the best relation.',
          options: const ['Tree', 'Water', 'Sand', 'Nest'],
          correctAnswer: 'Water',
          nextRoute: ReasoningChoiceGameScreen(
            childId: widget.childId,
            childName: widget.childName,
            levelNumber: 3,
            gameIndex: 2,
            gameKey: 'matrix_reasoning',
            gameTitle: 'Matrix Reasoning Game',
            question: 'Pick the missing tile pattern.',
            prompt: '⬛⬜  ⬜⬛  ?',
            options: const ['⬛⬜', '⬜⬛', '⬛⬛', '⬜⬜'],
            correctAnswer: '⬛⬜',
            nextRoute: LevelResultScreen(
              childId: widget.childId,
              childName: widget.childName,
              levelNumber: 3,
            ),
          ),
        );
      } else {
        screen = ReasoningChoiceGameScreen(
          childId: widget.childId,
          childName: widget.childName,
          levelNumber: 3,
          gameIndex: 2,
          gameKey: 'matrix_reasoning',
          gameTitle: 'Matrix Reasoning Game',
          question: 'Pick the missing tile pattern.',
          prompt: '⬛⬜  ⬜⬛  ?',
          options: const ['⬛⬜', '⬜⬛', '⬛⬛', '⬜⬜'],
          correctAnswer: '⬛⬜',
          nextRoute: LevelResultScreen(
            childId: widget.childId,
            childName: widget.childName,
            levelNumber: 3,
          ),
        );
      }
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _onPlay(_ResumeState state) {
    if (state.isAllCompleted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LevelResultScreen(
            childId: widget.childId,
            childName: widget.childName,
            levelNumber: 3,
          ),
        ),
      );
      return;
    }

    _openGame(levelNumber: state.levelNumber, gameIndex: state.progress.currentGameIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7ECFF),
        elevation: 0,
        title: const Text(
          'IQ Journey',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: FutureBuilder<_ResumeState>(
        future: _resumeFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final state = snapshot.data!;

          final totalGames = LevelCatalog.totalGames(state.levelNumber);
          final completed = state.progress.completedGameIndices.length;
          final nextGame = (state.progress.currentGameIndex + 1).clamp(1, totalGames);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        state.isAllCompleted
                            ? 'Amazing ${widget.childName}! You finished all levels!'
                            : 'Hi ${widget.childName}! Continue from Level ${state.levelNumber}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2F86D6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.isAllCompleted
                            ? 'Tap below to view your final achievement.'
                            : 'Progress: $completed/$totalGames games done\nNext game: $nextGame',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _levelCard(1, 'Level 1 - Beginner'),
                _levelCard(2, 'Level 2 - Medium'),
                _levelCard(3, 'Level 3 - Advanced'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _onPlay(state),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4C522),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      state.isAllCompleted ? 'View Final Result' : 'Play Game',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _levelCard(int level, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ResumeState {
  final int levelNumber;
  final LevelProgress progress;
  final bool isAllCompleted;

  const _ResumeState({
    required this.levelNumber,
    required this.progress,
    required this.isAllCompleted,
  });
}