import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'level_result_screen.dart';

class Level3SmartAnalogyChallengeScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const Level3SmartAnalogyChallengeScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<Level3SmartAnalogyChallengeScreen> createState() =>
      _Level3SmartAnalogyChallengeScreenState();
}

class _Level3SmartAnalogyChallengeScreenState
    extends State<Level3SmartAnalogyChallengeScreen> {
  final _progressService = const GameProgressService();

  int? _selectedOption;
  bool _isSaving = false;

  static const String _question = 'Bird : Sky = Fish : ?';
  static const String _correctAnswer = 'Ocean';

  static const List<_AnalogyOption> _options = [
    _AnalogyOption(
      label: 'Ocean',
      emoji: '🌊',
      color: Color(0xFF6C7CFF),
    ),
    _AnalogyOption(
      label: 'Tree',
      emoji: '🌳',
      color: Color(0xFF44AA73),
    ),
    _AnalogyOption(
      label: 'Nest',
      emoji: '🪺',
      color: Color(0xFFF5A000),
    ),
    _AnalogyOption(
      label: 'Cave',
      emoji: '🪨',
      color: Color(0xFFE85A75),
    ),
  ];

  Future<void> _finishGame() async {
    if (_selectedOption == null || _isSaving) return;

    setState(() => _isSaving = true);

    final selectedLabel = _options[_selectedOption!].label;
    final score = selectedLabel == _correctAnswer ? 1 : 0;

    await _progressService.saveGameResult(
      childId: widget.childId,
      levelNumber: 3,
      gameIndex: 2,
      gameKey: 'smart_analogy',
      selectedAnswer: selectedLabel,
      correctAnswer: _correctAnswer,
      score: score,
      gameTitle: 'Smart Analogy Challenge',
      totalQuestions: 1,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelResultScreen(
          childId: widget.childId,
          childName: widget.childName,
          levelNumber: 3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameLevelScaffold(
      levelLabel: 'Level 3',
      question: 'Smart Analogy Challenge',
      helperText: 'Read the relation carefully and choose the best matching answer.',
      onBackPressed: () => Navigator.pop(context),
      onFinishPressed: _finishGame,
      finishEnabled: _selectedOption != null && !_isSaving,
      finishLabel: _isSaving ? 'Saving...' : 'Finish',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7FB8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Choose one answer',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F86D6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final option = _options[index];
                final selected = _selectedOption == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => setState(() => _selectedOption = index),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: option.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? option.color : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(option.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle, color: option.color),
                      ],
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

class _AnalogyOption {
  final String label;
  final String emoji;
  final Color color;

  const _AnalogyOption({
    required this.label,
    required this.emoji,
    required this.color,
  });
}