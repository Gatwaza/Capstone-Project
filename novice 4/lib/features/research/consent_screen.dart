// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// ConsentScreen — Participant enrolment + informed consent.
// Required before any research session can begin.
//
// Implements §3.8 Ethical Considerations:
//   "Written informed consent will be obtained from all participants
//    prior to data collection."
//   "Participant data will be anonymized through assignment of
//    participant ID codes; names will not appear in any research output."

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/di/injection.dart';
import '../../models/research_models.dart';
import '../../services/research_logger.dart';
import '../../core/router/app_router.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form state
  String _participantId = '';
  StudyGroup _group = StudyGroup.groupA;
  AgeRange _ageRange = AgeRange.age18to24;
  PriorCprTraining _priorTraining = PriorCprTraining.none;
  String _language = 'en';
  bool _consentChecked = false;
  bool _saving = false;
  int _consentStep = 0; // 0=info, 1=form, 2=complete

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
        index: _consentStep,
        children: [
          _buildInfoStep(),
          _buildFormStep(),
          _buildCompleteStep(),
        ],
      ),
    );
  }

  // ── Step 0: Study information sheet ──────────────────────

  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PARTICIPANT INFORMATION SHEET'),
          const SizedBox(height: 16),

          _infoCard(
            icon: Icons.info_outline_rounded,
            title: 'Study Purpose',
            body:
              'You are invited to participate in a research study evaluating '
              'the Novice CPR coaching application. The study will assess whether '
              'real-time AI feedback improves CPR technique quality in first-time users.',
          ),
          _infoCard(
            icon: Icons.videocam_outlined,
            title: 'What We Collect',
            body:
              'The app will use your device camera to analyse your CPR technique '
              'on a manikin. Your body movement data (joint angles, compression rate) '
              'will be logged. No video footage is stored or transmitted. '
              'All data is stored locally on this device and anonymised using a '
              'participant ID code — your name is never recorded.',
          ),
          _infoCard(
            icon: Icons.schedule_rounded,
            title: 'Session Duration',
            body:
              'Each session is a maximum of 15 minutes. You will be asked to '
              'complete brief surveys before and after the session.',
          ),
          _infoCard(
            icon: Icons.exit_to_app_rounded,
            title: 'Your Rights',
            body:
              'Participation is entirely voluntary. You may withdraw at any time '
              'without consequence. Data collected before withdrawal will be deleted '
              'upon request. You are not required to give a reason for withdrawing.',
          ),
          _infoCard(
            icon: Icons.security_rounded,
            title: 'Data Security',
            body:
              'Session data is stored locally on this research device. '
              'It will be deleted after analysis in accordance with ALU '
              'research data management policy (minimum 5 years retention). '
              'Access is restricted to the principal researcher and supervisor.',
          ),
          _infoCard(
            icon: Icons.medical_services_outlined,
            title: 'Medical Disclaimer',
            body:
              'This study involves simulated CPR on a manikin ONLY. '
              'You will NOT perform CPR on any person. '
              'Novice is a training aid and does not replace formal CPR '
              'certification or professional medical advice.',
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _consentStep = 1),
            child: const Text('I have read and understood this information'),
          ),
          const SizedBox(height: 12),
          Text(
            'Ethical clearance reference: ALU Research Ethics Committee\n'
            'Declaration of Helsinki compliant.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Consent form + participant details ────────────

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('PARTICIPANT DETAILS'),
            const SizedBox(height: 16),

            // Participant ID
            TextFormField(
              decoration: _inputDecoration(
                label: 'Participant ID',
                hint: 'e.g. P001 (assigned by researcher)',
              ),
              style: TextStyle(color: AppTheme.textPrimary),
              onChanged: (v) => _participantId = v.trim().toUpperCase(),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Participant ID is required' : null,
            ),
            const SizedBox(height: 16),

            // Study group — set by researcher, not shown as editable in prod
            // TODO: In deployment, this should be pre-set by researcher and hidden
            _dropdownField<StudyGroup>(
              label: 'Study Group (researcher assigns)',
              value: _group,
              items: const [
                DropdownMenuItem(value: StudyGroup.groupA,
                    child: Text('Group A — With AI guidance')),
                DropdownMenuItem(value: StudyGroup.groupB,
                    child: Text('Group B — Without AI guidance (control)')),
              ],
              onChanged: (v) => setState(() => _group = v!),
            ),
            const SizedBox(height: 16),

            // Age range
            _dropdownField<AgeRange>(
              label: 'Age Range',
              value: _ageRange,
              items: const [
                DropdownMenuItem(value: AgeRange.under18,   child: Text('Under 18')),
                DropdownMenuItem(value: AgeRange.age18to24, child: Text('18–24')),
                DropdownMenuItem(value: AgeRange.age25to34, child: Text('25–34')),
                DropdownMenuItem(value: AgeRange.age35to44, child: Text('35–44')),
                DropdownMenuItem(value: AgeRange.age45plus, child: Text('45 or older')),
              ],
              onChanged: (v) => setState(() => _ageRange = v!),
            ),
            const SizedBox(height: 16),

            // Prior CPR training
            _dropdownField<PriorCprTraining>(
              label: 'Prior CPR Training',
              value: _priorTraining,
              items: const [
                DropdownMenuItem(value: PriorCprTraining.none,
                    child: Text('None — never learned CPR')),
                DropdownMenuItem(value: PriorCprTraining.watched,
                    child: Text('Watched a video or demo only')),
                DropdownMenuItem(value: PriorCprTraining.basic,
                    child: Text('Attended a first-aid class (over 1 year ago)')),
                DropdownMenuItem(value: PriorCprTraining.recent,
                    child: Text('Trained within the past 12 months')),
                DropdownMenuItem(value: PriorCprTraining.certified,
                    child: Text('Currently certified in CPR')),
              ],
              onChanged: (v) => setState(() => _priorTraining = v!),
            ),
            const SizedBox(height: 16),

            // Language preference
            _dropdownField<String>(
              label: 'Preferred Coaching Language',
              value: _language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'rw', child: Text('Kinyarwanda')),
              ],
              onChanged: (v) => setState(() => _language = v!),
            ),
            const SizedBox(height: 24),

            // Consent declaration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _consentChecked
                    ? AppTheme.accent.withOpacity(0.08)
                    : AppTheme.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _consentChecked
                      ? AppTheme.accent.withOpacity(0.4)
                      : AppTheme.border,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _consentChecked,
                    activeColor: AppTheme.accent,
                    onChanged: (v) => setState(() => _consentChecked = v!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'I confirm that I have read and understood the Participant '
                      'Information Sheet. I voluntarily agree to participate in '
                      'this study. I understand I may withdraw at any time. '
                      'I consent to the collection and use of anonymised body '
                      'movement data for research purposes.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: _consentChecked
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _consentChecked && !_saving ? _saveEnrolment : null,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Confirm & Enrol Participant'),
            ),

            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _consentStep = 0),
              child: Text('← Back to information sheet',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Confirmation ──────────────────────────────────

  Widget _buildCompleteStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: AppTheme.accent, size: 36),
          ),
          const SizedBox(height: 24),
          Text('Participant Enrolled',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'ID: $_participantId · ${_group == StudyGroup.groupA ? 'Group A' : 'Group B'}',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.accent),
          ),
          const SizedBox(height: 32),
          Text(
            'Consent recorded at ${DateTime.now().toLocal().toString().substring(0, 16)}.\n'
            'The participant may now begin a training session.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.training),
            child: Text(_group == StudyGroup.groupA
                ? 'Start Session (Group A — AI Guidance On)'
                : 'Start Session (Group B — Control)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text('Back to Home',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  // ── Save enrolment ────────────────────────────────────────

  Future<void> _saveEnrolment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final profile = UserProfile(
        userId:            _participantId,
        enrolledAt:        DateTime.now(),
        studyGroup:        _group,
        ageRange:          _ageRange,
        priorCprTraining:  _priorTraining,
        languagePreference: _language,
        consentGiven:      true,
        consentTimestamp:  DateTime.now(),
      );

      await getIt<ResearchLogger>().enrollParticipant(profile);
      setState(() { _consentStep = 2; _saving = false; });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrolment failed: $e'),
              backgroundColor: AppTheme.accentWarn),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall,
  );

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5)),
        filled: true,
        fillColor: AppTheme.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.accent, width: 1.5),
        ),
      );

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: AppTheme.card,
      style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: _inputDecoration(label: label),
    );
  }
}
