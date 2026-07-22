// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'landmark_frame.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$LandmarkFrame {
  DateTime get capturedAt =>
      throw _privateConstructorUsedError; // ── Raw MediaPipe landmark coordinates (normalized 0.0–1.0) ──
  double get leftShoulderX => throw _privateConstructorUsedError;
  double get leftShoulderY => throw _privateConstructorUsedError;
  double get rightShoulderX => throw _privateConstructorUsedError;
  double get rightShoulderY => throw _privateConstructorUsedError;
  double get leftElbowX => throw _privateConstructorUsedError;
  double get leftElbowY => throw _privateConstructorUsedError;
  double get rightElbowX => throw _privateConstructorUsedError;
  double get rightElbowY => throw _privateConstructorUsedError;
  double get leftWristX => throw _privateConstructorUsedError;
  double get leftWristY => throw _privateConstructorUsedError;
  double get rightWristX => throw _privateConstructorUsedError;
  double get rightWristY => throw _privateConstructorUsedError;
  double get leftHipX => throw _privateConstructorUsedError;
  double get leftHipY => throw _privateConstructorUsedError;
  double get rightHipX => throw _privateConstructorUsedError;
  double get rightHipY =>
      throw _privateConstructorUsedError; // ── Visibility scores from MediaPipe ─────────────────────────
  double get leftElbowVisibility => throw _privateConstructorUsedError;
  double get rightElbowVisibility => throw _privateConstructorUsedError;
  double get leftWristVisibility => throw _privateConstructorUsedError;
  double get rightWristVisibility =>
      throw _privateConstructorUsedError; // ── Derived metrics (computed by LandmarkMath) ────────────────
  double get leftElbowAngle => throw _privateConstructorUsedError; // degrees
  double get rightElbowAngle => throw _privateConstructorUsedError; // degrees
  double get spineVerticality =>
      throw _privateConstructorUsedError; // degrees from vertical
  double get wristMidX => throw _privateConstructorUsedError;
  double get wristMidY => throw _privateConstructorUsedError;
  double get shoulderWidth =>
      throw _privateConstructorUsedError; // normalised distance
// ── Temporal derivatives (computed across consecutive frames) ─
  double get wristVelocityY => throw _privateConstructorUsedError;
  double get wristAccelerationY =>
      throw _privateConstructorUsedError; // ── Quality flags ─────────────────────────────────────────────
  bool get allLandmarksVisible => throw _privateConstructorUsedError;
  double get meanLandmarkConfidence =>
      throw _privateConstructorUsedError; // ── Native camera frame size the landmarks are normalized against ─
// (video.videoWidth / video.videoHeight — NOT the on-screen widget
// size, which is usually cropped/scaled via CSS object-fit: cover).
// Needed by PoseOverlayPainter to correctly map normalized 0–1
// landmark coordinates onto the displayed canvas.
  double get sourceVideoWidth => throw _privateConstructorUsedError;
  double get sourceVideoHeight => throw _privateConstructorUsedError;

  /// Create a copy of LandmarkFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LandmarkFrameCopyWith<LandmarkFrame> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LandmarkFrameCopyWith<$Res> {
  factory $LandmarkFrameCopyWith(
          LandmarkFrame value, $Res Function(LandmarkFrame) then) =
      _$LandmarkFrameCopyWithImpl<$Res, LandmarkFrame>;
  @useResult
  $Res call(
      {DateTime capturedAt,
      double leftShoulderX,
      double leftShoulderY,
      double rightShoulderX,
      double rightShoulderY,
      double leftElbowX,
      double leftElbowY,
      double rightElbowX,
      double rightElbowY,
      double leftWristX,
      double leftWristY,
      double rightWristX,
      double rightWristY,
      double leftHipX,
      double leftHipY,
      double rightHipX,
      double rightHipY,
      double leftElbowVisibility,
      double rightElbowVisibility,
      double leftWristVisibility,
      double rightWristVisibility,
      double leftElbowAngle,
      double rightElbowAngle,
      double spineVerticality,
      double wristMidX,
      double wristMidY,
      double shoulderWidth,
      double wristVelocityY,
      double wristAccelerationY,
      bool allLandmarksVisible,
      double meanLandmarkConfidence,
      double sourceVideoWidth,
      double sourceVideoHeight});
}

