// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// ResearchLoggerWeb — full web implementation of the research logging layer.
//
// Storage: shared_preferences (→ localStorage on web). No SQLite on web.
// Export:  CSV + JSON triggered as browser downloads — no server required.
// Sync:    Optional POST to a researcher webhook (Google Apps Script, etc.)
//          Only anonymised metrics are sent — never video, never PII.
//
// Privacy §3.12.3:
//   "Camera footage … deleted within 48 hours of landmark extraction;
//    only the anonymised landmark sequences and aggregate performance
//    metrics will be retained."
//   This implementation stores NO video at all — only extracted metrics.

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/research_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Storage key namespace
// ─────────────────────────────────────────────────────────────────────────────

class _K {
  _K._();
  static const _p = 'novice_research';
  static const participants = '$_p.participants';
  static String sessionList(String group) => '$_p.sessions.$group';
  static String sessionDetail(String id)  => '$_p.session.$id';
  static String events(String id)         => '$_p.events.$id';
  static String sus(String id)            => '$_p.sus.$id';
  static String nasa(String id)           => '$_p.nasa.$id';
  static String efficacy(String id, bool post) =>
      '$_p.efficacy.${id}_${post ? "post" : "pre"}';
}

// ─────────────────────────────────────────────────────────────────────────────
// ResearchLoggerWeb
// ─────────────────────────────────────────────────────────────────────────────

class ResearchLoggerWeb {
  ResearchLoggerWeb({this.cloudWebhookUrl});

  /// Optional researcher endpoint (Google Apps Script / Supabase edge fn).
  /// POST body: { "event": "...", "timestamp": "...", "data": {...} }
  /// If null → local-only; still exportable via CSV/JSON download.
  final String? cloudWebhookUrl;

  SharedPreferences? _prefs;
  final _log = Logger();

