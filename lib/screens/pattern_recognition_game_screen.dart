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
    if (_selectedOption == null || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);

    final selectedLabel = _selectedOption == null ? '' : _patternOptions[_selectedOption!].label;
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

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelResultScreen(
          childId: widget.childId,
          childName: widget.childName,
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
      helperText: 'Look at the colors and shapes, then tap the best answer.',
      onBackPressed: _goHome,
      onFinishPressed: _finishGame,
      finishEnabled: _selectedOption != null && !_isSaving,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF7FB8F0),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _PatternTile(
                  background: Color(0xFFFCE4EC),
                  shape: _PatternShape.circle,
                  shapeColor: Color(0xFFE85A75),
                ),
                _PatternTile(
                  background: Color(0xFFE5F1FF),
                  shape: _PatternShape.square,
                  shapeColor: Color(0xFF2F86D6),
                ),
                _PatternTile(
                  background: Color(0xFFFCE4EC),
                  shape: _PatternShape.circle,
                  shapeColor: Color(0xFFE85A75),
                ),
                _PatternTile(
                  background: Color(0xFFE5F1FF),
                  shape: _PatternShape.square,
                  shapeColor: Color(0xFF2F86D6),
                ),
                _QuestionTile(),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Answer choices',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F86D6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final option = _patternOptions[index];
                final isSelected = _selectedOption == index;

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => setState(() => _selectedOption = index),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2F86D6)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Row(
                        children: [
                          _PatternTile(
                            background: option.background,
                            shape: option.shape,
                            shapeColor: option.shapeColor,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option.label,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isSelected)
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

class _PatternTile extends StatelessWidget {
  final Color background;
  final _PatternShape shape;
  final Color shapeColor;

  const _PatternTile({
    required this.background,
    required this.shape,
    required this.shapeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: switch (shape) {
          _PatternShape.circle => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: shapeColor,
                shape: BoxShape.circle,
              ),
            ),
          _PatternShape.square => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: shapeColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          _PatternShape.triangle => CustomPaint(
              size: const Size(26, 24),
              painter: _TrianglePainter(shapeColor),
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
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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

enum _PatternShape { circle, square, triangle }

class _PatternOption {
  final String label;
  final Color background;
  final _PatternShape shape;
  final Color shapeColor;

  const _PatternOption({
    required this.label,
    required this.background,
    required this.shape,
    required this.shapeColor,
  });
}

const _patternOptions = <_PatternOption>[
  _PatternOption(
    label: 'Blue square',
    background: Color(0xFFE5F1FF),
    shape: _PatternShape.square,
    shapeColor: Color(0xFF2F86D6),
  ),
  _PatternOption(
    label: 'Pink circle',
    background: Color(0xFFFCE4EC),
    shape: _PatternShape.circle,
    shapeColor: Color(0xFFE85A75),
  ),
  _PatternOption(
    label: 'Yellow triangle',
    background: Color(0xFFFFF3D4),
    shape: _PatternShape.triangle,
    shapeColor: Color(0xFFF5A000),
  ),
];

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