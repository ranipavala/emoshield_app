import 'package:flutter/material.dart';

import '../models/emotional_report.dart';
import '../services/reporting_service.dart';

class EmotionalReportScreen extends StatefulWidget {
  const EmotionalReportScreen({super.key});

  @override
  State<EmotionalReportScreen> createState() => _EmotionalReportScreenState();
}

class _EmotionalReportScreenState extends State<EmotionalReportScreen> {
  final ReportingService _reportingService = const ReportingService();

  List<Map<String, String>> _children = const [];
  String? _selectedChildId;
  DateTime _selectedDate = DateTime.now();
  EmotionalReport? _report;

  bool _loadingChildren = true;
  bool _loadingReport = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _loadingChildren = true;
      _error = null;
    });

    try {
      final children = await _reportingService.fetchChildren();
      if (!mounted) return;

      setState(() {
        _children = children;
        _selectedChildId = children.isNotEmpty ? children.first['id'] : null;
      });

      if (_selectedChildId != null) {
        await _loadReport();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load children. Please try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingChildren = false;
      });
    }
  }

  Future<void> _loadReport() async {
    final childId = _selectedChildId;
    if (childId == null) return;

    setState(() {
      _loadingReport = true;
      _error = null;
    });

    try {
      final report = await _reportingService.fetchEmotionalReportForDate(
        childId: childId,
        selectedDate: _selectedDate,
      );

      if (!mounted) return;
      setState(() {
        _report = report;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load emotional report for this date.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingReport = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _selectedDate,
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
    await _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7ECFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7ECFF),
        elevation: 0,
        title: const Text(
          'Emotional Report',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900),
        ),
      ),
      body: _loadingChildren
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_children.isEmpty)
                    _InfoCard(
                      child: _emptyText(
                        'No child profiles found.\nPlease add child profiles first.',
                      ),
                    )
                  else ...[
                    _InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select child',
                            style: TextStyle(fontWeight: FontWeight.w800),
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
                            onChanged: (value) async {
                              if (value == null) return;
                              setState(() {
                                _selectedChildId = value;
                              });
                              await _loadReport();
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Select date',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(_formatDate(_selectedDate)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingReport)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      Expanded(
                        child: _ReportCard(
                          report: _report,
                          selectedDate: _selectedDate,
                        ),
                      ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
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

  Widget _emptyText(String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _ReportCard extends StatelessWidget {
  final EmotionalReport? report;
  final DateTime selectedDate;

  const _ReportCard({required this.report, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return _InfoCard(
        child: Center(
          child: Text(
            'No emotional report found for ${_formatDate(selectedDate)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return _InfoCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emotion Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            _metricRow('Happy', report!.happyPercent),
            _metricRow('Sad', report!.sadPercent),
            _metricRow('Angry', report!.angryPercent),
            _metricRow('Neutral', report!.neutralPercent),
            _metricRow('Surprise', report!.surprisePercent),
            const Divider(height: 28),
            Text(
              'Major Emotion: ${report!.majorEmotion}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F86D6),
              ),
            ),
            if (report!.sessionId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Session ID: ${report!.sessionId}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label Percent',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$value%',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 6),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: child,
    );
  }
}