import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'level2_category_sorting_game_screen.dart';

class Level2MemorySequenceGameScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const Level2MemorySequenceGameScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<Level2MemorySequenceGameScreen> createState() => _Level2MemorySequenceGameScreenState();
}

class _Level2MemorySequenceGameScreenState extends State<Level2MemorySequenceGameScreen> {
  final _service = const GameProgressService();
  final List<String> _target = const ['🔴', '🟡', '🔵'];
  final List<String> _picked = [];
  bool _saving = false;

  Future<void> _finish() async {
    if (_picked.length != _target.length || _saving) return;
    setState(() => _saving = true);

    final selected = _picked.join('-');
    final correct = _target.join('-');
    final score = selected == correct ? 1 : 0;

    await _service.saveGameResult(
      childId: widget.childId,
      levelNumber: 2,
      gameIndex: 0,
      gameKey: 'memory_sequence',
      selectedAnswer: selected,
      correctAnswer: correct,
      score: score,
      gameTitle: 'Memory Sequence Game',
      totalQuestions: 1,
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Level2CategorySortingGameScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameLevelScaffold(
      question: 'Remember and repeat the sequence',
      helperText: 'Sequence: 🔴 🟡 🔵   → tap in same order',
      onBackPressed: () => Navigator.pop(context),
      onFinishPressed: _finish,
      finishEnabled: _picked.length == _target.length && !_saving,
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            children: ['🔴', '🟡', '🔵', '🟢'].map((e) {
              return GestureDetector(
                onTap: () {
                  if (_picked.length >= _target.length) return;
                  setState(() => _picked.add(e));
                },
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(e, style: const TextStyle(fontSize: 30)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Text(
            _picked.join('  '),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _picked.isEmpty ? null : () => setState(() => _picked.clear()),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}