// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// ConsentScreen — Participant enrolment + informed consent.
//
// FIX (2025-06): replaced direct getIt<ResearchLogger>() with
//   ResearchLoggerAdapter so this screen works on both web and mobile.
//
// Implements §3.12.2:
//   "Written informed consent will be obtained from all participants
//    prior to data collection."
//   "Participant data will be anonymised through assignment of
//    participant ID codes; names will not appear in any research output."

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../models/research_models.dart';
import '../../services/participant_service.dart';
import '../../services/research_logger_adapter.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _logger   = ResearchLoggerAdapter();
  final _participants = getIt<ParticipantService>();

  String          _participantId  = '';
  StudyGroup      _group          = StudyGroup.groupA;
  AgeRange        _ageRange       = AgeRange.age18to24;
  PriorCprTraining _priorTraining = PriorCprTraining.none;
  String          _language       = 'en';
  bool            _consentChecked = false;
  bool            _saving         = false;
  int             _step           = 0; // 0=info, 1=form, 2=done

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Pilot Study — Participant Enrolment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: IndexedStack(
        index: _step,
        children: [
          _buildInfoStep(),
          _buildFormStep(),
          _buildDoneStep(),
        ],
      ),
    );
  }

  // ── Step 0: Participant information sheet ─────────────────

  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('PARTICIPANT INFORMATION SHEET'),
          const SizedBox(height: 16),
          _infoCard(Icons.info_outline_rounded, 'Study Purpose',
            'You are invited to participate in a research study evaluating '
            'the Novice CPR coaching application. The study assesses whether '
            'real-time AI feedback improves CPR technique quality in first-time users.'),
          _infoCard(Icons.videocam_off_outlined, 'What Is — and Is NOT — Recorded',
            'The app uses your device camera to analyse your CPR posture on a '
            'training manikin. Only body movement data (joint angles, compression '
            'rate) is logged as numbers — no video footage is stored or transmitted '
            'at any point. All data is stored locally and anonymised using a '
            'participant ID code. Your name is never recorded.'),
          _infoCard(Icons.schedule_rounded, 'Session Duration',
            'Each session is a maximum of 15 minutes. You will complete brief '
            'surveys before and after the session (approx. 5 min each).'),
          _infoCard(Icons.exit_to_app_rounded, 'Your Rights',
            'Participation is entirely voluntary. You may withdraw at any time '
            'without consequence. Data collected before withdrawal will be deleted '
            'upon request. You are not required to give a reason.'),
          _infoCard(Icons.security_rounded, 'Data Security',
            'Session metrics are stored locally on this research device. '
            'After analysis they will be deleted per ALU data management policy. '
            'Access is restricted to the principal researcher and supervisor.'),
          _infoCard(Icons.medical_services_outlined, 'Medical Disclaimer',
            'This study involves simulated CPR on a manikin ONLY. '
            'You will NOT perform CPR on any person. '
            'Novice is a training aid — not a substitute for certified CPR '
            'training or professional medical advice. '
            'In a real emergency, call official emergency services first.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('I have read and understood this information'),
          ),
          const SizedBox(height: 12),
          Text(
            'Ethical clearance: ALU Research Ethics Committee\n'
            'Declaration of Helsinki compliant.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Consent form ──────────────────────────────────

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('PARTICIPANT DETAILS'),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border)),
              child: Row(
                children: [
                  Icon(Icons.badge_outlined, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your Participant ID will be assigned automatically '
                      'once you confirm enrolment below — you do not need '
                      'to enter one.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _dropdown<StudyGroup>(
              label: 'Study Group (researcher assigns)',
              value: _group,
              items: const [
                DropdownMenuItem(value: StudyGroup.groupA,
                    child: Text('Group A — With AI guidance')),
                DropdownMenuItem(value: StudyGroup.groupB,
                    child: Text('Group B — Control (no AI guidance)')),
              ],
              onChanged: (v) => setState(() => _group = v!),
            ),
            const SizedBox(height: 16),

            _dropdown<AgeRange>(
              label: 'Age Range',
              value: _ageRange,
              items: const [
                DropdownMenuItem(value: AgeRange.under18,    child: Text('Under 18')),
                DropdownMenuItem(value: AgeRange.age18to24,  child: Text('18–24')),
                DropdownMenuItem(value: AgeRange.age25to34,  child: Text('25–34')),
                DropdownMenuItem(value: AgeRange.age35to44,  child: Text('35–44')),
                DropdownMenuItem(value: AgeRange.age45plus,  child: Text('45 or older')),
              ],
              onChanged: (v) => setState(() => _ageRange = v!),
            ),
            const SizedBox(height: 16),

            _dropdown<PriorCprTraining>(
              label: 'Prior CPR Training',
              value: _priorTraining,
              items: const [
                DropdownMenuItem(value: PriorCprTraining.none,
                    child: Text('None — never learned CPR')),
                DropdownMenuItem(value: PriorCprTraining.watched,
                    child: Text('Watched a video or demo only')),
                DropdownMenuItem(value: PriorCprTraining.basic,
                    child: Text('First-aid class (over 1 year ago)')),
                DropdownMenuItem(value: PriorCprTraining.recent,
                    child: Text('Trained within the past 12 months')),
                DropdownMenuItem(value: PriorCprTraining.certified,
                    child: Text('Currently certified in CPR')),
              ],
              onChanged: (v) => setState(() => _priorTraining = v!),
            ),
            const SizedBox(height: 16),

            _dropdown<String>(
              label: 'Preferred Coaching Language',
              value: _language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'rw', child: Text('Kinyarwanda')),
              ],
              onChanged: (v) => setState(() => _language = v!),
            ),
            const SizedBox(height: 24),

            // Consent checkbox
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _consentChecked
                    ? AppTheme.accent.withOpacity(0.07) : AppTheme.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _consentChecked
                      ? AppTheme.accent.withOpacity(0.4) : AppTheme.border,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _consentChecked,
                    activeColor: AppTheme.accent,
                    onChanged: (v) =>
                        setState(() => _consentChecked = v ?? false),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'I confirm I have read and understood the Participant '
                      'Information Sheet. I voluntarily agree to participate. '
                      'I understand I may withdraw at any time. '
                      'I consent to collection and use of anonymised body '
                      'movement data (NOT video) for this research.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(height: 1.5,
                              color: _consentChecked
                                  ? AppTheme.textPrimary
                                  : AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed:
                  _consentChecked && !_saving ? _saveEnrolment : null,
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Text('Confirm & Enrol Participant'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: Text('← Back to information sheet',
                  style:
                      const TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Confirmation ──────────────────────────────────

  Widget _buildDoneStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                shape: BoxShape.circle),
            child:
                Icon(Icons.check_rounded, color: AppTheme.accent, size: 36),
          ),
          const SizedBox(height: 24),
          Text('Participant Enrolled',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'ID: $_participantId · ${_group == StudyGroup.groupA ? "Group A" : "Group B"}',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.accent),
          ),
          const SizedBox(height: 12),
          Text(
            'Consent recorded at '
            '${DateTime.now().toLocal().toString().substring(0, 16)}.\n'
            'The participant may now begin the pre-session survey.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.go('/training/$_participantId'),
            child: const Text('Start Training →'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text('Back to Home',
                style:
                    const TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────

  Future<void> _saveEnrolment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // The server assigns the participant_id atomically (Postgres sequence
      // + trigger — see participants_migration.sql). We never generate or
      // type an ID client-side, so two people registering at the same
      // moment from different devices can never collide.
      final assignedId = await _participants.registerParticipant(
        studyGroup: _group,
        ageRange: _ageRange,
        priorCprTraining: _priorTraining,
        languagePreference: _language,
      );
      _participantId = assignedId;

      // Mirror locally too, so existing on-device research-export tooling
      // (CSV/JSON download) keeps working unchanged.
      await _logger.enrollParticipant(UserProfile(
        userId:             assignedId,
        enrolledAt:         DateTime.now(),
        studyGroup:         _group,
        ageRange:           _ageRange,
        priorCprTraining:   _priorTraining,
        languagePreference: _language,
        consentGiven:       true,
        consentTimestamp:   DateTime.now(),
      ));
      setState(() { _step = 2; _saving = false; });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrolment failed: $e'),
              backgroundColor: AppTheme.accentWarn));
      }
    }
  }

  // ── Widget helpers ────────────────────────────────────────

  Widget _label(String t) =>
      Text(t, style: Theme.of(context).textTheme.labelSmall);

  Widget _infoCard(IconData icon, String title, String body) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(height: 1.5)),
              ],
            )),
          ],
        ),
      );

  InputDecoration _inputDec({required String label, String? hint}) =>
      InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 13),
        hintStyle: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.5)),
        filled: true, fillColor: AppTheme.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppTheme.accent, width: 1.5)),
      );

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value, items: items, onChanged: onChanged,
      dropdownColor: AppTheme.card,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: _inputDec(label: label),
    );
  }
}