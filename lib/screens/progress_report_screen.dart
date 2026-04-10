import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/game_session.dart';
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

class _ProgressReportScreenState extends State<ProgressReportScreen>
    with SingleTickerProviderStateMixin {
  final ProgressReportService _service = const ProgressReportService();

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _loading = true;
  String? _error;

  List<Map<String, String>> _children = const [];
  String? _selectedChildId;
  String _selectedChildName = 'Child';

  Map<String, dynamic>? _levelProgress;
  List<GameSession> _sessions = const [];

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    _selectedChildId = widget.childId;
    _selectedChildName = widget.childName ?? 'Child';

    _loadScreen();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
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
        await _loadChildData();
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      _entryController.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load progress right now. Please try again.';
      });
    }
  }

  Future<void> _loadChildData() async {
    final childId = _selectedChildId;
    if (childId == null) return;

    final progress = await _service.loadLevelProgress(childId);
    final sessions = await _service.loadRecentSessions(childId);

    if (!mounted) return;
    setState(() {
      _levelProgress = progress;
      _sessions = sessions;
    });
  }

  Future<void> _onChildChanged(String? childId) async {
    if (childId == null) return;

    setState(() {
      _selectedChildId = childId;
      _selectedChildName = _children.firstWhere(
        (child) => child['id'] == childId,
        orElse: () => {'name': 'Child'},
      )['name']!;
      _loading = true;
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
          isChildView ? 'My Game Journey' : 'Progress Report',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadScreen,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    children: [
                      if (!isChildView) _parentChildSelector(),
                      if (_selectedChildId == null)
                        _funEmptyCard(
                          icon: Icons.sentiment_dissatisfied,
                          title: 'No Child Found',
                          message: 'Add a child profile to start tracking progress.',
                        )
                      else ...[
                        _heroProgressCard(isChildView: isChildView),
                        const SizedBox(height: 12),
                        _progressBadgeRow(),
                        const SizedBox(height: 12),
                        _sessionsCard(isChildView: isChildView),
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
              ),
            ),
    );
  }

  Widget _parentChildSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Child',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedChildId,
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

  Widget _heroProgressCard({required bool isChildView}) {
    final currentLevel = (_levelProgress?['currentLevel'] ?? _levelProgress?['levelNumber'] ?? 1)
        .toString();
    final currentGameIndex = _toInt(_levelProgress?['currentGameIndex']);

    final completedRaw = _levelProgress?['completedGames'] ?? _levelProgress?['completedGameIndices'];
    final completedCount = completedRaw is List ? completedRaw.length : 0;

    const totalGames = 3;
    final progressFraction = (completedCount / totalGames).clamp(0.0, 1.0);

    final totalScore = _toInt(_levelProgress?['totalScore']);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
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
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amberAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isChildView
                      ? 'Awesome, $_selectedChildName!'
                      : 'Progress Overview',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isChildView
                ? 'You are on Level $currentLevel and shining bright 🌟'
                : 'Current Level: $currentLevel',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0, end: progressFraction),
            builder: (context, value, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      minHeight: 12,
                      value: value,
                      color: const Color(0xFFFFD54F),
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Completed $completedCount of $totalGames games',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Total Score: $totalScore'),
              _chip('Next Game: ${currentGameIndex + 1}'),
              _chip('Last Update: ${_formatTimestamp(_levelProgress?['updatedAt'])}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressBadgeRow() {
    final unlockedRaw = _levelProgress?['unlockedGames'];
    final unlockedCount = unlockedRaw is List ? unlockedRaw.length : 1;

    final completedRaw = _levelProgress?['completedGames'] ?? _levelProgress?['completedGameIndices'];
    final completedCount = completedRaw is List ? completedRaw.length : 0;

    final totalScore = _toInt(_levelProgress?['totalScore']);

    return Row(
      children: [
        Expanded(child: _statBadge('⭐ Stars', '$totalScore')),
        const SizedBox(width: 10),
        Expanded(child: _statBadge('🔓 Unlocked', '$unlockedCount')),
        const SizedBox(width: 10),
        Expanded(child: _statBadge('✅ Done', '$completedCount')),
      ],
    );
  }

  Widget _sessionsCard({required bool isChildView}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFF4A300)),
              const SizedBox(width: 8),
              Text(
                isChildView ? 'My Play History' : 'Recent Game Sessions',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _sessions.isEmpty
                ? _funEmptyCard(
                    icon: Icons.videogame_asset_outlined,
                    title: 'No Plays Yet',
                    message: isChildView
                        ? 'Play a game and your adventure history will appear here!'
                        : 'No game sessions recorded for this child yet.',
                  )
                : Column(
                    children: _sessions
                        .map(
                          (session) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD9ECFF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.sports_esports,
                                    color: Color(0xFF2F86D6),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.gameTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Level: ${session.levelName}'),
                                      Text('Score: ${session.score}/${session.totalQuestions}'),
                                      Text('Played: ${_formatDate(session.playedAt)}'),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD54F),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${session.score}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 450),
      tween: Tween(begin: 0.9, end: 1),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 7,
              offset: Offset(0, 4),
              color: Color(0x1A000000),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF2F86D6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _funEmptyCard({
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
          Icon(icon, size: 38, color: const Color(0xFFF4A300)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
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

  BoxDecoration _whiteCardDecoration() {
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return _formatDate(value.toDate());
    }
    return 'N/A';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$month-$day $hour:$minute';
  }
}