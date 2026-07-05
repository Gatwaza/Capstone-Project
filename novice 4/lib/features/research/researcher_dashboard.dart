// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// ResearcherDashboard — researcher-only view for pilot study management.
//
//   • Uses ResearchLoggerAdapter (works on both web and mobile) rather than
//     getIt<ResearchLogger>() directly.
//   • PIN-gated (default 2026) so participants can't reach this screen.
//   • CSV export (web: triggers browser download; mobile: uses share_plus).
//   • Data-privacy notice per §3.12.3.
//
// Access: Settings → Researcher Dashboard → PIN entry

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/research_models.dart';
import '../../services/research_logger_adapter.dart';

// ── PIN configuration ─────────────────────────────────────────────────────────
// Change this before deployment. Do NOT commit the real PIN to a public repo.
// Compile-time override: flutter build web --dart-define=RESEARCHER_PIN=XXXX
const String _researcherPin =
    String.fromEnvironment('RESEARCHER_PIN', defaultValue: '2026');

class ResearcherDashboard extends StatefulWidget {
  const ResearcherDashboard({super.key});

  @override
  State<ResearcherDashboard> createState() => _ResearcherDashboardState();
}

class _ResearcherDashboardState extends State<ResearcherDashboard> {
  // PIN gate
  bool _pinVerified = false;
  final _pinController = TextEditingController();
  bool _pinError = false;

