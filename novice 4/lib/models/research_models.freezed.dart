// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'research_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  /// Anonymous participant ID (e.g. "P001"). Never contains real name.
  String get userId => throw _privateConstructorUsedError;
  DateTime get enrolledAt => throw _privateConstructorUsedError;

  /// Pilot study group assignment.
  StudyGroup get studyGroup => throw _privateConstructorUsedError;

  /// Demographic — age band only (no DOB collected).
  AgeRange get ageRange => throw _privateConstructorUsedError;

  /// Self-reported prior CPR experience.
  PriorCprTraining get priorCprTraining => throw _privateConstructorUsedError;

  /// Preferred coaching language for this participant.
  String get languagePreference => throw _privateConstructorUsedError;

  /// Written informed consent obtained (must be true before any recording).
  /// §3.8 Ethical Considerations: "Written informed consent will be obtained
  /// from all participants prior to data collection."
  bool get consentGiven => throw _privateConstructorUsedError;

  /// Timestamp when consent was recorded in-app.
  DateTime? get consentTimestamp => throw _privateConstructorUsedError;

  /// Optional: device model used (for NFR3 portability analysis).
  String? get deviceModel => throw _privateConstructorUsedError;
  String? get osVersion => throw _privateConstructorUsedError;

  /// Optional free-text notes added by researcher after session.
  String? get researcherNotes => throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {String userId,
      DateTime enrolledAt,
      StudyGroup studyGroup,
      AgeRange ageRange,
      PriorCprTraining priorCprTraining,
      String languagePreference,
      bool consentGiven,
      DateTime? consentTimestamp,
      String? deviceModel,
      String? osVersion,
      String? researcherNotes});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? enrolledAt = null,
    Object? studyGroup = null,
    Object? ageRange = null,
    Object? priorCprTraining = null,
    Object? languagePreference = null,
    Object? consentGiven = null,
    Object? consentTimestamp = freezed,
    Object? deviceModel = freezed,
    Object? osVersion = freezed,
    Object? researcherNotes = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      enrolledAt: null == enrolledAt
          ? _value.enrolledAt
          : enrolledAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      studyGroup: null == studyGroup
          ? _value.studyGroup
          : studyGroup // ignore: cast_nullable_to_non_nullable
              as StudyGroup,
      ageRange: null == ageRange
          ? _value.ageRange
          : ageRange // ignore: cast_nullable_to_non_nullable
              as AgeRange,
      priorCprTraining: null == priorCprTraining
          ? _value.priorCprTraining
          : priorCprTraining // ignore: cast_nullable_to_non_nullable
              as PriorCprTraining,
      languagePreference: null == languagePreference
          ? _value.languagePreference
          : languagePreference // ignore: cast_nullable_to_non_nullable
              as String,
      consentGiven: null == consentGiven
          ? _value.consentGiven
          : consentGiven // ignore: cast_nullable_to_non_nullable
              as bool,
      consentTimestamp: freezed == consentTimestamp
          ? _value.consentTimestamp
          : consentTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deviceModel: freezed == deviceModel
          ? _value.deviceModel
          : deviceModel // ignore: cast_nullable_to_non_nullable
              as String?,
      osVersion: freezed == osVersion
          ? _value.osVersion
          : osVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      researcherNotes: freezed == researcherNotes
          ? _value.researcherNotes
          : researcherNotes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      DateTime enrolledAt,
      StudyGroup studyGroup,
      AgeRange ageRange,
      PriorCprTraining priorCprTraining,
      String languagePreference,
      bool consentGiven,
      DateTime? consentTimestamp,
      String? deviceModel,
      String? osVersion,
      String? researcherNotes});
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? enrolledAt = null,
    Object? studyGroup = null,
    Object? ageRange = null,
    Object? priorCprTraining = null,
    Object? languagePreference = null,
    Object? consentGiven = null,
    Object? consentTimestamp = freezed,
    Object? deviceModel = freezed,
    Object? osVersion = freezed,
    Object? researcherNotes = freezed,
  }) {
    return _then(_$UserProfileImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      enrolledAt: null == enrolledAt
          ? _value.enrolledAt
          : enrolledAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      studyGroup: null == studyGroup
          ? _value.studyGroup
          : studyGroup // ignore: cast_nullable_to_non_nullable
              as StudyGroup,
      ageRange: null == ageRange
          ? _value.ageRange
          : ageRange // ignore: cast_nullable_to_non_nullable
              as AgeRange,
      priorCprTraining: null == priorCprTraining
          ? _value.priorCprTraining
          : priorCprTraining // ignore: cast_nullable_to_non_nullable
              as PriorCprTraining,
      languagePreference: null == languagePreference
          ? _value.languagePreference
          : languagePreference // ignore: cast_nullable_to_non_nullable
              as String,
      consentGiven: null == consentGiven
          ? _value.consentGiven
          : consentGiven // ignore: cast_nullable_to_non_nullable
              as bool,
      consentTimestamp: freezed == consentTimestamp
          ? _value.consentTimestamp
          : consentTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deviceModel: freezed == deviceModel
          ? _value.deviceModel
          : deviceModel // ignore: cast_nullable_to_non_nullable
              as String?,
      osVersion: freezed == osVersion
          ? _value.osVersion
          : osVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      researcherNotes: freezed == researcherNotes
          ? _value.researcherNotes
          : researcherNotes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {required this.userId,
      required this.enrolledAt,
      required this.studyGroup,
      required this.ageRange,
      required this.priorCprTraining,
      this.languagePreference = 'en',
      this.consentGiven = false,
      this.consentTimestamp,
      this.deviceModel,
      this.osVersion,
      this.researcherNotes});

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  /// Anonymous participant ID (e.g. "P001"). Never contains real name.
  @override
  final String userId;
  @override
  final DateTime enrolledAt;

  /// Pilot study group assignment.
  @override
  final StudyGroup studyGroup;

  /// Demographic — age band only (no DOB collected).
  @override
  final AgeRange ageRange;

  /// Self-reported prior CPR experience.
  @override
  final PriorCprTraining priorCprTraining;

  /// Preferred coaching language for this participant.
  @override
  @JsonKey()
  final String languagePreference;

  /// Written informed consent obtained (must be true before any recording).
  /// §3.8 Ethical Considerations: "Written informed consent will be obtained
  /// from all participants prior to data collection."
  @override
  @JsonKey()
  final bool consentGiven;

  /// Timestamp when consent was recorded in-app.
  @override
  final DateTime? consentTimestamp;

  /// Optional: device model used (for NFR3 portability analysis).
  @override
  final String? deviceModel;
  @override
  final String? osVersion;

  /// Optional free-text notes added by researcher after session.
  @override
  final String? researcherNotes;

  @override
  String toString() {
    return 'UserProfile(userId: $userId, enrolledAt: $enrolledAt, studyGroup: $studyGroup, ageRange: $ageRange, priorCprTraining: $priorCprTraining, languagePreference: $languagePreference, consentGiven: $consentGiven, consentTimestamp: $consentTimestamp, deviceModel: $deviceModel, osVersion: $osVersion, researcherNotes: $researcherNotes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.enrolledAt, enrolledAt) ||
                other.enrolledAt == enrolledAt) &&
            (identical(other.studyGroup, studyGroup) ||
                other.studyGroup == studyGroup) &&
            (identical(other.ageRange, ageRange) ||
                other.ageRange == ageRange) &&
            (identical(other.priorCprTraining, priorCprTraining) ||
                other.priorCprTraining == priorCprTraining) &&
            (identical(other.languagePreference, languagePreference) ||
                other.languagePreference == languagePreference) &&
            (identical(other.consentGiven, consentGiven) ||
                other.consentGiven == consentGiven) &&
            (identical(other.consentTimestamp, consentTimestamp) ||
                other.consentTimestamp == consentTimestamp) &&
            (identical(other.deviceModel, deviceModel) ||
                other.deviceModel == deviceModel) &&
            (identical(other.osVersion, osVersion) ||
                other.osVersion == osVersion) &&
            (identical(other.researcherNotes, researcherNotes) ||
                other.researcherNotes == researcherNotes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      userId,
      enrolledAt,
      studyGroup,
      ageRange,
      priorCprTraining,
      languagePreference,
      consentGiven,
      consentTimestamp,
      deviceModel,
      osVersion,
      researcherNotes);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
      {required final String userId,
      required final DateTime enrolledAt,
      required final StudyGroup studyGroup,
      required final AgeRange ageRange,
      required final PriorCprTraining priorCprTraining,
      final String languagePreference,
      final bool consentGiven,
      final DateTime? consentTimestamp,
      final String? deviceModel,
      final String? osVersion,
      final String? researcherNotes}) = _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  /// Anonymous participant ID (e.g. "P001"). Never contains real name.
  @override
  String get userId;
  @override
  DateTime get enrolledAt;

  /// Pilot study group assignment.
  @override
  StudyGroup get studyGroup;

  /// Demographic — age band only (no DOB collected).
  @override
  AgeRange get ageRange;

  /// Self-reported prior CPR experience.
  @override
  PriorCprTraining get priorCprTraining;

  /// Preferred coaching language for this participant.
  @override
  String get languagePreference;

  /// Written informed consent obtained (must be true before any recording).
  /// §3.8 Ethical Considerations: "Written informed consent will be obtained
  /// from all participants prior to data collection."
  @override
  bool get consentGiven;

  /// Timestamp when consent was recorded in-app.
  @override
  DateTime? get consentTimestamp;

  /// Optional: device model used (for NFR3 portability analysis).
  @override
  String? get deviceModel;
  @override
  String? get osVersion;

  /// Optional free-text notes added by researcher after session.
  @override
  String? get researcherNotes;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ResearchSession _$ResearchSessionFromJson(Map<String, dynamic> json) {
  return _ResearchSession.fromJson(json);
}