/// @nodoc
class _$LandmarkFrameCopyWithImpl<$Res, $Val extends LandmarkFrame>
    implements $LandmarkFrameCopyWith<$Res> {
  _$LandmarkFrameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LandmarkFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? capturedAt = null,
    Object? leftShoulderX = null,
    Object? leftShoulderY = null,
    Object? rightShoulderX = null,
    Object? rightShoulderY = null,
    Object? leftElbowX = null,
    Object? leftElbowY = null,
    Object? rightElbowX = null,
    Object? rightElbowY = null,
    Object? leftWristX = null,
    Object? leftWristY = null,
    Object? rightWristX = null,
    Object? rightWristY = null,
    Object? leftHipX = null,
    Object? leftHipY = null,
    Object? rightHipX = null,
    Object? rightHipY = null,
    Object? leftElbowVisibility = null,
    Object? rightElbowVisibility = null,
    Object? leftWristVisibility = null,
    Object? rightWristVisibility = null,
    Object? leftElbowAngle = null,
    Object? rightElbowAngle = null,
    Object? spineVerticality = null,
    Object? wristMidX = null,
    Object? wristMidY = null,
    Object? shoulderWidth = null,
    Object? wristVelocityY = null,
    Object? wristAccelerationY = null,
    Object? allLandmarksVisible = null,
    Object? meanLandmarkConfidence = null,
    Object? sourceVideoWidth = null,
    Object? sourceVideoHeight = null,
  }) {
    return _then(_value.copyWith(
      capturedAt: null == capturedAt
          ? _value.capturedAt
          : capturedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      leftShoulderX: null == leftShoulderX
          ? _value.leftShoulderX
          : leftShoulderX // ignore: cast_nullable_to_non_nullable
              as double,
      leftShoulderY: null == leftShoulderY
          ? _value.leftShoulderY
          : leftShoulderY // ignore: cast_nullable_to_non_nullable
              as double,
      rightShoulderX: null == rightShoulderX
          ? _value.rightShoulderX
          : rightShoulderX // ignore: cast_nullable_to_non_nullable
              as double,
      rightShoulderY: null == rightShoulderY
          ? _value.rightShoulderY
          : rightShoulderY // ignore: cast_nullable_to_non_nullable
              as double,
      leftElbowX: null == leftElbowX
          ? _value.leftElbowX
          : leftElbowX // ignore: cast_nullable_to_non_nullable
              as double,
      leftElbowY: null == leftElbowY
          ? _value.leftElbowY
          : leftElbowY // ignore: cast_nullable_to_non_nullable
              as double,
      rightElbowX: null == rightElbowX
          ? _value.rightElbowX
          : rightElbowX // ignore: cast_nullable_to_non_nullable
              as double,
      rightElbowY: null == rightElbowY
          ? _value.rightElbowY
          : rightElbowY // ignore: cast_nullable_to_non_nullable
              as double,
      leftWristX: null == leftWristX
          ? _value.leftWristX
          : leftWristX // ignore: cast_nullable_to_non_nullable
              as double,
      leftWristY: null == leftWristY
          ? _value.leftWristY
          : leftWristY // ignore: cast_nullable_to_non_nullable
              as double,
      rightWristX: null == rightWristX
          ? _value.rightWristX
          : rightWristX // ignore: cast_nullable_to_non_nullable
              as double,
      rightWristY: null == rightWristY
          ? _value.rightWristY
          : rightWristY // ignore: cast_nullable_to_non_nullable
              as double,
      leftHipX: null == leftHipX
          ? _value.leftHipX
          : leftHipX // ignore: cast_nullable_to_non_nullable
              as double,
      leftHipY: null == leftHipY
          ? _value.leftHipY
          : leftHipY // ignore: cast_nullable_to_non_nullable
              as double,
      rightHipX: null == rightHipX
          ? _value.rightHipX
          : rightHipX // ignore: cast_nullable_to_non_nullable
              as double,
      rightHipY: null == rightHipY
          ? _value.rightHipY
          : rightHipY // ignore: cast_nullable_to_non_nullable
              as double,
      leftElbowVisibility: null == leftElbowVisibility
          ? _value.leftElbowVisibility
          : leftElbowVisibility // ignore: cast_nullable_to_non_nullable
              as double,
      rightElbowVisibility: null == rightElbowVisibility
          ? _value.rightElbowVisibility
          : rightElbowVisibility // ignore: cast_nullable_to_non_nullable
              as double,
      leftWristVisibility: null == leftWristVisibility
          ? _value.leftWristVisibility
          : leftWristVisibility // ignore: cast_nullable_to_non_nullable
              as double,
      rightWristVisibility: null == rightWristVisibility
          ? _value.rightWristVisibility
          : rightWristVisibility // ignore: cast_nullable_to_non_nullable
              as double,
      leftElbowAngle: null == leftElbowAngle
          ? _value.leftElbowAngle
          : leftElbowAngle // ignore: cast_nullable_to_non_nullable
              as double,
      rightElbowAngle: null == rightElbowAngle
          ? _value.rightElbowAngle
          : rightElbowAngle // ignore: cast_nullable_to_non_nullable
              as double,
      spineVerticality: null == spineVerticality
          ? _value.spineVerticality
          : spineVerticality // ignore: cast_nullable_to_non_nullable
              as double,
      wristMidX: null == wristMidX
          ? _value.wristMidX
          : wristMidX // ignore: cast_nullable_to_non_nullable
              as double,
      wristMidY: null == wristMidY
          ? _value.wristMidY
          : wristMidY // ignore: cast_nullable_to_non_nullable
              as double,
      shoulderWidth: null == shoulderWidth
          ? _value.shoulderWidth
          : shoulderWidth // ignore: cast_nullable_to_non_nullable
              as double,
      wristVelocityY: null == wristVelocityY
          ? _value.wristVelocityY
          : wristVelocityY // ignore: cast_nullable_to_non_nullable
              as double,
      wristAccelerationY: null == wristAccelerationY
          ? _value.wristAccelerationY
          : wristAccelerationY // ignore: cast_nullable_to_non_nullable
              as double,
      allLandmarksVisible: null == allLandmarksVisible
          ? _value.allLandmarksVisible
          : allLandmarksVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      meanLandmarkConfidence: null == meanLandmarkConfidence
          ? _value.meanLandmarkConfidence
          : meanLandmarkConfidence // ignore: cast_nullable_to_non_nullable
              as double,
      sourceVideoWidth: null == sourceVideoWidth
          ? _value.sourceVideoWidth
          : sourceVideoWidth // ignore: cast_nullable_to_non_nullable
              as double,
      sourceVideoHeight: null == sourceVideoHeight
          ? _value.sourceVideoHeight
          : sourceVideoHeight // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LandmarkFrameImplCopyWith<$Res>
    implements $LandmarkFrameCopyWith<$Res> {
  factory _$$LandmarkFrameImplCopyWith(
          _$LandmarkFrameImpl value, $Res Function(_$LandmarkFrameImpl) then) =
      __$$LandmarkFrameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime capturedAt,
      double leftShoulderX,
      double leftShoulderY,
      double rightShoulderX,
      double rightShoulderY,
      double leftElbowX,
      double leftElbowY,
      double rightElbowX,
      double rightElbowY,
      double leftWristX,
      double leftWristY,
      double rightWristX,
      double rightWristY,
      double leftHipX,
      double leftHipY,
      double rightHipX,
      double rightHipY,
      double leftElbowVisibility,
      double rightElbowVisibility,
      double leftWristVisibility,
      double rightWristVisibility,
      double leftElbowAngle,
      double rightElbowAngle,
      double spineVerticality,
      double wristMidX,
      double wristMidY,
      double shoulderWidth,
      double wristVelocityY,
      double wristAccelerationY,
      bool allLandmarksVisible,
      double meanLandmarkConfidence,
      double sourceVideoWidth,
      double sourceVideoHeight});
}

/// @nodoc
class __$$LandmarkFrameImplCopyWithImpl<$Res>
    extends _$LandmarkFrameCopyWithImpl<$Res, _$LandmarkFrameImpl>
    implements _$$LandmarkFrameImplCopyWith<$Res> {
  __$$LandmarkFrameImplCopyWithImpl(
      _$LandmarkFrameImpl _value, $Res Function(_$LandmarkFrameImpl) _then)
      : super(_value, _then);

  /// Create a copy of LandmarkFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? capturedAt = null,
    Object? leftShoulderX = null,
    Object? leftShoulderY = null,
    Object? rightShoulderX = null,
    Object? rightShoulderY = null,
    Object? leftElbowX = null,
    Object? leftElbowY = null,
    Object? rightElbowX = null,
    Object? rightElbowY = null,
    Object? leftWristX = null,
    Object? leftWristY = null,
    Object? rightWristX = null,
    Object? rightWristY = null,
    Object? leftHipX = null,
    Object? leftHipY = null,
    Object? rightHipX = null,
    Object? rightHipY = null,
    Object? leftElbowVisibility = null,
    Object? rightElbowVisibility = null,
    Object? leftWristVisibility = null,
    Object? rightWristVisibility = null,
    Object? leftElbowAngle = null,
    Object? rightElbowAngle = null,
    Object? spineVerticality = null,
    Object? wristMidX = null,
    Object? wristMidY = null,
    Object? shoulderWidth = null,
    Object? wristVelocityY = null,
    Object? wristAccelerationY = null,
    Object? allLandmarksVisible = null,
    Object? meanLandmarkConfidence = null,
    Object? sourceVideoWidth = null,
    Object? sourceVideoHeight = null,
  }) {
    return _then(_$LandmarkFrameImpl(
      capturedAt: null == capturedAt
          ? _value.capturedAt
          : capturedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      leftShoulderX: null == leftShoulderX
          ? _value.leftShoulderX
          : leftShoulderX // ignore: cast_nullable_to_non_nullable
              as double,
      leftShoulderY: null == leftShoulderY
          ? _value.leftShoulderY
          : leftShoulderY // ignore: cast_nullable_to_non_nullable
              as double,
      rightShoulderX: null == rightShoulderX
          ? _value.rightShoulderX
          : rightShoulderX // ignore: cast_nullable_to_non_nullable
              as double,
      rightShoulderY: null == rightShoulderY
          ? _value.rightShoulderY
          : rightShoulderY // ignore: cast_nullable_to_non_nullable
              as double,
      leftElbowX: null == leftElbowX
          ? _value.leftElbowX
          : leftElbowX // ignore: cast_nullable_to_non_nullable
              as double,
      leftElbowY: null == leftElbowY
          ? _value.leftElbowY
          : leftElbowY // ignore: cast_nullable_to_non_nullable
              as double,
      rightElbowX: null == rightElbowX
          ? _value.rightElbowX
          : rightElbowX // ignore: cast_nullable_to_non_nullable
              as double,
      rightElbowY: null == rightElbowY
          ? _value.rightElbowY
          : rightElbowY // ignore: cast_nullable_to_non_nullable
              as double,
      leftWristX: null == leftWristX
          ? _value.leftWristX
          : leftWristX // ignore: cast_nullable_to_non_nullable
              as double,
      leftWristY: null == leftWristY
          ? _value.leftWristY
          : leftWristY // ignore: cast_nullable_to_non_nullable
              as double,
      rightWristX: null == rightWristX
          ? _value.rightWristX
          : rightWristX // ignore: cast_nullable_to_non_nullable
              as double,
      rightWristY: null == rightWristY
          ? _value.rightWristY
          : rightWristY // ignore: cast_nullable_to_non_nullable
              as double,
      leftHipX: null == leftHipX
          ? _value.leftHipX
          : leftHipX // ignore: cast_nullable_to_non_nullable
              as double,
      leftHipY: null == leftHipY
          ? _value.leftHipY
          : leftHipY // ignore: cast_nullable_to_non_nullable
              as double,
      rightHipX: null == rightHipX
          ? _value.rightHipX
          : rightHipX // ignore: cast_nullable_to_non_nullable
              as double,
      rightHipY: null == rightHipY
          ? _value.rightHipY
          : rightHipY // ignore: cast_nullable_to_non_nullable
              as double,
      leftElbowVisibility: null == leftElbowVisibility
          ? _value.leftElbowVisibility
          : leftElbowVisibility // ignore: cast_nullable_to_non_nullable
              as double,
      rightElbowVisibility: null == rightElbowVisibility
          ? _value.rightElbowVisibility
          : rightElbowVisibility // ignore: cast_nullable_to_non_nullable
              as double,
      leftWristVisibility: null == leftWristVisibility
          ? _value.leftWristVisibility
          : leftWristVisibility // ignore: cast_nullable_to_non_nullable
              as double,
      rightWristVisibility: null == rightWristVisibility
          ? _value.rightWristVisibility
          : rightWristVisibility // ignore: cast_nullable_to_non_nullable
              as double,
      leftElbowAngle: null == leftElbowAngle
          ? _value.leftElbowAngle
          : leftElbowAngle // ignore: cast_nullable_to_non_nullable
              as double,
      rightElbowAngle: null == rightElbowAngle
          ? _value.rightElbowAngle
          : rightElbowAngle // ignore: cast_nullable_to_non_nullable
              as double,
      spineVerticality: null == spineVerticality
          ? _value.spineVerticality
          : spineVerticality // ignore: cast_nullable_to_non_nullable
              as double,
      wristMidX: null == wristMidX
          ? _value.wristMidX
          : wristMidX // ignore: cast_nullable_to_non_nullable
              as double,
      wristMidY: null == wristMidY
          ? _value.wristMidY
          : wristMidY // ignore: cast_nullable_to_non_nullable
              as double,
      shoulderWidth: null == shoulderWidth
          ? _value.shoulderWidth
          : shoulderWidth // ignore: cast_nullable_to_non_nullable
              as double,
      wristVelocityY: null == wristVelocityY
          ? _value.wristVelocityY
          : wristVelocityY // ignore: cast_nullable_to_non_nullable
              as double,
      wristAccelerationY: null == wristAccelerationY
          ? _value.wristAccelerationY
          : wristAccelerationY // ignore: cast_nullable_to_non_nullable
              as double,
      allLandmarksVisible: null == allLandmarksVisible
          ? _value.allLandmarksVisible
          : allLandmarksVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      meanLandmarkConfidence: null == meanLandmarkConfidence
          ? _value.meanLandmarkConfidence
          : meanLandmarkConfidence // ignore: cast_nullable_to_non_nullable
              as double,
      sourceVideoWidth: null == sourceVideoWidth
          ? _value.sourceVideoWidth
          : sourceVideoWidth // ignore: cast_nullable_to_non_nullable
              as double,
      sourceVideoHeight: null == sourceVideoHeight
          ? _value.sourceVideoHeight
          : sourceVideoHeight // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$LandmarkFrameImpl implements _LandmarkFrame {
  const _$LandmarkFrameImpl(
      {required this.capturedAt,
      required this.leftShoulderX,
      required this.leftShoulderY,
      required this.rightShoulderX,
      required this.rightShoulderY,
      required this.leftElbowX,
      required this.leftElbowY,
      required this.rightElbowX,
      required this.rightElbowY,
      required this.leftWristX,
      required this.leftWristY,
      required this.rightWristX,
      required this.rightWristY,
      required this.leftHipX,
      required this.leftHipY,
      required this.rightHipX,
      required this.rightHipY,
      required this.leftElbowVisibility,
      required this.rightElbowVisibility,
      required this.leftWristVisibility,
      required this.rightWristVisibility,
      required this.leftElbowAngle,
      required this.rightElbowAngle,
      required this.spineVerticality,
      required this.wristMidX,
      required this.wristMidY,
      required this.shoulderWidth,
      this.wristVelocityY = 0.0,
      this.wristAccelerationY = 0.0,
      this.allLandmarksVisible = false,
      this.meanLandmarkConfidence = 0.0,
      this.sourceVideoWidth = 0.0,
      this.sourceVideoHeight = 0.0});

  @override
  final DateTime capturedAt;
// ── Raw MediaPipe landmark coordinates (normalized 0.0–1.0) ──
  @override
  final double leftShoulderX;
  @override
  final double leftShoulderY;
  @override
  final double rightShoulderX;
  @override
  final double rightShoulderY;
  @override
  final double leftElbowX;
  @override
  final double leftElbowY;
  @override
  final double rightElbowX;
  @override
  final double rightElbowY;
  @override
  final double leftWristX;
  @override
  final double leftWristY;
  @override
  final double rightWristX;
  @override
  final double rightWristY;
  @override
  final double leftHipX;
  @override
  final double leftHipY;
  @override
  final double rightHipX;
  @override
  final double rightHipY;
// ── Visibility scores from MediaPipe ─────────────────────────
  @override
  final double leftElbowVisibility;
  @override
  final double rightElbowVisibility;
  @override
  final double leftWristVisibility;
  @override
  final double rightWristVisibility;
// ── Derived metrics (computed by LandmarkMath) ────────────────
  @override
  final double leftElbowAngle;
// degrees
  @override
  final double rightElbowAngle;
// degrees
  @override
  final double spineVerticality;
// degrees from vertical
  @override
  final double wristMidX;
  @override
  final double wristMidY;
  @override
  final double shoulderWidth;
// normalised distance
// ── Temporal derivatives (computed across consecutive frames) ─
  @override
  @JsonKey()
  final double wristVelocityY;
  @override
  @JsonKey()
  final double wristAccelerationY;
// ── Quality flags ─────────────────────────────────────────────
  @override
  @JsonKey()
  final bool allLandmarksVisible;
  @override
  @JsonKey()
  final double meanLandmarkConfidence;
// ── Native camera frame size the landmarks are normalized against ─
// (video.videoWidth / video.videoHeight — NOT the on-screen widget
// size, which is usually cropped/scaled via CSS object-fit: cover).
// Needed by PoseOverlayPainter to correctly map normalized 0–1
// landmark coordinates onto the displayed canvas.
  @override
  @JsonKey()
  final double sourceVideoWidth;
  @override
  @JsonKey()
  final double sourceVideoHeight;

  @override
  String toString() {
    return 'LandmarkFrame(capturedAt: $capturedAt, leftShoulderX: $leftShoulderX, leftShoulderY: $leftShoulderY, rightShoulderX: $rightShoulderX, rightShoulderY: $rightShoulderY, leftElbowX: $leftElbowX, leftElbowY: $leftElbowY, rightElbowX: $rightElbowX, rightElbowY: $rightElbowY, leftWristX: $leftWristX, leftWristY: $leftWristY, rightWristX: $rightWristX, rightWristY: $rightWristY, leftHipX: $leftHipX, leftHipY: $leftHipY, rightHipX: $rightHipX, rightHipY: $rightHipY, leftElbowVisibility: $leftElbowVisibility, rightElbowVisibility: $rightElbowVisibility, leftWristVisibility: $leftWristVisibility, rightWristVisibility: $rightWristVisibility, leftElbowAngle: $leftElbowAngle, rightElbowAngle: $rightElbowAngle, spineVerticality: $spineVerticality, wristMidX: $wristMidX, wristMidY: $wristMidY, shoulderWidth: $shoulderWidth, wristVelocityY: $wristVelocityY, wristAccelerationY: $wristAccelerationY, allLandmarksVisible: $allLandmarksVisible, meanLandmarkConfidence: $meanLandmarkConfidence, sourceVideoWidth: $sourceVideoWidth, sourceVideoHeight: $sourceVideoHeight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LandmarkFrameImpl &&
            (identical(other.capturedAt, capturedAt) ||
                other.capturedAt == capturedAt) &&
            (identical(other.leftShoulderX, leftShoulderX) ||
                other.leftShoulderX == leftShoulderX) &&
            (identical(other.leftShoulderY, leftShoulderY) ||
                other.leftShoulderY == leftShoulderY) &&
            (identical(other.rightShoulderX, rightShoulderX) ||
                other.rightShoulderX == rightShoulderX) &&
            (identical(other.rightShoulderY, rightShoulderY) ||
                other.rightShoulderY == rightShoulderY) &&
            (identical(other.leftElbowX, leftElbowX) ||
                other.leftElbowX == leftElbowX) &&
            (identical(other.leftElbowY, leftElbowY) ||
                other.leftElbowY == leftElbowY) &&
            (identical(other.rightElbowX, rightElbowX) ||
                other.rightElbowX == rightElbowX) &&
            (identical(other.rightElbowY, rightElbowY) ||
                other.rightElbowY == rightElbowY) &&
            (identical(other.leftWristX, leftWristX) ||
                other.leftWristX == leftWristX) &&
            (identical(other.leftWristY, leftWristY) ||
                other.leftWristY == leftWristY) &&
            (identical(other.rightWristX, rightWristX) ||
                other.rightWristX == rightWristX) &&
            (identical(other.rightWristY, rightWristY) ||
                other.rightWristY == rightWristY) &&
            (identical(other.leftHipX, leftHipX) ||
                other.leftHipX == leftHipX) &&
            (identical(other.leftHipY, leftHipY) ||
                other.leftHipY == leftHipY) &&
            (identical(other.rightHipX, rightHipX) ||
                other.rightHipX == rightHipX) &&
            (identical(other.rightHipY, rightHipY) ||
                other.rightHipY == rightHipY) &&
            (identical(other.leftElbowVisibility, leftElbowVisibility) ||
                other.leftElbowVisibility == leftElbowVisibility) &&
            (identical(other.rightElbowVisibility, rightElbowVisibility) ||
                other.rightElbowVisibility == rightElbowVisibility) &&
            (identical(other.leftWristVisibility, leftWristVisibility) ||
                other.leftWristVisibility == leftWristVisibility) &&
            (identical(other.rightWristVisibility, rightWristVisibility) ||
                other.rightWristVisibility == rightWristVisibility) &&
            (identical(other.leftElbowAngle, leftElbowAngle) ||
                other.leftElbowAngle == leftElbowAngle) &&
            (identical(other.rightElbowAngle, rightElbowAngle) ||
                other.rightElbowAngle == rightElbowAngle) &&
            (identical(other.spineVerticality, spineVerticality) ||
                other.spineVerticality == spineVerticality) &&
            (identical(other.wristMidX, wristMidX) ||
                other.wristMidX == wristMidX) &&
            (identical(other.wristMidY, wristMidY) ||
                other.wristMidY == wristMidY) &&
            (identical(other.shoulderWidth, shoulderWidth) ||
                other.shoulderWidth == shoulderWidth) &&
            (identical(other.wristVelocityY, wristVelocityY) ||
                other.wristVelocityY == wristVelocityY) &&
            (identical(other.wristAccelerationY, wristAccelerationY) ||
                other.wristAccelerationY == wristAccelerationY) &&
            (identical(other.allLandmarksVisible, allLandmarksVisible) ||
                other.allLandmarksVisible == allLandmarksVisible) &&
            (identical(other.meanLandmarkConfidence, meanLandmarkConfidence) ||
                other.meanLandmarkConfidence == meanLandmarkConfidence) &&
            (identical(other.sourceVideoWidth, sourceVideoWidth) ||
                other.sourceVideoWidth == sourceVideoWidth) &&
            (identical(other.sourceVideoHeight, sourceVideoHeight) ||
                other.sourceVideoHeight == sourceVideoHeight));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        capturedAt,
        leftShoulderX,
        leftShoulderY,
        rightShoulderX,
        rightShoulderY,
        leftElbowX,
        leftElbowY,
        rightElbowX,
        rightElbowY,
        leftWristX,
        leftWristY,
        rightWristX,
        rightWristY,
        leftHipX,
        leftHipY,
        rightHipX,
        rightHipY,
        leftElbowVisibility,
        rightElbowVisibility,
        leftWristVisibility,
        rightWristVisibility,
        leftElbowAngle,
        rightElbowAngle,
        spineVerticality,
        wristMidX,
        wristMidY,
        shoulderWidth,
        wristVelocityY,
        wristAccelerationY,
        allLandmarksVisible,
        meanLandmarkConfidence,
        sourceVideoWidth,
        sourceVideoHeight
      ]);

  /// Create a copy of LandmarkFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LandmarkFrameImplCopyWith<_$LandmarkFrameImpl> get copyWith =>
      __$$LandmarkFrameImplCopyWithImpl<_$LandmarkFrameImpl>(this, _$identity);
}