  // Data
  final _logger = ResearchLoggerAdapter();
  List<UserProfile>    _participants = [];
  List<ResearchSession> _groupA      = [];
  List<ResearchSession> _groupB      = [];
  bool _loading   = true;
  bool _exporting = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  // ── PIN gate UI ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_pinVerified) return _buildPinGate();
    return _buildDashboard();
  }

  Widget _buildPinGate() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Researcher Access'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded,
                    color: AppTheme.accent, size: 34),
              ),
              const SizedBox(height: 24),
              Text('Researcher PIN Required',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'This area is for the principal researcher only.\n'
                'Participants should not access this screen.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'Courier New',
                      fontSize: 22,
                      letterSpacing: 8),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '· · · ·',
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.card,
                    errorText: _pinError ? 'Incorrect PIN' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppTheme.accent, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _verifyPin(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyPin,
                child: const Text('Enter Dashboard'),
              ),
              const SizedBox(height: 24),
              Text(
                'PIN is set via --dart-define=RESEARCHER_PIN at build time.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 10, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyPin() {
    if (_pinController.text.trim() == _researcherPin) {
      setState(() {
        _pinVerified = true;
        _pinError    = false;
      });
      _loadData();
    } else {
      setState(() => _pinError = true);
      _pinController.clear();
    }
  }

  // ── Dashboard ─────────────────────────────────────────────

  Widget _buildDashboard() {
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
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
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
                    _privacyBanner(),
                    const SizedBox(height: 20),

                    // ── Study status ───────────────────────────────────
                    _sectionLabel('PILOT STUDY STATUS'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _statCard(
                        label: 'TOTAL',
                        value: '${_participants.length}',
                        target: '≥ ${ResearchConfig.minParticipantsPerGroup * 2}',
                        color: _participants.length >=
                                ResearchConfig.minParticipantsPerGroup * 2
                            ? AppTheme.accent
                            : AppTheme.accentAmber,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard(
                        label: 'GROUP A',
                        value: '${_groupA.length}',
                        target: '≥ ${ResearchConfig.minParticipantsPerGroup}',
                        color: _groupA.length >=
                                ResearchConfig.minParticipantsPerGroup
                            ? AppTheme.accent
                            : AppTheme.accentAmber,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard(
                        label: 'GROUP B',
                        value: '${_groupB.length}',
                        target: '≥ ${ResearchConfig.minParticipantsPerGroup}',
                        color: _groupB.length >=
                                ResearchConfig.minParticipantsPerGroup
                            ? AppTheme.accent
                            : AppTheme.accentAmber,
                      )),
                    ]),

                    const SizedBox(height: 24),

                    // ── Comparative metrics ───────────────────────────
                    _sectionLabel('COMPARATIVE METRICS (A vs B)'),
                    const SizedBox(height: 12),
                    _comparisonTable(),

                    const SizedBox(height: 24),

                    // ── SUS / NASA-TLX ────────────────────────────────
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

                    // ── Self-efficacy delta ───────────────────────────
                    _sectionLabel('SELF-EFFICACY (PRE vs POST)'),
                    const SizedBox(height: 12),
                    _efficacyRow(),

                    const SizedBox(height: 24),

                    // ── Participant list ──────────────────────────────
                    _sectionLabel('ENROLLED PARTICIPANTS'),
                    const SizedBox(height: 12),
                    if (_participants.isEmpty)
                      _emptyState('No participants enrolled yet.')
                    else
                      ..._participants.map((p) => _participantTile(p)),

                    const SizedBox(height: 32),

                    // ── Export ────────────────────────────────────────
                    _sectionLabel('DATA EXPORT'),
                    const SizedBox(height: 12),
                    _exportCard(),

                    const SizedBox(height: 24),
                    _footerNote(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Data loading ──────────────────────────────────────────

  Future<void> _loadData() async {
    final participants = await _logger.loadAllParticipants();
    final groupA       = await _logger.loadSessionsByGroup(StudyGroup.groupA);
    final groupB       = await _logger.loadSessionsByGroup(StudyGroup.groupB);
    if (mounted) {
      setState(() {
        _participants = participants;
        _groupA       = groupA;
        _groupB       = groupB;
        _loading      = false;
      });
    }
  }

  // ── Privacy banner ────────────────────────────────────────

  Widget _privacyBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data privacy notice — §3.12.3\n'
              'Only body movement metrics (joint angles, compression rate) '
              'are recorded. No video footage is stored or transmitted. '
              'All records are linked to anonymous participant IDs only. '
              'Handle exported files per ALU data management policy.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11, height: 1.5,
                    color: AppTheme.accent.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Comparison table ──────────────────────────────────────

  Widget _comparisonTable() {
    final rows = [
      ('Mean BPM (target 100–120)',    _mean(_groupA, (s) => s.meanBpm),
                                        _mean(_groupB, (s) => s.meanBpm),     '100–120'),
      ('Hand Placement % (≥ 85%)',     _mean(_groupA, (s) => s.handPlacementAccuracyPct),
                                        _mean(_groupB, (s) => s.handPlacementAccuracyPct), '≥ 85%'),
      ('Elbow Compliance % (≥ 85%)',   _mean(_groupA, (s) => s.elbowCompliancePct),
                                        _mean(_groupB, (s) => s.elbowCompliancePct),      '≥ 85%'),
      ('CPR Fraction (≥ 60%)',         _mean(_groupA, (s) => s.cprFraction * 100),
                                        _mean(_groupB, (s) => s.cprFraction * 100),       '≥ 60%'),
      ('Self-Efficacy Post (1–7)',      _mean(_groupA, (s) => s.selfEfficacyPost),
                                        _mean(_groupB, (s) => s.selfEfficacyPost),        'Higher'),
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
        ...rows.map((r) => _tableRow(r.$1, r.$2, r.$3, r.$4)),
      ]),
    );
  }

  Widget _tableHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      const Expanded(flex: 4,
          child: Text('METRIC', style: TextStyle(fontSize: 9,
              letterSpacing: 1, color: AppTheme.textSecondary))),
      const Expanded(child: Text('A', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, letterSpacing: 1,
              color: AppTheme.accent, fontWeight: FontWeight.w700))),
      const Expanded(child: Text('B', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, letterSpacing: 1,
              color: AppTheme.textSecondary, fontWeight: FontWeight.w700))),
      const SizedBox(width: 48),
    ]),
  );

  Widget _tableRow(String label, double? a, double? b, String target) {
    String fmt(double? v) => v != null ? v.toStringAsFixed(1) : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Expanded(flex: 4, child: Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12))),
        Expanded(child: Text(fmt(a), textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.accent,
                fontFamily: 'Courier New', fontWeight: FontWeight.w700, fontSize: 13))),
        Expanded(child: Text(fmt(b), textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary,
                fontFamily: 'Courier New', fontSize: 13))),
        SizedBox(width: 48, child: Text(target, textAlign: TextAlign.right,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9))),
      ]),
    );
  }

  // ── Self-efficacy delta row ───────────────────────────────

  Widget _efficacyRow() {
    double? deltaA, deltaB;
    if (_groupA.isNotEmpty) {
      final pre  = _mean(_groupA, (s) => s.selfEfficacyPre);
      final post = _mean(_groupA, (s) => s.selfEfficacyPost);
      if (pre != null && post != null) deltaA = post - pre;
    }
    if (_groupB.isNotEmpty) {
      final pre  = _mean(_groupB, (s) => s.selfEfficacyPre);
      final post = _mean(_groupB, (s) => s.selfEfficacyPost);
      if (pre != null && post != null) deltaB = post - pre;
    }

    String fmt(double? v) => v != null
        ? '${v >= 0 ? "+" : ""}${v.toStringAsFixed(2)}'
        : '—';

    return Row(children: [
      Expanded(child: _statCard(
        label: 'Δ SELF-EFF (A)',
        value: fmt(deltaA),
        target: 'higher = more confident',
        color: (deltaA ?? 0) > 0 ? AppTheme.accent : AppTheme.accentWarn,
      )),
      const SizedBox(width: 10),
      Expanded(child: _statCard(
        label: 'Δ SELF-EFF (B)',
        value: fmt(deltaB),
        target: 'higher = more confident',
        color: (deltaB ?? 0) > 0 ? AppTheme.accent : AppTheme.accentWarn,
      )),
    ]);
  }

  // ── Survey card ───────────────────────────────────────────

  Widget _surveyCard({
    required String title,
    required double? groupAMean,
    required double? groupBMean,
    required String target,
    required bool higherIsBetter,
  }) {
    bool isGoodA = groupAMean != null &&
        (higherIsBetter ? groupAMean >= 68 : groupAMean <= 40);

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
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10)),
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

  Widget _groupBadge(String group, double? value, Color color) => Column(
    children: [
      Text(group, style: TextStyle(color: color, fontSize: 10, letterSpacing: 1)),
      Text(value != null ? value.toStringAsFixed(1) : '—',
          style: TextStyle(color: color, fontFamily: 'Courier New',
              fontWeight: FontWeight.w700, fontSize: 20)),
    ],
  );

  // ── Participant tile ──────────────────────────────────────

  Widget _participantTile(UserProfile p) {
    final isA = p.studyGroup == StudyGroup.groupA;
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
            color: isA
                ? AppTheme.accent.withOpacity(0.12)
                : AppTheme.textSecondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(isA ? 'A' : 'B',
              style: TextStyle(
                  color: isA ? AppTheme.accent : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700, fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.userId,
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${p.ageRange.name} · ${p.priorCprTraining.name} · '
              '${p.languagePreference.toUpperCase()} · '
              '${p.enrolledAt.toLocal().toString().substring(0, 16)}',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
          ],
        )),
        Icon(p.consentGiven
            ? Icons.verified_rounded : Icons.warning_rounded,
            color: p.consentGiven ? AppTheme.accent : AppTheme.accentWarn,
            size: 18),
      ]),
    );
  }

  // ── Export card ───────────────────────────────────────────

  Widget _exportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Export Research Data',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'CSV includes one row per session with all §3.11.1 metrics. '
            'JSON includes the full hierarchical dataset with feedback events. '
            '${kIsWeb ? "Files download directly in the browser." : "File is shared via the system share sheet."}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(children: [
            // CSV
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exporting ? null : _exportCsv,
                icon: _exporting
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.table_chart_rounded, size: 16),
                label: const Text('Export CSV'),
              ),
            ),
            const SizedBox(width: 10),
            // JSON
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exporting ? null : _exportJson,
                icon: const Icon(Icons.data_object_rounded, size: 16),
                label: const Text('Export JSON'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'Only interaction metrics are exported — no video, no PII.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      await _logger.exportCsv();
      if (mounted && kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('CSV downloaded to your browser downloads folder.'),
          backgroundColor: AppTheme.accent.withOpacity(0.2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('CSV export failed: $e'),
          backgroundColor: AppTheme.accentWarn,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportJson() async {
    setState(() => _exporting = true);
    try {
      final json = await _logger.exportResearchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(kIsWeb
              ? 'JSON downloaded to your browser downloads folder.'
              : 'Exported ${json.length} chars. Share via the system sheet.'),
          backgroundColor: AppTheme.accent.withOpacity(0.2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('JSON export failed: $e'),
          backgroundColor: AppTheme.accentWarn,
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ── Small helpers ─────────────────────────────────────────

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
        Text(label, style: const TextStyle(color: AppTheme.textSecondary,
            fontSize: 9, letterSpacing: 1)),
        Text(value, style: TextStyle(color: color, fontSize: 26,
            fontWeight: FontWeight.w700, fontFamily: 'Courier New')),
        Text(target, style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 9)),
      ]),
    );
  }

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(child: Text(msg,
        style: const TextStyle(color: AppTheme.textSecondary))),
  );

  Widget _sectionLabel(String text) =>
      Text(text, style: Theme.of(context).textTheme.labelSmall);

  Widget _footerNote() => Text(
    'Researcher dashboard — PIN protected.\n'
    'Participant data is anonymised (IDs only).\n'
    'Handle exported files per ALU Research Data Management Policy.\n'
    'Ethical clearance: ALU REC · Declaration of Helsinki compliant.',
    style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontSize: 10, height: 1.6,
            color: AppTheme.textSecondary.withOpacity(0.7)),
  );

  double? _mean(
    List<ResearchSession> sessions,
    double? Function(ResearchSession) getter,
  ) {
    final vals = sessions.map(getter).whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }
}