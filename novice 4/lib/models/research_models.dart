// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Research data models matching the ER diagram in §3.6.2 of the proposal:
//   Session ──< FrameRecord
//   Session ──< FeedbackEvent
//   UserProfile >── Session
//
// These models capture ALL data needed for the pilot study comparative analysis
// (Group A: AI guidance vs Group B: no AI guidance, n ≥ 20 participants).

import 'package:freezed_annotation/freezed_annotation.dart';

part 'research_models.freezed.dart';
part 'research_models.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UserProfile
// Captures participant metadata for pilot study analysis.
// Stored once per participant; linked to all their sessions via user_id.
// ─────────────────────────────────────────────────────────────────────────────

/// Pilot study group assignment.
/// Group A receives AI voice + visual guidance.
/// Group B performs CPR without any AI feedback (control condition).
enum StudyGroup {
  /// AI guidance enabled — real-time voice + visual feedback active.
  groupA,
  /// Control condition — app records metrics silently, no coaching output.
  groupB,
}

/// Self-reported prior CPR training level.
enum PriorCprTraining {
  none,        // No CPR training whatsoever
  watched,     // Watched a video/demo only
  basic,       // Attended a basic first-aid class (≥1 year ago)
  recent,      // Trained within past 12 months
  certified,   // Holds current CPR certification
}

/// Age band for demographic analysis without identifying participants.
enum AgeRange {
  under18,    // <18
  age18to24,  // 18–24
  age25to34,  // 25–34
  age35to44,  // 35–44
  age45plus,  // 45+
}

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    /// Anonymous participant ID (e.g. "P001"). Never contains real name.
    required String userId,
    required DateTime enrolledAt,

    /// Pilot study group assignment.
    required StudyGroup studyGroup,

    /// Demographic — age band only (no DOB collected).
    required AgeRange ageRange,

    /// Self-reported prior CPR experience.
    required PriorCprTraining priorCprTraining,

    /// Preferred coaching language for this participant.
    @Default('en') String languagePreference,

    /// Written informed consent obtained (must be true before any recording).
    /// §3.8 Ethical Considerations: "Written informed consent will be obtained
    /// from all participants prior to data collection."
    @Default(false) bool consentGiven,

    /// Timestamp when consent was recorded in-app.
    DateTime? consentTimestamp,

    /// Optional: device model used (for NFR3 portability analysis).
    String? deviceModel,
    String? osVersion,

    /// Optional free-text notes added by researcher after session.
    String? researcherNotes,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Session
// One CPR training session. Linked to UserProfile via userId.
// Sessions are capped at 15 minutes per §3.8 Participant Safety.
// ─────────────────────────────────────────────────────────────────────────────

@freezed
class ResearchSession with _$ResearchSession {
  const factory ResearchSession({
    required String sessionId,
    required String userId,             // FK → UserProfile.userId
    required DateTime startTime,
    required DateTime endTime,
    required String deviceModel,
    required String osVersion,

    /// Study group — copied from UserProfile for convenience in analysis.
    required StudyGroup studyGroup,

    /// Whether the ML model was active (false = rule-based fallback).
    @Default(false) bool modelWasActive,

    /// Coaching language used during this session.
    @Default('en') String language,

    // ── Aggregate performance metrics (computed at session end) ──────────

    /// Total compressions detected via wrist-velocity peak detection.
    @Default(0) int totalCompressions,

    /// Mean compression rate across session (bpm). Target: 100–120.
    @Default(0.0) double meanBpm,

    /// Standard deviation of compression rate (consistency metric).
    @Default(0.0) double bpmStdDev,

    /// Mean estimated compression depth (cm). Target: 5.0–6.0.
    @Default(0.0) double meanDepthCm,

    /// % frames classified as 'correct_compression' or 'good'.
    @Default(0.0) double handPlacementAccuracyPct,

    /// % frames where mean elbow angle ≥ 160° (arms locked).
    @Default(0.0) double elbowCompliancePct,

    /// Seconds from session start to first compression detected.
    @Default(0.0) double timeToFirstCompressionSec,

    /// Fraction of session time actively compressing (target ≥ 0.6).
    @Default(0.0) double cprFraction,

    /// Composite quality score 0–100 (internal metric).
    @Default(0) int qualityScore,

    /// Per-error-class mean confidence scores over the session.
    @Default({}) Map<String, double> errorRates,

    // ── Post-session survey scores (entered by researcher/participant) ──

    /// System Usability Scale total score (0–100).
    /// Target: SUS ≥ 68 (acceptable threshold, per NFR4).
    /// Null until survey completed.
    double? susScore,

    /// NASA Task Load Index total score (0–100 weighted).
    /// Lower = less cognitive load. Target: ≤ 40.
    double? nasaTlxScore,

    /// NASA-TLX subscale breakdown (6 items × 0–100).
    @Default({}) Map<String, double> nasaTlxSubscales,

    /// Pre-session self-efficacy Likert mean (1–7 scale).
    double? selfEfficacyPre,

    /// Post-session self-efficacy Likert mean (1–7 scale).
    double? selfEfficacyPost,

    /// SUS individual item responses (10 items, 1–5 Likert).
    @Default([]) List<int> susItemResponses,

  }) = _ResearchSession;

