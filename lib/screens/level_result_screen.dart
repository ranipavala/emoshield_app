import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/level_progress.dart';
import '../services/game_progress_service.dart';
import 'child_home_screen.dart';

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

  Future<LevelProgress> _loadProgress() async {
    if (levelNumber == 1) {
      return const GameProgressService().loadLevelOneProgress(childId);
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return LevelProgress.initial();

    final snapshot = await FirebaseFirestore.instance
        .collection('parents')
        .doc(user.uid)
        .collection('children')
        .doc(childId)
        .collection('gameProgress')
        .doc('level_$levelNumber')
        .get();

    return LevelProgress.fromMap(snapshot.data());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      body: SafeArea(
        child: FutureBuilder<LevelProgress>(
          future: _loadProgress(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final progress = snapshot.data!;
            final gameLabels = <String, String>{
              'shape_match': 'Shape Match',
              'animal_guess': 'Animal Guess',
              'pattern_recognition': 'Pattern Recognition',
              'memory_sequence': 'Memory Sequence',
              'category_sorting': 'Category Sorting',
              'picture_logic': 'Picture Logic',
              'number_pattern': 'Number Pattern',
              'analogy_match': 'Analogy Match',
              'matrix_reasoning': 'Matrix Reasoning',
            };

            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/emoshield_logo.png',
                    height: 34,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Text(
                      'EmoShield',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
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
                          'Level $levelNumber Complete!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2F86D6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Great job, $childName! You finished this level.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 148,
                          height: 148,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF1B3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF4C522),
                              width: 6,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Score',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${progress.totalScore}/3',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF2F86D6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7FB8F0).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            children: progress.gameScores.entries.map((entry) {
                              final label = gameLabels[entry.key] ?? entry.key;
                              final score = entry.value;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$score/1',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF2F86D6),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4C522),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => ChildHomeScreen(
                              childId: childId,
                              childName: childName,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Back To Child Home',
                        style: TextStyle(
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
          },
        ),
      ),
    );
  }
}