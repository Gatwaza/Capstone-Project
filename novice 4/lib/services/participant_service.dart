// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

/// ParticipantService — registers new participants and looks up existing
/// ones against the Supabase `participants` table.
///
/// Why this exists (replacing free-text + localStorage enrolment):
///   • Participant IDs must be globally unique across every device/browser
///     a participant might use — localStorage is per-browser, so two
///     people on two laptops could both end up "P001".
///   • ID assignment must be atomic. We rely on a Postgres SEQUENCE +
///     trigger (see participants_migration.sql) so concurrent registrations
///     never race each other into the same ID — a client-side
///     "count rows then +1" approach is NOT safe under concurrency.
///   • Returning participants must be able to find and reuse their own ID
///     via a dropdown rather than retyping it (typos would silently create
///     a data-quality problem — sessions logged against a near-miss ID that
///     looks like, but isn't, their real one).
///
/// Setup: run participants_migration.sql in the Supabase SQL editor once
/// (after the original sessions-table setup). Uses SUPABASE_URL /
/// SUPABASE_ANON_KEY via Env (see lib/core/constants/env.dart).
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../core/constants/env.dart';
import '../core/di/injection.dart';
import '../core/constants/env.dart';
import '../models/research_models.dart';

class ParticipantService {
  ParticipantService({String? supabaseUrl, String? anonKey})
      : _supabaseUrl = supabaseUrl ?? Env.supabaseUrl,
        _anonKey     = anonKey     ?? Env.supabaseAnonKey;

  final String _supabaseUrl;
  final String _anonKey;

  bool get isConfigured => _supabaseUrl.isNotEmpty && _anonKey.isNotEmpty;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
      };

  /// Registers a new participant. The server (Postgres trigger) assigns the
  /// participant_id — we send an empty string and read back what was
  /// actually assigned via `Prefer: return=representation`.
  ///
  /// Returns the assigned participant ID (e.g. "P014").
  Future<String> registerParticipant({
    required StudyGroup studyGroup,
    required AgeRange ageRange,
    required PriorCprTraining priorCprTraining,
    required String languagePreference,
  }) async {
    if (!isConfigured) {
      throw StateError(
        '[ParticipantService] Not configured — set SUPABASE_URL and '
        'SUPABASE_ANON_KEY.',
      );
    }

    final response = await http
        .post(
          Uri.parse('$_supabaseUrl/rest/v1/participants'),
          headers: {..._headers, 'Prefer': 'return=representation'},
          body: jsonEncode({
            'consent_given': true,
            'consent_timestamp': DateTime.now().toIso8601String(),
            'study_group': studyGroup.name,
            'age_range': ageRange.name,
            'prior_cpr_training': priorCprTraining.name,
            'language_preference': languagePreference,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 201) {
      throw StateError(
        'Registration failed: ${response.statusCode} ${response.body}',
      );
    }

    final rows = jsonDecode(response.body) as List;
    if (rows.isEmpty) {
      throw StateError('Registration returned no rows.');
    }
    final assignedId = rows.first['participant_id'] as String;
    getIt<Logger>().i('[ParticipantService] Registered as $assignedId');
    return assignedId;
  }

  /// Fetches all existing participant IDs for the "returning participant"
  /// dropdown. Ordered most-recently-enrolled first so frequent test users
  /// during a pilot find themselves near the top.
  Future<List<ParticipantSummary>> listParticipants() async {
    if (!isConfigured) return [];
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/participants'
              '?select=participant_id,study_group,enrolled_at'
              '&order=enrolled_at.desc',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        getIt<Logger>().w(
          '[ParticipantService] List failed: ${response.statusCode}',
        );
        return [];
      }

      final rows = jsonDecode(response.body) as List;
      return rows
          .map((r) => ParticipantSummary(
                participantId: r['participant_id'] as String,
                studyGroup: r['study_group'] as String,
                enrolledAt: DateTime.parse(r['enrolled_at'] as String),
              ))
          .toList();
    } catch (e) {
      getIt<Logger>().d('[ParticipantService] List error (silent): $e');
      return [];
    }
  }

  /// Confirms a typed/selected participant ID actually exists before
  /// letting someone start a session under it.
  Future<bool> participantExists(String participantId) async {
    if (!isConfigured) return false;
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_supabaseUrl/rest/v1/participants'
              '?select=participant_id'
              '&participant_id=eq.$participantId',
            ),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      final rows = jsonDecode(response.body) as List;
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class ParticipantSummary {
  const ParticipantSummary({
    required this.participantId,
    required this.studyGroup,
    required this.enrolledAt,
  });

  final String participantId;
  final String studyGroup;
  final DateTime enrolledAt;
}