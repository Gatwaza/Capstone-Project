// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Pilot study research logger — 4-entity SQLite schema (§3.6.2 of proposal).
// Mobile only. Web: ResearchLoggerStub is used instead.
// Compiles on web via sqflite_compat.dart and path_provider_compat.dart.

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import 'sqflite_compat.dart';
import 'path_provider_compat.dart';
import '../models/research_models.dart';

class ResearchLogger {
  ResearchLogger();

  static const _dbName        = 'novice_research.db';
  static const _schemaVersion = 1;

  Database? _db;
  final _log = Logger();

  int _frameTick = 0;

  // ── Lifecycle ─────────────────────────────────────────────

  Future<void> init() async {
    if (kIsWeb) return;
    final dir  = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(path,
        version: _schemaVersion, onCreate: _createSchema, onUpgrade: _migrate);
    _log.i('ResearchLogger: opened at $path');
  }

  Future<void> _createSchema(Database db, int v) async {
    await db.execute('''CREATE TABLE user_profiles (
      user_id TEXT PRIMARY KEY, enrolled_at TEXT NOT NULL,
      study_group TEXT NOT NULL, age_range TEXT NOT NULL,
      prior_cpr_training TEXT NOT NULL, language_preference TEXT NOT NULL DEFAULT 'en',
      consent_given INTEGER NOT NULL DEFAULT 0, consent_timestamp TEXT,
      device_model TEXT, os_version TEXT, researcher_notes TEXT)''');

    await db.execute('''CREATE TABLE research_sessions (
      session_id TEXT PRIMARY KEY, user_id TEXT NOT NULL,
      start_time TEXT NOT NULL, end_time TEXT,
      device_model TEXT, os_version TEXT,
      study_group TEXT NOT NULL, model_was_active INTEGER NOT NULL DEFAULT 0,
      language TEXT NOT NULL DEFAULT 'en',
      total_compressions INTEGER NOT NULL DEFAULT 0,
      mean_bpm REAL NOT NULL DEFAULT 0, bpm_std_dev REAL NOT NULL DEFAULT 0,
      mean_depth_cm REAL NOT NULL DEFAULT 0,
      hand_placement_accuracy_pct REAL NOT NULL DEFAULT 0,
      elbow_compliance_pct REAL NOT NULL DEFAULT 0,
      time_to_first_compression_sec REAL NOT NULL DEFAULT 0,
      cpr_fraction REAL NOT NULL DEFAULT 0,
      quality_score INTEGER NOT NULL DEFAULT 0,
      error_rates_json TEXT NOT NULL DEFAULT '{}',
      sus_score REAL, nasa_tlx_score REAL, nasa_tlx_subscales_json TEXT,
      self_efficacy_pre REAL, self_efficacy_post REAL, sus_item_responses_json TEXT,
      FOREIGN KEY (user_id) REFERENCES user_profiles(user_id))''');

    await db.execute('''CREATE TABLE frame_records (
      frame_id TEXT PRIMARY KEY, session_id TEXT NOT NULL,
      timestamp TEXT NOT NULL, error_class TEXT NOT NULL,
      confidence_score REAL NOT NULL, bpm_estimate REAL NOT NULL,
      wrist_depth_proxy REAL NOT NULL, elbow_angle_mean REAL NOT NULL,
      spine_verticality_deg REAL NOT NULL,
      all_landmarks_visible INTEGER NOT NULL DEFAULT 0,
      from_model INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (session_id) REFERENCES research_sessions(session_id))''');

    await db.execute('''CREATE TABLE feedback_events (
      event_id TEXT PRIMARY KEY, session_id TEXT NOT NULL,
      timestamp TEXT NOT NULL, prompt_key TEXT NOT NULL,
      language TEXT NOT NULL, triggered_by TEXT NOT NULL,
      severity TEXT NOT NULL, was_spoken INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (session_id) REFERENCES research_sessions(session_id))''');

    await db.execute('''CREATE TABLE sus_surveys (
      session_id TEXT PRIMARY KEY, completed_at TEXT NOT NULL,
      responses_json TEXT NOT NULL, computed_score REAL NOT NULL,
      FOREIGN KEY (session_id) REFERENCES research_sessions(session_id))''');

    await db.execute('''CREATE TABLE nasa_tlx_surveys (
      session_id TEXT PRIMARY KEY, completed_at TEXT NOT NULL,
      mental_demand REAL NOT NULL, physical_demand REAL NOT NULL,
      temporal_demand REAL NOT NULL, performance REAL NOT NULL,
      effort REAL NOT NULL, frustration REAL NOT NULL, raw_score REAL NOT NULL,
      FOREIGN KEY (session_id) REFERENCES research_sessions(session_id))''');

    await db.execute('''CREATE TABLE self_efficacy_surveys (
      id TEXT PRIMARY KEY, session_id TEXT NOT NULL,
      is_post_session INTEGER NOT NULL, confidence INTEGER NOT NULL,
      rate_confidence INTEGER NOT NULL, depth_confidence INTEGER NOT NULL,
      willingness_to_act INTEGER NOT NULL, mean_score REAL NOT NULL,
      completed_at TEXT NOT NULL,
      FOREIGN KEY (session_id) REFERENCES research_sessions(session_id))''');

    await db.execute('CREATE INDEX idx_sessions_group ON research_sessions(study_group)');
    await db.execute('CREATE INDEX idx_frames_session ON frame_records(session_id)');
    await db.execute('CREATE INDEX idx_events_session ON feedback_events(session_id)');
    _log.i('ResearchLogger: schema v$v created');
  }

