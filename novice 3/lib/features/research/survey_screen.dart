// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// SurveyScreen — post-session surveys for pilot study analysis.
//
// Presents three instruments in sequence:
//   1. Self-Efficacy (pre-filled if pre-session survey already done)
//   2. System Usability Scale (SUS) — 10 items, Likert 1–5
//   3. NASA Task Load Index — 6 subscales, 0–100 sliders
//
// Per §1.4: "self-efficacy change" and "cognitive load" are primary outcomes.
// Per §1.4: "SUS ≥ 68" is the usability target.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/di/injection.dart';
import '../../models/research_models.dart';
import '../../services/research_logger.dart';
import '../../core/router/app_router.dart';

enum SurveyType { preSession, postSession }

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({
    super.key,
    required this.sessionId,
    required this.type,
  });
  final String sessionId;
  final SurveyType type;

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _step = 0;         // 0=self-efficacy, 1=SUS, 2=NASA-TLX, 3=done

  // Self-efficacy responses (1–7)
  final Map<String, int> _efficacy = {
    'confidence': 4, 'rate': 4, 'depth': 4, 'willingness': 4,
  };

  // SUS responses (1–5), 10 items
  final List<int> _sus = List.filled(10, 3);

  // NASA-TLX sliders (0–100)
  final Map<String, double> _nasa = {
    'mental': 50, 'physical': 50, 'temporal': 50,
    'performance': 50, 'effort': 50, 'frustration': 50,
  };

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    // Pre-session: only self-efficacy
    final steps = widget.type == SurveyType.preSession
        ? [_buildEfficacyStep()]
        : [_buildEfficacyStep(), _buildSusStep(), _buildNasaStep()];

    if (_step >= steps.length) return _buildDoneStep();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(widget.type == SurveyType.preSession
            ? 'Pre-Session Survey' : 'Post-Session Survey'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / (steps.length + 1),
            backgroundColor: AppTheme.border,
            color: AppTheme.accent,
            minHeight: 4,
          ),
        ),
      ),
      body: steps[_step],
    );
  }

  // ── Self-Efficacy ─────────────────────────────────────────

  Widget _buildEfficacyStep() {
    final questions = [
      ('confidence',   'I am confident I could perform CPR effectively in an emergency.'),
      ('rate',         'I believe my compressions would be at the correct rate (100–120 bpm).'),
      ('depth',        'I believe my compressions would be at the correct depth (5–6 cm).'),
      ('willingness',  'I would attempt CPR on a stranger if I witnessed cardiac arrest.'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'Self-Efficacy',
            'Rate your agreement with each statement.\n1 = Strongly disagree · 7 = Strongly agree',
          ),
          const SizedBox(height: 20),
          ...questions.map((q) => _likert7(
            key: q.$1,
            question: q.$2,
            value: _efficacy[q.$1]!,
            onChanged: (v) => setState(() => _efficacy[q.$1] = v),
          )),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveEfficacyAndAdvance,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ── SUS ───────────────────────────────────────────────────

  Widget _buildSusStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'System Usability Scale',
            'Rate your experience with the Novice app.\n1 = Strongly disagree · 5 = Strongly agree',
          ),
          const SizedBox(height: 16),
          ...List.generate(10, (i) => _likert5(
            index: i + 1,
            question: SusItems.questions[i],
            value: _sus[i],
            onChanged: (v) => setState(() => _sus[i] = v),
          )),
          const SizedBox(height: 8),
          Text(
            'Computed SUS score: ${SusItems.compute(_sus).toStringAsFixed(1)} / 100\n'
            '(Target: ≥ 68 — "acceptable usability")',
            style: TextStyle(
              color: SusItems.compute(_sus) >= 68
                  ? AppTheme.accent : AppTheme.accentWarn,
              fontSize: 12,
              fontFamily: 'Courier New',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSusAndAdvance,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // ── NASA-TLX ──────────────────────────────────────────────

  Widget _buildNasaStep() {
    final dimensions = [
      ('mental',       'Mental Demand',
       'How much mental and perceptual activity was required?'),
      ('physical',     'Physical Demand',
       'How much physical activity was required?'),
      ('temporal',     'Temporal Demand',
       'How much time pressure did you feel?'),
      ('performance',  'Performance',
       'How successful were you? (0 = perfect · 100 = complete failure)'),
      ('effort',       'Effort',
       'How hard did you work to achieve your level of performance?'),
      ('frustration',  'Frustration',
       'How irritated, stressed, or annoyed did you feel?'),
    ];

    final rawScore = _nasa.values.reduce((a, b) => a + b) / 6;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            'NASA Task Load Index',
            'Rate the demands of this task.\n0 = Very low · 100 = Very high',
          ),
          const SizedBox(height: 20),
          ...dimensions.map((d) => _nasaSlider(
            key: d.$1,
            title: d.$2,
            description: d.$3,
            value: _nasa[d.$1]!,
            onChanged: (v) => setState(() => _nasa[d.$1] = v),
          )),
          const SizedBox(height: 8),
          Text(
            'Raw NASA-TLX score: ${rawScore.toStringAsFixed(1)} / 100\n'
            '(Target: ≤ 40 — "low cognitive load")',
            style: TextStyle(
              color: rawScore <= 40 ? AppTheme.accent : AppTheme.accentWarn,
              fontSize: 12,
              fontFamily: 'Courier New',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveNasaAndFinish,
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Submit Surveys'),
          ),
        ],
      ),
    );
  }

  // ── Done ──────────────────────────────────────────────────

  Widget _buildDoneStep() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 64),
              const SizedBox(height: 20),
              Text('Surveys Complete',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                widget.type == SurveyType.preSession
                    ? 'Pre-session survey saved. You may now start the training session.'
                    : 'All surveys saved. Thank you for participating.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => widget.type == SurveyType.preSession
                    ? context.go(AppRoutes.training)
                    : context.go(AppRoutes.home),
                child: Text(widget.type == SurveyType.preSession
                    ? 'Start Training Session'
                    : 'Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save actions ──────────────────────────────────────────

  Future<void> _saveEfficacyAndAdvance() async {
    await getIt<ResearchLogger>().saveSelfEfficacySurvey(
      SelfEfficacySurvey(
        sessionId:       widget.sessionId,
        isPostSession:   widget.type == SurveyType.postSession,
        confidence:      _efficacy['confidence']!,
        rateConfidence:  _efficacy['rate']!,
        depthConfidence: _efficacy['depth']!,
        willingnessToAct: _efficacy['willingness']!,
      ),
    );
    setState(() => _step++);
  }

  Future<void> _saveSusAndAdvance() async {
    await getIt<ResearchLogger>().saveSusSurvey(
      SusSurvey(
        sessionId:   widget.sessionId,
        completedAt: DateTime.now(),
        responses:   _sus,
      ),
    );
    setState(() => _step++);
  }

  Future<void> _saveNasaAndFinish() async {
    setState(() => _saving = true);
    await getIt<ResearchLogger>().saveNasaTlxSurvey(
      NasaTlxSurvey(
        sessionId:      widget.sessionId,
        completedAt:    DateTime.now(),
        mentalDemand:   _nasa['mental']!,
        physicalDemand: _nasa['physical']!,
        temporalDemand: _nasa['temporal']!,
        performance:    _nasa['performance']!,
        effort:         _nasa['effort']!,
        frustration:    _nasa['frustration']!,
      ),
    );
    setState(() { _saving = false; _step++; });
  }

  // ── Widget helpers ────────────────────────────────────────

  Widget _stepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _likert7({
    required String key,
    required String question,
    required int value,
    required void Function(int) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(height: 1.4)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final v = i + 1;
              return GestureDetector(
                onTap: () => onChanged(v),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: value == v
                      ? AppTheme.accent : AppTheme.surface,
                  child: Text('$v',
                    style: TextStyle(
                      fontSize: 12,
                      color: value == v ? Colors.black : AppTheme.textSecondary,
                      fontWeight: value == v ? FontWeight.w700 : FontWeight.w400,
                    )),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Strongly\ndisagree', style: _scaleLabel(), textAlign: TextAlign.left),
              Text('Strongly\nagree',    style: _scaleLabel(), textAlign: TextAlign.right),
            ],
          ),
        ],
      ),
    );
  }

  Widget _likert5({
    required int index,
    required String question,
    required int value,
    required void Function(int) onChanged,
  }) {
    final isNegative = index.isEven;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('$index.', style: TextStyle(
              color: isNegative ? AppTheme.accentWarn : AppTheme.accent,
              fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(width: 6),
            Expanded(child: Text(question,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4))),
          ]),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final v = i + 1;
              return GestureDetector(
                onTap: () => onChanged(v),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: value == v ? AppTheme.accent : AppTheme.surface,
                  child: Text('$v', style: TextStyle(
                    fontSize: 13,
                    color: value == v ? Colors.black : AppTheme.textSecondary,
                    fontWeight: value == v ? FontWeight.w700 : FontWeight.w400,
                  )),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _nasaSlider({
    required String key,
    required String title,
    required String description,
    required double value,
    required void Function(double) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text('${value.round()}',
              style: TextStyle(
                color: AppTheme.accent,
                fontFamily: 'Courier New',
                fontWeight: FontWeight.w700,
              )),
          ]),
          const SizedBox(height: 4),
          Text(description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
          Slider(
            value: value,
            min: 0, max: 100, divisions: 20,
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.border,
            onChanged: onChanged,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Very low', style: _scaleLabel()),
            Text('Very high', style: _scaleLabel()),
          ]),
        ],
      ),
    );
  }

  TextStyle _scaleLabel() => TextStyle(
    color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 0.5,
  );
}
