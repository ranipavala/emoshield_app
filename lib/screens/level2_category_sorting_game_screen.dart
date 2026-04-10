import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'reasoning_choice_game_screen.dart';

class Level2CategorySortingGameScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const Level2CategorySortingGameScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<Level2CategorySortingGameScreen> createState() => _Level2CategorySortingGameScreenState();
}

class _Level2CategorySortingGameScreenState extends State<Level2CategorySortingGameScreen> {
  final _service = const GameProgressService();

  String? _selectedCategory;
  bool _saving = false;

  Future<void> _finish() async {
    if (_selectedCategory == null || _saving) return;
    setState(() => _saving = true);

    const correct = 'Fruits';
    final score = _selectedCategory == correct ? 1 : 0;

    await _service.saveGameResult(
      childId: widget.childId,
      levelNumber: 2,
      gameIndex: 1,
      gameKey: 'category_sorting',
      selectedAnswer: _selectedCategory!,
      correctAnswer: correct,
      score: score,
      gameTitle: 'Category Sorting Game',
      totalQuestions: 1,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReasoningChoiceGameScreen(
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
          nextRoute: LevelResultScreen(
            childId: widget.childId,
            childName: widget.childName,
            levelNumber: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameLevelScaffold(
      question: 'Tap the correct category for 🍎',
      helperText: 'Choose one category.',
      onBackPressed: () => Navigator.pop(context),
      onFinishPressed: _finish,
      finishEnabled: _selectedCategory != null && !_saving,
      child: Column(
        children: [
          const Text('🍎', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          ...['Animals', 'Fruits', 'Vehicles', 'Shapes'].map((cat) {
            final selected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? const Color(0xFF2F86D6) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Text(cat, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}