  // ── Lifecycle ─────────────────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _log.i('ResearchLoggerWeb: ready');
  }

  // ── UserProfile ───────────────────────────────────────────

  Future<void> enrollParticipant(UserProfile profile) async {
    if (!profile.consentGiven) {
      throw StateError('Cannot enrol participant without consent (§3.12.2).');
    }
    final existing = await loadAllParticipants();
    final updated = [
      ...existing.where((p) => p.userId != profile.userId),
      profile,
    ];
    await _prefs!.setString(
      _K.participants,
      jsonEncode(updated.map((p) => p.toJson()).toList()),
    );
    _log.i('ResearchLoggerWeb: enrolled ${profile.userId} (${profile.studyGroup.name})');
    await _syncToCloud('enrolment', profile.toJson());
  }

  Future<UserProfile?> loadParticipant(String userId) async {
    final all = await loadAllParticipants();
    try {
      return all.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  Future<List<UserProfile>> loadAllParticipants() async {
    final raw = _prefs?.getString(_K.participants);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log.w('ResearchLoggerWeb: parse participants failed: $e');
      return [];
    }
  }

  // ── ResearchSession ───────────────────────────────────────

  Future<String> startResearchSession({
    required String userId,
    required StudyGroup studyGroup,
    required String language,
    required bool modelActive,
    required String deviceModel,
    required String osVersion,
  }) async {
    final profile = await loadParticipant(userId);
    if (profile == null || !profile.consentGiven) {
      throw StateError('Participant $userId has not given consent (§3.12.2).');
    }
    final sessionId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final session = ResearchSession(
      sessionId: sessionId,
      userId: userId,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      deviceModel: deviceModel,
      osVersion: osVersion,
      studyGroup: studyGroup,
      modelWasActive: modelActive,
      language: language,
    );
    await _prefs!.setString(
        _K.sessionDetail(sessionId), jsonEncode(session.toJson()));

    final ids = _prefs!.getStringList(_K.sessionList(studyGroup.name)) ?? [];
    await _prefs!.setStringList(
        _K.sessionList(studyGroup.name), [...ids, sessionId]);

    _log.i('ResearchLoggerWeb: session $sessionId started');
    return sessionId;
  }

  Future<void> endResearchSession(ResearchSession session) async {
    await _prefs!.setString(
        _K.sessionDetail(session.sessionId), jsonEncode(session.toJson()));
    _log.i('ResearchLoggerWeb: session ${session.sessionId} ended');
    await _syncToCloud('session_end', session.toJson());
  }

  Future<List<ResearchSession>> loadSessionsByGroup(StudyGroup group) async {
    final ids = _prefs?.getStringList(_K.sessionList(group.name)) ?? [];
    final out = <ResearchSession>[];
    for (final id in ids) {
      final raw = _prefs?.getString(_K.sessionDetail(id));
      if (raw == null) continue;
      try {
        out.add(ResearchSession.fromJson(
            jsonDecode(raw) as Map<String, dynamic>));
      } catch (e) {
        _log.w('ResearchLoggerWeb: parse session $id failed: $e');
      }
    }
    return out;
  }

  // ── FeedbackEvent ─────────────────────────────────────────

  Future<void> logFeedbackEvent(FeedbackEvent event) async {
    final list = _jsonList(_K.events(event.sessionId));
    list.add(event.toJson());
    await _prefs!.setString(_K.events(event.sessionId), jsonEncode(list));
  }

  Future<List<FeedbackEvent>> loadFeedbackEvents(String sessionId) async {
    return _jsonList(_K.events(sessionId))
        .map((e) => FeedbackEvent.fromJson(e))
        .toList();
  }

  // ── Survey responses ──────────────────────────────────────

  Future<void> saveSusSurvey(SusSurvey survey) async {
    final score = SusItems.compute(survey.responses);
    await _prefs!.setString(_K.sus(survey.sessionId),
        jsonEncode({...survey.toJson(), 'computed_score': score}));
    await _patchSession(survey.sessionId, {'susScore': score});
    _log.i('ResearchLoggerWeb: SUS $score for ${survey.sessionId}');
  }

  Future<void> saveNasaTlxSurvey(NasaTlxSurvey survey) async {
    final raw = NasaTlxSurvey.computeRaw(survey);
    await _prefs!.setString(_K.nasa(survey.sessionId),
        jsonEncode({...survey.toJson(), 'raw_score': raw}));
    await _patchSession(survey.sessionId, {'nasaTlxScore': raw});
  }

  Future<void> saveSelfEfficacySurvey(SelfEfficacySurvey survey) async {
    final mean = SelfEfficacySurvey.mean(survey);
    await _prefs!.setString(
        _K.efficacy(survey.sessionId, survey.isPostSession),
        jsonEncode({...survey.toJson(), 'mean_score': mean}));
    final field =
        survey.isPostSession ? 'selfEfficacyPost' : 'selfEfficacyPre';
    await _patchSession(survey.sessionId, {field: mean});
  }

  // ── CSV export ────────────────────────────────────────────
  //
  // One row per completed session. Columns match §3.11.1 analysis plan:
  //   participant_id · study_group · age_range · prior_cpr_training ·
  //   language · session_id · start/end · duration_sec · model_active ·
  //   total_compressions · mean_bpm · bpm_std_dev · mean_depth_cm ·
  //   hand_placement_accuracy_pct · elbow_compliance_pct ·
  //   time_to_first_compression_sec · cpr_fraction · quality_score ·
  //   sus_score · nasa_tlx_score · self_efficacy_pre · self_efficacy_post ·
  //   self_efficacy_delta · consent_given · enrolled_at · device_model · os_version
  //
  // Triggers browser file-download — no server needed.

  Future<void> exportCsv() async {
    final groupA    = await loadSessionsByGroup(StudyGroup.groupA);
    final groupB    = await loadSessionsByGroup(StudyGroup.groupB);
    final profiles  = await loadAllParticipants();
    final pMap      = {for (final p in profiles) p.userId: p};
    final sessions  = [...groupA, ...groupB];

    final buf = StringBuffer();
    // Header
    buf.writeln([
      'participant_id','study_group','age_range','prior_cpr_training',
      'language_preference','session_id','start_time','end_time',
      'duration_sec','model_active','total_compressions','mean_bpm',
      'bpm_std_dev','mean_depth_cm','hand_placement_accuracy_pct',
      'elbow_compliance_pct','time_to_first_compression_sec','cpr_fraction',
      'quality_score','sus_score','nasa_tlx_score','self_efficacy_pre',
      'self_efficacy_post','self_efficacy_delta','device_model','os_version',
      'consent_given','enrolled_at',
    ].join(','));

    for (final s in sessions) {
      final p       = pMap[s.userId];
      final dur     = s.endTime.difference(s.startTime).inSeconds;
      final delta   = (s.selfEfficacyPost != null && s.selfEfficacyPre != null)
          ? (s.selfEfficacyPost! - s.selfEfficacyPre!).toStringAsFixed(2)
          : '';
      buf.writeln([
        s.userId,
        s.studyGroup.name,
        p?.ageRange.name ?? '',
        p?.priorCprTraining.name ?? '',
        p?.languagePreference ?? s.language,
        s.sessionId,
        s.startTime.toIso8601String(),
        s.endTime.toIso8601String(),
        dur,
        s.modelWasActive ? '1' : '0',
        s.totalCompressions,
        s.meanBpm.toStringAsFixed(1),
        s.bpmStdDev.toStringAsFixed(1),
        s.meanDepthCm.toStringAsFixed(2),
        s.handPlacementAccuracyPct.toStringAsFixed(1),
        s.elbowCompliancePct.toStringAsFixed(1),
        s.timeToFirstCompressionSec.toStringAsFixed(1),
        s.cprFraction.toStringAsFixed(3),
        s.qualityScore,
        s.susScore?.toStringAsFixed(1) ?? '',
        s.nasaTlxScore?.toStringAsFixed(1) ?? '',
        s.selfEfficacyPre?.toStringAsFixed(2) ?? '',
        s.selfEfficacyPost?.toStringAsFixed(2) ?? '',
        delta,
        _cell(s.deviceModel),
        _cell(s.osVersion),
        p?.consentGiven == true ? '1' : '0',
        p?.enrolledAt.toIso8601String() ?? '',
      ].map(_cell).join(','));
    }

    _download(
      content: buf.toString(),
      filename:
          'novice_pilot_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
      mime: 'text/csv;charset=utf-8;',
    );
    _log.i('ResearchLoggerWeb: CSV — ${sessions.length} sessions');
  }

  // ── JSON export ───────────────────────────────────────────

  Future<String> exportResearchData() async {
    final groupA    = await loadSessionsByGroup(StudyGroup.groupA);
    final groupB    = await loadSessionsByGroup(StudyGroup.groupB);
    final profiles  = await loadAllParticipants();

    Future<Map<String, dynamic>> enrich(ResearchSession s) async {
      final evts = await loadFeedbackEvents(s.sessionId);
      return {...s.toJson(), 'feedback_events': evts.map((e) => e.toJson()).toList()};
    }

    final payload = {
      'exported_at':    DateTime.now().toIso8601String(),
      'platform':       'web',
      'study_summary': {
        'group_a_count':      groupA.length,
        'group_b_count':      groupB.length,
        'total_participants': profiles.length,
      },
      'participants':       profiles.map((p) => p.toJson()).toList(),
      'group_a_sessions':   await Future.wait(groupA.map(enrich)),
      'group_b_sessions':   await Future.wait(groupB.map(enrich)),
    };

    final json = const JsonEncoder.withIndent('  ').convert(payload);
    _download(
      content: json,
      filename:
          'novice_research_${DateTime.now().toIso8601String().substring(0, 10)}.json',
      mime: 'application/json',
    );
    _log.i('ResearchLoggerWeb: JSON — A:${groupA.length} B:${groupB.length}');
    return json;
  }

  // ── Private helpers ───────────────────────────────────────

  Future<void> _syncToCloud(String event, Map<String, dynamic> data) async {
    if (cloudWebhookUrl == null || cloudWebhookUrl!.isEmpty) return;
    try {
      final xhr = html.HttpRequest();
      xhr.open('POST', cloudWebhookUrl!);
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(jsonEncode({
        'event':     event,
        'timestamp': DateTime.now().toIso8601String(),
        'data':      data,
      }));
    } catch (e) {
      _log.w('ResearchLoggerWeb: cloud sync non-critical failure: $e');
    }
  }

  Future<void> _patchSession(String id, Map<String, dynamic> fields) async {
    final raw = _prefs?.getString(_K.sessionDetail(id));
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.addAll(fields);
      await _prefs!.setString(_K.sessionDetail(id), jsonEncode(map));
    } catch (_) {}
  }

  List<Map<String, dynamic>> _jsonList(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static void _download({
    required String content,
    required String filename,
    required String mime,
  }) {
    final bytes  = utf8.encode(content);
    final blob   = html.Blob([bytes], mime);
    final url    = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = filename;
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  static String _cell(dynamic v) {
    final s = v?.toString() ?? '';
    return (s.contains(',') || s.contains('"') || s.contains('\n'))
        ? '"${s.replaceAll('"', '""')}"'
        : s;
  }

  Future<void> dispose() async {}
}
