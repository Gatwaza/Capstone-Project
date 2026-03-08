import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/app_constants.dart';
import '../core/di/injection.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/landmark_math.dart';
import '../models/landmark_frame.dart';
import '../models/session_model.dart';
import '../services/feedback_engine.dart';
import '../services/inference_service.dart';
import '../services/pose_service.dart';
import '../services/session_logger.dart';
import '../services/tts_service.dart';
import '../widgets/bpm_indicator.dart';
import '../widgets/feedback_banner.dart';
import '../widgets/pose_overlay.dart';
import '../widgets/compression_gauge.dart';
import 'results_screen.dart';

class TrainingScreen extends StatefulWidget {
  final String lang;
  const TrainingScreen({super.key, required this.lang});
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with WidgetsBindingObserver {
  // Services
  late final PoseService _poseService;
  late final FeedbackEngine _engine;

  CameraController? _cameraController;
  Timer? _sessionTimer;

  // State
  bool _permissionGranted = false;
  bool _cameraReady = false;
  bool _sessionStarted = false;
  int _timeLeft = AppConstants.sessionDurationSeconds;
  EngineMetrics _metrics = const EngineMetrics(
      accuracy: 0, frameCount: 0, totalCompressions: 0);
  String? _currentPromptKey;
  FeedbackType _feedbackType = FeedbackType.idle;
  Map<PoseLandmarkType, PoseLandmark>? _landmarks;
  Size? _imageSize;
  final List<FeedbackEvent> _events = [];
  double _depthNorm = 0.0;
  String _sessionId = '';

  // Calibration
  double _baselineWristY = 0.5;
  double _refShoulderWidth = 0.3;
  bool _calibrated = false;
  int _calibrationFrames = 0;

  // Feature tracking
  double _prevWristY = 0.5;
  double _prevVelY = 0.0;
  final List<double> _wristYBuffer = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    _poseService = PoseService(onFrame: _onPoseFrame);
    _engine = FeedbackEngine(
      tts: getIt<TtsService>(),
      inference: getIt<InferenceService>(),
      onMetricsUpdate: (m) {
        if (mounted) setState(() => _metrics = m);
      },
      onFeedbackEvent: (e) {
        if (mounted) {
          setState(() {
            _events.add(e);
            _currentPromptKey = e.promptKey;
            _feedbackType = e.priority == AppConstants.priorityCritical
                ? FeedbackType.critical
                : e.priority == AppConstants.priorityEncouragement
                    ? FeedbackType.positive
                    : FeedbackType.coaching;
          });
        }
      },
    );

    _init();
  }