/// @nodoc
mixin _$ResearchSession {
  String get sessionId => throw _privateConstructorUsedError;
  String get userId =>
      throw _privateConstructorUsedError; // FK → UserProfile.userId
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime get endTime => throw _privateConstructorUsedError;
  String get deviceModel => throw _privateConstructorUsedError;
  String get osVersion => throw _privateConstructorUsedError;

  /// Study group — copied from UserProfile for convenience in analysis.
  StudyGroup get studyGroup => throw _privateConstructorUsedError;

  /// Whether the ML model was active (false = rule-based fallback).
  bool get modelWasActive => throw _privateConstructorUsedError;

  /// Coaching language used during this session.
  String get language =>
      throw _privateConstructorUsedError; // ── Aggregate performance metrics (computed at session end) ──────────
  /// Total compressions detected via wrist-velocity peak detection.
  int get totalCompressions => throw _privateConstructorUsedError;

  /// Mean compression rate across session (bpm). Target: 100–120.
  double get meanBpm => throw _privateConstructorUsedError;

  /// Standard deviation of compression rate (consistency metric).
  double get bpmStdDev => throw _privateConstructorUsedError;

  /// Mean estimated compression depth (cm). Target: 5.0–6.0.
  double get meanDepthCm => throw _privateConstructorUsedError;

  /// % frames classified as 'correct_compression' or 'good'.
  double get handPlacementAccuracyPct => throw _privateConstructorUsedError;

  /// % frames where mean elbow angle ≥ 160° (arms locked).
  double get elbowCompliancePct => throw _privateConstructorUsedError;

  /// Seconds from session start to first compression detected.
  double get timeToFirstCompressionSec => throw _privateConstructorUsedError;

  /// Fraction of session time actively compressing (target ≥ 0.6).
  double get cprFraction => throw _privateConstructorUsedError;

  /// Composite quality score 0–100 (internal metric).
  int get qualityScore => throw _privateConstructorUsedError;

  /// Per-error-class mean confidence scores over the session.
  Map<String, double> get errorRates =>
      throw _privateConstructorUsedError; // ── Post-session survey scores (entered by researcher/participant) ──
  /// System Usability Scale total score (0–100).
  /// Target: SUS ≥ 68 (acceptable threshold, per NFR4).
  /// Null until survey completed.
  double? get susScore => throw _privateConstructorUsedError;

  /// NASA Task Load Index total score (0–100 weighted).
  /// Lower = less cognitive load. Target: ≤ 40.
  double? get nasaTlxScore => throw _privateConstructorUsedError;

  /// NASA-TLX subscale breakdown (6 items × 0–100).
  Map<String, double> get nasaTlxSubscales =>
      throw _privateConstructorUsedError;

  /// Pre-session self-efficacy Likert mean (1–7 scale).
  double? get selfEfficacyPre => throw _privateConstructorUsedError;

  /// Post-session self-efficacy Likert mean (1–7 scale).
  double? get selfEfficacyPost => throw _privateConstructorUsedError;

  /// SUS individual item responses (10 items, 1–5 Likert).
  List<int> get susItemResponses => throw _privateConstructorUsedError;

  /// Serializes this ResearchSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ResearchSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResearchSessionCopyWith<ResearchSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResearchSessionCopyWith<$Res> {
  factory $ResearchSessionCopyWith(
          ResearchSession value, $Res Function(ResearchSession) then) =
      _$ResearchSessionCopyWithImpl<$Res, ResearchSession>;
  @useResult
  $Res call(
      {String sessionId,
      String userId,
      DateTime startTime,
      DateTime endTime,
      String deviceModel,
      String osVersion,
      StudyGroup studyGroup,
      bool modelWasActive,
      String language,
      int totalCompressions,
      double meanBpm,
      double bpmStdDev,
      double meanDepthCm,
      double handPlacementAccuracyPct,
      double elbowCompliancePct,
      double timeToFirstCompressionSec,
      double cprFraction,
      int qualityScore,
      Map<String, double> errorRates,
      double? susScore,
      double? nasaTlxScore,
      Map<String, double> nasaTlxSubscales,
      double? selfEfficacyPre,
      double? selfEfficacyPost,
      List<int> susItemResponses});
}

