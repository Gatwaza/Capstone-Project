// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// ResearchLoggerAdapter — thin facade over ResearchLoggerWeb
// (web / SharedPreferences + browser download).
//
// Usage in any screen:
//   final logger = ResearchLoggerAdapter();
//   await logger.enrollParticipant(profile);
//   await logger.exportCsv();   // triggers browser download
//
// NOTE: mobile (SQLite via ResearchLogger) support is on hold. If mobile
// work resumes, restore ResearchLogger and the kIsWeb branches this file
// used to have (see git history) instead of the direct _web calls below.

import '../core/di/injection.dart';
import '../models/research_models.dart';
import '../services/research_logger_web.dart';

class ResearchLoggerAdapter {
  // ── Singleton access helper ───────────────────────────────

  ResearchLoggerWeb get _web => getIt<ResearchLoggerWeb>();

  // ── UserProfile ───────────────────────────────────────────

  Future<void> enrollParticipant(UserProfile profile) =>
      _web.enrollParticipant(profile);

  Future<UserProfile?> loadParticipant(String userId) =>
      _web.loadParticipant(userId);

  Future<List<UserProfile>> loadAllParticipants() =>
      _web.loadAllParticipants();

  // ── ResearchSession ───────────────────────────────────────

  Future<String> startResearchSession({
    required String userId,
    required StudyGroup studyGroup,
    required String language,
    required bool modelActive,
    required String deviceModel,
    required String osVersion,
  }) {
    return _web.startResearchSession(
      userId: userId,
      studyGroup: studyGroup,
      language: language,
      modelActive: modelActive,
      deviceModel: deviceModel,
      osVersion: osVersion,
    );
  }

  Future<void> endResearchSession(ResearchSession session) =>
      _web.endResearchSession(session);

  Future<List<ResearchSession>> loadSessionsByGroup(StudyGroup group) =>
      _web.loadSessionsByGroup(group);

  // ── FeedbackEvent ─────────────────────────────────────────

  Future<void> logFeedbackEvent(FeedbackEvent event) =>
      _web.logFeedbackEvent(event);

  // ── Survey responses ──────────────────────────────────────

  Future<void> saveSusSurvey(SusSurvey survey) => _web.saveSusSurvey(survey);

  Future<void> saveNasaTlxSurvey(NasaTlxSurvey survey) =>
      _web.saveNasaTlxSurvey(survey);

  Future<void> saveSelfEfficacySurvey(SelfEfficacySurvey survey) =>
      _web.saveSelfEfficacySurvey(survey);

  // ── Export ────────────────────────────────────────────────

  /// Triggers a CSV browser download.
  Future<void> exportCsv() => _web.exportCsv();

  /// Full JSON export. Triggers a browser download.
  Future<String> exportResearchData() => _web.exportResearchData();

  Future<void> dispose() => _web.dispose();
}