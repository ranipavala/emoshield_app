import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'level2_visual_logic_completion_game_screen.dart';

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

  static const String _targetCategory = 'Transport';
  static const Set<String> _correctItems = {'Bus', 'Car', 'Train'};

  static const List<_CategoryItem> _items = [
    _CategoryItem(label: 'Bus', emoji: '🚌'),
    _CategoryItem(label: 'Car', emoji: '🚗'),
    _CategoryItem(label: 'Train', emoji: '🚆'),
    _CategoryItem(label: 'Apple', emoji: '🍎'),
    _CategoryItem(label: 'Dog', emoji: '🐶'),
    _CategoryItem(label: 'Pizza', emoji: '🍕'),
    _CategoryItem(label: 'Cat', emoji: '🐱'),
    _CategoryItem(label: 'Banana', emoji: '🍌'),
    _CategoryItem(label: 'Plane', emoji: '✈️'),
  ];

  final Set<String> _selected = <String>{};
  bool _isSaving = false;

  Future<void> _finishGame() async {
    if (_selected.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    final selectedSorted = _selected.toList()..sort();
    final correctSorted = _correctItems.toList()..sort();

    final selectedAnswer = selectedSorted.join(', ');
    final correctAnswer = correctSorted.join(', ');

    final score = _selected.length == _correctItems.length &&
            _selected.containsAll(_correctItems)
        ? 1
        : 0;

    await _progressService.saveGameResult(
      childId: widget.childId,
      levelNumber: 2,
      gameIndex: 1,
      gameKey: 'category_sorting',
      selectedAnswer: selectedAnswer,
      correctAnswer: correctAnswer,
      score: score,
      gameTitle: 'Category Sorting Game',
      totalQuestions: 1,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Level2VisualLogicCompletionGameScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
  }

  void _toggleSelection(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameLevelScaffold(
      levelLabel: 'Level 2',
      question: 'Category Sorting Game',
      helperText:
          'Select all items that belong to the shown category, then press Finish.',
      onBackPressed: () => Navigator.pop(context),
      onFinishPressed: _finishGame,
      finishEnabled: _selected.isNotEmpty && !_isSaving,
      finishLabel: _isSaving ? 'Saving...' : 'Finish',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Target category:',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2F86D6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF44AA73),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  _targetCategory,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              itemCount: _items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final item = _items[index];
                final selected = _selected.contains(item.label);

                return GestureDetector(
                  onTap: _isSaving ? null : () => _toggleSelection(item.label),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF2F86D6)
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 6,
                          offset: Offset(0, 3),
                          color: Color(0x14000000),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2F86D6),
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${_selected.isEmpty ? 'None' : _selected.join(', ')}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final String emoji;

  const _CategoryItem({
    required this.label,
    required this.emoji,
  });
}