/// @nodoc
class _$ResearchSessionCopyWithImpl<$Res, $Val extends ResearchSession>
    implements $ResearchSessionCopyWith<$Res> {
  _$ResearchSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ResearchSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? userId = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? deviceModel = null,
    Object? osVersion = null,
    Object? studyGroup = null,
    Object? modelWasActive = null,
    Object? language = null,
    Object? totalCompressions = null,
    Object? meanBpm = null,
    Object? bpmStdDev = null,
    Object? meanDepthCm = null,
    Object? handPlacementAccuracyPct = null,
    Object? elbowCompliancePct = null,
    Object? timeToFirstCompressionSec = null,
    Object? cprFraction = null,
    Object? qualityScore = null,
    Object? errorRates = null,
    Object? susScore = freezed,
    Object? nasaTlxScore = freezed,
    Object? nasaTlxSubscales = null,
    Object? selfEfficacyPre = freezed,
    Object? selfEfficacyPost = freezed,
    Object? susItemResponses = null,
  }) {
    return _then(_value.copyWith(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deviceModel: null == deviceModel
          ? _value.deviceModel
          : deviceModel // ignore: cast_nullable_to_non_nullable
              as String,
      osVersion: null == osVersion
          ? _value.osVersion
          : osVersion // ignore: cast_nullable_to_non_nullable
              as String,
      studyGroup: null == studyGroup
          ? _value.studyGroup
          : studyGroup // ignore: cast_nullable_to_non_nullable
              as StudyGroup,
      modelWasActive: null == modelWasActive
          ? _value.modelWasActive
          : modelWasActive // ignore: cast_nullable_to_non_nullable
              as bool,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      totalCompressions: null == totalCompressions
          ? _value.totalCompressions
          : totalCompressions // ignore: cast_nullable_to_non_nullable
              as int,
      meanBpm: null == meanBpm
          ? _value.meanBpm
          : meanBpm // ignore: cast_nullable_to_non_nullable
              as double,
      bpmStdDev: null == bpmStdDev
          ? _value.bpmStdDev
          : bpmStdDev // ignore: cast_nullable_to_non_nullable
              as double,
      meanDepthCm: null == meanDepthCm
          ? _value.meanDepthCm
          : meanDepthCm // ignore: cast_nullable_to_non_nullable
              as double,
      handPlacementAccuracyPct: null == handPlacementAccuracyPct
          ? _value.handPlacementAccuracyPct
          : handPlacementAccuracyPct // ignore: cast_nullable_to_non_nullable
              as double,
      elbowCompliancePct: null == elbowCompliancePct
          ? _value.elbowCompliancePct
          : elbowCompliancePct // ignore: cast_nullable_to_non_nullable
              as double,
      timeToFirstCompressionSec: null == timeToFirstCompressionSec
          ? _value.timeToFirstCompressionSec
          : timeToFirstCompressionSec // ignore: cast_nullable_to_non_nullable
              as double,
      cprFraction: null == cprFraction
          ? _value.cprFraction
          : cprFraction // ignore: cast_nullable_to_non_nullable
              as double,
      qualityScore: null == qualityScore
          ? _value.qualityScore
          : qualityScore // ignore: cast_nullable_to_non_nullable
              as int,
      errorRates: null == errorRates
          ? _value.errorRates
          : errorRates // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      susScore: freezed == susScore
          ? _value.susScore
          : susScore // ignore: cast_nullable_to_non_nullable
              as double?,
      nasaTlxScore: freezed == nasaTlxScore
          ? _value.nasaTlxScore
          : nasaTlxScore // ignore: cast_nullable_to_non_nullable
              as double?,
      nasaTlxSubscales: null == nasaTlxSubscales
          ? _value.nasaTlxSubscales
          : nasaTlxSubscales // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      selfEfficacyPre: freezed == selfEfficacyPre
          ? _value.selfEfficacyPre
          : selfEfficacyPre // ignore: cast_nullable_to_non_nullable
              as double?,
      selfEfficacyPost: freezed == selfEfficacyPost
          ? _value.selfEfficacyPost
          : selfEfficacyPost // ignore: cast_nullable_to_non_nullable
              as double?,
      susItemResponses: null == susItemResponses
          ? _value.susItemResponses
          : susItemResponses // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ResearchSessionImplCopyWith<$Res>
    implements $ResearchSessionCopyWith<$Res> {
  factory _$$ResearchSessionImplCopyWith(_$ResearchSessionImpl value,
          $Res Function(_$ResearchSessionImpl) then) =
      __$$ResearchSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sessionId,
      String userId,
      DateTime startTime,
      DateTime endTime,
      String deviceModel,
      String osVersion,
      StudyGroup studyGroup,
      bool modelWasActive,
      String language,
      int totalCompressions,
      double meanBpm,
      double bpmStdDev,
      double meanDepthCm,
      double handPlacementAccuracyPct,
      double elbowCompliancePct,
      double timeToFirstCompressionSec,
      double cprFraction,
      int qualityScore,
      Map<String, double> errorRates,
      double? susScore,
      double? nasaTlxScore,
      Map<String, double> nasaTlxSubscales,
      double? selfEfficacyPre,
      double? selfEfficacyPost,
      List<int> susItemResponses});
}

/// @nodoc
class __$$ResearchSessionImplCopyWithImpl<$Res>
    extends _$ResearchSessionCopyWithImpl<$Res, _$ResearchSessionImpl>
    implements _$$ResearchSessionImplCopyWith<$Res> {
  __$$ResearchSessionImplCopyWithImpl(
      _$ResearchSessionImpl _value, $Res Function(_$ResearchSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ResearchSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? userId = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? deviceModel = null,
    Object? osVersion = null,
    Object? studyGroup = null,
    Object? modelWasActive = null,
    Object? language = null,
    Object? totalCompressions = null,
    Object? meanBpm = null,
    Object? bpmStdDev = null,
    Object? meanDepthCm = null,
    Object? handPlacementAccuracyPct = null,
    Object? elbowCompliancePct = null,
    Object? timeToFirstCompressionSec = null,
    Object? cprFraction = null,
    Object? qualityScore = null,
    Object? errorRates = null,
    Object? susScore = freezed,
    Object? nasaTlxScore = freezed,
    Object? nasaTlxSubscales = null,
    Object? selfEfficacyPre = freezed,
    Object? selfEfficacyPost = freezed,
    Object? susItemResponses = null,
  }) {
    return _then(_$ResearchSessionImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deviceModel: null == deviceModel
          ? _value.deviceModel
          : deviceModel // ignore: cast_nullable_to_non_nullable
              as String,
      osVersion: null == osVersion
          ? _value.osVersion
          : osVersion // ignore: cast_nullable_to_non_nullable
              as String,
      studyGroup: null == studyGroup
          ? _value.studyGroup
          : studyGroup // ignore: cast_nullable_to_non_nullable
              as StudyGroup,
      modelWasActive: null == modelWasActive
          ? _value.modelWasActive
          : modelWasActive // ignore: cast_nullable_to_non_nullable
              as bool,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      totalCompressions: null == totalCompressions
          ? _value.totalCompressions
          : totalCompressions // ignore: cast_nullable_to_non_nullable
              as int,
      meanBpm: null == meanBpm
          ? _value.meanBpm
          : meanBpm // ignore: cast_nullable_to_non_nullable
              as double,
      bpmStdDev: null == bpmStdDev
          ? _value.bpmStdDev
          : bpmStdDev // ignore: cast_nullable_to_non_nullable
              as double,
      meanDepthCm: null == meanDepthCm
          ? _value.meanDepthCm
          : meanDepthCm // ignore: cast_nullable_to_non_nullable
              as double,
      handPlacementAccuracyPct: null == handPlacementAccuracyPct
          ? _value.handPlacementAccuracyPct
          : handPlacementAccuracyPct // ignore: cast_nullable_to_non_nullable
              as double,
      elbowCompliancePct: null == elbowCompliancePct
          ? _value.elbowCompliancePct
          : elbowCompliancePct // ignore: cast_nullable_to_non_nullable
              as double,
      timeToFirstCompressionSec: null == timeToFirstCompressionSec
          ? _value.timeToFirstCompressionSec
          : timeToFirstCompressionSec // ignore: cast_nullable_to_non_nullable
              as double,
      cprFraction: null == cprFraction
          ? _value.cprFraction
          : cprFraction // ignore: cast_nullable_to_non_nullable
              as double,
      qualityScore: null == qualityScore
          ? _value.qualityScore
          : qualityScore // ignore: cast_nullable_to_non_nullable
              as int,
      errorRates: null == errorRates
          ? _value._errorRates
          : errorRates // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      susScore: freezed == susScore
          ? _value.susScore
          : susScore // ignore: cast_nullable_to_non_nullable
              as double?,
      nasaTlxScore: freezed == nasaTlxScore
          ? _value.nasaTlxScore
          : nasaTlxScore // ignore: cast_nullable_to_non_nullable
              as double?,
      nasaTlxSubscales: null == nasaTlxSubscales
          ? _value._nasaTlxSubscales
          : nasaTlxSubscales // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      selfEfficacyPre: freezed == selfEfficacyPre
          ? _value.selfEfficacyPre
          : selfEfficacyPre // ignore: cast_nullable_to_non_nullable
              as double?,
      selfEfficacyPost: freezed == selfEfficacyPost
          ? _value.selfEfficacyPost
          : selfEfficacyPost // ignore: cast_nullable_to_non_nullable
              as double?,
      susItemResponses: null == susItemResponses
          ? _value._susItemResponses
          : susItemResponses // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ResearchSessionImpl implements _ResearchSession {
  const _$ResearchSessionImpl(
      {required this.sessionId,
      required this.userId,
      required this.startTime,
      required this.endTime,
      required this.deviceModel,
      required this.osVersion,
      required this.studyGroup,
      this.modelWasActive = false,
      this.language = 'en',
      this.totalCompressions = 0,
      this.meanBpm = 0.0,
      this.bpmStdDev = 0.0,
      this.meanDepthCm = 0.0,
      this.handPlacementAccuracyPct = 0.0,
      this.elbowCompliancePct = 0.0,
      this.timeToFirstCompressionSec = 0.0,
      this.cprFraction = 0.0,
      this.qualityScore = 0,
      final Map<String, double> errorRates = const {},
      this.susScore,
      this.nasaTlxScore,
      final Map<String, double> nasaTlxSubscales = const {},
      this.selfEfficacyPre,
      this.selfEfficacyPost,
      final List<int> susItemResponses = const []})
      : _errorRates = errorRates,
        _nasaTlxSubscales = nasaTlxSubscales,
        _susItemResponses = susItemResponses;

  factory _$ResearchSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResearchSessionImplFromJson(json);

  @override
  final String sessionId;
  @override
  final String userId;
// FK → UserProfile.userId
  @override
  final DateTime startTime;
  @override
  final DateTime endTime;
  @override
  final String deviceModel;
  @override
  final String osVersion;

  /// Study group — copied from UserProfile for convenience in analysis.
  @override
  final StudyGroup studyGroup;

  /// Whether the ML model was active (false = rule-based fallback).
  @override
  @JsonKey()
  final bool modelWasActive;

  /// Coaching language used during this session.
  @override
  @JsonKey()
  final String language;
// ── Aggregate performance metrics (computed at session end) ──────────
  /// Total compressions detected via wrist-velocity peak detection.
  @override
  @JsonKey()
  final int totalCompressions;

  /// Mean compression rate across session (bpm). Target: 100–120.
  @override
  @JsonKey()
  final double meanBpm;

  /// Standard deviation of compression rate (consistency metric).
  @override
  @JsonKey()
  final double bpmStdDev;

  /// Mean estimated compression depth (cm). Target: 5.0–6.0.
  @override
  @JsonKey()
  final double meanDepthCm;

  /// % frames classified as 'correct_compression' or 'good'.
  @override
  @JsonKey()
  final double handPlacementAccuracyPct;

  /// % frames where mean elbow angle ≥ 160° (arms locked).
  @override
  @JsonKey()
  final double elbowCompliancePct;

  /// Seconds from session start to first compression detected.
  @override
  @JsonKey()
  final double timeToFirstCompressionSec;

  /// Fraction of session time actively compressing (target ≥ 0.6).
  @override
  @JsonKey()
  final double cprFraction;

  /// Composite quality score 0–100 (internal metric).
  @override
  @JsonKey()
  final int qualityScore;

  /// Per-error-class mean confidence scores over the session.
  final Map<String, double> _errorRates;

  /// Per-error-class mean confidence scores over the session.
  @override
  @JsonKey()
  Map<String, double> get errorRates {
    if (_errorRates is EqualUnmodifiableMapView) return _errorRates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_errorRates);
  }

// ── Post-session survey scores (entered by researcher/participant) ──
  /// System Usability Scale total score (0–100).
  /// Target: SUS ≥ 68 (acceptable threshold, per NFR4).
  /// Null until survey completed.
  @override
  final double? susScore;

  /// NASA Task Load Index total score (0–100 weighted).
  /// Lower = less cognitive load. Target: ≤ 40.
  @override
  final double? nasaTlxScore;

  /// NASA-TLX subscale breakdown (6 items × 0–100).
  final Map<String, double> _nasaTlxSubscales;

  /// NASA-TLX subscale breakdown (6 items × 0–100).
  @override
  @JsonKey()
  Map<String, double> get nasaTlxSubscales {
    if (_nasaTlxSubscales is EqualUnmodifiableMapView) return _nasaTlxSubscales;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_nasaTlxSubscales);
  }

  /// Pre-session self-efficacy Likert mean (1–7 scale).
  @override
  final double? selfEfficacyPre;

  /// Post-session self-efficacy Likert mean (1–7 scale).
  @override
  final double? selfEfficacyPost;

  /// SUS individual item responses (10 items, 1–5 Likert).
  final List<int> _susItemResponses;

  /// SUS individual item responses (10 items, 1–5 Likert).
  @override
  @JsonKey()
  List<int> get susItemResponses {
    if (_susItemResponses is EqualUnmodifiableListView)
      return _susItemResponses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_susItemResponses);
  }

  @override
  String toString() {
    return 'ResearchSession(sessionId: $sessionId, userId: $userId, startTime: $startTime, endTime: $endTime, deviceModel: $deviceModel, osVersion: $osVersion, studyGroup: $studyGroup, modelWasActive: $modelWasActive, language: $language, totalCompressions: $totalCompressions, meanBpm: $meanBpm, bpmStdDev: $bpmStdDev, meanDepthCm: $meanDepthCm, handPlacementAccuracyPct: $handPlacementAccuracyPct, elbowCompliancePct: $elbowCompliancePct, timeToFirstCompressionSec: $timeToFirstCompressionSec, cprFraction: $cprFraction, qualityScore: $qualityScore, errorRates: $errorRates, susScore: $susScore, nasaTlxScore: $nasaTlxScore, nasaTlxSubscales: $nasaTlxSubscales, selfEfficacyPre: $selfEfficacyPre, selfEfficacyPost: $selfEfficacyPost, susItemResponses: $susItemResponses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResearchSessionImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.deviceModel, deviceModel) ||
                other.deviceModel == deviceModel) &&
            (identical(other.osVersion, osVersion) ||
                other.osVersion == osVersion) &&
            (identical(other.studyGroup, studyGroup) ||
                other.studyGroup == studyGroup) &&
            (identical(other.modelWasActive, modelWasActive) ||
                other.modelWasActive == modelWasActive) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.totalCompressions, totalCompressions) ||
                other.totalCompressions == totalCompressions) &&
            (identical(other.meanBpm, meanBpm) || other.meanBpm == meanBpm) &&
            (identical(other.bpmStdDev, bpmStdDev) ||
                other.bpmStdDev == bpmStdDev) &&
            (identical(other.meanDepthCm, meanDepthCm) ||
                other.meanDepthCm == meanDepthCm) &&
            (identical(
                    other.handPlacementAccuracyPct, handPlacementAccuracyPct) ||
                other.handPlacementAccuracyPct == handPlacementAccuracyPct) &&
            (identical(other.elbowCompliancePct, elbowCompliancePct) ||
                other.elbowCompliancePct == elbowCompliancePct) &&
            (identical(other.timeToFirstCompressionSec,
                    timeToFirstCompressionSec) ||
                other.timeToFirstCompressionSec == timeToFirstCompressionSec) &&
            (identical(other.cprFraction, cprFraction) ||
                other.cprFraction == cprFraction) &&
            (identical(other.qualityScore, qualityScore) ||
                other.qualityScore == qualityScore) &&
            const DeepCollectionEquality()
                .equals(other._errorRates, _errorRates) &&
            (identical(other.susScore, susScore) ||
                other.susScore == susScore) &&
            (identical(other.nasaTlxScore, nasaTlxScore) ||
                other.nasaTlxScore == nasaTlxScore) &&
            const DeepCollectionEquality()
                .equals(other._nasaTlxSubscales, _nasaTlxSubscales) &&
            (identical(other.selfEfficacyPre, selfEfficacyPre) ||
                other.selfEfficacyPre == selfEfficacyPre) &&
            (identical(other.selfEfficacyPost, selfEfficacyPost) ||
                other.selfEfficacyPost == selfEfficacyPost) &&
            const DeepCollectionEquality()
                .equals(other._susItemResponses, _susItemResponses));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        sessionId,
        userId,
        startTime,
        endTime,
        deviceModel,
        osVersion,
        studyGroup,
        modelWasActive,
        language,
        totalCompressions,
        meanBpm,
        bpmStdDev,
        meanDepthCm,
        handPlacementAccuracyPct,
        elbowCompliancePct,
        timeToFirstCompressionSec,
        cprFraction,
        qualityScore,
        const DeepCollectionEquality().hash(_errorRates),
        susScore,
        nasaTlxScore,
        const DeepCollectionEquality().hash(_nasaTlxSubscales),
        selfEfficacyPre,
        selfEfficacyPost,
        const DeepCollectionEquality().hash(_susItemResponses)
      ]);

  /// Create a copy of ResearchSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResearchSessionImplCopyWith<_$ResearchSessionImpl> get copyWith =>
      __$$ResearchSessionImplCopyWithImpl<_$ResearchSessionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ResearchSessionImplToJson(
      this,
    );
  }
}

