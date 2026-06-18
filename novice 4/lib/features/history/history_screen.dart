// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/session_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(sessionHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Session History'),
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading history: $e',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      color: AppTheme.textSecondary, size: 48),
                  const SizedBox(height: 16),
                  Text('No sessions yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Complete a training session to see your results here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = sessions[i];
              return GestureDetector(
                onTap: () => context.push('/results/${s.id}'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _scoreColor(s.qualityScore).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${s.qualityScore}',
                            style: TextStyle(
                              color: _scoreColor(s.qualityScore),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${s.totalCompressions} compressions · ${s.meanBpm.round()} bpm',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(s.startedAt),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            // NEW: Per-task mini breakdown
                            if (s.taskAccuracies.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _TaskMiniRow(taskAccuracies: s.taskAccuracies),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.accent;
    if (score >= 60) return AppTheme.accentAmber;
    return AppTheme.accentWarn;
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Per-task mini row for history list ──────────────────────────────────────

class _TaskMiniRow extends StatelessWidget {
  const _TaskMiniRow({required this.taskAccuracies});
  final Map<String, double> taskAccuracies;

  @override
  Widget build(BuildContext context) {
    final rate = ((taskAccuracies['rate'] ?? 0.0) * 100).round();
    final depth = ((taskAccuracies['depth'] ?? 0.0) * 100).round();
    final recoil = ((taskAccuracies['recoil'] ?? 0.0) * 100).round();

    return Row(
      children: [
        _MiniTaskChip(label: 'Rate', value: rate),
        const SizedBox(width: 6),
        _MiniTaskChip(label: 'Depth', value: depth),
        const SizedBox(width: 6),
        _MiniTaskChip(label: 'Recoil', value: recoil),
      ],
    );
  }
}

class _MiniTaskChip extends StatelessWidget {
  const _MiniTaskChip({required this.label, required this.value});
  final String label;
  final int value;

  Color _getColor() {
    if (value >= 80) return AppTheme.accent;
    if (value >= 60) return AppTheme.accentAmber;
    return AppTheme.accentWarn;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value%',
        style: TextStyle(
          color: _getColor(),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
