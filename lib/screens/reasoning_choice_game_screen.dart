import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';

class ReasoningChoiceGameScreen extends StatefulWidget {
  final String childId;
  final String childName;
  final int levelNumber;
  final int gameIndex;
  final String gameKey;
  final String gameTitle;
  final String question;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final Widget nextRoute;

  const ReasoningChoiceGameScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.levelNumber,
    required this.gameIndex,
    required this.gameKey,
    required this.gameTitle,
    required this.question,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.nextRoute,
  });

  @override
  State<ReasoningChoiceGameScreen> createState() => _ReasoningChoiceGameScreenState();
}

class _ReasoningChoiceGameScreenState extends State<ReasoningChoiceGameScreen> {
  final _service = const GameProgressService();
  String? _selected;
  bool _saving = false;

  Future<void> _finish() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);

    final score = _selected == widget.correctAnswer ? 1 : 0;

    await _service.saveGameResult(
      childId: widget.childId,
      levelNumber: widget.levelNumber,
      gameIndex: widget.gameIndex,
      gameKey: widget.gameKey,
      selectedAnswer: _selected!,
      correctAnswer: widget.correctAnswer,
      score: score,
      gameTitle: widget.gameTitle,
      totalQuestions: 1,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => widget.nextRoute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameLevelScaffold(
      question: widget.question,
      helperText: widget.prompt,
      onBackPressed: () => Navigator.pop(context),
      onFinishPressed: _finish,
      finishEnabled: _selected != null && !_saving,
      child: Column(
        children: widget.options.map((option) {
          final selected = _selected == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => _selected = option),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? const Color(0xFF2F86D6) : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Text(
                  option,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}