// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// privacy_policy_screen.dart — General-audience Privacy Policy.
//
// This is distinct from ConsentScreen (features/research/consent_screen.dart),
// which is the research-participant information sheet + consent capture flow
// for the Group A/B pilot study. This screen applies to EVERY Novice user,
// whether or not they are enrolled as a study participant, and is reachable
// from Settings without going through Pilot Study enrolment.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(context, 'PRIVACY POLICY — APPLIES TO ALL NOVICE USERS'),
            const SizedBox(height: 4),
            Text(
              'Last updated: July 2026',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 16),

            _infoCard(
              context,
              Icons.info_outline_rounded,
              '1. What Novice Is',
              'Novice is a browser-based CPR training aid that gives real-time '
                  'feedback on compression technique using your device camera. '
                  'It is a training tool, not a clinical or diagnostic device, '
                  'and is not a substitute for certified first-aid training or '
                  'professional medical advice. In a real emergency, always call '
                  'official emergency services first.',
            ),
            _infoCard(
              context,
              Icons.videocam_off_outlined,
              '2. What Data We Collect — and What We Never Record',
              'During a coaching session, Novice runs MediaPipe pose detection '
                  'entirely inside your browser. Only numeric body-landmark '
                  'coordinates — never an image, video frame, or clip — are '
                  'generated and used for technique classification. No video or '
                  'image of you is ever recorded, stored, or transmitted during a '
                  'standard coaching session, for any user. Session metrics '
                  '(compression rate, depth, recoil, language preference) and, if '
                  'you choose to enrol in the pilot study, consent-form responses '
                  'are the only data ever stored.',
            ),
            _infoCard(
              context,
              Icons.fact_check_outlined,
              '3. Legal Basis for Processing',
              'Data handling is governed by Rwanda\'s Law No. 058/2021 Relating '
                  'to the Protection of Personal Data and Privacy, which requires '
                  'clear and unambiguous consent for the collection, storage, and '
                  'processing of personal data. Because Novice never captures '
                  'video or images in standard use, the personal-data footprint is '
                  'minimised by design rather than by later redaction.',
            ),
            _infoCard(
              context,
              Icons.security_rounded,
              '4. Data Security & Storage',
              'Session data is stored in an access-controlled Supabase project '
                  'rather than a general-purpose or undocumented store, '
                  'consistent with the African Union Malabo Convention on Cyber '
                  'Security and Personal Data Protection, which Rwanda has '
                  'ratified. Access is restricted to the principal researcher and '
                  'supervisor.',
            ),
            _infoCard(
              context,
              Icons.schedule_rounded,
              '5. Data Retention',
              'Session metrics are retained only for as long as needed for '
                  'coaching-history display and, for pilot participants, study '
                  'analysis, after which they are deleted in line with ALU data '
                  'management policy. You may request earlier deletion at any '
                  'time — see "Your Rights" below.',
            ),
            _infoCard(
              context,
              Icons.exit_to_app_rounded,
              '6. Your Rights',
              'You may request access to, or deletion of, any data associated '
                  'with your sessions at any time, without needing to give a '
                  'reason. If you are a pilot-study participant, you may also '
                  'withdraw from the study at any time without consequence; data '
                  'collected before withdrawal will be deleted on request. To make '
                  'a request, use the "Export session data" option in Settings or '
                  'contact the developer directly.',
            ),
            _infoCard(
              context,
              Icons.groups_outlined,
              '7. Known Limitation — Model Fairness',
              'The underlying pose-classification model was trained on a single, '
                  'lab-collected dataset without documented demographic '
                  'diversity. This is disclosed here as a stated limitation, '
                  'consistent with WHO and UNESCO AI-ethics guidance on '
                  'inclusiveness and fairness: technique feedback has not yet '
                  'been independently validated across skin tones and body '
                  'types, and stratified evaluation is a planned next step before '
                  'any field-readiness claim is made.',
            ),
            _infoCard(
              context,
              Icons.description_outlined,
              '8. Open-Source License',
              'Novice is free software distributed under the GNU General '
                  'Public License v3.0. Source code is available at '
                  'github.com/Gatwaza/Capstone-Project. This license governs '
                  'use and redistribution of the code itself, separately from '
                  'how your data is handled, which is covered by this policy.',
            ),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'Pilot-study participants: enrolling through Settings → Pilot '
                'Study → Participant Enrolment presents an additional, '
                'study-specific Participant Information Sheet and consent form '
                'covering the Group A/B study design. This policy applies '
                'regardless of whether you enrol.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 11, height: 1.6),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Questions about this policy: Jean Robert Gatwaza — African '
              'Leadership University. Ethical clearance for the associated '
              'research pilot: ALU Research Ethics Committee, Approval Code '
              'M26-BSE-040.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String t) =>
      Text(t, style: Theme.of(context).textTheme.labelSmall);

  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String title,
    String body,
  ) =>
      Container(
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
                  Text(
                    body,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}