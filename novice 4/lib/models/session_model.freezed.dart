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
  String get id =>
      throw _privateConstructorUsedError; // millisecondsSinceEpoch string
  String get participantId =>
      throw _privateConstructorUsedError; // FK -> participants.participant_id (Supabase)
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime get endedAt => throw _privateConstructorUsedError;
  int get totalCompressions => throw _privateConstructorUsedError;
  double get meanBpm => throw _privateConstructorUsedError;
  double get meanDepthCm => throw _privateConstructorUsedError;
  double get cprFraction =>
      throw _privateConstructorUsedError; // % of session time actively compressing
  int get qualityScore =>
      throw _privateConstructorUsedError; // 0–100, derived from CNN-BiLSTM multi-task weighted formula (research: ml_pipeline/CPR_Coach_Training.ipynb cell 35)
  Map<String, double> get errorRates =>
      throw _privateConstructorUsedError; // classLabel → fraction of session frames classified as that label (model-derived)
  /// Per-task model accuracies from CNN-BiLSTM (test-set baseline reference)
  /// Example: {'rate': 0.76, 'depth': 0.94, 'recoil': 0.75}
  /// Research basis: Rate F1_w=75.92%, Depth F1_w=94.05%, Recoil F1_w=74.79%
  Map<String, double> get taskAccuracies => throw _privateConstructorUsedError;

  /// Per-task model confidence scores from inference
  /// Example: {'rate': 0.89, 'depth': 0.92, 'recoil': 0.81}
  /// Used for quality score weighting and session reliability assessment
  Map<String, double> get taskConfidences => throw _privateConstructorUsedError;
  String get language => throw _privateConstructorUsedError;
  bool get modelWasAvailable => throw _privateConstructorUsedError;

  /// Device identifier for performance tracking across sessions
  String? get deviceModel => throw _privateConstructorUsedError;

  /// Raw per-frame landmark data for retraining pipeline.
  /// Excluded from json_serializable — StorageService serialises frames
  /// manually via _frameToMap / exportFramesNdjson so we keep full control
  /// over the wire format and avoid bloating the freezed generated code.
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<LandmarkFrame> get rawFrames => throw _privateConstructorUsedError;

  /// Reviewer label assigned after session review (null = not yet reviewed).
  /// Values: 'correct' | 'incorrect' | 'partial'
  String? get reviewLabel => throw _privateConstructorUsedError;

  /// Optional free-text note from reviewer or researcher.
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
      Map<String, double> taskAccuracies,
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
    Object? taskAccuracies = null,
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
      taskAccuracies: null == taskAccuracies
          ? _value.taskAccuracies
          : taskAccuracies // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
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
      Map<String, double> taskAccuracies,
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
    Object? taskAccuracies = null,
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
      taskAccuracies: null == taskAccuracies
          ? _value._taskAccuracies
          : taskAccuracies // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
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
      final Map<String, double> taskAccuracies = const {},
      final Map<String, double> taskConfidences = const {},
      this.language = 'en',
      this.modelWasAvailable = false,
      this.deviceModel,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<LandmarkFrame> rawFrames = const [],
      this.reviewLabel,
      this.reviewNote})
      : _errorRates = errorRates,
        _taskAccuracies = taskAccuracies,
        _taskConfidences = taskConfidences,
        _rawFrames = rawFrames;

  factory _$SessionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionModelImplFromJson(json);

  @override
  final String id;
// millisecondsSinceEpoch string
  @override
  final String participantId;
// FK -> participants.participant_id (Supabase)
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
// % of session time actively compressing
  @override
  final int qualityScore;
// 0–100, derived from CNN-BiLSTM multi-task weighted formula (research: ml_pipeline/CPR_Coach_Training.ipynb cell 35)
  final Map<String, double> _errorRates;
// 0–100, derived from CNN-BiLSTM multi-task weighted formula (research: ml_pipeline/CPR_Coach_Training.ipynb cell 35)
  @override
  Map<String, double> get errorRates {
    if (_errorRates is EqualUnmodifiableMapView) return _errorRates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_errorRates);
  }

// classLabel → fraction of session frames classified as that label (model-derived)
  /// Per-task model accuracies from CNN-BiLSTM (test-set baseline reference)
  /// Example: {'rate': 0.76, 'depth': 0.94, 'recoil': 0.75}
  /// Research basis: Rate F1_w=75.92%, Depth F1_w=94.05%, Recoil F1_w=74.79%
  final Map<String, double> _taskAccuracies;