  Future<void> _migrate(Database db, int o, int n) async {}

  // ── UserProfile ───────────────────────────────────────────

  Future<void> enrollParticipant(UserProfile profile) async {
    if (!profile.consentGiven) {
      throw StateError('Cannot enrol participant without consent (§3.8).');
    }
    await _db?.insert('user_profiles', {
      'user_id':             profile.userId,
      'enrolled_at':         profile.enrolledAt.toIso8601String(),
      'study_group':         profile.studyGroup.name,
      'age_range':           profile.ageRange.name,
      'prior_cpr_training':  profile.priorCprTraining.name,
      'language_preference': profile.languagePreference,
      'consent_given':       profile.consentGiven ? 1 : 0,
      'consent_timestamp':   profile.consentTimestamp?.toIso8601String(),
      'device_model':        profile.deviceModel,
      'os_version':          profile.osVersion,
      'researcher_notes':    profile.researcherNotes,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _log.i('ResearchLogger: enrolled ${profile.userId} (${profile.studyGroup.name})');
  }

  Future<UserProfile?> loadParticipant(String userId) async {
    final rows = await _db?.query('user_profiles',
        where: 'user_id=?', whereArgs: [userId], limit: 1) ?? [];
    if (rows.isEmpty) return null;
    return _rowToProfile(rows.first);
  }

  Future<List<UserProfile>> loadAllParticipants() async {
    final rows = await _db?.query('user_profiles', orderBy: 'enrolled_at') ?? [];
    return rows.map(_rowToProfile).toList();
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
      throw StateError('Participant $userId has not given consent (§3.8).');
    }
    final sessionId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    _frameTick = 0;

    await _db?.insert('research_sessions', {
      'session_id': sessionId, 'user_id': userId,
      'start_time': DateTime.now().toIso8601String(),
      'study_group': studyGroup.name, 'model_was_active': modelActive ? 1 : 0,
      'language': language, 'device_model': deviceModel, 'os_version': osVersion,
      'error_rates_json': '{}',
    });
    _log.i('ResearchLogger: session $sessionId started');
    return sessionId;
  }

  Future<void> endResearchSession(ResearchSession session) async {
    await _db?.update('research_sessions', {
      'end_time':                          session.endTime.toIso8601String(),
      'total_compressions':                session.totalCompressions,
      'mean_bpm':                          session.meanBpm,
      'bpm_std_dev':                       session.bpmStdDev,
      'mean_depth_cm':                     session.meanDepthCm,
      'hand_placement_accuracy_pct':       session.handPlacementAccuracyPct,
      'elbow_compliance_pct':              session.elbowCompliancePct,
      'time_to_first_compression_sec':     session.timeToFirstCompressionSec,
      'cpr_fraction':                      session.cprFraction,
      'quality_score':                     session.qualityScore,
      'error_rates_json':                  jsonEncode(session.errorRates),
    }, where: 'session_id=?', whereArgs: [session.sessionId]);
    _log.i('ResearchLogger: session ${session.sessionId} ended');
  }

  Future<List<ResearchSession>> loadSessionsByGroup(StudyGroup group) async {
    final rows = await _db?.query('research_sessions',
        where: 'study_group=? AND end_time IS NOT NULL',
        whereArgs: [group.name], orderBy: 'start_time') ?? [];
    return rows.map(_rowToSession).toList();
  }

  // ── FrameRecord (logged every N ticks) ──────────────────

  Future<void> logFrame(FrameRecord frame) async {
    _frameTick++;
    if (_frameTick % ResearchConfig.frameLogInterval != 0) return;
    await _db?.insert('frame_records', {
      'frame_id':              frame.frameId,
      'session_id':            frame.sessionId,
      'timestamp':             frame.timestamp.toIso8601String(),
      'error_class':           frame.errorClass,
      'confidence_score':      frame.confidenceScore,
      'bpm_estimate':          frame.bpmEstimate,
      'wrist_depth_proxy':     frame.wristDepthProxy,
      'elbow_angle_mean':      frame.elbowAngleMean,
      'spine_verticality_deg': frame.spineVerticalityDeg,
      'all_landmarks_visible': frame.allLandmarksVisible ? 1 : 0,
      'from_model':            frame.fromModel ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<FrameRecord>> loadFrames(String sessionId) async {
    final rows = await _db?.query('frame_records',
        where: 'session_id=?', whereArgs: [sessionId], orderBy: 'timestamp') ?? [];
    return rows.map((r) => FrameRecord(
      frameId:             r['frame_id'] as String,
      sessionId:           r['session_id'] as String,
      timestamp:           DateTime.parse(r['timestamp'] as String),
      errorClass:          r['error_class'] as String,
      confidenceScore:     (r['confidence_score'] as num).toDouble(),
      bpmEstimate:         (r['bpm_estimate'] as num).toDouble(),
      wristDepthProxy:     (r['wrist_depth_proxy'] as num).toDouble(),
      elbowAngleMean:      (r['elbow_angle_mean'] as num).toDouble(),
      spineVerticalityDeg: (r['spine_verticality_deg'] as num).toDouble(),
      allLandmarksVisible: (r['all_landmarks_visible'] as int) == 1,
      fromModel:           (r['from_model'] as int) == 1,
    )).toList();
  }

  // ── FeedbackEvent ─────────────────────────────────────────

  Future<void> logFeedbackEvent(FeedbackEvent event) async {
    await _db?.insert('feedback_events', {
      'event_id':   event.eventId,
      'session_id': event.sessionId,
      'timestamp':  event.timestamp.toIso8601String(),
      'prompt_key': event.promptKey,
      'language':   event.language,
      'triggered_by': event.triggeredByClass,
      'severity':   event.severity,
      'was_spoken': event.wasSpoken ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ── Survey responses ──────────────────────────────────────

  Future<void> saveSusSurvey(SusSurvey survey) async {
    final score = SusItems.compute(survey.responses);
    await _db?.insert('sus_surveys', {
      'session_id': survey.sessionId,
      'completed_at': survey.completedAt.toIso8601String(),
      'responses_json': jsonEncode(survey.responses),
      'computed_score': score,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _db?.update('research_sessions',
      {'sus_score': score, 'sus_item_responses_json': jsonEncode(survey.responses)},
      where: 'session_id=?', whereArgs: [survey.sessionId]);
    _log.i('ResearchLogger: SUS score $score for ${survey.sessionId}');
  }

  Future<void> saveNasaTlxSurvey(NasaTlxSurvey survey) async {
    final raw = NasaTlxSurvey.computeRaw(survey);
    await _db?.insert('nasa_tlx_surveys', {
      'session_id': survey.sessionId,
      'completed_at': survey.completedAt.toIso8601String(),
      'mental_demand': survey.mentalDemand, 'physical_demand': survey.physicalDemand,
      'temporal_demand': survey.temporalDemand, 'performance': survey.performance,
      'effort': survey.effort, 'frustration': survey.frustration, 'raw_score': raw,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _db?.update('research_sessions', {
      'nasa_tlx_score': raw,
      'nasa_tlx_subscales_json': jsonEncode({
        'mental': survey.mentalDemand, 'physical': survey.physicalDemand,
        'temporal': survey.temporalDemand, 'performance': survey.performance,
        'effort': survey.effort, 'frustration': survey.frustration,
      }),
    }, where: 'session_id=?', whereArgs: [survey.sessionId]);
  }

  Future<void> saveSelfEfficacySurvey(SelfEfficacySurvey survey) async {
    final mean = SelfEfficacySurvey.mean(survey);
    final id   = '${survey.sessionId}_${survey.isPostSession ? "post" : "pre"}';
    await _db?.insert('self_efficacy_surveys', {
      'id': id, 'session_id': survey.sessionId,
      'is_post_session': survey.isPostSession ? 1 : 0,
      'confidence': survey.confidence, 'rate_confidence': survey.rateConfidence,
      'depth_confidence': survey.depthConfidence,
      'willingness_to_act': survey.willingnessToAct,
      'mean_score': mean, 'completed_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final field = survey.isPostSession ? 'self_efficacy_post' : 'self_efficacy_pre';
    await _db?.update('research_sessions', {field: mean},
        where: 'session_id=?', whereArgs: [survey.sessionId]);
  }

  // ── Researcher Export ─────────────────────────────────────

  Future<String> exportResearchData() async {
    final groupA = await loadSessionsByGroup(StudyGroup.groupA);
    final groupB = await loadSessionsByGroup(StudyGroup.groupB);
    final participants = await loadAllParticipants();

    Future<Map<String, dynamic>> enriched(ResearchSession s) async {
      final frames  = await loadFrames(s.sessionId);
      final events  = await _loadFeedbackEvents(s.sessionId);
      return {
        ...s.toJson(),
        'frame_records':   frames.map((f) => f.toJson()).toList(),
        'feedback_events': events.map((e) => e.toJson()).toList(),
      };
    }

    final export = {
      'exported_at':    DateTime.now().toIso8601String(),
      'schema_version': _schemaVersion,
      'study_summary': {
        'group_a_count': groupA.length,
        'group_b_count': groupB.length,
        'total_participants': participants.length,
      },
      'participants':     participants.map((p) => p.toJson()).toList(),
      'group_a_sessions': await Future.wait(groupA.map(enriched)),
      'group_b_sessions': await Future.wait(groupB.map(enriched)),
    };

    final json = const JsonEncoder.withIndent('  ').convert(export);
    _log.i('ResearchLogger: exported ${groupA.length} A + ${groupB.length} B sessions');
    return json;
  }

  // ── Private helpers ───────────────────────────────────────

  Future<List<FeedbackEvent>> _loadFeedbackEvents(String sessionId) async {
    final rows = await _db?.query('feedback_events',
        where: 'session_id=?', whereArgs: [sessionId], orderBy: 'timestamp') ?? [];
    return rows.map((r) => FeedbackEvent(
      eventId:          r['event_id'] as String,
      sessionId:        r['session_id'] as String,
      timestamp:        DateTime.parse(r['timestamp'] as String),
      promptKey:        r['prompt_key'] as String,
      language:         r['language'] as String,
      triggeredByClass: r['triggered_by'] as String,
      severity:         r['severity'] as String,
      wasSpoken:        (r['was_spoken'] as int) == 1,
    )).toList();
  }

  UserProfile _rowToProfile(Map<String, dynamic> r) => UserProfile(
    userId:             r['user_id'] as String,
    enrolledAt:         DateTime.parse(r['enrolled_at'] as String),
    studyGroup:         StudyGroup.values.byName(r['study_group'] as String),
    ageRange:           AgeRange.values.byName(r['age_range'] as String),
    priorCprTraining:   PriorCprTraining.values.byName(r['prior_cpr_training'] as String),
    languagePreference: r['language_preference'] as String? ?? 'en',
    consentGiven:       (r['consent_given'] as int) == 1,
    consentTimestamp:   r['consent_timestamp'] != null
        ? DateTime.parse(r['consent_timestamp'] as String) : null,
    deviceModel:        r['device_model'] as String?,
    osVersion:          r['os_version'] as String?,
    researcherNotes:    r['researcher_notes'] as String?,
  );

  ResearchSession _rowToSession(Map<String, dynamic> r) => ResearchSession(
    sessionId:   r['session_id'] as String,
    userId:      r['user_id'] as String,
    startTime:   DateTime.parse(r['start_time'] as String),
    endTime:     r['end_time'] != null
        ? DateTime.parse(r['end_time'] as String) : DateTime.now(),
    deviceModel: r['device_model'] as String? ?? '',
    osVersion:   r['os_version'] as String? ?? '',
    studyGroup:  StudyGroup.values.byName(r['study_group'] as String),
    modelWasActive: (r['model_was_active'] as int) == 1,
    language:    r['language'] as String? ?? 'en',
    totalCompressions:         r['total_compressions'] as int? ?? 0,
    meanBpm:                   (r['mean_bpm'] as num?)?.toDouble() ?? 0,
    bpmStdDev:                 (r['bpm_std_dev'] as num?)?.toDouble() ?? 0,
    meanDepthCm:               (r['mean_depth_cm'] as num?)?.toDouble() ?? 0,
    handPlacementAccuracyPct:  (r['hand_placement_accuracy_pct'] as num?)?.toDouble() ?? 0,
    elbowCompliancePct:        (r['elbow_compliance_pct'] as num?)?.toDouble() ?? 0,
    timeToFirstCompressionSec: (r['time_to_first_compression_sec'] as num?)?.toDouble() ?? 0,
    cprFraction:               (r['cpr_fraction'] as num?)?.toDouble() ?? 0,
    qualityScore:              r['quality_score'] as int? ?? 0,
    errorRates: Map<String, double>.from(
        jsonDecode(r['error_rates_json'] as String? ?? '{}') as Map),
    susScore:          (r['sus_score'] as num?)?.toDouble(),
    nasaTlxScore:      (r['nasa_tlx_score'] as num?)?.toDouble(),
    selfEfficacyPre:   (r['self_efficacy_pre'] as num?)?.toDouble(),
    selfEfficacyPost:  (r['self_efficacy_post'] as num?)?.toDouble(),
  );

  Future<void> dispose() async => _db?.close();
}