abstract class _ResearchSession implements ResearchSession {
  const factory _ResearchSession(
      {required final String sessionId,
      required final String userId,
      required final DateTime startTime,
      required final DateTime endTime,
      required final String deviceModel,
      required final String osVersion,
      required final StudyGroup studyGroup,
      final bool modelWasActive,
      final String language,
      final int totalCompressions,
      final double meanBpm,
      final double bpmStdDev,
      final double meanDepthCm,
      final double handPlacementAccuracyPct,
      final double elbowCompliancePct,
      final double timeToFirstCompressionSec,
      final double cprFraction,
      final int qualityScore,
      final Map<String, double> errorRates,
      final double? susScore,
      final double? nasaTlxScore,
      final Map<String, double> nasaTlxSubscales,
      final double? selfEfficacyPre,
      final double? selfEfficacyPost,
      final List<int> susItemResponses}) = _$ResearchSessionImpl;

  factory _ResearchSession.fromJson(Map<String, dynamic> json) =
      _$ResearchSessionImpl.fromJson;

  @override
  String get sessionId;
  @override
  String get userId; // FK → UserProfile.userId
  @override
  DateTime get startTime;
  @override
  DateTime get endTime;
  @override
  String get deviceModel;
  @override
  String get osVersion;

  /// Study group — copied from UserProfile for convenience in analysis.
  @override
  StudyGroup get studyGroup;

  /// Whether the ML model was active (false = rule-based fallback).
  @override
  bool get modelWasActive;

  /// Coaching language used during this session.
  @override
  String
      get language; // ── Aggregate performance metrics (computed at session end) ──────────
  /// Total compressions detected via wrist-velocity peak detection.
  @override
  int get totalCompressions;

  /// Mean compression rate across session (bpm). Target: 100–120.
  @override
  double get meanBpm;

  /// Standard deviation of compression rate (consistency metric).
  @override
  double get bpmStdDev;

  /// Mean estimated compression depth (cm). Target: 5.0–6.0.
  @override
  double get meanDepthCm;

  /// % frames classified as 'correct_compression' or 'good'.
  @override
  double get handPlacementAccuracyPct;

  /// % frames where mean elbow angle ≥ 160° (arms locked).
  @override
  double get elbowCompliancePct;

  /// Seconds from session start to first compression detected.
  @override
  double get timeToFirstCompressionSec;

  /// Fraction of session time actively compressing (target ≥ 0.6).
  @override
  double get cprFraction;

  /// Composite quality score 0–100 (internal metric).
  @override
  int get qualityScore;

  /// Per-error-class mean confidence scores over the session.
  @override
  Map<String, double>
      get errorRates; // ── Post-session survey scores (entered by researcher/participant) ──
  /// System Usability Scale total score (0–100).
  /// Target: SUS ≥ 68 (acceptable threshold, per NFR4).
  /// Null until survey completed.
  @override
  double? get susScore;

  /// NASA Task Load Index total score (0–100 weighted).
  /// Lower = less cognitive load. Target: ≤ 40.
  @override
  double? get nasaTlxScore;

  /// NASA-TLX subscale breakdown (6 items × 0–100).
  @override
  Map<String, double> get nasaTlxSubscales;

  /// Pre-session self-efficacy Likert mean (1–7 scale).
  @override
  double? get selfEfficacyPre;

  /// Post-session self-efficacy Likert mean (1–7 scale).
  @override
  double? get selfEfficacyPost;

  /// SUS individual item responses (10 items, 1–5 Likert).
  @override
  List<int> get susItemResponses;

  /// Create a copy of ResearchSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResearchSessionImplCopyWith<_$ResearchSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FrameRecord _$FrameRecordFromJson(Map<String, dynamic> json) {
  return _FrameRecord.fromJson(json);
}

/// @nodoc
mixin _$FrameRecord {
  String get frameId => throw _privateConstructorUsedError;
  String get sessionId =>
      throw _privateConstructorUsedError; // FK → ResearchSession.sessionId
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// BiLSTM or rule-based output class label.
  String get errorClass => throw _privateConstructorUsedError;

  /// Confidence score for errorClass (0.0–1.0).
  double get confidenceScore => throw _privateConstructorUsedError;

  /// Rule-based BPM estimate at this frame.
  double get bpmEstimate => throw _privateConstructorUsedError;

  /// Normalised wrist displacement (depth proxy, 0.0–1.0).
  double get wristDepthProxy => throw _privateConstructorUsedError;

  /// Mean of left + right elbow angles (degrees).
  double get elbowAngleMean => throw _privateConstructorUsedError;

  /// Spine verticality angle (degrees from vertical; 0 = correct).
  double get spineVerticalityDeg => throw _privateConstructorUsedError;

  /// Whether all key landmarks had visibility ≥ minLandmarkVisibility.
  bool get allLandmarksVisible => throw _privateConstructorUsedError;

  /// Was this frame produced by the TFLite model (true) or rule-based (false)?
  bool get fromModel => throw _privateConstructorUsedError;

  /// Serializes this FrameRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FrameRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FrameRecordCopyWith<FrameRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FrameRecordCopyWith<$Res> {
  factory $FrameRecordCopyWith(
          FrameRecord value, $Res Function(FrameRecord) then) =
      _$FrameRecordCopyWithImpl<$Res, FrameRecord>;
  @useResult
  $Res call(
      {String frameId,
      String sessionId,
      DateTime timestamp,
      String errorClass,
      double confidenceScore,
      double bpmEstimate,
      double wristDepthProxy,
      double elbowAngleMean,
      double spineVerticalityDeg,
      bool allLandmarksVisible,
      bool fromModel});
}

