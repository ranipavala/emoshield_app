import 'package:flutter/material.dart';

import '../models/level_progress.dart';
import '../services/game_progress_service.dart';
import 'child_home_screen.dart';
import 'games_screen.dart';

class LevelResultScreen extends StatelessWidget {
  final String childId;
  final String childName;
  final int levelNumber;

  const LevelResultScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.levelNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      body: SafeArea(
        child: FutureBuilder<LevelProgress>(
          future: const GameProgressService().loadLevelProgress(
            childId: childId,
            levelNumber: levelNumber,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final progress = snapshot.data!;
            final totalGames = 3;

            return Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    '🎉 Great Job!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2F86D6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$childName completed Level $levelNumber',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF1B3),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF4C522), width: 6),
                    ),
                    child: Center(
                      child: Text(
                        '${progress.totalScore}/$totalGames',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          color: Color(0xFF2F86D6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    progress.isCompleted
                        ? 'You finished this level successfully!'
                        : 'You are still in progress.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (levelNumber < 3) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GamesScreen(
                                childId: childId,
                                childName: childName,
                              ),
                            ),
                            (route) => false,
                          );
                        } else {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChildHomeScreen(
                                childId: childId,
                                childName: childName,
                              ),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4C522),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        levelNumber < 3 ? 'Continue Journey' : 'Back To Child Home',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}