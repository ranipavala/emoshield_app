import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'level_result_screen.dart';

class Level2CategorySortingGameScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const Level2CategorySortingGameScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<Level2CategorySortingGameScreen> createState() =>
      _Level2CategorySortingGameScreenState();
}

class _Level2CategorySortingGameScreenState
    extends State<Level2CategorySortingGameScreen> {
  final _progressService = const GameProgressService();

  String? _selectedCategory;
  bool _isSaving = false;

  Future<void> _finishGame() async {
    if (_selectedCategory == null || _isSaving) return;

    setState(() => _isSaving = true);

    const correctCategory = 'Fruits';
    final score = _selectedCategory == correctCategory ? 1 : 0;

    await _progressService.saveGameResult(
      childId: widget.childId,
      gameIndex: 1,
      gameKey: 'category_sorting',
      selectedAnswer: _selectedCategory!,
      correctAnswer: correctCategory,
      score: score,
      gameTitle: 'Category Sorting Game',
      totalQuestions: 1,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelResultScreen(
          childId: widget.childId,
          childName: widget.childName,
          levelNumber: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameLevelScaffold(
      question: 'Tap the correct category for 🍎',
      helperText: 'Choose the best matching category.',
      onBackPressed: () => Navigator.pop(context),
      onFinishPressed: _finishGame,
      finishEnabled: _selectedCategory != null && !_isSaving,
      child: Column(
        children: [
          const Text('🍎', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 20),
          ...['Animals', 'Fruits', 'Vehicles', 'Shapes'].map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2F86D6)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}