  Future<void> _init() async {
    await _poseService.initialize();
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() => _permissionGranted = true);
      final controller = await _poseService.startCamera();
      if (mounted && controller != null) {
        setState(() {
          _cameraController = controller;
          _cameraReady = true;
          _imageSize = Size(
            controller.value.previewSize?.height ?? 480,
            controller.value.previewSize?.width ?? 640,
          );
        });
        _startSession();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startSession() {
    _engine.startSession();
    setState(() => _sessionStarted = true);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft == 15) {
        getIt<TtsService>().enqueue(
            AppConstants.promptAlmostThere, AppConstants.priorityCoaching);
      }
      if (_timeLeft <= 0) _endSession();
    });
  }

  void _onPoseFrame(LandmarkFrame frame) {
    if (!mounted || !_sessionStarted) return;
    setState(() => _landmarks = frame.landmarks.isEmpty ? null : frame.landmarks);

    if (frame.landmarks.isEmpty) {
      _engine.processFrame(
        features: const {},
        wristY: null,
        spineAngle: null,
        featureVector: null,
        hasSufficientLandmarks: false,
      );
      return;
    }

    final lm = frame.landmarks;
    final wristY = frame.wristY;
    final sw = frame.shoulderWidth ?? 0.3;

    // Calibrate baseline
    if (!_calibrated) {
      _calibrationFrames++;
      if (wristY != null && _calibrationFrames == 1) {
        _baselineWristY = wristY;
        _refShoulderWidth = sw;
      }
      if (_calibrationFrames >= AppConstants.baselineCalibrationFrames) {
        _calibrated = true;
      }
    }

    // Build feature vector
    List<double>? features;
    if (_calibrated) {
      features = LandmarkMath.featureVector(
        lm,
        prevWristY: _prevWristY,
        prevVelY: _prevVelY,
        baselineWristY: _baselineWristY,
        refShoulderWidth: _refShoulderWidth,
      );
      if (wristY != null) {
        final vel = wristY - _prevWristY;
        _prevVelY = vel;
        _prevWristY = wristY;
        _wristYBuffer.add(wristY);
        if (_wristYBuffer.length > 300) _wristYBuffer.removeAt(0);
      }
    }

    // Update depth normalised for gauge display
    if (_calibrated && wristY != null) {
      final disp = (wristY - _baselineWristY).abs();
      setState(() => _depthNorm = (disp / (_refShoulderWidth + 0.001)).clamp(0.0, 1.0));
    }

    _engine.processFrame(
      features: {
        'shoulderWidth': sw,
        'wristY': wristY,
      },
      wristY: wristY,
      spineAngle: frame.spineVerticality,
      featureVector: features,
      hasSufficientLandmarks: frame.hasSufficientVisibility,
    );
  }

  Future<void> _endSession() async {
    _sessionTimer?.cancel();
    _engine.stopSession();
    await _poseService.stopCamera();

    final session = _engine.buildSession(
      id: _sessionId,
      lang: widget.lang,
      duration: AppConstants.sessionDurationSeconds - _timeLeft,
    );

    await getIt<SessionLogger>().saveSession(session);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(sessionId: _sessionId),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    _engine.stopSession();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera preview ──────────────────────────────────────────────
          if (_cameraReady && _cameraController != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            Container(
              color: AppColors.background,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accentRed),
              ),
            ),

          // ── Skeleton overlay ────────────────────────────────────────────
          if (_landmarks != null && _imageSize != null)
            Positioned.fill(
              child: PoseOverlay(
                landmarks: _landmarks,
                imageSize: _imageSize!,
                mirror: true,
              ),
            ),

          // ── Top HUD: timer + stop ───────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _timerBadge(),
                    _stopButton(),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom dashboard ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _metricsRow(),
                    const SizedBox(height: 12),
                    FeedbackBanner(
                      promptKey: _currentPromptKey,
                      lang: widget.lang,
                      type: _feedbackType,
                    ),
                    const SizedBox(height: 10),
                    BpmRangeBar(bpm: _metrics.bpm),
                    if (!getIt<InferenceService>().modelLoaded)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '⚡ Rule-based mode — train model to enable AI feedback',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // ── Depth gauge (right edge overlay) ─────────────────────────
          if (_metrics.frameCount > 10)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: CompressionGauge(
                  depth: _depthNorm,
                  elbowsLocked: _metrics.currentLabel != 'bent_elbows',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timerBadge() {
    final m = _timeLeft ~/ 60;
    final s = (_timeLeft % 60).toString().padLeft(2, '0');
    final isLow = _timeLeft <= 30;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (isLow ? AppColors.accentRed : AppColors.surface).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$m:$s',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _stopButton() {
    return GestureDetector(
      onTap: _endSession,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.stop_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _metricsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        BpmIndicator(bpm: _metrics.bpm, large: true),
        _divider(),
        _metricColumn(
          '${(_metrics.accuracy * 100).round()}%',
          'Accuracy',
          _metrics.accuracy > 0.8 ? AppColors.accentGreen : AppColors.accentAmber,
        ),
        _divider(),
        _metricColumn(
          '${_metrics.totalCompressions}',
          'Compressions',
          AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 50, color: AppColors.divider);
  }

  Widget _metricColumn(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()])),
        Text(label,
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.5)),
      ],
    );
  }
}
