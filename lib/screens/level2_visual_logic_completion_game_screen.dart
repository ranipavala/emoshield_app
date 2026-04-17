import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'level_result_screen.dart';

class Level2VisualLogicCompletionGameScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const Level2VisualLogicCompletionGameScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<Level2VisualLogicCompletionGameScreen> createState() =>
      _Level2VisualLogicCompletionGameScreenState();
}

class _Level2VisualLogicCompletionGameScreenState
    extends State<Level2VisualLogicCompletionGameScreen> {
  final _progressService = const GameProgressService();

  int? _selectedOption;
  bool _isSaving = false;

  static const String _correctLabel = 'Red square';

  Future<void> _finishGame() async {
    if (_selectedOption == null || _isSaving) return;

    setState(() => _isSaving = true);

    final selectedLabel = _options[_selectedOption!].label;
    final score = selectedLabel == _correctLabel ? 1 : 0;

    await _progressService.saveGameResult(
      childId: widget.childId,
      levelNumber: 2,
      gameIndex: 2,
      gameKey: 'picture_logic',
      selectedAnswer: selectedLabel,
      correctAnswer: _correctLabel,
      score: score,
      gameTitle: 'Visual Logic Completion Game',
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
      levelLabel: 'Level 2',
      question: 'Visual Logic Completion Game',
      helperText:
          'Look at the sequence. Choose the missing final option that best completes the pattern.',
      onBackPressed: () => Navigator.pop(context),
      onFinishPressed: _finishGame,
      finishEnabled: _selectedOption != null && !_isSaving,
      finishLabel: _isSaving ? 'Saving...' : 'Finish',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF7FB8F0),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _LogicTile(
                  shape: _LogicShape.circle,
                  color: Color(0xFFE85A75),
                ),
                _LogicTile(
                  shape: _LogicShape.square,
                  color: Color(0xFF2F86D6),
                ),
                _LogicTile(
                  shape: _LogicShape.triangle,
                  color: Color(0xFFE85A75),
                ),
                _LogicTile(
                  shape: _LogicShape.circle,
                  color: Color(0xFF2F86D6),
                ),
                _QuestionTile(),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Answer options',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F86D6),
                fontSize: 16,
              ),
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
                          _LogicTile(
                            shape: option.shape,
                            color: option.color,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              option.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF2F86D6),
                            ),
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

enum _LogicShape { circle, square, triangle }

class _LogicOption {
  final String label;
  final _LogicShape shape;
  final Color color;

  const _LogicOption({
    required this.label,
    required this.shape,
    required this.color,
  });
}

const List<_LogicOption> _options = [
  _LogicOption(
    label: 'Red square',
    shape: _LogicShape.square,
    color: Color(0xFFE85A75),
  ),
  _LogicOption(
    label: 'Blue triangle',
    shape: _LogicShape.triangle,
    color: Color(0xFF2F86D6),
  ),
  _LogicOption(
    label: 'Red circle',
    shape: _LogicShape.circle,
    color: Color(0xFFE85A75),
  ),
  _LogicOption(
    label: 'Blue square',
    shape: _LogicShape.square,
    color: Color(0xFF2F86D6),
  ),
];

class _LogicTile extends StatelessWidget {
  final _LogicShape shape;
  final Color color;

  const _LogicTile({
    required this.shape,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: switch (shape) {
          _LogicShape.circle => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          _LogicShape.square => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          _LogicShape.triangle => CustomPaint(
              size: const Size(26, 22),
              painter: _TrianglePainter(color),
            ),
        },
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}