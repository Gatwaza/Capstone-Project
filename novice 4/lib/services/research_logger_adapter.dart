// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// ResearchLoggerAdapter — platform-transparent facade over:
//   • ResearchLogger     (mobile / SQLite)
//   • ResearchLoggerWeb  (web / SharedPreferences + browser download)
//
// Usage in any screen:
//   final logger = ResearchLoggerAdapter();
//   await logger.enrollParticipant(profile);
//   await logger.exportCsv();   // web only — triggers browser download
//
// This eliminates all kIsWeb checks from UI code and fixes the original
// "ResearchLogger not registered on web" crash.

import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/di/injection.dart';
import '../models/research_models.dart';
import '../services/research_logger.dart';
import '../services/research_logger_web.dart';

class ResearchLoggerAdapter {
  // ── Singleton access helpers ──────────────────────────────

  ResearchLogger? get _mobile => kIsWeb ? null : getIt<ResearchLogger>();
  ResearchLoggerWeb? get _web => kIsWeb ? getIt<ResearchLoggerWeb>() : null;

  // ── UserProfile ───────────────────────────────────────────

  Future<void> enrollParticipant(UserProfile profile) => kIsWeb
      ? _web!.enrollParticipant(profile)
      : _mobile!.enrollParticipant(profile);

  Future<UserProfile?> loadParticipant(String userId) =>
      kIsWeb ? _web!.loadParticipant(userId) : _mobile!.loadParticipant(userId);

  Future<List<UserProfile>> loadAllParticipants() =>
      kIsWeb ? _web!.loadAllParticipants() : _mobile!.loadAllParticipants();

  // ── ResearchSession ───────────────────────────────────────

  Future<String> startResearchSession({
    required String userId,
    required StudyGroup studyGroup,
    required String language,
    required bool modelActive,
    required String deviceModel,
    required String osVersion,
  }) {
    if (kIsWeb) {
      return _web!.startResearchSession(
        userId: userId,
        studyGroup: studyGroup,
        language: language,
        modelActive: modelActive,
        deviceModel: deviceModel,
        osVersion: osVersion,
      );
    }
    return _mobile!.startResearchSession(
      userId: userId,
      studyGroup: studyGroup,
      language: language,
      modelActive: modelActive,
      deviceModel: deviceModel,
      osVersion: osVersion,
    );
  }

  Future<void> endResearchSession(ResearchSession session) => kIsWeb
      ? _web!.endResearchSession(session)
      : _mobile!.endResearchSession(session);

  Future<List<ResearchSession>> loadSessionsByGroup(StudyGroup group) => kIsWeb
      ? _web!.loadSessionsByGroup(group)
      : _mobile!.loadSessionsByGroup(group);

  // ── FeedbackEvent ─────────────────────────────────────────

  Future<void> logFeedbackEvent(FeedbackEvent event) =>
      kIsWeb ? _web!.logFeedbackEvent(event) : _mobile!.logFeedbackEvent(event);

  // ── Survey responses ──────────────────────────────────────

  Future<void> saveSusSurvey(SusSurvey survey) =>
      kIsWeb ? _web!.saveSusSurvey(survey) : _mobile!.saveSusSurvey(survey);

  Future<void> saveNasaTlxSurvey(NasaTlxSurvey survey) => kIsWeb
      ? _web!.saveNasaTlxSurvey(survey)
      : _mobile!.saveNasaTlxSurvey(survey);

  Future<void> saveSelfEfficacySurvey(SelfEfficacySurvey survey) => kIsWeb
      ? _web!.saveSelfEfficacySurvey(survey)
      : _mobile!.saveSelfEfficacySurvey(survey);

  // ── Export ────────────────────────────────────────────────

  /// Triggers a CSV browser download on web.
  /// On mobile, returns empty (use share_plus separately).
  Future<void> exportCsv() async {
    if (kIsWeb) {
      await _web!.exportCsv();
    }
    // Mobile CSV handled via share_plus in researcher_dashboard
  }

  /// Full JSON export. On web triggers a browser download.
  Future<String> exportResearchData() =>
      kIsWeb ? _web!.exportResearchData() : _mobile!.exportResearchData();

  Future<void> dispose() async {
    if (kIsWeb) {
      await _web!.dispose();
    } else {
      await _mobile!.dispose();
    }
  }
}
