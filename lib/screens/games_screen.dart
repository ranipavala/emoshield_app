import 'package:flutter/material.dart';

import '../models/level_progress.dart';
import '../services/game_progress_service.dart';
import 'animal_guess_game_screen.dart';
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
  late Future<LevelProgress> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _progressService.ensureLevelOneProgress(widget.childId);
  }

  Future<void> _resumeLevel() async {
    final progress = await _progressService.ensureLevelOneProgress(widget.childId);

    if (!mounted) return;

    if (progress.isCompleted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LevelResultScreen(
            childId: widget.childId,
            childName: widget.childName,
          ),
        ),
      );
      return;
    }

    switch (progress.currentGameIndex) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7ECFF),
        elevation: 0,
        title: const Text(
          'Level 1',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<LevelProgress>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final progress = snapshot.data!;
          final completedGames = progress.completedGameIndices.length;
          final nextGameNumber = (progress.currentGameIndex + 1).clamp(1, 3);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                    children: [
                      Text(
                        'Hi ${widget.childName}! Ready for IQ Level 1?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2F86D6),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        progress.isCompleted
                            ? 'Awesome! You completed all 3 games.'
                            : 'Progress: $completedGames/3 games finished.\nNext game: $nextGameNumber',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (progress.isCompleted) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Total score: ${progress.totalScore}/3',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2F86D6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _GameListTile(index: 1, title: 'Shape Match Game'),
                const SizedBox(height: 12),
                const _GameListTile(index: 2, title: 'Animal Guess Game'),
                const SizedBox(height: 12),
                const _GameListTile(index: 3, title: 'Pattern Recognition Game'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4C522),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _resumeLevel,
                    child: Text(
                      progress.isCompleted ? 'View Result' : 'Play Game',
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
}

class _GameListTile extends StatelessWidget {
  final int index;
  final String title;

  const _GameListTile({required this.index, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF7FB8F0),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}