// classLabel → fraction of session frames classified as that label (model-derived)
  /// Per-task model accuracies from CNN-BiLSTM (test-set baseline reference)
  /// Example: {'rate': 0.76, 'depth': 0.94, 'recoil': 0.75}
  /// Research basis: Rate F1_w=75.92%, Depth F1_w=94.05%, Recoil F1_w=74.79%
  @override
  @JsonKey()
  Map<String, double> get taskAccuracies {
    if (_taskAccuracies is EqualUnmodifiableMapView) return _taskAccuracies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_taskAccuracies);
  }

  /// Per-task model confidence scores from inference
  /// Example: {'rate': 0.89, 'depth': 0.92, 'recoil': 0.81}
  /// Used for quality score weighting and session reliability assessment
  final Map<String, double> _taskConfidences;

  /// Per-task model confidence scores from inference
  /// Example: {'rate': 0.89, 'depth': 0.92, 'recoil': 0.81}
  /// Used for quality score weighting and session reliability assessment
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

  /// Device identifier for performance tracking across sessions
  @override
  final String? deviceModel;

  /// Raw per-frame landmark data for retraining pipeline.
  /// Excluded from json_serializable — StorageService serialises frames
  /// manually via _frameToMap / exportFramesNdjson so we keep full control
  /// over the wire format and avoid bloating the freezed generated code.
  final List<LandmarkFrame> _rawFrames;

  /// Raw per-frame landmark data for retraining pipeline.
  /// Excluded from json_serializable — StorageService serialises frames
  /// manually via _frameToMap / exportFramesNdjson so we keep full control
  /// over the wire format and avoid bloating the freezed generated code.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<LandmarkFrame> get rawFrames {
    if (_rawFrames is EqualUnmodifiableListView) return _rawFrames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rawFrames);
  }

  /// Reviewer label assigned after session review (null = not yet reviewed).
  /// Values: 'correct' | 'incorrect' | 'partial'
  @override
  final String? reviewLabel;

  /// Optional free-text note from reviewer or researcher.
  @override
  final String? reviewNote;

  @override
  String toString() {
    return 'SessionModel(id: $id, participantId: $participantId, startedAt: $startedAt, endedAt: $endedAt, totalCompressions: $totalCompressions, meanBpm: $meanBpm, meanDepthCm: $meanDepthCm, cprFraction: $cprFraction, qualityScore: $qualityScore, errorRates: $errorRates, taskAccuracies: $taskAccuracies, taskConfidences: $taskConfidences, language: $language, modelWasAvailable: $modelWasAvailable, deviceModel: $deviceModel, rawFrames: $rawFrames, reviewLabel: $reviewLabel, reviewNote: $reviewNote)';
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
            const DeepCollectionEquality()
                .equals(other._taskAccuracies, _taskAccuracies) &&
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
  int get hashCode => Object.hash(
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
      const DeepCollectionEquality().hash(_taskAccuracies),
      const DeepCollectionEquality().hash(_taskConfidences),
      language,
      modelWasAvailable,
      deviceModel,
      const DeepCollectionEquality().hash(_rawFrames),
      reviewLabel,
      reviewNote);

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
      final Map<String, double> taskAccuracies,
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
  String get id; // millisecondsSinceEpoch string
  @override
  String get participantId; // FK -> participants.participant_id (Supabase)
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
  double get cprFraction; // % of session time actively compressing
  @override
  int get qualityScore; // 0–100, derived from CNN-BiLSTM multi-task weighted formula (research: ml_pipeline/CPR_Coach_Training.ipynb cell 35)
  @override
  Map<String, double>
      get errorRates; // classLabel → fraction of session frames classified as that label (model-derived)
  /// Per-task model accuracies from CNN-BiLSTM (test-set baseline reference)
  /// Example: {'rate': 0.76, 'depth': 0.94, 'recoil': 0.75}
  /// Research basis: Rate F1_w=75.92%, Depth F1_w=94.05%, Recoil F1_w=74.79%
  @override
  Map<String, double> get taskAccuracies;

  /// Per-task model confidence scores from inference
  /// Example: {'rate': 0.89, 'depth': 0.92, 'recoil': 0.81}
  /// Used for quality score weighting and session reliability assessment
  @override
  Map<String, double> get taskConfidences;
  @override
  String get language;
  @override
  bool get modelWasAvailable;

  /// Device identifier for performance tracking across sessions
  @override
  String? get deviceModel;

  /// Raw per-frame landmark data for retraining pipeline.
  /// Excluded from json_serializable — StorageService serialises frames
  /// manually via _frameToMap / exportFramesNdjson so we keep full control
  /// over the wire format and avoid bloating the freezed generated code.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<LandmarkFrame> get rawFrames;

  /// Reviewer label assigned after session review (null = not yet reviewed).
  /// Values: 'correct' | 'incorrect' | 'partial'
  @override
  String? get reviewLabel;

  /// Optional free-text note from reviewer or researcher.
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
      throw _privateConstructorUsedError; // Per-task metrics from CNN-BiLSTM three-head model
  double? get rateAccuracy =>
      throw _privateConstructorUsedError; // Rate classification accuracy (0.0–1.0)
  double? get rateConfidence =>
      throw _privateConstructorUsedError; // Rate classification confidence
  double? get depthAccuracy =>
      throw _privateConstructorUsedError; // Depth classification accuracy (0.0–1.0)
  double? get depthConfidence =>
      throw _privateConstructorUsedError; // Depth classification confidence
  double? get recoilAccuracy =>
      throw _privateConstructorUsedError; // Recoil classification accuracy (0.0–1.0)
  double? get recoilConfidence =>
      throw _privateConstructorUsedError; // Recoil classification confidence
  bool get isSimulated => throw _privateConstructorUsedError;

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
      bool isSimulated});
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
    Object? isSimulated = null,
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
      isSimulated: null == isSimulated
          ? _value.isSimulated
          : isSimulated // ignore: cast_nullable_to_non_nullable
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
      bool isSimulated});
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
    Object? isSimulated = null,
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
      isSimulated: null == isSimulated
          ? _value.isSimulated
          : isSimulated // ignore: cast_nullable_to_non_nullable
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
      this.isSimulated = false})
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
// Per-task metrics from CNN-BiLSTM three-head model
  @override
  final double? rateAccuracy;
