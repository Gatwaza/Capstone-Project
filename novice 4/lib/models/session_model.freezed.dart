// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SessionModel _$SessionModelFromJson(Map<String, dynamic> json) {
  return _SessionModel.fromJson(json);
}

/// @nodoc
mixin _$SessionModel {
  String get id => throw _privateConstructorUsedError;
  String get participantId => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime get endedAt => throw _privateConstructorUsedError;
  int get totalCompressions => throw _privateConstructorUsedError;
  double get meanBpm => throw _privateConstructorUsedError;
  double get meanDepthCm => throw _privateConstructorUsedError;
  double get cprFraction => throw _privateConstructorUsedError;

  /// 0–100 weighted multi-task quality score (TCN AUC-weighted).
  int get qualityScore => throw _privateConstructorUsedError;

  /// Per-frame class distribution: label → fraction of session frames.
  Map<String, double> get errorRates => throw _privateConstructorUsedError;

  /// Schema generation for this session record.
  ///   1 = pre-3-head-refactor: 8-class single-label output
  ///       (error_rates keys like 'bent_elbows', 'hand_too_high', etc.,
  ///       no rate/depth/recoil precision/recall/F1/AUC columns).
  ///   2 = current: 3-head model (rate/depth/recoil independent labels),
  ///       full per-task accuracy/precision/recall/F1/AUC populated.
  /// Existing rows created before this field existed are migrated to 1
  /// by scripts/migrate_schema_version.py — see that script for the CSV
  /// heuristic used to tell old sessions apart from new ones.
  int get schemaVersion =>
      throw _privateConstructorUsedError; // ── Research metrics: ACCURACY ──────────────────────────────────────────
// Fraction of frames where the model classified the task as "Correct".
  double get rateAccuracy => throw _privateConstructorUsedError;
  double get depthAccuracy => throw _privateConstructorUsedError;
  double get recoilAccuracy =>
      throw _privateConstructorUsedError; // ── Research metrics: PRECISION ─────────────────────────────────────────
// Macro-averaged precision per task (client-side, from frame tally).
  double get ratePrecision => throw _privateConstructorUsedError;
  double get depthPrecision => throw _privateConstructorUsedError;
  double get recoilPrecision =>
      throw _privateConstructorUsedError; // ── Research metrics: RECALL ────────────────────────────────────────────
  double get rateRecall => throw _privateConstructorUsedError;
  double get depthRecall => throw _privateConstructorUsedError;
  double get recoilRecall =>
      throw _privateConstructorUsedError; // ── Research metrics: F1-SCORE ──────────────────────────────────────────
// Weighted F1 per task (matches notebook evaluation: F1_w).
  double get rateF1 => throw _privateConstructorUsedError;
  double get depthF1 => throw _privateConstructorUsedError;
  double get recoilF1 =>
      throw _privateConstructorUsedError; // ── Research metrics: ROC-AUC ───────────────────────────────────────────
// Mean model confidence used as probabilistic score for AUC estimation.
  double get rateAuc => throw _privateConstructorUsedError;
  double get depthAuc => throw _privateConstructorUsedError;
  double get recoilAuc =>
      throw _privateConstructorUsedError; // ── Legacy per-task confidence (kept for quality score weighting) ───────
  Map<String, double> get taskConfidences => throw _privateConstructorUsedError;
  String get language => throw _privateConstructorUsedError;
  bool get modelWasAvailable => throw _privateConstructorUsedError;
  String? get deviceModel => throw _privateConstructorUsedError;

  /// Raw per-frame landmark data for retraining pipeline.
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<LandmarkFrame> get rawFrames => throw _privateConstructorUsedError;
  String? get reviewLabel => throw _privateConstructorUsedError;
  String? get reviewNote => throw _privateConstructorUsedError;

  /// Serializes this SessionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SessionModelCopyWith<SessionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionModelCopyWith<$Res> {
  factory $SessionModelCopyWith(
          SessionModel value, $Res Function(SessionModel) then) =
      _$SessionModelCopyWithImpl<$Res, SessionModel>;
  @useResult
  $Res call(
      {String id,
      String participantId,
      DateTime startedAt,
      DateTime endedAt,
      int totalCompressions,
      double meanBpm,
      double meanDepthCm,
      double cprFraction,
      int qualityScore,
      Map<String, double> errorRates,
      int schemaVersion,
      double rateAccuracy,
      double depthAccuracy,
      double recoilAccuracy,
      double ratePrecision,
      double depthPrecision,
      double recoilPrecision,
      double rateRecall,
      double depthRecall,
      double recoilRecall,
      double rateF1,
      double depthF1,
      double recoilF1,
      double rateAuc,
      double depthAuc,
      double recoilAuc,
      Map<String, double> taskConfidences,
      String language,
      bool modelWasAvailable,
      String? deviceModel,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<LandmarkFrame> rawFrames,
      String? reviewLabel,
      String? reviewNote});
}