  factory ResearchSession.fromJson(Map<String, dynamic> json) =>
      _$ResearchSessionFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// FrameRecord
// Per-frame inference snapshot logged during an active session.
// Written every Nth frame (configurable via ResearchConfig.frameLogInterval).
// Provides fine-grained data for compression rate and depth timeline analysis.
// ─────────────────────────────────────────────────────────────────────────────

@freezed
class FrameRecord with _$FrameRecord {
  const factory FrameRecord({
    required String frameId,
    required String sessionId,          // FK → ResearchSession.sessionId
    required DateTime timestamp,

    /// TCN or rule-based output class label.
    required String errorClass,

    /// Confidence score for errorClass (0.0–1.0).
    required double confidenceScore,

    /// Rule-based BPM estimate at this frame.
    required double bpmEstimate,

    /// Normalised wrist displacement (depth proxy, 0.0–1.0).
    required double wristDepthProxy,

    /// Mean of left + right elbow angles (degrees).
    required double elbowAngleMean,

    /// Spine verticality angle (degrees from vertical; 0 = correct).
    required double spineVerticalityDeg,

    /// Whether all key landmarks had visibility ≥ minLandmarkVisibility.
    @Default(false) bool allLandmarksVisible,

    /// Was this frame produced by the TFLite model (true) or rule-based (false)?
    @Default(false) bool fromModel,
  }) = _FrameRecord;

  factory FrameRecord.fromJson(Map<String, dynamic> json) =>
      _$FrameRecordFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// FeedbackEvent
// Each time a coaching prompt is spoken / displayed, one event is recorded.
// Enables analysis of feedback frequency, distribution, and triggered errors.
// ─────────────────────────────────────────────────────────────────────────────

@freezed
class FeedbackEvent with _$FeedbackEvent {
  const factory FeedbackEvent({
    required String eventId,
    required String sessionId,          // FK → ResearchSession.sessionId
    required DateTime timestamp,

    /// The prompt key (e.g. 'bent_elbows', 'rate_too_slow').
    required String promptKey,

    /// Language the prompt was delivered in ('en' or 'rw').
    required String language,

    /// The error class that triggered this prompt.
    required String triggeredByClass,

    /// Severity: 'good' | 'warning' | 'critical'.
    required String severity,

    /// Whether voice TTS was actually spoken (false = display only).
    @Default(false) bool wasSpoken,
  }) = _FeedbackEvent;

  factory FeedbackEvent.fromJson(Map<String, dynamic> json) =>
      _$FeedbackEventFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// SUS Survey Model
// System Usability Scale — 10-item alternating Likert (1–5).
// Score computed per Brooke (1996): (Σodd−5 + 25−Σeven) × 2.5
// ─────────────────────────────────────────────────────────────────────────────

@freezed
class SusSurvey with _$SusSurvey {
  const factory SusSurvey({
    required String sessionId,
    required DateTime completedAt,

    /// 10 SUS items, each rated 1–5.
    /// Items 1,3,5,7,9 = positively worded.
    /// Items 2,4,6,8,10 = negatively worded.
    required List<int> responses,    // length must be 10
  }) = _SusSurvey;

  factory SusSurvey.fromJson(Map<String, dynamic> json) =>
      _$SusSurveyFromJson(json);
}

/// SUS scoring constants — item wording per Brooke (1996).
class SusItems {
  static const List<String> questions = [
    'I think that I would like to use this system frequently.',                   // 1 +
    'I found the system unnecessarily complex.',                                  // 2 −
    'I thought the system was easy to use.',                                      // 3 +
    'I think that I would need the support of a technical person to use this.',   // 4 −
    'I found the various functions in this system were well integrated.',          // 5 +
    'I thought there was too much inconsistency in this system.',                 // 6 −
    'I would imagine that most people would learn to use this system quickly.',   // 7 +
    'I found the system very cumbersome to use.',                                 // 8 −
    'I felt very confident using the system.',                                    // 9 +
    'I needed to learn a lot of things before I could get going with this system.',// 10 −
  ];