/// @nodoc
class _$FrameRecordCopyWithImpl<$Res, $Val extends FrameRecord>
    implements $FrameRecordCopyWith<$Res> {
  _$FrameRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FrameRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frameId = null,
    Object? sessionId = null,
    Object? timestamp = null,
    Object? errorClass = null,
    Object? confidenceScore = null,
    Object? bpmEstimate = null,
    Object? wristDepthProxy = null,
    Object? elbowAngleMean = null,
    Object? spineVerticalityDeg = null,
    Object? allLandmarksVisible = null,
    Object? fromModel = null,
  }) {
    return _then(_value.copyWith(
      frameId: null == frameId
          ? _value.frameId
          : frameId // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      errorClass: null == errorClass
          ? _value.errorClass
          : errorClass // ignore: cast_nullable_to_non_nullable
              as String,
      confidenceScore: null == confidenceScore
          ? _value.confidenceScore
          : confidenceScore // ignore: cast_nullable_to_non_nullable
              as double,
      bpmEstimate: null == bpmEstimate
          ? _value.bpmEstimate
          : bpmEstimate // ignore: cast_nullable_to_non_nullable
              as double,
      wristDepthProxy: null == wristDepthProxy
          ? _value.wristDepthProxy
          : wristDepthProxy // ignore: cast_nullable_to_non_nullable
              as double,
      elbowAngleMean: null == elbowAngleMean
          ? _value.elbowAngleMean
          : elbowAngleMean // ignore: cast_nullable_to_non_nullable
              as double,
      spineVerticalityDeg: null == spineVerticalityDeg
          ? _value.spineVerticalityDeg
          : spineVerticalityDeg // ignore: cast_nullable_to_non_nullable
              as double,
      allLandmarksVisible: null == allLandmarksVisible
          ? _value.allLandmarksVisible
          : allLandmarksVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      fromModel: null == fromModel
          ? _value.fromModel
          : fromModel // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FrameRecordImplCopyWith<$Res>
    implements $FrameRecordCopyWith<$Res> {
  factory _$$FrameRecordImplCopyWith(
          _$FrameRecordImpl value, $Res Function(_$FrameRecordImpl) then) =
      __$$FrameRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String frameId,
      String sessionId,
      DateTime timestamp,
      String errorClass,
      double confidenceScore,
      double bpmEstimate,
      double wristDepthProxy,
      double elbowAngleMean,
      double spineVerticalityDeg,
      bool allLandmarksVisible,
      bool fromModel});
}

/// @nodoc
class __$$FrameRecordImplCopyWithImpl<$Res>
    extends _$FrameRecordCopyWithImpl<$Res, _$FrameRecordImpl>
    implements _$$FrameRecordImplCopyWith<$Res> {
  __$$FrameRecordImplCopyWithImpl(
      _$FrameRecordImpl _value, $Res Function(_$FrameRecordImpl) _then)
      : super(_value, _then);

  /// Create a copy of FrameRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frameId = null,
    Object? sessionId = null,
    Object? timestamp = null,
    Object? errorClass = null,
    Object? confidenceScore = null,
    Object? bpmEstimate = null,
    Object? wristDepthProxy = null,
    Object? elbowAngleMean = null,
    Object? spineVerticalityDeg = null,
    Object? allLandmarksVisible = null,
    Object? fromModel = null,
  }) {
    return _then(_$FrameRecordImpl(
      frameId: null == frameId
          ? _value.frameId
          : frameId // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      errorClass: null == errorClass
          ? _value.errorClass
          : errorClass // ignore: cast_nullable_to_non_nullable
              as String,
      confidenceScore: null == confidenceScore
          ? _value.confidenceScore
          : confidenceScore // ignore: cast_nullable_to_non_nullable
              as double,
      bpmEstimate: null == bpmEstimate
          ? _value.bpmEstimate
          : bpmEstimate // ignore: cast_nullable_to_non_nullable
              as double,
      wristDepthProxy: null == wristDepthProxy
          ? _value.wristDepthProxy
          : wristDepthProxy // ignore: cast_nullable_to_non_nullable
              as double,
      elbowAngleMean: null == elbowAngleMean
          ? _value.elbowAngleMean
          : elbowAngleMean // ignore: cast_nullable_to_non_nullable
              as double,
      spineVerticalityDeg: null == spineVerticalityDeg
          ? _value.spineVerticalityDeg
          : spineVerticalityDeg // ignore: cast_nullable_to_non_nullable
              as double,
      allLandmarksVisible: null == allLandmarksVisible
          ? _value.allLandmarksVisible
          : allLandmarksVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      fromModel: null == fromModel
          ? _value.fromModel
          : fromModel // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FrameRecordImpl implements _FrameRecord {
  const _$FrameRecordImpl(
      {required this.frameId,
      required this.sessionId,
      required this.timestamp,
      required this.errorClass,
      required this.confidenceScore,
      required this.bpmEstimate,
      required this.wristDepthProxy,
      required this.elbowAngleMean,
      required this.spineVerticalityDeg,
      this.allLandmarksVisible = false,
      this.fromModel = false});

  factory _$FrameRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$FrameRecordImplFromJson(json);

  @override
  final String frameId;
  @override
  final String sessionId;
// FK → ResearchSession.sessionId
  @override
  final DateTime timestamp;

  /// BiLSTM or rule-based output class label.
  @override
  final String errorClass;

  /// Confidence score for errorClass (0.0–1.0).
  @override
  final double confidenceScore;

  /// Rule-based BPM estimate at this frame.
  @override
  final double bpmEstimate;

  /// Normalised wrist displacement (depth proxy, 0.0–1.0).
  @override
  final double wristDepthProxy;

  /// Mean of left + right elbow angles (degrees).
  @override
  final double elbowAngleMean;

  /// Spine verticality angle (degrees from vertical; 0 = correct).
  @override
  final double spineVerticalityDeg;

  /// Whether all key landmarks had visibility ≥ minLandmarkVisibility.
  @override
  @JsonKey()
  final bool allLandmarksVisible;

  /// Was this frame produced by the TFLite model (true) or rule-based (false)?
  @override
  @JsonKey()
  final bool fromModel;

  @override
  String toString() {
    return 'FrameRecord(frameId: $frameId, sessionId: $sessionId, timestamp: $timestamp, errorClass: $errorClass, confidenceScore: $confidenceScore, bpmEstimate: $bpmEstimate, wristDepthProxy: $wristDepthProxy, elbowAngleMean: $elbowAngleMean, spineVerticalityDeg: $spineVerticalityDeg, allLandmarksVisible: $allLandmarksVisible, fromModel: $fromModel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FrameRecordImpl &&
            (identical(other.frameId, frameId) || other.frameId == frameId) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.errorClass, errorClass) ||
                other.errorClass == errorClass) &&
            (identical(other.confidenceScore, confidenceScore) ||
                other.confidenceScore == confidenceScore) &&
            (identical(other.bpmEstimate, bpmEstimate) ||
                other.bpmEstimate == bpmEstimate) &&
            (identical(other.wristDepthProxy, wristDepthProxy) ||
                other.wristDepthProxy == wristDepthProxy) &&
            (identical(other.elbowAngleMean, elbowAngleMean) ||
                other.elbowAngleMean == elbowAngleMean) &&
            (identical(other.spineVerticalityDeg, spineVerticalityDeg) ||
                other.spineVerticalityDeg == spineVerticalityDeg) &&
            (identical(other.allLandmarksVisible, allLandmarksVisible) ||
                other.allLandmarksVisible == allLandmarksVisible) &&
            (identical(other.fromModel, fromModel) ||
                other.fromModel == fromModel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      frameId,
      sessionId,
      timestamp,
      errorClass,
      confidenceScore,
      bpmEstimate,
      wristDepthProxy,
      elbowAngleMean,
      spineVerticalityDeg,
      allLandmarksVisible,
      fromModel);

  /// Create a copy of FrameRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FrameRecordImplCopyWith<_$FrameRecordImpl> get copyWith =>
      __$$FrameRecordImplCopyWithImpl<_$FrameRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FrameRecordImplToJson(
      this,
    );
  }
}

abstract class _FrameRecord implements FrameRecord {
  const factory _FrameRecord(
      {required final String frameId,
      required final String sessionId,
      required final DateTime timestamp,
      required final String errorClass,
      required final double confidenceScore,
      required final double bpmEstimate,
      required final double wristDepthProxy,
      required final double elbowAngleMean,
      required final double spineVerticalityDeg,
      final bool allLandmarksVisible,
      final bool fromModel}) = _$FrameRecordImpl;

  factory _FrameRecord.fromJson(Map<String, dynamic> json) =
      _$FrameRecordImpl.fromJson;

  @override
  String get frameId;
  @override
  String get sessionId; // FK → ResearchSession.sessionId
  @override
  DateTime get timestamp;

  /// BiLSTM or rule-based output class label.
  @override
  String get errorClass;

  /// Confidence score for errorClass (0.0–1.0).
  @override
  double get confidenceScore;

  /// Rule-based BPM estimate at this frame.
  @override
  double get bpmEstimate;

  /// Normalised wrist displacement (depth proxy, 0.0–1.0).
  @override
  double get wristDepthProxy;

  /// Mean of left + right elbow angles (degrees).
  @override
  double get elbowAngleMean;