/// @nodoc
class _$SessionModelCopyWithImpl<$Res, $Val extends SessionModel>
    implements $SessionModelCopyWith<$Res> {
  _$SessionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participantId = null,
    Object? startedAt = null,
    Object? endedAt = null,
    Object? totalCompressions = null,
    Object? meanBpm = null,
    Object? meanDepthCm = null,
    Object? cprFraction = null,
    Object? qualityScore = null,
    Object? errorRates = null,
    Object? schemaVersion = null,
    Object? rateAccuracy = null,
    Object? depthAccuracy = null,
    Object? recoilAccuracy = null,
    Object? ratePrecision = null,
    Object? depthPrecision = null,
    Object? recoilPrecision = null,
    Object? rateRecall = null,
    Object? depthRecall = null,
    Object? recoilRecall = null,
    Object? rateF1 = null,
    Object? depthF1 = null,
    Object? recoilF1 = null,
    Object? rateAuc = null,
    Object? depthAuc = null,
    Object? recoilAuc = null,
    Object? taskConfidences = null,
    Object? language = null,
    Object? modelWasAvailable = null,
    Object? deviceModel = freezed,
    Object? rawFrames = null,
    Object? reviewLabel = freezed,
    Object? reviewNote = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      participantId: null == participantId
          ? _value.participantId
          : participantId // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: null == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalCompressions: null == totalCompressions
          ? _value.totalCompressions
          : totalCompressions // ignore: cast_nullable_to_non_nullable
              as int,
      meanBpm: null == meanBpm
          ? _value.meanBpm
          : meanBpm // ignore: cast_nullable_to_non_nullable
              as double,
      meanDepthCm: null == meanDepthCm
          ? _value.meanDepthCm
          : meanDepthCm // ignore: cast_nullable_to_non_nullable
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
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      rateAccuracy: null == rateAccuracy
          ? _value.rateAccuracy
          : rateAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      depthAccuracy: null == depthAccuracy
          ? _value.depthAccuracy
          : depthAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      recoilAccuracy: null == recoilAccuracy
          ? _value.recoilAccuracy
          : recoilAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      ratePrecision: null == ratePrecision
          ? _value.ratePrecision
          : ratePrecision // ignore: cast_nullable_to_non_nullable
              as double,
      depthPrecision: null == depthPrecision
          ? _value.depthPrecision
          : depthPrecision // ignore: cast_nullable_to_non_nullable
              as double,
      recoilPrecision: null == recoilPrecision
          ? _value.recoilPrecision
          : recoilPrecision // ignore: cast_nullable_to_non_nullable
              as double,
      rateRecall: null == rateRecall
          ? _value.rateRecall
          : rateRecall // ignore: cast_nullable_to_non_nullable
              as double,
      depthRecall: null == depthRecall
          ? _value.depthRecall
          : depthRecall // ignore: cast_nullable_to_non_nullable
              as double,
      recoilRecall: null == recoilRecall
          ? _value.recoilRecall
          : recoilRecall // ignore: cast_nullable_to_non_nullable
              as double,
      rateF1: null == rateF1
          ? _value.rateF1
          : rateF1 // ignore: cast_nullable_to_non_nullable
              as double,
      depthF1: null == depthF1
          ? _value.depthF1
          : depthF1 // ignore: cast_nullable_to_non_nullable
              as double,
      recoilF1: null == recoilF1
          ? _value.recoilF1
          : recoilF1 // ignore: cast_nullable_to_non_nullable
              as double,
      rateAuc: null == rateAuc
          ? _value.rateAuc
          : rateAuc // ignore: cast_nullable_to_non_nullable
              as double,
      depthAuc: null == depthAuc
          ? _value.depthAuc
          : depthAuc // ignore: cast_nullable_to_non_nullable
              as double,
      recoilAuc: null == recoilAuc
          ? _value.recoilAuc
          : recoilAuc // ignore: cast_nullable_to_non_nullable
              as double,
      taskConfidences: null == taskConfidences
          ? _value.taskConfidences
          : taskConfidences // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      modelWasAvailable: null == modelWasAvailable
          ? _value.modelWasAvailable
          : modelWasAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      deviceModel: freezed == deviceModel
          ? _value.deviceModel
          : deviceModel // ignore: cast_nullable_to_non_nullable
              as String?,
      rawFrames: null == rawFrames
          ? _value.rawFrames
          : rawFrames // ignore: cast_nullable_to_non_nullable
              as List<LandmarkFrame>,
      reviewLabel: freezed == reviewLabel
          ? _value.reviewLabel
          : reviewLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewNote: freezed == reviewNote
          ? _value.reviewNote
          : reviewNote // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SessionModelImplCopyWith<$Res>
    implements $SessionModelCopyWith<$Res> {
  factory _$$SessionModelImplCopyWith(
          _$SessionModelImpl value, $Res Function(_$SessionModelImpl) then) =
      __$$SessionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String participantId,
      DateTime startedAt,
      DateTime endedAt,
      int totalCompressions,
      double meanBpm,
      double meanDepthCm,
      double cprFraction,
      int qualityScore,
      Map<String, double> errorRates,
      int schemaVersion,
      double rateAccuracy,
      double depthAccuracy,
      double recoilAccuracy,
      double ratePrecision,
      double depthPrecision,
      double recoilPrecision,
      double rateRecall,
      double depthRecall,
      double recoilRecall,
      double rateF1,
      double depthF1,
      double recoilF1,
      double rateAuc,
      double depthAuc,
      double recoilAuc,
      Map<String, double> taskConfidences,
      String language,
      bool modelWasAvailable,
      String? deviceModel,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<LandmarkFrame> rawFrames,
      String? reviewLabel,
      String? reviewNote});
}

