import 'package:flutter/material.dart';

import '../services/progress_report_service.dart';

class ProgressReportScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  final bool isChildView;

  const ProgressReportScreen({
    super.key,
    this.childId,
    this.childName,
    this.isChildView = false,
  });

  @override
  State<ProgressReportScreen> createState() => _ProgressReportScreenState();
}

class _ProgressReportScreenState extends State<ProgressReportScreen> {
  final ProgressReportService _service = const ProgressReportService();

  bool _loading = true;
  String? _error;

  List<Map<String, String>> _children = const [];
  String? _selectedChildId;
  String _selectedChildName = 'Child';

  ChildProgressBundle? _bundle;
  final Set<int> _expandedLevels = <int>{};

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
    _selectedChildName = widget.childName ?? 'Child';
    _loadScreen();
  }

  Future<void> _loadScreen() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_selectedChildId == null) {
        final children = await _service.fetchChildren();
        _children = children;

        if (_children.isNotEmpty) {
          _selectedChildId = _children.first['id'];
          _selectedChildName = _children.first['name'] ?? 'Child';
        }
      }

      if (_selectedChildId != null) {
        final bundle = await _service.loadChildProgressBundle(_selectedChildId!);
        if (!mounted) return;
        setState(() {
          _bundle = bundle;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _bundle = null;
        });
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load progress right now. Please try again.';
      });
    }
  }

  Future<void> _onChildChanged(String? childId) async {
    if (childId == null) return;

    setState(() {
      _selectedChildId = childId;
      _selectedChildName = _children.firstWhere(
        (child) => child['id'] == childId,
        orElse: () => {'name': 'Child'},
      )['name']!;
    });

    await _loadScreen();
  }

  @override
  Widget build(BuildContext context) {
    final isChildView = widget.isChildView;

    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7ECFF),
        elevation: 0,
        title: Text(
          isChildView ? 'My Progress Adventure' : 'Progress Report',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadScreen,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  if (!isChildView) _parentChildSelector(),
                  if (_selectedChildId == null)
                    _emptyCard(
                      icon: Icons.child_care,
                      title: 'No Child Found',
                      message: 'Add a child profile to see progress data.',
                    )
                  else ...[
                    _summaryCard(isChildView: isChildView),
                    const SizedBox(height: 12),
                    _levelsSection(isChildView: isChildView),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _parentChildSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Child',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedChildId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _children
                .map(
                  (child) => DropdownMenuItem<String>(
                    value: child['id'],
                    child: Text(child['name'] ?? 'Child'),
                  ),
                )
                .toList(),
            onChanged: _onChildChanged,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({required bool isChildView}) {
    final bundle = _bundle;
    if (bundle == null) {
      return _emptyCard(
        icon: Icons.info_outline,
        title: 'No Progress Yet',
        message: isChildView
            ? 'Play your first game to start your learning journey!'
            : 'No progress records available yet.',
      );
    }

    final subtitle = isChildView
        ? 'Great job, $_selectedChildName! Keep going! 🌟'
        : 'Performance summary for $_selectedChildName';

    final progressFraction = bundle.totalLevels == 0
        ? 0.0
        : (bundle.completedLevels / bundle.totalLevels).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D5FEF), Color(0xFF2F86D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 7),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isChildView ? 'Your Level Journey' : 'Level Performance',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: progressFraction,
              color: const Color(0xFFFFD54F),
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Completed Levels: ${bundle.completedLevels}/${bundle.totalLevels}'),
              _chip('Total Score: ${bundle.totalScore}'),
              _chip('Current Level: ${bundle.currentLevel}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _levelsSection({required bool isChildView}) {
    final bundle = _bundle;
    if (bundle == null || bundle.levels.isEmpty) {
      return _emptyCard(
        icon: Icons.videogame_asset_outlined,
        title: 'No Level Data',
        message: isChildView
            ? 'Play games to unlock your report cards!'
            : 'No level progress docs found for this child.',
      );
    }

    return Column(
      children: bundle.levels.map((level) {
        final isExpanded = _expandedLevels.contains(level.levelNumber);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: _whiteCard(),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedLevels.remove(level.levelNumber);
                    } else {
                      _expandedLevels.add(level.levelNumber);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFE8EEFF),
                            child: Text(
                              '${level.levelNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2F86D6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Level ${level.levelNumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          _statusBadge(level.status),
                          const SizedBox(width: 6),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: const Color(0xFF2F86D6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // MAIN numeric indicator (kept): Score only.
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Score: ${level.score}/${level.totalGames}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          _supportBadge(_supportLabel(level)),
                        ],
                      ),

                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: level.totalGames == 0
                              ? 0
                              : (level.completedCount / level.totalGames).clamp(0.0, 1.0),
                          color: _statusColor(level.status),
                          backgroundColor: const Color(0xFFE7ECF6),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isExpanded ? Icons.visibility : Icons.touch_app,
                            size: 16,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isExpanded ? 'Reviewing games below' : 'Tap to review games',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _gameReviewPanel(
                    isChildView: isChildView,
                    games: level.gameReviews,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _supportLabel(LevelReviewData level) {
    if (level.status == LevelStatus.locked) return 'Not Started';
    if (level.status == LevelStatus.inProgress) {
      if (level.completedCount == 0) return 'Ready to Continue';
      return 'In Progress';
    }

    // Completed
    final ratio = level.totalGames == 0 ? 0 : level.score / level.totalGames;
    if (ratio >= 1.0) return 'Perfect Score';
    if (ratio >= 0.67) return 'Great Job';
    return 'Needs Practice';
  }

  Widget _supportBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF2F86D6),
        ),
      ),
    );
  }

  Widget _gameReviewPanel({
    required bool isChildView,
    required List<GameReviewItem> games,
  }) {
    if (games.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          isChildView
              ? 'No games played in this level yet. You can do it! 💪'
              : 'No game review data for this level yet.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: games.map((game) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6ECFA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  game.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: game.isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.gameTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isChildView
                            ? 'Your answer: ${game.selectedAnswer}'
                            : 'Selected answer: ${game.selectedAnswer}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (!game.isCorrect)
                        Text(
                          isChildView
                              ? 'Correct answer: ${game.correctAnswer} 💡'
                              : 'Correct answer: ${game.correctAnswer}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2F86D6),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: game.isCorrect
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    game.isCorrect ? 'Correct' : 'Try Again',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: game.isCorrect
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusBadge(LevelStatus status) {
    String text;
    switch (status) {
      case LevelStatus.completed:
        text = 'Completed';
        break;
      case LevelStatus.inProgress:
        text = 'In Progress';
        break;
      case LevelStatus.locked:
        text = 'Locked';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Color _statusColor(LevelStatus status) {
    switch (status) {
      case LevelStatus.completed:
        return const Color(0xFF2E7D32);
      case LevelStatus.inProgress:
        return const Color(0xFF2F86D6);
      case LevelStatus.locked:
        return const Color(0xFF8E8E93);
    }
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xFFF4A300)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF8A4D00),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A4D00),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _whiteCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          blurRadius: 10,
          offset: Offset(0, 6),
          color: Color(0x22000000),
        ),
      ],
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}