  /// Spine verticality angle (degrees from vertical; 0 = correct).
  @override
  double get spineVerticalityDeg;

  /// Whether all key landmarks had visibility ≥ minLandmarkVisibility.
  @override
  bool get allLandmarksVisible;

  /// Was this frame produced by the TFLite model (true) or rule-based (false)?
  @override
  bool get fromModel;

  /// Create a copy of FrameRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FrameRecordImplCopyWith<_$FrameRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FeedbackEvent _$FeedbackEventFromJson(Map<String, dynamic> json) {
  return _FeedbackEvent.fromJson(json);
}

/// @nodoc
mixin _$FeedbackEvent {
  String get eventId => throw _privateConstructorUsedError;
  String get sessionId =>
      throw _privateConstructorUsedError; // FK → ResearchSession.sessionId
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// The prompt key (e.g. 'bent_elbows', 'rate_too_slow').
  String get promptKey => throw _privateConstructorUsedError;

  /// Language the prompt was delivered in ('en' or 'rw').
  String get language => throw _privateConstructorUsedError;

  /// The error class that triggered this prompt.
  String get triggeredByClass => throw _privateConstructorUsedError;

  /// Severity: 'good' | 'warning' | 'critical'.
  String get severity => throw _privateConstructorUsedError;

  /// Whether voice TTS was actually spoken (false = display only).
  bool get wasSpoken => throw _privateConstructorUsedError;

  /// Serializes this FeedbackEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeedbackEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedbackEventCopyWith<FeedbackEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedbackEventCopyWith<$Res> {
  factory $FeedbackEventCopyWith(
          FeedbackEvent value, $Res Function(FeedbackEvent) then) =
      _$FeedbackEventCopyWithImpl<$Res, FeedbackEvent>;
  @useResult
  $Res call(
      {String eventId,
      String sessionId,
      DateTime timestamp,
      String promptKey,
      String language,
      String triggeredByClass,
      String severity,
      bool wasSpoken});
}

/// @nodoc
class _$FeedbackEventCopyWithImpl<$Res, $Val extends FeedbackEvent>
    implements $FeedbackEventCopyWith<$Res> {
  _$FeedbackEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedbackEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? sessionId = null,
    Object? timestamp = null,
    Object? promptKey = null,
    Object? language = null,
    Object? triggeredByClass = null,
    Object? severity = null,
    Object? wasSpoken = null,
  }) {
    return _then(_value.copyWith(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      promptKey: null == promptKey
          ? _value.promptKey
          : promptKey // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      triggeredByClass: null == triggeredByClass
          ? _value.triggeredByClass
          : triggeredByClass // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as String,
      wasSpoken: null == wasSpoken
          ? _value.wasSpoken
          : wasSpoken // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeedbackEventImplCopyWith<$Res>
    implements $FeedbackEventCopyWith<$Res> {
  factory _$$FeedbackEventImplCopyWith(
          _$FeedbackEventImpl value, $Res Function(_$FeedbackEventImpl) then) =
      __$$FeedbackEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String eventId,
      String sessionId,
      DateTime timestamp,
      String promptKey,
      String language,
      String triggeredByClass,
      String severity,
      bool wasSpoken});
}

/// @nodoc
class __$$FeedbackEventImplCopyWithImpl<$Res>
    extends _$FeedbackEventCopyWithImpl<$Res, _$FeedbackEventImpl>
    implements _$$FeedbackEventImplCopyWith<$Res> {
  __$$FeedbackEventImplCopyWithImpl(
      _$FeedbackEventImpl _value, $Res Function(_$FeedbackEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of FeedbackEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventId = null,
    Object? sessionId = null,
    Object? timestamp = null,
    Object? promptKey = null,
    Object? language = null,
    Object? triggeredByClass = null,
    Object? severity = null,
    Object? wasSpoken = null,
  }) {
    return _then(_$FeedbackEventImpl(
      eventId: null == eventId
          ? _value.eventId
          : eventId // ignore: cast_nullable_to_non_nullable
              as String,
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      promptKey: null == promptKey
          ? _value.promptKey
          : promptKey // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      triggeredByClass: null == triggeredByClass
          ? _value.triggeredByClass
          : triggeredByClass // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as String,
      wasSpoken: null == wasSpoken
          ? _value.wasSpoken
          : wasSpoken // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedbackEventImpl implements _FeedbackEvent {
  const _$FeedbackEventImpl(
      {required this.eventId,
      required this.sessionId,
      required this.timestamp,
      required this.promptKey,
      required this.language,
      required this.triggeredByClass,
      required this.severity,
      this.wasSpoken = false});

  factory _$FeedbackEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedbackEventImplFromJson(json);

  @override
  final String eventId;
  @override
  final String sessionId;
// FK → ResearchSession.sessionId
  @override
  final DateTime timestamp;

  /// The prompt key (e.g. 'bent_elbows', 'rate_too_slow').
  @override
  final String promptKey;

  /// Language the prompt was delivered in ('en' or 'rw').
  @override
  final String language;

  /// The error class that triggered this prompt.
  @override
  final String triggeredByClass;

  /// Severity: 'good' | 'warning' | 'critical'.
  @override
  final String severity;

  /// Whether voice TTS was actually spoken (false = display only).
  @override
  @JsonKey()
  final bool wasSpoken;

  @override
  String toString() {
    return 'FeedbackEvent(eventId: $eventId, sessionId: $sessionId, timestamp: $timestamp, promptKey: $promptKey, language: $language, triggeredByClass: $triggeredByClass, severity: $severity, wasSpoken: $wasSpoken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedbackEventImpl &&
            (identical(other.eventId, eventId) || other.eventId == eventId) &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.promptKey, promptKey) ||
                other.promptKey == promptKey) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.triggeredByClass, triggeredByClass) ||
                other.triggeredByClass == triggeredByClass) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.wasSpoken, wasSpoken) ||
                other.wasSpoken == wasSpoken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, eventId, sessionId, timestamp,
      promptKey, language, triggeredByClass, severity, wasSpoken);

  /// Create a copy of FeedbackEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedbackEventImplCopyWith<_$FeedbackEventImpl> get copyWith =>
      __$$FeedbackEventImplCopyWithImpl<_$FeedbackEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedbackEventImplToJson(
      this,
    );
  }
}

abstract class _FeedbackEvent implements FeedbackEvent {
  const factory _FeedbackEvent(
      {required final String eventId,
      required final String sessionId,
      required final DateTime timestamp,
      required final String promptKey,
      required final String language,
      required final String triggeredByClass,
      required final String severity,
      final bool wasSpoken}) = _$FeedbackEventImpl;

  factory _FeedbackEvent.fromJson(Map<String, dynamic> json) =
      _$FeedbackEventImpl.fromJson;

  @override
  String get eventId;
  @override
  String get sessionId; // FK → ResearchSession.sessionId
  @override
  DateTime get timestamp;

  /// The prompt key (e.g. 'bent_elbows', 'rate_too_slow').
  @override
  String get promptKey;

  /// Language the prompt was delivered in ('en' or 'rw').
  @override
  String get language;

  /// The error class that triggered this prompt.
  @override
  String get triggeredByClass;

  /// Severity: 'good' | 'warning' | 'critical'.
  @override
  String get severity;

  /// Whether voice TTS was actually spoken (false = display only).
  @override
  bool get wasSpoken;

  /// Create a copy of FeedbackEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedbackEventImplCopyWith<_$FeedbackEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SusSurvey _$SusSurveyFromJson(Map<String, dynamic> json) {
  return _SusSurvey.fromJson(json);
}

/// @nodoc
mixin _$SusSurvey {
  String get sessionId => throw _privateConstructorUsedError;
  DateTime get completedAt => throw _privateConstructorUsedError;

  /// 10 SUS items, each rated 1–5.
  /// Items 1,3,5,7,9 = positively worded.
  /// Items 2,4,6,8,10 = negatively worded.
  List<int> get responses => throw _privateConstructorUsedError;

  /// Serializes this SusSurvey to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SusSurvey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SusSurveyCopyWith<SusSurvey> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SusSurveyCopyWith<$Res> {
  factory $SusSurveyCopyWith(SusSurvey value, $Res Function(SusSurvey) then) =
      _$SusSurveyCopyWithImpl<$Res, SusSurvey>;
  @useResult
  $Res call({String sessionId, DateTime completedAt, List<int> responses});
}