/// @nodoc
class __$$SessionModelImplCopyWithImpl<$Res>
    extends _$SessionModelCopyWithImpl<$Res, _$SessionModelImpl>
    implements _$$SessionModelImplCopyWith<$Res> {
  __$$SessionModelImplCopyWithImpl(
      _$SessionModelImpl _value, $Res Function(_$SessionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participantId = null,
    Object? startedAt = null,
    Object? endedAt = null,
    Object? totalCompressions = null,
    Object? meanBpm = null,
    Object? meanDepthCm = null,
    Object? cprFraction = null,
    Object? qualityScore = null,
    Object? errorRates = null,
    Object? schemaVersion = null,
    Object? rateAccuracy = null,
    Object? depthAccuracy = null,
    Object? recoilAccuracy = null,
    Object? ratePrecision = null,
    Object? depthPrecision = null,
    Object? recoilPrecision = null,
    Object? rateRecall = null,
    Object? depthRecall = null,
    Object? recoilRecall = null,
    Object? rateF1 = null,
    Object? depthF1 = null,
    Object? recoilF1 = null,
    Object? rateAuc = null,
    Object? depthAuc = null,
    Object? recoilAuc = null,
    Object? taskConfidences = null,
    Object? language = null,
    Object? modelWasAvailable = null,
    Object? deviceModel = freezed,
    Object? rawFrames = null,
    Object? reviewLabel = freezed,
    Object? reviewNote = freezed,
  }) {
    return _then(_$SessionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      participantId: null == participantId
          ? _value.participantId
          : participantId // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: null == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalCompressions: null == totalCompressions
          ? _value.totalCompressions
          : totalCompressions // ignore: cast_nullable_to_non_nullable
              as int,
      meanBpm: null == meanBpm
          ? _value.meanBpm
          : meanBpm // ignore: cast_nullable_to_non_nullable
              as double,
      meanDepthCm: null == meanDepthCm
          ? _value.meanDepthCm
          : meanDepthCm // ignore: cast_nullable_to_non_nullable
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
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      rateAccuracy: null == rateAccuracy
          ? _value.rateAccuracy
          : rateAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      depthAccuracy: null == depthAccuracy
          ? _value.depthAccuracy
          : depthAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      recoilAccuracy: null == recoilAccuracy
          ? _value.recoilAccuracy
          : recoilAccuracy // ignore: cast_nullable_to_non_nullable
              as double,
      ratePrecision: null == ratePrecision
          ? _value.ratePrecision
          : ratePrecision // ignore: cast_nullable_to_non_nullable
              as double,
      depthPrecision: null == depthPrecision
          ? _value.depthPrecision
          : depthPrecision // ignore: cast_nullable_to_non_nullable
              as double,
      recoilPrecision: null == recoilPrecision
          ? _value.recoilPrecision
          : recoilPrecision // ignore: cast_nullable_to_non_nullable
              as double,
      rateRecall: null == rateRecall
          ? _value.rateRecall
          : rateRecall // ignore: cast_nullable_to_non_nullable
              as double,
      depthRecall: null == depthRecall
          ? _value.depthRecall
          : depthRecall // ignore: cast_nullable_to_non_nullable
              as double,
      recoilRecall: null == recoilRecall
          ? _value.recoilRecall
          : recoilRecall // ignore: cast_nullable_to_non_nullable
              as double,
      rateF1: null == rateF1
          ? _value.rateF1
          : rateF1 // ignore: cast_nullable_to_non_nullable
              as double,
      depthF1: null == depthF1
          ? _value.depthF1
          : depthF1 // ignore: cast_nullable_to_non_nullable
              as double,
      recoilF1: null == recoilF1
          ? _value.recoilF1
          : recoilF1 // ignore: cast_nullable_to_non_nullable
              as double,
      rateAuc: null == rateAuc
          ? _value.rateAuc
          : rateAuc // ignore: cast_nullable_to_non_nullable
              as double,
      depthAuc: null == depthAuc
          ? _value.depthAuc
          : depthAuc // ignore: cast_nullable_to_non_nullable
              as double,
      recoilAuc: null == recoilAuc
          ? _value.recoilAuc
          : recoilAuc // ignore: cast_nullable_to_non_nullable
              as double,
      taskConfidences: null == taskConfidences
          ? _value._taskConfidences
          : taskConfidences // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      modelWasAvailable: null == modelWasAvailable
          ? _value.modelWasAvailable
          : modelWasAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      deviceModel: freezed == deviceModel
          ? _value.deviceModel
          : deviceModel // ignore: cast_nullable_to_non_nullable
              as String?,
      rawFrames: null == rawFrames
          ? _value._rawFrames
          : rawFrames // ignore: cast_nullable_to_non_nullable
              as List<LandmarkFrame>,
      reviewLabel: freezed == reviewLabel
          ? _value.reviewLabel
          : reviewLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewNote: freezed == reviewNote
          ? _value.reviewNote
          : reviewNote // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionModelImpl implements _SessionModel {
  const _$SessionModelImpl(
      {required this.id,
      required this.participantId,
      required this.startedAt,
      required this.endedAt,
      required this.totalCompressions,
      required this.meanBpm,
      required this.meanDepthCm,
      required this.cprFraction,
      required this.qualityScore,
      required final Map<String, double> errorRates,
      this.schemaVersion = 2,
      this.rateAccuracy = 0.0,
      this.depthAccuracy = 0.0,
      this.recoilAccuracy = 0.0,
      this.ratePrecision = 0.0,
      this.depthPrecision = 0.0,
      this.recoilPrecision = 0.0,
      this.rateRecall = 0.0,
      this.depthRecall = 0.0,
      this.recoilRecall = 0.0,
      this.rateF1 = 0.0,
      this.depthF1 = 0.0,
      this.recoilF1 = 0.0,
      this.rateAuc = 0.0,
      this.depthAuc = 0.0,
      this.recoilAuc = 0.0,
      final Map<String, double> taskConfidences = const {},
      this.language = 'en',
      this.modelWasAvailable = false,
      this.deviceModel,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<LandmarkFrame> rawFrames = const [],
      this.reviewLabel,
      this.reviewNote})
      : _errorRates = errorRates,
        _taskConfidences = taskConfidences,
        _rawFrames = rawFrames;

  factory _$SessionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionModelImplFromJson(json);

  @override
  final String id;
  @override
  final String participantId;
  @override
  final DateTime startedAt;
  @override
  final DateTime endedAt;
  @override
  final int totalCompressions;
  @override
  final double meanBpm;
  @override
  final double meanDepthCm;
  @override
  final double cprFraction;

  /// 0–100 weighted multi-task quality score (TCN AUC-weighted).
  @override
  final int qualityScore;

  /// Per-frame class distribution: label → fraction of session frames.
  final Map<String, double> _errorRates;

  /// Per-frame class distribution: label → fraction of session frames.
  @override
  Map<String, double> get errorRates {
    if (_errorRates is EqualUnmodifiableMapView) return _errorRates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_errorRates);
  }

  /// Schema generation for this session record.
  ///   1 = pre-3-head-refactor: 8-class single-label output
  ///       (error_rates keys like 'bent_elbows', 'hand_too_high', etc.,
  ///       no rate/depth/recoil precision/recall/F1/AUC columns).
  ///   2 = current: 3-head model (rate/depth/recoil independent labels),
  ///       full per-task accuracy/precision/recall/F1/AUC populated.
  /// Existing rows created before this field existed are migrated to 1
  /// by scripts/migrate_schema_version.py — see that script for the CSV
  /// heuristic used to tell old sessions apart from new ones.
  @override
  @JsonKey()
  final int schemaVersion;
// ── Research metrics: ACCURACY ──────────────────────────────────────────
// Fraction of frames where the model classified the task as "Correct".
  @override
  @JsonKey()
  final double rateAccuracy;
  @override
  @JsonKey()
  final double depthAccuracy;
  @override
  @JsonKey()
  final double recoilAccuracy;
// ── Research metrics: PRECISION ─────────────────────────────────────────
// Macro-averaged precision per task (client-side, from frame tally).
  @override
  @JsonKey()
  final double ratePrecision;
  @override
  @JsonKey()
  final double depthPrecision;
  @override
  @JsonKey()
  final double recoilPrecision;
// ── Research metrics: RECALL ────────────────────────────────────────────
  @override
  @JsonKey()
  final double rateRecall;
  @override
  @JsonKey()
  final double depthRecall;
  @override
  @JsonKey()
  final double recoilRecall;
// ── Research metrics: F1-SCORE ──────────────────────────────────────────
// Weighted F1 per task (matches notebook evaluation: F1_w).
  @override
  @JsonKey()
  final double rateF1;
  @override
  @JsonKey()
  final double depthF1;
  @override
  @JsonKey()
  final double recoilF1;
// ── Research metrics: ROC-AUC ───────────────────────────────────────────
// Mean model confidence used as probabilistic score for AUC estimation.
  @override
  @JsonKey()
  final double rateAuc;
  @override
  @JsonKey()
  final double depthAuc;
  @override
  @JsonKey()
  final double recoilAuc;
// ── Legacy per-task confidence (kept for quality score weighting) ───────
  final Map<String, double> _taskConfidences;
// ── Legacy per-task confidence (kept for quality score weighting) ───────
  @override
  @JsonKey()
  Map<String, double> get taskConfidences {
    if (_taskConfidences is EqualUnmodifiableMapView) return _taskConfidences;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_taskConfidences);
  }

  @override
  @JsonKey()
  final String language;
  @override
  @JsonKey()
  final bool modelWasAvailable;
  @override
  final String? deviceModel;

  /// Raw per-frame landmark data for retraining pipeline.
  final List<LandmarkFrame> _rawFrames;

  /// Raw per-frame landmark data for retraining pipeline.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<LandmarkFrame> get rawFrames {
    if (_rawFrames is EqualUnmodifiableListView) return _rawFrames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rawFrames);
  }

  @override
  final String? reviewLabel;
  @override
  final String? reviewNote;

  @override
  String toString() {
    return 'SessionModel(id: $id, participantId: $participantId, startedAt: $startedAt, endedAt: $endedAt, totalCompressions: $totalCompressions, meanBpm: $meanBpm, meanDepthCm: $meanDepthCm, cprFraction: $cprFraction, qualityScore: $qualityScore, errorRates: $errorRates, schemaVersion: $schemaVersion, rateAccuracy: $rateAccuracy, depthAccuracy: $depthAccuracy, recoilAccuracy: $recoilAccuracy, ratePrecision: $ratePrecision, depthPrecision: $depthPrecision, recoilPrecision: $recoilPrecision, rateRecall: $rateRecall, depthRecall: $depthRecall, recoilRecall: $recoilRecall, rateF1: $rateF1, depthF1: $depthF1, recoilF1: $recoilF1, rateAuc: $rateAuc, depthAuc: $depthAuc, recoilAuc: $recoilAuc, taskConfidences: $taskConfidences, language: $language, modelWasAvailable: $modelWasAvailable, deviceModel: $deviceModel, rawFrames: $rawFrames, reviewLabel: $reviewLabel, reviewNote: $reviewNote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.participantId, participantId) ||
                other.participantId == participantId) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.totalCompressions, totalCompressions) ||
                other.totalCompressions == totalCompressions) &&
            (identical(other.meanBpm, meanBpm) || other.meanBpm == meanBpm) &&
            (identical(other.meanDepthCm, meanDepthCm) ||
                other.meanDepthCm == meanDepthCm) &&
            (identical(other.cprFraction, cprFraction) ||
                other.cprFraction == cprFraction) &&
            (identical(other.qualityScore, qualityScore) ||
                other.qualityScore == qualityScore) &&
            const DeepCollectionEquality()
                .equals(other._errorRates, _errorRates) &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            (identical(other.rateAccuracy, rateAccuracy) ||
                other.rateAccuracy == rateAccuracy) &&
            (identical(other.depthAccuracy, depthAccuracy) ||
                other.depthAccuracy == depthAccuracy) &&
            (identical(other.recoilAccuracy, recoilAccuracy) ||
                other.recoilAccuracy == recoilAccuracy) &&
            (identical(other.ratePrecision, ratePrecision) ||
                other.ratePrecision == ratePrecision) &&
            (identical(other.depthPrecision, depthPrecision) ||
                other.depthPrecision == depthPrecision) &&
            (identical(other.recoilPrecision, recoilPrecision) ||
                other.recoilPrecision == recoilPrecision) &&
            (identical(other.rateRecall, rateRecall) ||
                other.rateRecall == rateRecall) &&
            (identical(other.depthRecall, depthRecall) ||
                other.depthRecall == depthRecall) &&
            (identical(other.recoilRecall, recoilRecall) ||
                other.recoilRecall == recoilRecall) &&
            (identical(other.rateF1, rateF1) || other.rateF1 == rateF1) &&
            (identical(other.depthF1, depthF1) || other.depthF1 == depthF1) &&
            (identical(other.recoilF1, recoilF1) ||
                other.recoilF1 == recoilF1) &&
            (identical(other.rateAuc, rateAuc) || other.rateAuc == rateAuc) &&
            (identical(other.depthAuc, depthAuc) ||
                other.depthAuc == depthAuc) &&
            (identical(other.recoilAuc, recoilAuc) ||
                other.recoilAuc == recoilAuc) &&
            const DeepCollectionEquality()
                .equals(other._taskConfidences, _taskConfidences) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.modelWasAvailable, modelWasAvailable) ||
                other.modelWasAvailable == modelWasAvailable) &&
            (identical(other.deviceModel, deviceModel) ||
                other.deviceModel == deviceModel) &&
            const DeepCollectionEquality()
                .equals(other._rawFrames, _rawFrames) &&
            (identical(other.reviewLabel, reviewLabel) ||
                other.reviewLabel == reviewLabel) &&
            (identical(other.reviewNote, reviewNote) ||
                other.reviewNote == reviewNote));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        participantId,
        startedAt,
        endedAt,
        totalCompressions,
        meanBpm,
        meanDepthCm,
        cprFraction,
        qualityScore,
        const DeepCollectionEquality().hash(_errorRates),
        schemaVersion,
        rateAccuracy,
        depthAccuracy,
        recoilAccuracy,
        ratePrecision,
        depthPrecision,
        recoilPrecision,
        rateRecall,
        depthRecall,
        recoilRecall,
        rateF1,
        depthF1,
        recoilF1,
        rateAuc,
        depthAuc,
        recoilAuc,
        const DeepCollectionEquality().hash(_taskConfidences),
        language,
        modelWasAvailable,
        deviceModel,
        const DeepCollectionEquality().hash(_rawFrames),
        reviewLabel,
        reviewNote
      ]);

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionModelImplCopyWith<_$SessionModelImpl> get copyWith =>
      __$$SessionModelImplCopyWithImpl<_$SessionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionModelImplToJson(
      this,
    );
  }
}

