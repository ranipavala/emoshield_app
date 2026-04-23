import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'level3_smart_analogy_challenge_screen.dart';

class Level3SequenceBuilderGameScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const Level3SequenceBuilderGameScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<Level3SequenceBuilderGameScreen> createState() =>
      _Level3SequenceBuilderGameScreenState();
}

class _Level3SequenceBuilderGameScreenState
    extends State<Level3SequenceBuilderGameScreen> {
  final _progressService = const GameProgressService();

  static const List<String> _correctOrder = [
    'Morning',
    'Afternoon',
    'Night',
  ];

  static const List<String> _choices = [
    'Night',
    'Morning',
    'Afternoon',
    'Evening',
  ];

  final List<String> _builtSequence = [];
  bool _isSaving = false;

  bool get _canFinish => _builtSequence.length == _correctOrder.length && !_isSaving;

  void _addChoice(String value) {
    if (_builtSequence.length >= _correctOrder.length) return;
    setState(() => _builtSequence.add(value));
  }

  void _clearSequence() {
    setState(() => _builtSequence.clear());
  }

  Future<void> _finishGame() async {
    if (!_canFinish) return;

    setState(() => _isSaving = true);

    final selectedAnswer = _builtSequence.join(' -> ');
    final correctAnswer = _correctOrder.join(' -> ');
    final score = selectedAnswer == correctAnswer ? 1 : 0;

    await _progressService.saveGameResult(
      childId: widget.childId,
      levelNumber: 3,
      gameIndex: 1,
      gameKey: 'sequence_builder',
      selectedAnswer: selectedAnswer,
      correctAnswer: correctAnswer,
      score: score,
      gameTitle: 'Sequence Builder Game',
      totalQuestions: 1,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Level3SmartAnalogyChallengeScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameLevelScaffold(
      levelLabel: 'Level 3',
      question: 'Sequence Builder Game',
      helperText:
          'Build the correct daily order by tapping choices: Morning → Afternoon → Night.',
      onBackPressed: () => Navigator.pop(context),
      onFinishPressed: _finishGame,
      finishEnabled: _canFinish,
      finishLabel: _isSaving ? 'Saving...' : 'Finish',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tap to build your sequence',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F86D6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _choices.map((choice) {
              final used = _builtSequence.contains(choice);

              return GestureDetector(
                onTap: used || _isSaving ? null : () => _addChoice(choice),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: used ? const Color(0xFFE85A75) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    choice,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: used ? Colors.white : const Color(0xFF2F86D6),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your built order',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F86D6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _builtSequence.isEmpty
                ? const Text(
                    'No steps selected yet.',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_builtSequence.length, (index) {
                      final step = _builtSequence[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7ECFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}. $step',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2F86D6),
                          ),
                        ),
                      );
                    }),
                  ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _builtSequence.isEmpty || _isSaving ? null : _clearSequence,
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Answer'),
            ),
          ),
        ],
      ),
    );
  }
}