abstract class _LandmarkFrame implements LandmarkFrame {
  const factory _LandmarkFrame(
      {required final DateTime capturedAt,
      required final double leftShoulderX,
      required final double leftShoulderY,
      required final double rightShoulderX,
      required final double rightShoulderY,
      required final double leftElbowX,
      required final double leftElbowY,
      required final double rightElbowX,
      required final double rightElbowY,
      required final double leftWristX,
      required final double leftWristY,
      required final double rightWristX,
      required final double rightWristY,
      required final double leftHipX,
      required final double leftHipY,
      required final double rightHipX,
      required final double rightHipY,
      required final double leftElbowVisibility,
      required final double rightElbowVisibility,
      required final double leftWristVisibility,
      required final double rightWristVisibility,
      required final double leftElbowAngle,
      required final double rightElbowAngle,
      required final double spineVerticality,
      required final double wristMidX,
      required final double wristMidY,
      required final double shoulderWidth,
      final double wristVelocityY,
      final double wristAccelerationY,
      final bool allLandmarksVisible,
      final double meanLandmarkConfidence,
      final double sourceVideoWidth,
      final double sourceVideoHeight}) = _$LandmarkFrameImpl;

  @override
  DateTime
      get capturedAt; // ── Raw MediaPipe landmark coordinates (normalized 0.0–1.0) ──
  @override
  double get leftShoulderX;
  @override
  double get leftShoulderY;
  @override
  double get rightShoulderX;
  @override
  double get rightShoulderY;
  @override
  double get leftElbowX;
  @override
  double get leftElbowY;
  @override
  double get rightElbowX;
  @override
  double get rightElbowY;
  @override
  double get leftWristX;
  @override
  double get leftWristY;
  @override
  double get rightWristX;
  @override
  double get rightWristY;
  @override
  double get leftHipX;
  @override
  double get leftHipY;
  @override
  double get rightHipX;
  @override
  double
      get rightHipY; // ── Visibility scores from MediaPipe ─────────────────────────
  @override
  double get leftElbowVisibility;
  @override
  double get rightElbowVisibility;
  @override
  double get leftWristVisibility;
  @override
  double
      get rightWristVisibility; // ── Derived metrics (computed by LandmarkMath) ────────────────
  @override
  double get leftElbowAngle; // degrees
  @override
  double get rightElbowAngle; // degrees
  @override
  double get spineVerticality; // degrees from vertical
  @override
  double get wristMidX;
  @override
  double get wristMidY;
  @override
  double get shoulderWidth; // normalised distance
// ── Temporal derivatives (computed across consecutive frames) ─
  @override
  double get wristVelocityY;
  @override
  double
      get wristAccelerationY; // ── Quality flags ─────────────────────────────────────────────
  @override
  bool get allLandmarksVisible;
  @override
  double
      get meanLandmarkConfidence; // ── Native camera frame size the landmarks are normalized against ─
// (video.videoWidth / video.videoHeight — NOT the on-screen widget
// size, which is usually cropped/scaled via CSS object-fit: cover).
// Needed by PoseOverlayPainter to correctly map normalized 0–1
// landmark coordinates onto the displayed canvas.
  @override
  double get sourceVideoWidth;
  @override
  double get sourceVideoHeight;

  /// Create a copy of LandmarkFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LandmarkFrameImplCopyWith<_$LandmarkFrameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