abstract class _SessionModel implements SessionModel {
  const factory _SessionModel(
      {required final String id,
      required final String participantId,
      required final DateTime startedAt,
      required final DateTime endedAt,
      required final int totalCompressions,
      required final double meanBpm,
      required final double meanDepthCm,
      required final double cprFraction,
      required final int qualityScore,
      required final Map<String, double> errorRates,
      final int schemaVersion,
      final double rateAccuracy,
      final double depthAccuracy,
      final double recoilAccuracy,
      final double ratePrecision,
      final double depthPrecision,
      final double recoilPrecision,
      final double rateRecall,
      final double depthRecall,
      final double recoilRecall,
      final double rateF1,
      final double depthF1,
      final double recoilF1,
      final double rateAuc,
      final double depthAuc,
      final double recoilAuc,
      final Map<String, double> taskConfidences,
      final String language,
      final bool modelWasAvailable,
      final String? deviceModel,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<LandmarkFrame> rawFrames,
      final String? reviewLabel,
      final String? reviewNote}) = _$SessionModelImpl;

  factory _SessionModel.fromJson(Map<String, dynamic> json) =
      _$SessionModelImpl.fromJson;

  @override
  String get id;
  @override
  String get participantId;
  @override
  DateTime get startedAt;
  @override
  DateTime get endedAt;
  @override
  int get totalCompressions;
  @override
  double get meanBpm;
  @override
  double get meanDepthCm;
  @override
  double get cprFraction;

