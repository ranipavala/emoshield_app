import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'child_home_screen.dart';
import 'level_result_screen.dart';

class PatternRecognitionGameScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const PatternRecognitionGameScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<PatternRecognitionGameScreen> createState() =>
      _PatternRecognitionGameScreenState();
}

class _PatternRecognitionGameScreenState
    extends State<PatternRecognitionGameScreen> {
  final _progressService = const GameProgressService();

  int? _selectedOption;
  bool _isSaving = false;

  Future<void> _finishGame() async {
    if (_selectedOption == null || _isSaving) return;

    setState(() => _isSaving = true);

    final selectedLabel = _patternOptions[_selectedOption!].label;
    const correctLabel = 'Pink circle';
    final score = selectedLabel == correctLabel ? 1 : 0;

    await _progressService.saveGameResult(
      childId: widget.childId,
      gameIndex: 2,
      gameKey: 'pattern_recognition',
      selectedAnswer: selectedLabel,
      correctAnswer: correctLabel,
      score: score,
      gameTitle: 'Pattern Recognition Game',
      totalQuestions: 1,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelResultScreen(
          childId: widget.childId,
          childName: widget.childName,
          levelNumber: 1,
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
      question: 'Choose the correct pattern to complete the row.',
      helperText: 'Look at colors and shapes.',
      onBackPressed: _goHome,
      onFinishPressed: _finishGame,
      finishEnabled: _selectedOption != null && !_isSaving,
      child: Column(
        children: [
          const Text(
            '🔴 🔵 🔴 ?',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: _patternOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = _patternOptions[index];
                final isSelected = _selectedOption == index;

                return InkWell(
                  onTap: () => setState(() => _selectedOption = index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2F86D6)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Text(
                      option.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternOption {
  final String label;
  const _PatternOption(this.label);
}

const _patternOptions = <_PatternOption>[
  _PatternOption('Blue square'),
  _PatternOption('Pink circle'),
  _PatternOption('Yellow triangle'),
];