/// @nodoc
class _$SusSurveyCopyWithImpl<$Res, $Val extends SusSurvey>
    implements $SusSurveyCopyWith<$Res> {
  _$SusSurveyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SusSurvey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? completedAt = null,
    Object? responses = null,
  }) {
    return _then(_value.copyWith(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      responses: null == responses
          ? _value.responses
          : responses // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SusSurveyImplCopyWith<$Res>
    implements $SusSurveyCopyWith<$Res> {
  factory _$$SusSurveyImplCopyWith(
          _$SusSurveyImpl value, $Res Function(_$SusSurveyImpl) then) =
      __$$SusSurveyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String sessionId, DateTime completedAt, List<int> responses});
}

/// @nodoc
class __$$SusSurveyImplCopyWithImpl<$Res>
    extends _$SusSurveyCopyWithImpl<$Res, _$SusSurveyImpl>
    implements _$$SusSurveyImplCopyWith<$Res> {
  __$$SusSurveyImplCopyWithImpl(
      _$SusSurveyImpl _value, $Res Function(_$SusSurveyImpl) _then)
      : super(_value, _then);

  /// Create a copy of SusSurvey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? completedAt = null,
    Object? responses = null,
  }) {
    return _then(_$SusSurveyImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      responses: null == responses
          ? _value._responses
          : responses // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SusSurveyImpl implements _SusSurvey {
  const _$SusSurveyImpl(
      {required this.sessionId,
      required this.completedAt,
      required final List<int> responses})
      : _responses = responses;

  factory _$SusSurveyImpl.fromJson(Map<String, dynamic> json) =>
      _$$SusSurveyImplFromJson(json);

  @override
  final String sessionId;
  @override
  final DateTime completedAt;

  /// 10 SUS items, each rated 1–5.
  /// Items 1,3,5,7,9 = positively worded.
  /// Items 2,4,6,8,10 = negatively worded.
  final List<int> _responses;

  /// 10 SUS items, each rated 1–5.
  /// Items 1,3,5,7,9 = positively worded.
  /// Items 2,4,6,8,10 = negatively worded.
  @override
  List<int> get responses {
    if (_responses is EqualUnmodifiableListView) return _responses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_responses);
  }

  @override
  String toString() {
    return 'SusSurvey(sessionId: $sessionId, completedAt: $completedAt, responses: $responses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SusSurveyImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            const DeepCollectionEquality()
                .equals(other._responses, _responses));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, sessionId, completedAt,
      const DeepCollectionEquality().hash(_responses));

  /// Create a copy of SusSurvey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SusSurveyImplCopyWith<_$SusSurveyImpl> get copyWith =>
      __$$SusSurveyImplCopyWithImpl<_$SusSurveyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SusSurveyImplToJson(
      this,
    );
  }
}

abstract class _SusSurvey implements SusSurvey {
  const factory _SusSurvey(
      {required final String sessionId,
      required final DateTime completedAt,
      required final List<int> responses}) = _$SusSurveyImpl;

  factory _SusSurvey.fromJson(Map<String, dynamic> json) =
      _$SusSurveyImpl.fromJson;

  @override
  String get sessionId;
  @override
  DateTime get completedAt;

  /// 10 SUS items, each rated 1–5.
  /// Items 1,3,5,7,9 = positively worded.
  /// Items 2,4,6,8,10 = negatively worded.
  @override
  List<int> get responses;

  /// Create a copy of SusSurvey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SusSurveyImplCopyWith<_$SusSurveyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NasaTlxSurvey _$NasaTlxSurveyFromJson(Map<String, dynamic> json) {
  return _NasaTlxSurvey.fromJson(json);
}

/// @nodoc
mixin _$NasaTlxSurvey {
  String get sessionId => throw _privateConstructorUsedError;
  DateTime get completedAt => throw _privateConstructorUsedError;

  /// Mental demand: How much mental/perceptual activity was required? (0–100)
  double get mentalDemand => throw _privateConstructorUsedError;

  /// Physical demand: How much physical activity was required? (0–100)
  double get physicalDemand => throw _privateConstructorUsedError;

  /// Temporal demand: How much time pressure did you feel? (0–100)
  double get temporalDemand => throw _privateConstructorUsedError;

  /// Performance: How successful were you? (0=perfect, 100=failure)
  double get performance => throw _privateConstructorUsedError;

  /// Effort: How hard did you work to achieve your level of performance? (0–100)
  double get effort => throw _privateConstructorUsedError;

  /// Frustration: How irritated/annoyed did you feel? (0–100)
  double get frustration => throw _privateConstructorUsedError;

  /// Serializes this NasaTlxSurvey to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NasaTlxSurvey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NasaTlxSurveyCopyWith<NasaTlxSurvey> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NasaTlxSurveyCopyWith<$Res> {
  factory $NasaTlxSurveyCopyWith(
          NasaTlxSurvey value, $Res Function(NasaTlxSurvey) then) =
      _$NasaTlxSurveyCopyWithImpl<$Res, NasaTlxSurvey>;
  @useResult
  $Res call(
      {String sessionId,
      DateTime completedAt,
      double mentalDemand,
      double physicalDemand,
      double temporalDemand,
      double performance,
      double effort,
      double frustration});
}

/// @nodoc
class _$NasaTlxSurveyCopyWithImpl<$Res, $Val extends NasaTlxSurvey>
    implements $NasaTlxSurveyCopyWith<$Res> {
  _$NasaTlxSurveyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NasaTlxSurvey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? completedAt = null,
    Object? mentalDemand = null,
    Object? physicalDemand = null,
    Object? temporalDemand = null,
    Object? performance = null,
    Object? effort = null,
    Object? frustration = null,
  }) {
    return _then(_value.copyWith(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mentalDemand: null == mentalDemand
          ? _value.mentalDemand
          : mentalDemand // ignore: cast_nullable_to_non_nullable
              as double,
      physicalDemand: null == physicalDemand
          ? _value.physicalDemand
          : physicalDemand // ignore: cast_nullable_to_non_nullable
              as double,
      temporalDemand: null == temporalDemand
          ? _value.temporalDemand
          : temporalDemand // ignore: cast_nullable_to_non_nullable
              as double,
      performance: null == performance
          ? _value.performance
          : performance // ignore: cast_nullable_to_non_nullable
              as double,
      effort: null == effort
          ? _value.effort
          : effort // ignore: cast_nullable_to_non_nullable
              as double,
      frustration: null == frustration
          ? _value.frustration
          : frustration // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NasaTlxSurveyImplCopyWith<$Res>
    implements $NasaTlxSurveyCopyWith<$Res> {
  factory _$$NasaTlxSurveyImplCopyWith(
          _$NasaTlxSurveyImpl value, $Res Function(_$NasaTlxSurveyImpl) then) =
      __$$NasaTlxSurveyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sessionId,
      DateTime completedAt,
      double mentalDemand,
      double physicalDemand,
      double temporalDemand,
      double performance,
      double effort,
      double frustration});
}

/// @nodoc
class __$$NasaTlxSurveyImplCopyWithImpl<$Res>
    extends _$NasaTlxSurveyCopyWithImpl<$Res, _$NasaTlxSurveyImpl>
    implements _$$NasaTlxSurveyImplCopyWith<$Res> {
  __$$NasaTlxSurveyImplCopyWithImpl(
      _$NasaTlxSurveyImpl _value, $Res Function(_$NasaTlxSurveyImpl) _then)
      : super(_value, _then);

  /// Create a copy of NasaTlxSurvey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? completedAt = null,
    Object? mentalDemand = null,
    Object? physicalDemand = null,
    Object? temporalDemand = null,
    Object? performance = null,
    Object? effort = null,
    Object? frustration = null,
  }) {
    return _then(_$NasaTlxSurveyImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      completedAt: null == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mentalDemand: null == mentalDemand
          ? _value.mentalDemand
          : mentalDemand // ignore: cast_nullable_to_non_nullable
              as double,
      physicalDemand: null == physicalDemand
          ? _value.physicalDemand
          : physicalDemand // ignore: cast_nullable_to_non_nullable
              as double,
      temporalDemand: null == temporalDemand
          ? _value.temporalDemand
          : temporalDemand // ignore: cast_nullable_to_non_nullable
              as double,
      performance: null == performance
          ? _value.performance
          : performance // ignore: cast_nullable_to_non_nullable
              as double,
      effort: null == effort
          ? _value.effort
          : effort // ignore: cast_nullable_to_non_nullable
              as double,
      frustration: null == frustration
          ? _value.frustration
          : frustration // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NasaTlxSurveyImpl implements _NasaTlxSurvey {
  const _$NasaTlxSurveyImpl(
      {required this.sessionId,
      required this.completedAt,
      required this.mentalDemand,
      required this.physicalDemand,
      required this.temporalDemand,
      required this.performance,
      required this.effort,
      required this.frustration});

  factory _$NasaTlxSurveyImpl.fromJson(Map<String, dynamic> json) =>
      _$$NasaTlxSurveyImplFromJson(json);

  @override
  final String sessionId;
  @override
  final DateTime completedAt;

  /// Mental demand: How much mental/perceptual activity was required? (0–100)
  @override
  final double mentalDemand;

  /// Physical demand: How much physical activity was required? (0–100)
  @override
  final double physicalDemand;

  /// Temporal demand: How much time pressure did you feel? (0–100)
  @override
  final double temporalDemand;

  /// Performance: How successful were you? (0=perfect, 100=failure)
  @override
  final double performance;

  /// Effort: How hard did you work to achieve your level of performance? (0–100)
  @override
  final double effort;

  /// Frustration: How irritated/annoyed did you feel? (0–100)
  @override
  final double frustration;

  @override
  String toString() {
    return 'NasaTlxSurvey(sessionId: $sessionId, completedAt: $completedAt, mentalDemand: $mentalDemand, physicalDemand: $physicalDemand, temporalDemand: $temporalDemand, performance: $performance, effort: $effort, frustration: $frustration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NasaTlxSurveyImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.mentalDemand, mentalDemand) ||
                other.mentalDemand == mentalDemand) &&
            (identical(other.physicalDemand, physicalDemand) ||
                other.physicalDemand == physicalDemand) &&
            (identical(other.temporalDemand, temporalDemand) ||
                other.temporalDemand == temporalDemand) &&
            (identical(other.performance, performance) ||
                other.performance == performance) &&
            (identical(other.effort, effort) || other.effort == effort) &&
            (identical(other.frustration, frustration) ||
                other.frustration == frustration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sessionId,
      completedAt,
      mentalDemand,
      physicalDemand,
      temporalDemand,
      performance,
      effort,
      frustration);

  /// Create a copy of NasaTlxSurvey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NasaTlxSurveyImplCopyWith<_$NasaTlxSurveyImpl> get copyWith =>
      __$$NasaTlxSurveyImplCopyWithImpl<_$NasaTlxSurveyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NasaTlxSurveyImplToJson(
      this,
    );
  }
}