  /// 0–100 weighted multi-task quality score (TCN AUC-weighted).
  @override
  int get qualityScore;

  /// Per-frame class distribution: label → fraction of session frames.
  @override
  Map<String, double> get errorRates;

  /// Schema generation for this session record.
  ///   1 = pre-3-head-refactor: 8-class single-label output
  ///       (error_rates keys like 'bent_elbows', 'hand_too_high', etc.,
  ///       no rate/depth/recoil precision/recall/F1/AUC columns).
  ///   2 = current: 3-head model (rate/depth/recoil independent labels),
  ///       full per-task accuracy/precision/recall/F1/AUC populated.
  /// Existing rows created before this field existed are migrated to 1
  /// by scripts/migrate_schema_version.py — see that script for the CSV
  /// heuristic used to tell old sessions apart from new ones.
  @override
  int get schemaVersion; // ── Research metrics: ACCURACY ──────────────────────────────────────────
// Fraction of frames where the model classified the task as "Correct".
  @override
  double get rateAccuracy;
  @override
  double get depthAccuracy;
  @override
  double
      get recoilAccuracy; // ── Research metrics: PRECISION ─────────────────────────────────────────
// Macro-averaged precision per task (client-side, from frame tally).
  @override
  double get ratePrecision;
  @override
  double get depthPrecision;
  @override
  double
      get recoilPrecision; // ── Research metrics: RECALL ────────────────────────────────────────────
  @override
  double get rateRecall;
  @override
  double get depthRecall;
  @override
  double
      get recoilRecall; // ── Research metrics: F1-SCORE ──────────────────────────────────────────
// Weighted F1 per task (matches notebook evaluation: F1_w).
  @override
  double get rateF1;
  @override
  double get depthF1;
  @override
  double
      get recoilF1; // ── Research metrics: ROC-AUC ───────────────────────────────────────────
// Mean model confidence used as probabilistic score for AUC estimation.
  @override
  double get rateAuc;
  @override
  double get depthAuc;
  @override
  double
      get recoilAuc; // ── Legacy per-task confidence (kept for quality score weighting) ───────
  @override
  Map<String, double> get taskConfidences;
  @override
  String get language;
  @override
  bool get modelWasAvailable;
  @override
  String? get deviceModel;

  /// Raw per-frame landmark data for retraining pipeline.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<LandmarkFrame> get rawFrames;
  @override
  String? get reviewLabel;
  @override
  String? get reviewNote;

  /// Create a copy of SessionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SessionModelImplCopyWith<_$SessionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$InferenceResult {
  DateTime get timestamp => throw _privateConstructorUsedError;
  int get topClassIndex => throw _privateConstructorUsedError;
  String get topClassLabel => throw _privateConstructorUsedError;
  double get topClassConfidence => throw _privateConstructorUsedError;
  Map<String, double> get allClassScores => throw _privateConstructorUsedError;
  double get currentBpm => throw _privateConstructorUsedError;
  double get estimatedDepthCm => throw _privateConstructorUsedError;
  double get elbowAngleMean => throw _privateConstructorUsedError;
  double get spineVerticalityDeg =>
      throw _privateConstructorUsedError; // Per-task accuracy and confidence from TCN three-head model
  double? get rateAccuracy => throw _privateConstructorUsedError;
  double? get rateConfidence => throw _privateConstructorUsedError;
  double? get depthAccuracy => throw _privateConstructorUsedError;
  double? get depthConfidence => throw _privateConstructorUsedError;
  double? get recoilAccuracy => throw _privateConstructorUsedError;
  double? get recoilConfidence =>
      throw _privateConstructorUsedError; // Direct per-task labels from the 3-head web/API path (e.g. 'Correct',
// 'Too_Fast', 'Too_Shallow', 'Incomplete'). Null on mobile — the
// rule-based/8-class inference_service.dart never sets these, so
// consumers must fall back to topClassLabel/allClassScores when null.
  String? get rateLabel => throw _privateConstructorUsedError;
  String? get depthLabel => throw _privateConstructorUsedError;
  String? get recoilLabel => throw _privateConstructorUsedError;
  bool get isSimulated =>
      throw _privateConstructorUsedError; // Distinguishes a frame carrying a genuinely-fresh API classification
// from one merely reusing the last cached result
// (inference_service_web.dart throttles real API calls to every
// ~600ms / 15 frames at 25fps, then serves the cached label+accuracy
// for up to 1.5s / ~37 frames afterward, restamped with that frame's
// own freshly-computed currentBpm/estimatedDepthCm). Only frames where
// isFreshPrediction=true should be accumulated into the live accuracy
// histories — otherwise a stale label gets re-scored against bpm/depth
// values that may have drifted since the API actually evaluated it.
  bool get isFreshPrediction => throw _privateConstructorUsedError;

  /// Create a copy of InferenceResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InferenceResultCopyWith<InferenceResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InferenceResultCopyWith<$Res> {
  factory $InferenceResultCopyWith(
          InferenceResult value, $Res Function(InferenceResult) then) =
      _$InferenceResultCopyWithImpl<$Res, InferenceResult>;
  @useResult
  $Res call(
      {DateTime timestamp,
      int topClassIndex,
      String topClassLabel,
      double topClassConfidence,
      Map<String, double> allClassScores,
      double currentBpm,
      double estimatedDepthCm,
      double elbowAngleMean,
      double spineVerticalityDeg,
      double? rateAccuracy,
      double? rateConfidence,
      double? depthAccuracy,
      double? depthConfidence,
      double? recoilAccuracy,
      double? recoilConfidence,
      String? rateLabel,
      String? depthLabel,
      String? recoilLabel,
      bool isSimulated,
      bool isFreshPrediction});
}

