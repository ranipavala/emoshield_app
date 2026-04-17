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
  State<Level2MemorySequenceGameScreen> createState() =>
      _Level2MemorySequenceGameScreenState();
}

class _Level2MemorySequenceGameScreenState
    extends State<Level2MemorySequenceGameScreen> {
  final _progressService = const GameProgressService();

  static const List<_ShapeToken> _targetSequence = [
    _ShapeToken(
      label: 'Red Circle',
      color: Color(0xFFE85A75),
      shape: _ShapeType.circle,
    ),
    _ShapeToken(
      label: 'Blue Square',
      color: Color(0xFF2F86D6),
      shape: _ShapeType.square,
    ),
    _ShapeToken(
      label: 'Yellow Triangle',
      color: Color(0xFFF5A000),
      shape: _ShapeType.triangle,
    ),
  ];

  static const List<_ShapeToken> _inputChoices = [
    _ShapeToken(
      label: 'Red Circle',
      color: Color(0xFFE85A75),
      shape: _ShapeType.circle,
    ),
    _ShapeToken(
      label: 'Blue Square',
      color: Color(0xFF2F86D6),
      shape: _ShapeType.square,
    ),
    _ShapeToken(
      label: 'Yellow Triangle',
      color: Color(0xFFF5A000),
      shape: _ShapeType.triangle,
    ),
    _ShapeToken(
      label: 'Green Diamond',
      color: Color(0xFF44AA73),
      shape: _ShapeType.diamond,
    ),
  ];

  final List<_ShapeToken> _picked = [];
  bool _isSaving = false;

  bool get _canFinish => _picked.length == _targetSequence.length && !_isSaving;

  Future<void> _finishGame() async {
    if (!_canFinish) return;

    setState(() => _isSaving = true);

    final selectedAnswer = _picked.map((e) => e.label).join(' -> ');
    final correctAnswer = _targetSequence.map((e) => e.label).join(' -> ');
    final score = selectedAnswer == correctAnswer ? 1 : 0;

    await _progressService.saveGameResult(
      childId: widget.childId,
      levelNumber: 2,
      gameIndex: 0,
      gameKey: 'memory_sequence',
      selectedAnswer: selectedAnswer,
      correctAnswer: correctAnswer,
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

  void _addPick(_ShapeToken token) {
    if (_picked.length >= _targetSequence.length) return;
    setState(() => _picked.add(token));
  }

  void _clearAnswer() {
    setState(() => _picked.clear());
  }

  @override
  Widget build(BuildContext context) {
    return GameLevelScaffold(
      levelLabel: 'Level 2',
      question: 'Memory Sequence Game',
      helperText:
          'Look at the shown sequence. Tap the same sequence back in the exact order, then press Finish.',
      onBackPressed: () => Navigator.pop(context),
      onFinishPressed: _finishGame,
      finishEnabled: _canFinish,
      finishLabel: _isSaving ? 'Saving...' : 'Finish',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target sequence',
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
            children: _targetSequence
                .map((token) => _ShapeCard(token: token, size: 72, showLabel: true))
                .toList(),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tap your answer sequence',
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
            children: _inputChoices
                .map(
                  (token) => GestureDetector(
                    onTap: _isSaving ? null : () => _addPick(token),
                    child: _ShapeCard(
                      token: token,
                      size: 68,
                      showLabel: true,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your tapped sequence',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (_picked.isEmpty)
                  const Text(
                    'No answers tapped yet.',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black54),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _picked
                        .map((token) => _ShapeCard(token: token, size: 58, showLabel: false))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _picked.isEmpty || _isSaving ? null : _clearAnswer,
              icon: const Icon(Icons.refresh),
              label: const Text('Clear Answer'),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ShapeType { circle, square, triangle, diamond }

class _ShapeToken {
  final String label;
  final Color color;
  final _ShapeType shape;

  const _ShapeToken({
    required this.label,
    required this.color,
    required this.shape,
  });
}

class _ShapeCard extends StatelessWidget {
  final _ShapeToken token;
  final double size;
  final bool showLabel;

  const _ShapeCard({
    required this.token,
    required this.size,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: showLabel ? size + 30 : size,
      padding: EdgeInsets.all(showLabel ? 8 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Center(
              child: _ShapeView(
                color: token.color,
                shape: token.shape,
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 6),
            Text(
              token.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShapeView extends StatelessWidget {
  final Color color;
  final _ShapeType shape;

  const _ShapeView({
    required this.color,
    required this.shape,
  });

  @override
  Widget build(BuildContext context) {
    switch (shape) {
      case _ShapeType.circle:
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      case _ShapeType.square:
        return Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      case _ShapeType.triangle:
        return CustomPaint(
          size: const Size(36, 32),
          painter: _TrianglePainter(color),
        );
      case _ShapeType.diamond:
        return Transform.rotate(
          angle: 0.785398, // 45 degrees
          child: Container(
            width: 28,
            height: 28,
            color: color,
          ),
        );
    }
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