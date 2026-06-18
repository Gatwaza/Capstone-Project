// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ResultsContent extends StatefulWidget {
  const _ResultsContent({required this.session});
  final SessionModel session;

  @override
  State<_ResultsContent> createState() => _ResultsContentState();
}

class _ResultsContentState extends State<_ResultsContent> {
  String? _selectedLabel;
  final _noteController = TextEditingController();
  bool _labelSaved = false;
  bool _exporting  = false;

  @override
  void initState() {
    super.initState();
    _selectedLabel       = widget.session.reviewLabel;
    _noteController.text = widget.session.reviewNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveLabel() async {
    if (_selectedLabel == null) return;
    await getIt<StorageService>().labelSession(
      widget.session.id,
      label: _selectedLabel!,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    setState(() => _labelSaved = true);
  }

  Future<void> _exportFrames() async {
    setState(() => _exporting = true);
    try {
      final ndjson = await getIt<StorageService>().exportFramesNdjson();
      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: ndjson));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Frame data copied to clipboard')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration =
        widget.session.endedAt.difference(widget.session.startedAt);

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
              const SizedBox(height: 4),
              Text(
                _formatDateTime(widget.session.startedAt),
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 28),

              // ── Quality score ────────────────────────────────
              _ScoreCard(score: widget.session.qualityScore),

              const SizedBox(height: 24),

              // ── Metric grid ──────────────────────────────────
              Text('Session Metrics',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 12),

              // FIX: Replace GridView with a manual 2-column layout using
              // intrinsic-height rows. GridView.count with a fixed
              // childAspectRatio clips content on smaller/web viewports,
              // rendering the cards as solid black boxes when text overflows.
              _MetricGrid(
                tiles: [
                  _MetricTile(
                    label: 'COMPRESSIONS',
                    value: '${widget.session.totalCompressions}',
                  ),
                  _MetricTile(
                    label: 'DURATION',
                    value: _formatDuration(duration),
                  ),
                  _MetricTile(
                    label: 'MEAN RATE',
                    value: '${widget.session.meanBpm.round()} bpm',
                    valueColor: _bpmColor(widget.session.meanBpm),
                  ),
                  _MetricTile(
                    label: 'MEAN DEPTH',
                    value:
                        '${widget.session.meanDepthCm.toStringAsFixed(1)} cm',
                    valueColor: _depthColor(widget.session.meanDepthCm),
                  ),
                  _MetricTile(
                    label: 'CPR FRACTION',
                    value:
                        '${(widget.session.cprFraction * 100).round()}%',
                  ),
                  _MetricTile(
                    label: 'AI MODEL',
                    value: widget.session.modelWasAvailable
                        ? 'CNN-BiLSTM'
                        : 'Rule-based',
                    valueColor: widget.session.modelWasAvailable
                        ? AppTheme.accent
                        : AppTheme.accentAmber,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Researcher review panel ──────────────────────
              if (widget.session.rawFrames.isNotEmpty ||
                  widget.session.reviewLabel != null) ...[
                _ReviewPanel(
                  frameCount:     widget.session.rawFrames.length,
                  selectedLabel:  _selectedLabel,
                  noteController: _noteController,
                  labelSaved:     _labelSaved,
                  exporting:      _exporting,
                  onLabelChanged: (v) => setState(() {
                    _selectedLabel = v;
                    _labelSaved    = false;
                  }),
                  onSave:         _saveLabel,
                  onExport:       _exportFrames,
                ),
                const SizedBox(height: 24),
              ],

              // ── Actions ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.training),
                  child: const Text('Practice Again'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: Text(
                    'Back to Home',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
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

              const SizedBox(height: 16),
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
      '${dt.day}/${dt.month}/${dt.year}  '
      '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }
}

// ── 2-column grid that sizes rows by content, not a fixed aspect ratio ─────────

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.tiles});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    // Pair tiles into rows of 2
    final rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += 2) {
      final left  = tiles[i];
      final right = i + 1 < tiles.length ? tiles[i + 1] : const SizedBox();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              Expanded(child: right),
            ],
          ),
        ),
      );
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

// ── Review panel ───────────────────────────────────────────────────────────────

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.frameCount,
    required this.selectedLabel,
    required this.noteController,
    required this.labelSaved,
    required this.exporting,
    required this.onLabelChanged,
    required this.onSave,
    required this.onExport,
  });

  final int frameCount;
  final String? selectedLabel;
  final TextEditingController noteController;
  final bool labelSaved;
  final bool exporting;
  final ValueChanged<String?> onLabelChanged;
  final VoidCallback onSave;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined,
                  size: 16, color: AppTheme.accentAmber),
              const SizedBox(width: 8),
              Text(
                'Researcher Review',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.accentAmber,
                    ),
              ),
              const Spacer(),
              if (frameCount > 0)
                Text(
                  '$frameCount frames',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 14),

          Text('Quality label',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['correct', 'partial', 'incorrect'].map((label) {
              final selected = selectedLabel == label;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => onLabelChanged(label),
                selectedColor: AppTheme.accent.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selected
                      ? AppTheme.accent
                      : AppTheme.textSecondary,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: noteController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Reviewer note (optional)',
              hintStyle: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.border),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: selectedLabel != null ? onSave : null,
                  icon: Icon(
                    labelSaved
                        ? Icons.check_rounded
                        : Icons.save_outlined,
                    size: 16,
                  ),
                  label: Text(labelSaved ? 'Saved' : 'Save label'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      frameCount > 0 && !exporting ? onExport : null,
                  icon: exporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined, size: 16),
                  label:
                      Text(exporting ? 'Exporting…' : 'Export frames'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Score card ─────────────────────────────────────────────────────────────────

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quality Score',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }
}

// ── Metric tile ────────────────────────────────────────────────────────────────

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      // No fixed height — sized by IntrinsicHeight in _MetricGrid
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontSize: 9, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}