/// @nodoc
class _$InferenceResultCopyWithImpl<$Res, $Val extends InferenceResult>
    implements $InferenceResultCopyWith<$Res> {
  _$InferenceResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InferenceResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? topClassIndex = null,
    Object? topClassLabel = null,
    Object? topClassConfidence = null,
    Object? allClassScores = null,
    Object? currentBpm = null,
    Object? estimatedDepthCm = null,
    Object? elbowAngleMean = null,
    Object? spineVerticalityDeg = null,
    Object? rateAccuracy = freezed,
    Object? rateConfidence = freezed,
    Object? depthAccuracy = freezed,
    Object? depthConfidence = freezed,
    Object? recoilAccuracy = freezed,
    Object? recoilConfidence = freezed,
    Object? rateLabel = freezed,
    Object? depthLabel = freezed,
    Object? recoilLabel = freezed,
    Object? isSimulated = null,
    Object? isFreshPrediction = null,
  }) {
    return _then(_value.copyWith(
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      topClassIndex: null == topClassIndex
          ? _value.topClassIndex
          : topClassIndex // ignore: cast_nullable_to_non_nullable
              as int,
      topClassLabel: null == topClassLabel
          ? _value.topClassLabel
          : topClassLabel // ignore: cast_nullable_to_non_nullable
              as String,
      topClassConfidence: null == topClassConfidence
          ? _value.topClassConfidence
          : topClassConfidence // ignore: cast_nullable_to_non_nullable
              as double,
      allClassScores: null == allClassScores
          ? _value.allClassScores
          : allClassScores // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      currentBpm: null == currentBpm
          ? _value.currentBpm
          : currentBpm // ignore: cast_nullable_to_non_nullable
              as double,
      estimatedDepthCm: null == estimatedDepthCm
          ? _value.estimatedDepthCm
          : estimatedDepthCm // ignore: cast_nullable_to_non_nullable
              as double,
      elbowAngleMean: null == elbowAngleMean
          ? _value.elbowAngleMean
          : elbowAngleMean // ignore: cast_nullable_to_non_nullable
              as double,
      spineVerticalityDeg: null == spineVerticalityDeg
          ? _value.spineVerticalityDeg
          : spineVerticalityDeg // ignore: cast_nullable_to_non_nullable
              as double,
      rateAccuracy: freezed == rateAccuracy
          ? _value.rateAccuracy
          : rateAccuracy // ignore: cast_nullable_to_non_nullable
              as double?,
      rateConfidence: freezed == rateConfidence
          ? _value.rateConfidence
          : rateConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      depthAccuracy: freezed == depthAccuracy
          ? _value.depthAccuracy
          : depthAccuracy // ignore: cast_nullable_to_non_nullable
              as double?,
      depthConfidence: freezed == depthConfidence
          ? _value.depthConfidence
          : depthConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      recoilAccuracy: freezed == recoilAccuracy
          ? _value.recoilAccuracy
          : recoilAccuracy // ignore: cast_nullable_to_non_nullable
              as double?,
      recoilConfidence: freezed == recoilConfidence
          ? _value.recoilConfidence
          : recoilConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      rateLabel: freezed == rateLabel
          ? _value.rateLabel
          : rateLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      depthLabel: freezed == depthLabel
          ? _value.depthLabel
          : depthLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      recoilLabel: freezed == recoilLabel
          ? _value.recoilLabel
          : recoilLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      isSimulated: null == isSimulated
          ? _value.isSimulated
          : isSimulated // ignore: cast_nullable_to_non_nullable
              as bool,
      isFreshPrediction: null == isFreshPrediction
          ? _value.isFreshPrediction
          : isFreshPrediction // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InferenceResultImplCopyWith<$Res>
    implements $InferenceResultCopyWith<$Res> {
  factory _$$InferenceResultImplCopyWith(_$InferenceResultImpl value,
          $Res Function(_$InferenceResultImpl) then) =
      __$$InferenceResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime timestamp,
      int topClassIndex,
      String topClassLabel,
      double topClassConfidence,
      Map<String, double> allClassScores,
      double currentBpm,
      double estimatedDepthCm,
      double elbowAngleMean,
      double spineVerticalityDeg,
      double? rateAccuracy,
      double? rateConfidence,
      double? depthAccuracy,
      double? depthConfidence,
      double? recoilAccuracy,
      double? recoilConfidence,
      String? rateLabel,
      String? depthLabel,
      String? recoilLabel,
      bool isSimulated,
      bool isFreshPrediction});
}

/// @nodoc
class __$$InferenceResultImplCopyWithImpl<$Res>
    extends _$InferenceResultCopyWithImpl<$Res, _$InferenceResultImpl>
    implements _$$InferenceResultImplCopyWith<$Res> {
  __$$InferenceResultImplCopyWithImpl(
      _$InferenceResultImpl _value, $Res Function(_$InferenceResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of InferenceResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? topClassIndex = null,
    Object? topClassLabel = null,
    Object? topClassConfidence = null,
    Object? allClassScores = null,
    Object? currentBpm = null,
    Object? estimatedDepthCm = null,
    Object? elbowAngleMean = null,
    Object? spineVerticalityDeg = null,
    Object? rateAccuracy = freezed,
    Object? rateConfidence = freezed,
    Object? depthAccuracy = freezed,
    Object? depthConfidence = freezed,
    Object? recoilAccuracy = freezed,
    Object? recoilConfidence = freezed,
    Object? rateLabel = freezed,
    Object? depthLabel = freezed,
    Object? recoilLabel = freezed,
    Object? isSimulated = null,
    Object? isFreshPrediction = null,
  }) {
    return _then(_$InferenceResultImpl(
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      topClassIndex: null == topClassIndex
          ? _value.topClassIndex
          : topClassIndex // ignore: cast_nullable_to_non_nullable
              as int,
      topClassLabel: null == topClassLabel
          ? _value.topClassLabel
          : topClassLabel // ignore: cast_nullable_to_non_nullable
              as String,
      topClassConfidence: null == topClassConfidence
          ? _value.topClassConfidence
          : topClassConfidence // ignore: cast_nullable_to_non_nullable
              as double,
      allClassScores: null == allClassScores
          ? _value._allClassScores
          : allClassScores // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      currentBpm: null == currentBpm
          ? _value.currentBpm
          : currentBpm // ignore: cast_nullable_to_non_nullable
              as double,
      estimatedDepthCm: null == estimatedDepthCm
          ? _value.estimatedDepthCm
          : estimatedDepthCm // ignore: cast_nullable_to_non_nullable
              as double,
      elbowAngleMean: null == elbowAngleMean
          ? _value.elbowAngleMean
          : elbowAngleMean // ignore: cast_nullable_to_non_nullable
              as double,
      spineVerticalityDeg: null == spineVerticalityDeg
          ? _value.spineVerticalityDeg
          : spineVerticalityDeg // ignore: cast_nullable_to_non_nullable
              as double,
      rateAccuracy: freezed == rateAccuracy
          ? _value.rateAccuracy
          : rateAccuracy // ignore: cast_nullable_to_non_nullable
              as double?,
      rateConfidence: freezed == rateConfidence
          ? _value.rateConfidence
          : rateConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      depthAccuracy: freezed == depthAccuracy
          ? _value.depthAccuracy
          : depthAccuracy // ignore: cast_nullable_to_non_nullable
              as double?,
      depthConfidence: freezed == depthConfidence
          ? _value.depthConfidence
          : depthConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      recoilAccuracy: freezed == recoilAccuracy
          ? _value.recoilAccuracy
          : recoilAccuracy // ignore: cast_nullable_to_non_nullable
              as double?,
      recoilConfidence: freezed == recoilConfidence
          ? _value.recoilConfidence
          : recoilConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      rateLabel: freezed == rateLabel
          ? _value.rateLabel
          : rateLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      depthLabel: freezed == depthLabel
          ? _value.depthLabel
          : depthLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      recoilLabel: freezed == recoilLabel
          ? _value.recoilLabel
          : recoilLabel // ignore: cast_nullable_to_non_nullable
              as String?,
      isSimulated: null == isSimulated
          ? _value.isSimulated
          : isSimulated // ignore: cast_nullable_to_non_nullable
              as bool,
      isFreshPrediction: null == isFreshPrediction
          ? _value.isFreshPrediction
          : isFreshPrediction // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$InferenceResultImpl implements _InferenceResult {
  const _$InferenceResultImpl(
      {required this.timestamp,
      required this.topClassIndex,
      required this.topClassLabel,
      required this.topClassConfidence,
      required final Map<String, double> allClassScores,
      required this.currentBpm,
      required this.estimatedDepthCm,
      required this.elbowAngleMean,
      required this.spineVerticalityDeg,
      this.rateAccuracy,
      this.rateConfidence,
      this.depthAccuracy,
      this.depthConfidence,
      this.recoilAccuracy,
      this.recoilConfidence,
      this.rateLabel,
      this.depthLabel,
      this.recoilLabel,
      this.isSimulated = false,
      this.isFreshPrediction = false})
      : _allClassScores = allClassScores;

  @override
  final DateTime timestamp;
  @override
  final int topClassIndex;
  @override
  final String topClassLabel;
  @override
  final double topClassConfidence;
  final Map<String, double> _allClassScores;
  @override
  Map<String, double> get allClassScores {
    if (_allClassScores is EqualUnmodifiableMapView) return _allClassScores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_allClassScores);
  }

  @override
  final double currentBpm;
  @override
  final double estimatedDepthCm;
  @override
  final double elbowAngleMean;
  @override
  final double spineVerticalityDeg;
// Per-task accuracy and confidence from TCN three-head model
  @override
  final double? rateAccuracy;
  @override
  final double? rateConfidence;
  @override
  final double? depthAccuracy;
  @override
  final double? depthConfidence;
  @override
  final double? recoilAccuracy;
  @override
  final double? recoilConfidence;
// Direct per-task labels from the 3-head web/API path (e.g. 'Correct',
// 'Too_Fast', 'Too_Shallow', 'Incomplete'). Null on mobile — the
// rule-based/8-class inference_service.dart never sets these, so
// consumers must fall back to topClassLabel/allClassScores when null.
  @override
  final String? rateLabel;
  @override
  final String? depthLabel;
  @override
  final String? recoilLabel;
  @override
  @JsonKey()
  final bool isSimulated;
// Distinguishes a frame carrying a genuinely-fresh API classification
// from one merely reusing the last cached result
// (inference_service_web.dart throttles real API calls to every
// ~600ms / 15 frames at 25fps, then serves the cached label+accuracy
// for up to 1.5s / ~37 frames afterward, restamped with that frame's
// own freshly-computed currentBpm/estimatedDepthCm). Only frames where
// isFreshPrediction=true should be accumulated into the live accuracy
// histories — otherwise a stale label gets re-scored against bpm/depth
// values that may have drifted since the API actually evaluated it.
  @override
  @JsonKey()
  final bool isFreshPrediction;

  @override
  String toString() {
    return 'InferenceResult(timestamp: $timestamp, topClassIndex: $topClassIndex, topClassLabel: $topClassLabel, topClassConfidence: $topClassConfidence, allClassScores: $allClassScores, currentBpm: $currentBpm, estimatedDepthCm: $estimatedDepthCm, elbowAngleMean: $elbowAngleMean, spineVerticalityDeg: $spineVerticalityDeg, rateAccuracy: $rateAccuracy, rateConfidence: $rateConfidence, depthAccuracy: $depthAccuracy, depthConfidence: $depthConfidence, recoilAccuracy: $recoilAccuracy, recoilConfidence: $recoilConfidence, rateLabel: $rateLabel, depthLabel: $depthLabel, recoilLabel: $recoilLabel, isSimulated: $isSimulated, isFreshPrediction: $isFreshPrediction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InferenceResultImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.topClassIndex, topClassIndex) ||
                other.topClassIndex == topClassIndex) &&
            (identical(other.topClassLabel, topClassLabel) ||
                other.topClassLabel == topClassLabel) &&
            (identical(other.topClassConfidence, topClassConfidence) ||
                other.topClassConfidence == topClassConfidence) &&
            const DeepCollectionEquality()
                .equals(other._allClassScores, _allClassScores) &&
            (identical(other.currentBpm, currentBpm) ||
                other.currentBpm == currentBpm) &&
            (identical(other.estimatedDepthCm, estimatedDepthCm) ||
                other.estimatedDepthCm == estimatedDepthCm) &&
            (identical(other.elbowAngleMean, elbowAngleMean) ||
                other.elbowAngleMean == elbowAngleMean) &&
            (identical(other.spineVerticalityDeg, spineVerticalityDeg) ||
                other.spineVerticalityDeg == spineVerticalityDeg) &&
            (identical(other.rateAccuracy, rateAccuracy) ||
                other.rateAccuracy == rateAccuracy) &&
            (identical(other.rateConfidence, rateConfidence) ||
                other.rateConfidence == rateConfidence) &&
            (identical(other.depthAccuracy, depthAccuracy) ||
                other.depthAccuracy == depthAccuracy) &&
            (identical(other.depthConfidence, depthConfidence) ||
                other.depthConfidence == depthConfidence) &&
            (identical(other.recoilAccuracy, recoilAccuracy) ||
                other.recoilAccuracy == recoilAccuracy) &&
            (identical(other.recoilConfidence, recoilConfidence) ||
                other.recoilConfidence == recoilConfidence) &&
            (identical(other.rateLabel, rateLabel) ||
                other.rateLabel == rateLabel) &&
            (identical(other.depthLabel, depthLabel) ||
                other.depthLabel == depthLabel) &&
            (identical(other.recoilLabel, recoilLabel) ||
                other.recoilLabel == recoilLabel) &&
            (identical(other.isSimulated, isSimulated) ||
                other.isSimulated == isSimulated) &&
            (identical(other.isFreshPrediction, isFreshPrediction) ||
                other.isFreshPrediction == isFreshPrediction));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        timestamp,
        topClassIndex,
        topClassLabel,
        topClassConfidence,
        const DeepCollectionEquality().hash(_allClassScores),
        currentBpm,
        estimatedDepthCm,
        elbowAngleMean,
        spineVerticalityDeg,
        rateAccuracy,
        rateConfidence,
        depthAccuracy,
        depthConfidence,
        recoilAccuracy,
        recoilConfidence,
        rateLabel,
        depthLabel,
        recoilLabel,
        isSimulated,
        isFreshPrediction
      ]);

  /// Create a copy of InferenceResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InferenceResultImplCopyWith<_$InferenceResultImpl> get copyWith =>
      __$$InferenceResultImplCopyWithImpl<_$InferenceResultImpl>(
          this, _$identity);
}

