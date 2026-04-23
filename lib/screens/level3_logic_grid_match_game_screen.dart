import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'level3_sequence_builder_game_screen.dart';

class Level3LogicGridMatchGameScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const Level3LogicGridMatchGameScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<Level3LogicGridMatchGameScreen> createState() =>
      _Level3LogicGridMatchGameScreenState();
}

class _Level3LogicGridMatchGameScreenState
    extends State<Level3LogicGridMatchGameScreen> {
  final _progressService = const GameProgressService();

  int? _selectedOption;
  bool _isSaving = false;

  static const String _correctLabel = 'Blue square 4';

  Future<void> _finishGame() async {
    if (_selectedOption == null || _isSaving) return;

    setState(() => _isSaving = true);

    final selectedLabel = _options[_selectedOption!].label;
    final score = selectedLabel == _correctLabel ? 1 : 0;

    await _progressService.saveGameResult(
      childId: widget.childId,
      levelNumber: 3,
      gameIndex: 0,
      gameKey: 'logic_grid_match',
      selectedAnswer: selectedLabel,
      correctAnswer: _correctLabel,
      score: score,
      gameTitle: 'Logic Grid Match Game',
      totalQuestions: 1,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Level3SequenceBuilderGameScreen(
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
      question: 'Logic Grid Match Game',
      helperText:
          'Find the missing tile using the pattern: shape stays square, number increases 1→2→3→4, and color alternates Red/Blue.',
      onBackPressed: () => Navigator.pop(context),
      onFinishPressed: _finishGame,
      finishEnabled: _selectedOption != null && !_isSaving,
      finishLabel: _isSaving ? 'Saving...' : 'Finish',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logic row',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F86D6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF7FB8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _GridTile(label: 'Red square 1', color: Color(0xFFE85A75), number: 1),
                _GridTile(label: 'Blue square 2', color: Color(0xFF2F86D6), number: 2),
                _GridTile(label: 'Red square 3', color: Color(0xFFE85A75), number: 3),
                _QuestionGridTile(),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Choose the missing tile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F86D6),
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

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _selectedOption = index),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF2F86D6)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Row(
                        children: [
                          _GridTile(
                            label: option.label,
                            color: option.color,
                            number: option.number,
                            small: true,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle, color: Color(0xFF2F86D6)),
                        ],
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

class _LogicOption {
  final String label;
  final Color color;
  final int number;

  const _LogicOption({
    required this.label,
    required this.color,
    required this.number,
  });
}

const _options = <_LogicOption>[
  _LogicOption(
    label: 'Blue square 4',
    color: Color(0xFF2F86D6),
    number: 4,
  ),
  _LogicOption(
    label: 'Red square 4',
    color: Color(0xFFE85A75),
    number: 4,
  ),
  _LogicOption(
    label: 'Blue square 3',
    color: Color(0xFF2F86D6),
    number: 3,
  ),
  _LogicOption(
    label: 'Blue circle 4',
    color: Color(0xFF2F86D6),
    number: 4,
  ),
];

class _GridTile extends StatelessWidget {
  final String label;
  final Color color;
  final int number;
  final bool small;

  const _GridTile({
    required this.label,
    required this.color,
    required this.number,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final boxSize = small ? 46.0 : 56.0;
    final fontSize = small ? 14.0 : 18.0;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: small ? 22 : 26,
            height: small ? 22 : 26,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 4,
            child: Text(
              '$number',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: fontSize,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionGridTile extends StatelessWidget {
  const _QuestionGridTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F86D6), width: 2),
      ),
      alignment: Alignment.center,
      child: const Text(
        '?',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Color(0xFF2F86D6),
        ),
      ),
    );
  }
}