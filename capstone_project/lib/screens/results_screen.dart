import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/di/injection.dart';
import '../core/theme/app_theme.dart';
import '../models/session_model.dart';
import '../services/drive_service.dart';
import '../services/session_logger.dart';
import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String? sessionId;
  const ResultsScreen({super.key, this.sessionId});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreAnim;
  late Animation<double> _scoreVal;
  CprSession? _session;
  List<CprSession> _history = [];
  bool _uploading = false;
  String? _uploadStatus;

  @override
  void initState() {
    super.initState();
    _scoreAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreVal = CurvedAnimation(parent: _scoreAnim, curve: Curves.easeOut);
    _loadData();
  }

  Future<void> _loadData() async {
    final logger = getIt<SessionLogger>();
    final all = await logger.getAllSessions();
    CprSession? latest;
    if (widget.sessionId != null) {
      latest = await logger.getSession(widget.sessionId!);
    }
    latest ??= all.isNotEmpty ? all.first : null;

    if (mounted) {
      setState(() {
        _session = latest;
        _history = all.take(5).toList();
      });
      if (_session != null) {
        _scoreVal = Tween<double>(begin: 0, end: _session!.overallScore)
            .animate(CurvedAnimation(parent: _scoreAnim, curve: Curves.easeOut));
        _scoreAnim.forward();
      }
    }
  }

  Future<void> _uploadToDrive() async {
    if (_session == null) return;
    setState(() { _uploading = true; _uploadStatus = null; });
    final id = await getIt<DriveService>().uploadSession(_session!);
    setState(() {
      _uploading = false;
      _uploadStatus = id != null ? '✓ Uploaded to Google Drive' : '✗ Upload failed';
    });
  }

  @override
  void dispose() {
    _scoreAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Session Results'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          ),
        ),
      ),
      body: _session == null
          ? _buildEmpty()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildScoreCard(),
                  const SizedBox(height: 16),
                  _buildMetricsGrid(),
                  const SizedBox(height: 16),
                  _buildRadarChart(),
                  const SizedBox(height: 16),
                  _buildTimeline(),
                  const SizedBox(height: 16),
                  _buildHistoryChart(),
                  const SizedBox(height: 16),
                  _buildActions(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, color: AppColors.textMuted, size: 64),
          SizedBox(height: 16),
          Text('No sessions yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
          SizedBox(height: 8),
          Text('Complete a training session to see results here.',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    final s = _session!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _scoreColor(s.overallScore).withOpacity(0.3),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _scoreColor(s.overallScore).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(s.scoreGrade,
              style: TextStyle(
                  color: _scoreColor(s.overallScore),
                  fontSize: 13,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _scoreVal,
            builder: (_, __) => Text(
              '${(_scoreVal.value * 100).round()}%',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 72,
                  fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'Overall Score',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            'Session on ${_formatDate(s.startedAt)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final s = _session!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _metricTile('${s.avgBpm?.round() ?? "—"}', 'Avg BPM',
            s.avgBpm != null && s.avgBpm! >= 100 && s.avgBpm! <= 120
                ? AppColors.accentGreen
                : AppColors.accentAmber),
        _metricTile('${s.totalCompressions}', 'Compressions', AppColors.textPrimary),
        _metricTile('${s.durationSeconds}s', 'Duration', AppColors.textPrimary),
        _metricTile(s.language.toUpperCase(), 'Language', AppColors.accentRed),
      ],
    );
  }

  Widget _metricTile(String val, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    final s = _session!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('Performance Breakdown',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _scoreBar('Rate', s.rateAdherenceScore, AppColors.accentGreen),
              _scoreBar('Posture', s.postureScore, AppColors.accentAmber),
              _scoreBar('Overall', s.overallScore, AppColors.accentRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreBar(String label, double value, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 7,
                backgroundColor: color.withOpacity(0.15),
                color: color,
              ),
              Text('${(value * 100).round()}%',
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildTimeline() {
    if (_session!.events.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Feedback Timeline',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._session!.events.take(6).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: e.priority == 1
                            ? AppColors.accentRed
                            : AppColors.accentAmber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppConstants.promptsEn[e.promptKey] ?? e.promptKey,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'f${e.frameIndex}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHistoryChart() {
    if (_history.length < 2) return const SizedBox.shrink();
    final spots = _history.reversed.toList().asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.overallScore * 100))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: LineChart(LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.accentRed,
                  barWidth: 3,
                  dotData: FlDotData(
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.accentRed,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.accentRed.withOpacity(0.1),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (_uploadStatus != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_uploadStatus!,
                style: TextStyle(
                    color: _uploadStatus!.startsWith('✓')
                        ? AppColors.accentGreen
                        : AppColors.accentRed)),
          ),
        ElevatedButton.icon(
          onPressed: _uploading ? null : _uploadToDrive,
          icon: _uploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(_uploading ? 'Uploading...' : 'Save to Google Drive'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (_) => TrainingScreen(lang: _session?.language ?? 'en')),
            (r) => r.isFirst,
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Practice Again'),
        ),
      ],
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.85) return AppColors.accentGreen;
    if (score >= 0.60) return AppColors.accentAmber;
    return AppColors.accentRed;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}
