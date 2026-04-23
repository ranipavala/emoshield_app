import 'package:flutter/material.dart';

import '../services/game_emotion_session_service.dart';
import '../services/game_progress_service.dart';
import '../widgets/game_level_scaffold.dart';
import 'level_result_screen.dart';
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
  State<Level2CategorySortingGameScreen> createState() =>
      _Level2CategorySortingGameScreenState();
}

class _Level2CategorySortingGameScreenState
    extends State<Level2CategorySortingGameScreen> {
  final _progressService = const GameProgressService();
  final _emotionSessionService = GameEmotionSessionService();

  String? _selectedCategory;
  bool _isSaving = false;
  bool _sessionFinalized = false;
  String? _emotionNotice;
  String? _cameraPrompt;

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
      levelNumber: 2,
      gameId: 'category_sorting',
      gameTitle: 'Category Sorting Game',
      minCaptureDuration: const Duration(seconds: 6),
    );

    if (!mounted || result.warning == null) return;
    setState(() => _emotionNotice = result.warning);
  }

  Future<void> _finishGame() async {
    if (_selectedCategory == null || _isSaving) return;

    setState(() => _isSaving = true);

    const correctCategory = 'Fruits';
    final score = _selectedCategory == correctCategory ? 1 : 0;
    final sessionId = _emotionSessionService.sessionId;

    await _emotionSessionService.completeSession(score: score, totalQuestions: 1);
    _sessionFinalized = true;

    await _progressService.saveGameResult(
      childId: widget.childId,
      levelNumber: 2,
      gameIndex: 1,
      gameKey: 'category_sorting',
      selectedAnswer: _selectedCategory!,
      correctAnswer: correctCategory,
      score: score,
      gameTitle: 'Category Sorting Game',
      totalQuestions: 1,
      recordSession: false,
      sessionId: sessionId,
    );

    if (!mounted) return;

    // Continue to the third game in Level 2 (picture_logic) to align with LevelCatalog.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReasoningChoiceGameScreen(
          childId: widget.childId,
          childName: widget.childName,
          levelNumber: 2,
          gameIndex: 2,
          gameKey: 'picture_logic',
          gameTitle: 'Picture Logic Game',
          question: 'Which object best completes this group?',
          prompt: 'Choose the picture that logically belongs with 🍎 🍌 🍇.',
          options: const ['🍓', '🚗', '⚽', '📚'],
          correctAnswer: '🍓',
          nextRoute: LevelResultScreen(
            childId: widget.childId,
            childName: widget.childName,
            levelNumber: 2,
          ),
        ),
      ),
    );
  }

  Future<void> _goBack() async {
    if (!_sessionFinalized) {
      await _emotionSessionService.abandonSession();
      _sessionFinalized = true;
    }

    if (!mounted) return;
    Navigator.pop(context);
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
    const categories = ['Animals', 'Fruits', 'Vehicles', 'Shapes'];

    return WillPopScope(
      onWillPop: () async {
        await _goBack();
        return false;
      },
      child: GameLevelScaffold(
        question: 'Tap the correct category for 🍎',
        helperText: _buildHelperText('Choose the best matching category.'),
        onBackPressed: _goBack,
        onFinishPressed: _finishGame,
        finishEnabled: _selectedCategory != null && !_isSaving,
        child: Column(
          children: [
            const Text('🍎', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            for (final category in categories)
              Padding(
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
                        color: _selectedCategory == category
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
              ),
          ],
        ),
      ),
    );
  }
}