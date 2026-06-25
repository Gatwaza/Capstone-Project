// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// ParticipantGateScreen — entry point before any training session.
//
// Two paths:
//   1. New participant  -> full consent flow (ConsentScreen), which
//      registers against Supabase and receives a server-assigned ID.
//   2. Returning participant -> picks their existing ID from a dropdown
//      populated from Supabase (`participants` table). No re-consent;
//      every session they log afterwards is tagged with the SAME
//      participant_id, so the backend sees one participant with many
//      session rows rather than a new ID per visit.
//
// This screen is the single gate training must pass through — see
// app_router.dart, where AppRoutes.training now requires a participantId
// path parameter instead of being reachable with no identity at all.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/env.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../services/participant_service.dart';

class ParticipantGateScreen extends StatefulWidget {
  const ParticipantGateScreen({super.key});

  @override
  State<ParticipantGateScreen> createState() => _ParticipantGateScreenState();
}

class _ParticipantGateScreenState extends State<ParticipantGateScreen> {
  final _participants = getIt<ParticipantService>();

  late Future<List<ParticipantSummary>> _future;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _future = _participants.listParticipants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Who is training?'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Config warning (fail fast, before consent flow) ───
            if (!Env.isConfigured) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentWarn.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentWarn),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppTheme.accentWarn, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Backend not configured — enrolment and the '
                        'returning-participant list will not work until '
                        'SUPABASE_URL and SUPABASE_ANON_KEY are set. '
                        'If you just deployed, check that window.__NOVICE_CONFIG__ '
                        'is present in index.html and that you reloaded past any '
                        'cached service worker.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppTheme.accentWarn, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── New participant ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_add_alt_1_rounded,
                          color: AppTheme.accent, size: 22),
                      const SizedBox(width: 10),
                      Text('First time here',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will be asked for informed consent, then assigned '
                    'a participant ID automatically.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: Env.isConfigured
                        ? () => context.push(AppRoutes.consent)
                        : null,
                    child: const Text('Register as a new participant'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider(color: AppTheme.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR',
                      style: Theme.of(context).textTheme.labelSmall),
                ),
                const Expanded(child: Divider(color: AppTheme.border)),
              ],
            ),
            const SizedBox(height: 20),

            // ── Returning participant ───────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          color: AppTheme.textSecondary, size: 22),
                      const SizedBox(width: 10),
                      Text('I have already registered',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your participant ID — every session you train '
                    'will be logged under the same ID.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<ParticipantSummary>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final list = snapshot.data ?? [];
                      if (list.isEmpty) {
                        return Text(
                          'No registered participants found yet.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedId,
                        isExpanded: true,
                        dropdownColor: AppTheme.card,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Participant ID',
                          labelStyle: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: AppTheme.bg,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppTheme.border)),
                        ),
                        items: list
                            .map((p) => DropdownMenuItem(
                                  value: p.participantId,
                                  child: Text(
                                    '${p.participantId}  ·  ${p.studyGroup == "groupA" ? "Group A" : "Group B"}',
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _selectedId == null
                        ? null
                        : () => context.push(
                              '/training/${_selectedId!}',
                            ),
                    child: const Text('Continue to training'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}