abstract class _NasaTlxSurvey implements NasaTlxSurvey {
  const factory _NasaTlxSurvey(
      {required final String sessionId,
      required final DateTime completedAt,
      required final double mentalDemand,
      required final double physicalDemand,
      required final double temporalDemand,
      required final double performance,
      required final double effort,
      required final double frustration}) = _$NasaTlxSurveyImpl;

  factory _NasaTlxSurvey.fromJson(Map<String, dynamic> json) =
      _$NasaTlxSurveyImpl.fromJson;

  @override
  String get sessionId;
  @override
  DateTime get completedAt;

  /// Mental demand: How much mental/perceptual activity was required? (0–100)
  @override
  double get mentalDemand;

  /// Physical demand: How much physical activity was required? (0–100)
  @override
  double get physicalDemand;

  /// Temporal demand: How much time pressure did you feel? (0–100)
  @override
  double get temporalDemand;

  /// Performance: How successful were you? (0=perfect, 100=failure)
  @override
  double get performance;

  /// Effort: How hard did you work to achieve your level of performance? (0–100)
  @override
  double get effort;

  /// Frustration: How irritated/annoyed did you feel? (0–100)
  @override
  double get frustration;

  /// Create a copy of NasaTlxSurvey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NasaTlxSurveyImplCopyWith<_$NasaTlxSurveyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SelfEfficacySurvey _$SelfEfficacySurveyFromJson(Map<String, dynamic> json) {
  return _SelfEfficacySurvey.fromJson(json);
}

/// @nodoc
mixin _$SelfEfficacySurvey {
  String get sessionId => throw _privateConstructorUsedError;
  bool get isPostSession =>
      throw _privateConstructorUsedError; // false = pre, true = post
  /// "I am confident I could perform CPR effectively in an emergency." (1–7)
  int get confidence => throw _privateConstructorUsedError;

  /// "I believe my CPR compressions would be at the correct rate." (1–7)
  int get rateConfidence => throw _privateConstructorUsedError;

  /// "I believe my CPR compressions would be at the correct depth." (1–7)
  int get depthConfidence => throw _privateConstructorUsedError;

  /// "I would attempt CPR on a stranger if I witnessed cardiac arrest." (1–7)
  int get willingnessToAct => throw _privateConstructorUsedError;

  /// Serializes this SelfEfficacySurvey to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SelfEfficacySurvey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SelfEfficacySurveyCopyWith<SelfEfficacySurvey> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SelfEfficacySurveyCopyWith<$Res> {
  factory $SelfEfficacySurveyCopyWith(
          SelfEfficacySurvey value, $Res Function(SelfEfficacySurvey) then) =
      _$SelfEfficacySurveyCopyWithImpl<$Res, SelfEfficacySurvey>;
  @useResult
  $Res call(
      {String sessionId,
      bool isPostSession,
      int confidence,
      int rateConfidence,
      int depthConfidence,
      int willingnessToAct});
}

/// @nodoc
class _$SelfEfficacySurveyCopyWithImpl<$Res, $Val extends SelfEfficacySurvey>
    implements $SelfEfficacySurveyCopyWith<$Res> {
  _$SelfEfficacySurveyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SelfEfficacySurvey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? isPostSession = null,
    Object? confidence = null,
    Object? rateConfidence = null,
    Object? depthConfidence = null,
    Object? willingnessToAct = null,
  }) {
    return _then(_value.copyWith(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      isPostSession: null == isPostSession
          ? _value.isPostSession
          : isPostSession // ignore: cast_nullable_to_non_nullable
              as bool,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as int,
      rateConfidence: null == rateConfidence
          ? _value.rateConfidence
          : rateConfidence // ignore: cast_nullable_to_non_nullable
              as int,
      depthConfidence: null == depthConfidence
          ? _value.depthConfidence
          : depthConfidence // ignore: cast_nullable_to_non_nullable
              as int,
      willingnessToAct: null == willingnessToAct
          ? _value.willingnessToAct
          : willingnessToAct // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SelfEfficacySurveyImplCopyWith<$Res>
    implements $SelfEfficacySurveyCopyWith<$Res> {
  factory _$$SelfEfficacySurveyImplCopyWith(_$SelfEfficacySurveyImpl value,
          $Res Function(_$SelfEfficacySurveyImpl) then) =
      __$$SelfEfficacySurveyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String sessionId,
      bool isPostSession,
      int confidence,
      int rateConfidence,
      int depthConfidence,
      int willingnessToAct});
}

/// @nodoc
class __$$SelfEfficacySurveyImplCopyWithImpl<$Res>
    extends _$SelfEfficacySurveyCopyWithImpl<$Res, _$SelfEfficacySurveyImpl>
    implements _$$SelfEfficacySurveyImplCopyWith<$Res> {
  __$$SelfEfficacySurveyImplCopyWithImpl(_$SelfEfficacySurveyImpl _value,
      $Res Function(_$SelfEfficacySurveyImpl) _then)
      : super(_value, _then);

  /// Create a copy of SelfEfficacySurvey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? isPostSession = null,
    Object? confidence = null,
    Object? rateConfidence = null,
    Object? depthConfidence = null,
    Object? willingnessToAct = null,
  }) {
    return _then(_$SelfEfficacySurveyImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as String,
      isPostSession: null == isPostSession
          ? _value.isPostSession
          : isPostSession // ignore: cast_nullable_to_non_nullable
              as bool,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as int,
      rateConfidence: null == rateConfidence
          ? _value.rateConfidence
          : rateConfidence // ignore: cast_nullable_to_non_nullable
              as int,
      depthConfidence: null == depthConfidence
          ? _value.depthConfidence
          : depthConfidence // ignore: cast_nullable_to_non_nullable
              as int,
      willingnessToAct: null == willingnessToAct
          ? _value.willingnessToAct
          : willingnessToAct // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SelfEfficacySurveyImpl implements _SelfEfficacySurvey {
  const _$SelfEfficacySurveyImpl(
      {required this.sessionId,
      required this.isPostSession,
      required this.confidence,
      required this.rateConfidence,
      required this.depthConfidence,
      required this.willingnessToAct});

  factory _$SelfEfficacySurveyImpl.fromJson(Map<String, dynamic> json) =>
      _$$SelfEfficacySurveyImplFromJson(json);

  @override
  final String sessionId;
  @override
  final bool isPostSession;
// false = pre, true = post
  /// "I am confident I could perform CPR effectively in an emergency." (1–7)
  @override
  final int confidence;

  /// "I believe my CPR compressions would be at the correct rate." (1–7)
  @override
  final int rateConfidence;

  /// "I believe my CPR compressions would be at the correct depth." (1–7)
  @override
  final int depthConfidence;

  /// "I would attempt CPR on a stranger if I witnessed cardiac arrest." (1–7)
  @override
  final int willingnessToAct;

  @override
  String toString() {
    return 'SelfEfficacySurvey(sessionId: $sessionId, isPostSession: $isPostSession, confidence: $confidence, rateConfidence: $rateConfidence, depthConfidence: $depthConfidence, willingnessToAct: $willingnessToAct)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelfEfficacySurveyImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.isPostSession, isPostSession) ||
                other.isPostSession == isPostSession) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.rateConfidence, rateConfidence) ||
                other.rateConfidence == rateConfidence) &&
            (identical(other.depthConfidence, depthConfidence) ||
                other.depthConfidence == depthConfidence) &&
            (identical(other.willingnessToAct, willingnessToAct) ||
                other.willingnessToAct == willingnessToAct));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, sessionId, isPostSession,
      confidence, rateConfidence, depthConfidence, willingnessToAct);

  /// Create a copy of SelfEfficacySurvey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SelfEfficacySurveyImplCopyWith<_$SelfEfficacySurveyImpl> get copyWith =>
      __$$SelfEfficacySurveyImplCopyWithImpl<_$SelfEfficacySurveyImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SelfEfficacySurveyImplToJson(
      this,
    );
  }
}

abstract class _SelfEfficacySurvey implements SelfEfficacySurvey {
  const factory _SelfEfficacySurvey(
      {required final String sessionId,
      required final bool isPostSession,
      required final int confidence,
      required final int rateConfidence,
      required final int depthConfidence,
      required final int willingnessToAct}) = _$SelfEfficacySurveyImpl;

  factory _SelfEfficacySurvey.fromJson(Map<String, dynamic> json) =
      _$SelfEfficacySurveyImpl.fromJson;

  @override
  String get sessionId;
  @override
  bool get isPostSession; // false = pre, true = post
  /// "I am confident I could perform CPR effectively in an emergency." (1–7)
  @override
  int get confidence;

  /// "I believe my CPR compressions would be at the correct rate." (1–7)
  @override
  int get rateConfidence;

  /// "I believe my CPR compressions would be at the correct depth." (1–7)
  @override
  int get depthConfidence;

  /// "I would attempt CPR on a stranger if I witnessed cardiac arrest." (1–7)
  @override
  int get willingnessToAct;

  /// Create a copy of SelfEfficacySurvey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SelfEfficacySurveyImplCopyWith<_$SelfEfficacySurveyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
