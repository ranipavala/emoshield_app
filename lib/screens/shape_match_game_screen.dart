import 'package:flutter/material.dart';

import '../services/game_emotion_session_service.dart';
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
  final _emotionSessionService = GameEmotionSessionService();

  static const String _correctAnswer = 'Triangle';
  static const List<String> _options = ['Circle', 'Star', 'Triangle', 'Square'];

  String? _selectedAnswer;
  bool _isSaving = false;
  bool _sessionFinalized = false;
  String? _emotionNotice;
  String? _cameraPrompt;

  bool get _hasAnswered => _selectedAnswer != null;

  @override
  void initState() {
    super.initState();
    _emotionSessionService.facePromptNotifier.addListener(_onFacePromptChanged);
    _startEmotionSession();
  }

  void _onFacePromptChanged() {
    if (!mounted) return;
    setState(() => _cameraPrompt = _emotionSessionService.facePromptNotifier.value);
  }

  Future<void> _startEmotionSession() async {
    final result = await _emotionSessionService.startSession(
      childId: widget.childId,
      levelNumber: 1,
      gameId: 'shape_match',
      gameTitle: 'Shape Match Game',
    );

    if (!mounted || result.warning == null) return;
    setState(() => _emotionNotice = result.warning);
  }

  Future<void> _finishGame() async {
    if (!_hasAnswered || _isSaving) return;

    setState(() => _isSaving = true);

    final score = _selectedAnswer == _correctAnswer ? 1 : 0;
    final sessionId = _emotionSessionService.sessionId;

    await _emotionSessionService.completeSession(
      score: score,
      totalQuestions: 1,
    );
    _sessionFinalized = true;

    await _progressService.saveGameResult(
      childId: widget.childId,
      levelNumber: 1,
      gameIndex: 0,
      gameKey: 'shape_match',
      selectedAnswer: _selectedAnswer!,
      correctAnswer: _correctAnswer,
      score: score,
      gameTitle: 'Shape Match Game',
      totalQuestions: 1,
      recordSession: false,
      sessionId: sessionId,
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

  Future<void> _goHome() async {
    if (!_sessionFinalized) {
      await _emotionSessionService.abandonSession();
      _sessionFinalized = true;
    }

    if (!mounted) return;
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


  String _buildHelperText(String base) {
    final parts = <String>[base];
    if (_emotionNotice != null && _emotionNotice!.isNotEmpty) {
      parts.add(_emotionNotice!);
    }
    if (_cameraPrompt != null && _cameraPrompt!.isNotEmpty) {
      parts.add(_cameraPrompt!);
    }
    return parts.join('\n');
  }

  @override
  void dispose() {
    if (!_sessionFinalized) {
      _emotionSessionService.abandonSession();
    }
    _emotionSessionService.facePromptNotifier.removeListener(_onFacePromptChanged);
    _emotionSessionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _goHome();
        return false;
      },
      child: GameLevelScaffold(
        question: 'Which name matches this shape?',
        helperText: _buildHelperText('Tap one option, then press Finish.'),
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