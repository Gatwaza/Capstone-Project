// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/injection.dart';
import '../../models/session_model.dart';
import '../../services/platform/storage_service.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<SessionModel?>(
      future: getIt<StorageService>().loadSession(sessionId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snap.data;
        if (session == null) {
          return Scaffold(
            body: Center(
              child: Text('Session not found',
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
          );
        }
        return _ResultsContent(session: session);
      },
    );
  }
}

class _ResultsContent extends StatelessWidget {
  const _ResultsContent({required this.session});
  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final duration = session.endedAt.difference(session.startedAt);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Row(
                children: [
                  Text('Session Results',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.textSecondary,
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDateTime(session.startedAt),
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 32),

              // ── Quality score ────────────────────────────────
              _ScoreCard(score: session.qualityScore),

              const SizedBox(height: 24),

              // ── Metric grid ──────────────────────────────────
              Text('Session Metrics',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _MetricTile(
                    label: 'COMPRESSIONS',
                    value: '${session.totalCompressions}',
                  ),
                  _MetricTile(
                    label: 'DURATION',
                    value: _formatDuration(duration),
                  ),
                  _MetricTile(
                    label: 'MEAN RATE',
                    value: '${session.meanBpm.round()} bpm',
                    valueColor: _bpmColor(session.meanBpm),
                  ),
                  _MetricTile(
                    label: 'MEAN DEPTH',
                    value: '${session.meanDepthCm.toStringAsFixed(1)} cm',
                    valueColor: _depthColor(session.meanDepthCm),
                  ),
                  _MetricTile(
                    label: 'CPR FRACTION',
                    value: '${(session.cprFraction * 100).round()}%',
                  ),
                  _MetricTile(
                    label: 'AI MODEL',
                    value: session.modelWasAvailable ? 'Active' : 'Demo mode',
                    valueColor: session.modelWasAvailable
                        ? AppTheme.accent
                        : AppTheme.accentAmber,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Actions ──────────────────────────────────────
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.training),
                child: const Text('Practice Again'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(
                  'Back to Home',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),

              const SizedBox(height: 24),

              // ── Disclaimer ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Medical Disclaimer: Novice is a training simulation tool only. '
                  'It does not replace formal CPR certification or professional '
                  'medical advice. Always call emergency services first.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bpmColor(double bpm) {
    if (bpm < 100 || bpm > 120) return AppTheme.accentWarn;
    return AppTheme.accent;
  }

  Color _depthColor(double cm) {
    if (cm < 5.0 || cm > 6.0) return AppTheme.accentWarn;
    return AppTheme.accent;
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppTheme.accent
        : score >= 60
            ? AppTheme.accentAmber
            : AppTheme.accentWarn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quality Score',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(
                score >= 80
                    ? 'Excellent technique'
                    : score >= 60
                        ? 'Good — keep practising'
                        : 'Needs improvement',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontSize: 9)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
