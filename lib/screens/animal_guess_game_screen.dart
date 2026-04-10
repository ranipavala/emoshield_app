import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'child_home_screen.dart';
import 'pattern_recognition_game_screen.dart';

class AnimalGuessGameScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const AnimalGuessGameScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<AnimalGuessGameScreen> createState() => _AnimalGuessGameScreenState();
}

class _AnimalGuessGameScreenState extends State<AnimalGuessGameScreen> {
  static const String _answer = 'FOX';
  static const List<String> _letters = ['X', 'A', 'F', 'J', 'L', 'O', 'I'];

  final _progressService = const GameProgressService();

  final List<String> _pickedLetters = [];
  bool _isSaving = false;

  bool get _canFinish => _pickedLetters.length == _answer.length && !_isSaving;

  Future<void> _finishGame() async {
    if (!_canFinish) return;

    setState(() => _isSaving = true);

    final guess = _pickedLetters.join();
    final score = guess == _answer ? 1 : 0;

    await _progressService.saveGameResult(
      childId: widget.childId,
      gameIndex: 1,
      gameKey: 'animal_guess',
      selectedAnswer: guess,
      correctAnswer: _answer,
      score: score,
      gameTitle: 'Animal Guess Game',
      totalQuestions: 1,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PatternRecognitionGameScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ChildHomeScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameLevelScaffold(
      question: 'Which animal is this?',
      helperText: 'Tap letters in order to spell the animal name.',
      onBackPressed: _goHome,
      onFinishPressed: _finishGame,
      finishEnabled: _canFinish,
      child: Column(
        children: [
          const _FoxFace(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _answer.length,
              (index) {
                final current = index < _pickedLetters.length ? _pickedLetters[index] : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Text(
                        current,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF44AA73),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _letters.map((letter) {
              final isUsed = _pickedLetters.contains(letter);

              return GestureDetector(
                onTap: () {
                  if (_pickedLetters.length >= _answer.length || isUsed) return;
                  setState(() => _pickedLetters.add(letter));
                },
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isUsed ? const Color(0xFFEF4458) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 4,
                        offset: Offset(0, 3),
                        color: Color(0x22000000),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: isUsed ? Colors.white : const Color(0xFFEF4458),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _pickedLetters.isEmpty
                    ? null
                    : () => setState(() => _pickedLetters.removeLast()),
                icon: const Icon(Icons.backspace_outlined),
                label: const Text(
                  'Backspace',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _pickedLetters.isEmpty
                    ? null
                    : () => setState(() => _pickedLetters.clear()),
                icon: const Icon(Icons.restart_alt),
                label: const Text(
                  'Reset',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoxFace extends StatelessWidget {
  const _FoxFace();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.pets,
          size: 96,
          color: Color(0xFFF39B43),
        ),
        const SizedBox(height: 6),
        Container(
          width: 120,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7E9),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}