abstract class _InferenceResult implements InferenceResult {
  const factory _InferenceResult(
      {required final DateTime timestamp,
      required final int topClassIndex,
      required final String topClassLabel,
      required final double topClassConfidence,
      required final Map<String, double> allClassScores,
      required final double currentBpm,
      required final double estimatedDepthCm,
      required final double elbowAngleMean,
      required final double spineVerticalityDeg,
      final double? rateAccuracy,
      final double? rateConfidence,
      final double? depthAccuracy,
      final double? depthConfidence,
      final double? recoilAccuracy,
      final double? recoilConfidence,
      final String? rateLabel,
      final String? depthLabel,
      final String? recoilLabel,
      final bool isSimulated,
      final bool isFreshPrediction}) = _$InferenceResultImpl;

  @override
  DateTime get timestamp;
  @override
  int get topClassIndex;
  @override
  String get topClassLabel;
  @override
  double get topClassConfidence;
  @override
  Map<String, double> get allClassScores;
  @override
  double get currentBpm;
  @override
  double get estimatedDepthCm;
  @override
  double get elbowAngleMean;
  @override
  double
      get spineVerticalityDeg; // Per-task accuracy and confidence from TCN three-head model
  @override
  double? get rateAccuracy;
  @override
  double? get rateConfidence;
  @override
  double? get depthAccuracy;
  @override
  double? get depthConfidence;
  @override
  double? get recoilAccuracy;
  @override
  double?
      get recoilConfidence; // Direct per-task labels from the 3-head web/API path (e.g. 'Correct',
// 'Too_Fast', 'Too_Shallow', 'Incomplete'). Null on mobile — the
// rule-based/8-class inference_service.dart never sets these, so
// consumers must fall back to topClassLabel/allClassScores when null.
  @override
  String? get rateLabel;
  @override
  String? get depthLabel;
  @override
  String? get recoilLabel;
  @override
  bool
      get isSimulated; // Distinguishes a frame carrying a genuinely-fresh API classification
// from one merely reusing the last cached result
// (inference_service_web.dart throttles real API calls to every
// ~600ms / 15 frames at 25fps, then serves the cached label+accuracy
// for up to 1.5s / ~37 frames afterward, restamped with that frame's
// own freshly-computed currentBpm/estimatedDepthCm). Only frames where
// isFreshPrediction=true should be accumulated into the live accuracy
// histories — otherwise a stale label gets re-scored against bpm/depth
// values that may have drifted since the API actually evaluated it.
  @override
  bool get isFreshPrediction;