// Rate classification accuracy (0.0–1.0)
  @override
  final double? rateConfidence;
// Rate classification confidence
  @override
  final double? depthAccuracy;
// Depth classification accuracy (0.0–1.0)
  @override
  final double? depthConfidence;
// Depth classification confidence
  @override
  final double? recoilAccuracy;
// Recoil classification accuracy (0.0–1.0)
  @override
  final double? recoilConfidence;
// Recoil classification confidence
  @override
  @JsonKey()
  final bool isSimulated;

  @override
  String toString() {
    return 'InferenceResult(timestamp: $timestamp, topClassIndex: $topClassIndex, topClassLabel: $topClassLabel, topClassConfidence: $topClassConfidence, allClassScores: $allClassScores, currentBpm: $currentBpm, estimatedDepthCm: $estimatedDepthCm, elbowAngleMean: $elbowAngleMean, spineVerticalityDeg: $spineVerticalityDeg, rateAccuracy: $rateAccuracy, rateConfidence: $rateConfidence, depthAccuracy: $depthAccuracy, depthConfidence: $depthConfidence, recoilAccuracy: $recoilAccuracy, recoilConfidence: $recoilConfidence, isSimulated: $isSimulated)';
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
            (identical(other.isSimulated, isSimulated) ||
                other.isSimulated == isSimulated));
  }

  @override
  int get hashCode => Object.hash(
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
      isSimulated);

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
      final bool isSimulated}) = _$InferenceResultImpl;

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
      get spineVerticalityDeg; // Per-task metrics from CNN-BiLSTM three-head model
  @override
  double? get rateAccuracy; // Rate classification accuracy (0.0–1.0)
  @override
  double? get rateConfidence; // Rate classification confidence
  @override
  double? get depthAccuracy; // Depth classification accuracy (0.0–1.0)
  @override
  double? get depthConfidence; // Depth classification confidence
  @override
  double? get recoilAccuracy; // Recoil classification accuracy (0.0–1.0)
  @override
  double? get recoilConfidence; // Recoil classification confidence
  @override
  bool get isSimulated;

  /// Create a copy of InferenceResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InferenceResultImplCopyWith<_$InferenceResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$FeedbackPrompt {
  String get key =>
      throw _privateConstructorUsedError; // matches AppConstants.promptsEn keys
  String get message =>
      throw _privateConstructorUsedError; // resolved string in active language
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
// matches AppConstants.promptsEn keys
  @override
  final String message;
// resolved string in active language
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
  String get key; // matches AppConstants.promptsEn keys
  @override
  String get message; // resolved string in active language
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