  /// Compute SUS score from 10 responses (1–5 each).
  static double compute(List<int> responses) {
    assert(responses.length == 10);
    double oddSum  = 0;
    double evenSum = 0;
    for (int i = 0; i < 10; i++) {
      if (i.isEven) {
        oddSum  += responses[i] - 1;  // items 1,3,5,7,9 (index 0,2,4,6,8)
      } else {
        evenSum += 5 - responses[i];  // items 2,4,6,8,10 (index 1,3,5,7,9)
      }
    }
    return (oddSum + evenSum) * 2.5;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NASA-TLX Survey Model
// 6 subscales × 0–100 ratings. Weighted score per Hart & Staveland (1988).
// ─────────────────────────────────────────────────────────────────────────────

@freezed
class NasaTlxSurvey with _$NasaTlxSurvey {
  const factory NasaTlxSurvey({
    required String sessionId,
    required DateTime completedAt,

    /// Mental demand: How much mental/perceptual activity was required? (0–100)
    required double mentalDemand,

    /// Physical demand: How much physical activity was required? (0–100)
    required double physicalDemand,

    /// Temporal demand: How much time pressure did you feel? (0–100)
    required double temporalDemand,

    /// Performance: How successful were you? (0=perfect, 100=failure)
    required double performance,

    /// Effort: How hard did you work to achieve your level of performance? (0–100)
    required double effort,

    /// Frustration: How irritated/annoyed did you feel? (0–100)
    required double frustration,
  }) = _NasaTlxSurvey;

  factory NasaTlxSurvey.fromJson(Map<String, dynamic> json) =>
      _$NasaTlxSurveyFromJson(json);

  /// Unweighted NASA-TLX mean (raw TLX).
  /// Target for Novice: ≤ 40 (from research proposal §1.4).
  static double computeRaw(NasaTlxSurvey s) {
    return (s.mentalDemand + s.physicalDemand + s.temporalDemand +
            s.performance + s.effort + s.frustration) / 6.0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Self-Efficacy Survey
// 4-item Likert (1–7) measuring CPR confidence before and after session.
// Captures self-efficacy change — a primary research outcome per §1.3.
// ─────────────────────────────────────────────────────────────────────────────

@freezed
class SelfEfficacySurvey with _$SelfEfficacySurvey {
  const factory SelfEfficacySurvey({
    required String sessionId,
    required bool isPostSession,        // false = pre, true = post

    /// "I am confident I could perform CPR effectively in an emergency." (1–7)
    required int confidence,

    /// "I believe my CPR compressions would be at the correct rate." (1–7)
    required int rateConfidence,

    /// "I believe my CPR compressions would be at the correct depth." (1–7)
    required int depthConfidence,

    /// "I would attempt CPR on a stranger if I witnessed cardiac arrest." (1–7)
    required int willingnessToAct,
  }) = _SelfEfficacySurvey;

  factory SelfEfficacySurvey.fromJson(Map<String, dynamic> json) =>
      _$SelfEfficacySurveyFromJson(json);

  /// Mean Likert score (1–7). Higher = more self-efficacy.
  static double mean(SelfEfficacySurvey s) =>
      (s.confidence + s.rateConfidence + s.depthConfidence + s.willingnessToAct) / 4.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Research configuration
// Controls pilot study behaviour (group blinding, logging granularity, limits).
// ─────────────────────────────────────────────────────────────────────────────

class ResearchConfig {
  ResearchConfig._();

  /// Maximum session duration in minutes (§3.8 Participant Safety).
  static const int maxSessionMinutes = 15;

  /// Log a FrameRecord every N inference ticks (5 Hz × every 3rd = ~1.67 Hz).
  /// Balances data granularity vs. database size.
  static const int frameLogInterval = 3;

  /// Minimum participants per group for pilot study (§1.4).
  static const int minParticipantsPerGroup = 10;

  /// Participant ID prefix format: 'P001', 'P002', etc.
  static String participantId(int n) => 'P${n.toString().padLeft(3, '0')}';
}