  /// Create a copy of InferenceResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InferenceResultImplCopyWith<_$InferenceResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$FeedbackPrompt {
  String get key => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  FeedbackSeverity get severity => throw _privateConstructorUsedError;
  DateTime get issuedAt => throw _privateConstructorUsedError;

  /// Create a copy of FeedbackPrompt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedbackPromptCopyWith<FeedbackPrompt> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedbackPromptCopyWith<$Res> {
  factory $FeedbackPromptCopyWith(
          FeedbackPrompt value, $Res Function(FeedbackPrompt) then) =
      _$FeedbackPromptCopyWithImpl<$Res, FeedbackPrompt>;
  @useResult
  $Res call(
      {String key,
      String message,
      FeedbackSeverity severity,
      DateTime issuedAt});
}

/// @nodoc
class _$FeedbackPromptCopyWithImpl<$Res, $Val extends FeedbackPrompt>
    implements $FeedbackPromptCopyWith<$Res> {
  _$FeedbackPromptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedbackPrompt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? message = null,
    Object? severity = null,
    Object? issuedAt = null,
  }) {
    return _then(_value.copyWith(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as FeedbackSeverity,
      issuedAt: null == issuedAt
          ? _value.issuedAt
          : issuedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeedbackPromptImplCopyWith<$Res>
    implements $FeedbackPromptCopyWith<$Res> {
  factory _$$FeedbackPromptImplCopyWith(_$FeedbackPromptImpl value,
          $Res Function(_$FeedbackPromptImpl) then) =
      __$$FeedbackPromptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String key,
      String message,
      FeedbackSeverity severity,
      DateTime issuedAt});
}

/// @nodoc
class __$$FeedbackPromptImplCopyWithImpl<$Res>
    extends _$FeedbackPromptCopyWithImpl<$Res, _$FeedbackPromptImpl>
    implements _$$FeedbackPromptImplCopyWith<$Res> {
  __$$FeedbackPromptImplCopyWithImpl(
      _$FeedbackPromptImpl _value, $Res Function(_$FeedbackPromptImpl) _then)
      : super(_value, _then);

  /// Create a copy of FeedbackPrompt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? message = null,
    Object? severity = null,
    Object? issuedAt = null,
  }) {
    return _then(_$FeedbackPromptImpl(
      key: null == key
          ? _value.key
          : key // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as FeedbackSeverity,
      issuedAt: null == issuedAt
          ? _value.issuedAt
          : issuedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$FeedbackPromptImpl implements _FeedbackPrompt {
  const _$FeedbackPromptImpl(
      {required this.key,
      required this.message,
      required this.severity,
      required this.issuedAt});

  @override
  final String key;
  @override
  final String message;
  @override
  final FeedbackSeverity severity;
  @override
  final DateTime issuedAt;

  @override
  String toString() {
    return 'FeedbackPrompt(key: $key, message: $message, severity: $severity, issuedAt: $issuedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedbackPromptImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.issuedAt, issuedAt) ||
                other.issuedAt == issuedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, key, message, severity, issuedAt);

  /// Create a copy of FeedbackPrompt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedbackPromptImplCopyWith<_$FeedbackPromptImpl> get copyWith =>
      __$$FeedbackPromptImplCopyWithImpl<_$FeedbackPromptImpl>(
          this, _$identity);
}

abstract class _FeedbackPrompt implements FeedbackPrompt {
  const factory _FeedbackPrompt(
      {required final String key,
      required final String message,
      required final FeedbackSeverity severity,
      required final DateTime issuedAt}) = _$FeedbackPromptImpl;

  @override
  String get key;
  @override
  String get message;
  @override
  FeedbackSeverity get severity;
  @override
  DateTime get issuedAt;

  /// Create a copy of FeedbackPrompt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedbackPromptImplCopyWith<_$FeedbackPromptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
