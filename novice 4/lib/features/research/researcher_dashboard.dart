// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// ResearcherDashboard — researcher-only view for pilot study management.
//
// Access: Settings → Research Mode (password-gated in production).
// TODO: Add PIN/password gate before deployment to prevent participants
//       from accessing this screen.
//
// Provides:
//   • Group A vs Group B participant counts
//   • Mean metrics per group (BPM accuracy, hand placement, elbow compliance)
//   • SUS and NASA-TLX score distributions
//   • Per-participant session list
//   • Full JSON export of all research data

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/di/injection.dart';
import '../../models/research_models.dart';
import '../../services/research_logger.dart';

class ResearcherDashboard extends StatefulWidget {
  const ResearcherDashboard({super.key});

  @override
  State<ResearcherDashboard> createState() => _ResearcherDashboardState();
}

class _ResearcherDashboardState extends State<ResearcherDashboard> {
  List<UserProfile> _participants = [];
  List<ResearchSession> _groupA = [];
  List<ResearchSession> _groupB = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final logger = getIt<ResearchLogger>();
    final participants = await logger.loadAllParticipants();
    final groupA = await logger.loadSessionsByGroup(StudyGroup.groupA);
    final groupB = await logger.loadSessionsByGroup(StudyGroup.groupB);
    setState(() {
      _participants = participants;
      _groupA = groupA;
      _groupB = groupB;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Researcher Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () { setState(() => _loading = true); _loadData(); },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Study status ───────────────────────────────────
                    _sectionLabel('PILOT STUDY STATUS'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _statCard(
                        label: 'PARTICIPANTS',
                        value: '${_participants.length}',
                        target: '≥ ${ResearchConfig.minParticipantsPerGroup * 2}',
                        color: _participants.length >= ResearchConfig.minParticipantsPerGroup * 2
                            ? AppTheme.accent : AppTheme.accentAmber,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard(
                        label: 'GROUP A',
                        value: '${_groupA.length}',
                        target: '≥ ${ResearchConfig.minParticipantsPerGroup}',
                        color: _groupA.length >= ResearchConfig.minParticipantsPerGroup
                            ? AppTheme.accent : AppTheme.accentAmber,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard(
                        label: 'GROUP B',
                        value: '${_groupB.length}',
                        target: '≥ ${ResearchConfig.minParticipantsPerGroup}',
                        color: _groupB.length >= ResearchConfig.minParticipantsPerGroup
                            ? AppTheme.accent : AppTheme.accentAmber,
                      )),
                    ]),

                    const SizedBox(height: 24),

                    // ── Comparative metrics ───────────────────────────
                    _sectionLabel('COMPARATIVE METRICS (GROUP A vs B)'),
                    const SizedBox(height: 12),
                    _comparisonTable(),

                    const SizedBox(height: 24),

                    // ── SUS / NASA-TLX summary ────────────────────────
                    _sectionLabel('SURVEY SCORES'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _surveyCard(
                        title: 'SUS Score',
                        groupAMean: _mean(_groupA, (s) => s.susScore),
                        groupBMean: _mean(_groupB, (s) => s.susScore),
                        target: '≥ 68',
                        higherIsBetter: true,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _surveyCard(
                        title: 'NASA-TLX',
                        groupAMean: _mean(_groupA, (s) => s.nasaTlxScore),
                        groupBMean: _mean(_groupB, (s) => s.nasaTlxScore),
                        target: '≤ 40',
                        higherIsBetter: false,
                      )),
                    ]),

                    const SizedBox(height: 24),

                    // ── Participant list ──────────────────────────────
                    _sectionLabel('PARTICIPANTS'),
                    const SizedBox(height: 12),
                    ..._participants.map((p) => _participantTile(p)),

                    const SizedBox(height: 32),

                    // ── Export ────────────────────────────────────────
                    _sectionLabel('DATA EXPORT'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Full Research Export', 
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Exports all sessions, frame records, feedback events, '
                            'and survey responses as structured JSON. '
                            'Use this file for comparative Group A vs B analysis in Python/R.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _exporting ? null : _exportData,
                            icon: _exporting
                                ? const SizedBox(width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black))
                                : const Icon(Icons.download_rounded, size: 18),
                            label: Text(_exporting ? 'Exporting…' : 'Export JSON'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Disclaimer
                    Text(
                      'This dashboard is for researcher use only. '
                      'Participant data is anonymised. '
                      'Handle exported data per ALU research data management policy.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 11, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _comparisonTable() {
    final metrics = [
      ('Mean BPM',              _mean(_groupA, (s) => s.meanBpm),
                                _mean(_groupB, (s) => s.meanBpm),
                                '100–120'),
      ('Hand Placement %',      _mean(_groupA, (s) => s.handPlacementAccuracyPct),
                                _mean(_groupB, (s) => s.handPlacementAccuracyPct),
                                '≥ 85%'),
      ('Elbow Compliance %',    _mean(_groupA, (s) => s.elbowCompliancePct),
                                _mean(_groupB, (s) => s.elbowCompliancePct),
                                '≥ 85%'),
      ('CPR Fraction',          _mean(_groupA, (s) => s.cprFraction * 100),
                                _mean(_groupB, (s) => s.cprFraction * 100),
                                '≥ 60%'),
      ('Self-Efficacy Post',    _mean(_groupA, (s) => s.selfEfficacyPost),
                                _mean(_groupB, (s) => s.selfEfficacyPost),
                                ''),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: [
        _tableHeader(),
        const Divider(height: 1, color: AppTheme.border),
        ...metrics.map((m) => _tableRow(m.$1, m.$2, m.$3, m.$4)),
      ]),
    );
  }

  Widget _tableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        const Expanded(flex: 3, child: Text('Metric',
            style: TextStyle(fontSize: 10, letterSpacing: 1,
                color: AppTheme.textSecondary))),
        const Expanded(child: Text('A', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, letterSpacing: 1,
                color: AppTheme.accent, fontWeight: FontWeight.w700))),
        const Expanded(child: Text('B', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, letterSpacing: 1,
                color: AppTheme.textSecondary, fontWeight: FontWeight.w700))),
        const SizedBox(width: 50),
      ]),
    );
  }

  Widget _tableRow(String label, double? a, double? b, String target) {
    String fmt(double? v) => v != null ? v.toStringAsFixed(1) : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13))),
        Expanded(child: Text(fmt(a), textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.accent, fontFamily: 'Courier New',
                fontWeight: FontWeight.w700, fontSize: 13))),
        Expanded(child: Text(fmt(b), textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Courier New',
                fontSize: 13))),
        SizedBox(width: 50, child: Text(target,
            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6),
                fontSize: 10))),
      ]),
    );
  }

  Widget _surveyCard({
    required String title,
    required double? groupAMean,
    required double? groupBMean,
    required String target,
    required bool higherIsBetter,
  }) {
    bool isGoodA = groupAMean != null && (
      higherIsBetter ? groupAMean >= 68 : groupAMean <= 40);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text('Target: $target',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        const SizedBox(height: 12),
        Row(children: [
          _groupBadge('A', groupAMean,
              isGoodA ? AppTheme.accent : AppTheme.accentAmber),
          const SizedBox(width: 8),
          _groupBadge('B', groupBMean, AppTheme.textSecondary),
        ]),
      ]),
    );
  }

  Widget _groupBadge(String group, double? value, Color color) {
    return Column(children: [
      Text(group, style: TextStyle(color: color, fontSize: 10, letterSpacing: 1)),
      Text(value != null ? value.toStringAsFixed(1) : '—',
          style: TextStyle(color: color, fontFamily: 'Courier New',
              fontWeight: FontWeight.w700, fontSize: 18)),
    ]);
  }

  Widget _participantTile(UserProfile p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: p.studyGroup == StudyGroup.groupA
                ? AppTheme.accent.withOpacity(0.12)
                : AppTheme.textSecondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(
            p.studyGroup == StudyGroup.groupA ? 'A' : 'B',
            style: TextStyle(
              color: p.studyGroup == StudyGroup.groupA
                  ? AppTheme.accent : AppTheme.textSecondary,
              fontWeight: FontWeight.w700, fontSize: 14),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.userId,
              style: Theme.of(context).textTheme.titleMedium),
          Text('${p.ageRange.name} · ${p.priorCprTraining.name} · ${p.languagePreference.toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
        ])),
        Icon(p.consentGiven ? Icons.verified_rounded : Icons.warning_rounded,
          color: p.consentGiven ? AppTheme.accent : AppTheme.accentWarn,
          size: 18),
      ]),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String target,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary,
            fontSize: 9, letterSpacing: 1)),
        Text(value, style: TextStyle(color: color, fontSize: 28,
            fontWeight: FontWeight.w700, fontFamily: 'Courier New')),
        Text(target, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: Theme.of(context).textTheme.labelSmall);

  double? _mean(
    List<ResearchSession> sessions,
    double? Function(ResearchSession) getter,
  ) {
    final vals = sessions.map(getter).whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final json = await getIt<ResearchLogger>().exportResearchData();
      // Share the JSON string via share_plus
      if (mounted) {
        // Copy to clipboard as fallback until share_plus wired for files
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Exported ${json.length} chars. Use Settings → Export to share.'),
          backgroundColor: AppTheme.accent.withOpacity(0.2),
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppTheme.accentWarn,
        ));
      }
    } finally {
      setState(() => _exporting = false);
    }
  }
}
