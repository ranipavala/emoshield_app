import 'package:flutter/material.dart';

import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'animal_guess_game_screen.dart';
import 'child_home_screen.dart';

class ShapeMatchGameScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ShapeMatchGameScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ShapeMatchGameScreen> createState() => _ShapeMatchGameScreenState();
}

class _ShapeMatchGameScreenState extends State<ShapeMatchGameScreen> {
  final _progressService = const GameProgressService();

  static const String _correctAnswer = 'Triangle';
  static const List<String> _options = ['Circle', 'Star', 'Triangle', 'Square'];

  String? _selectedAnswer;
  bool _isSaving = false;

  bool get _hasAnswered => _selectedAnswer != null;

  Future<void> _finishGame() async {
    if (!_hasAnswered || _isSaving) return;

    setState(() => _isSaving = true);

    final score = _selectedAnswer == _correctAnswer ? 1 : 0;

    await _progressService.saveGameResult(
      childId: widget.childId,
      gameIndex: 0,
      gameKey: 'shape_match',
      selectedAnswer: _selectedAnswer!,
      correctAnswer: _correctAnswer,
      score: score,
      gameTitle: 'Shape Match Game',
      totalQuestions: 1,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AnimalGuessGameScreen(
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
      question: 'Which name matches this shape?',
      helperText: 'Tap one option, then press Finish.',
      onBackPressed: _goHome,
      onFinishPressed: _finishGame,
      finishEnabled: _hasAnswered && !_isSaving,
      child: Column(
        children: [
          Container(
            width: 170,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  offset: Offset(0, 6),
                  color: Color(0x22000000),
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(80, 72),
                painter: _TrianglePainter(const Color(0xFF8FE4E3)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = _options[index];
                final isSelected = _selectedAnswer == option;

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  elevation: 4,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => _selectedAnswer = option),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2F86D6) : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (isSelected)
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