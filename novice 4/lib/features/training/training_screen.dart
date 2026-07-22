// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js show context;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Web-only build: google_mlkit_pose_detection is mobile-only and no longer
// a dependency. mlkit_stub.dart supplies the InputImageRotation type used
// below. If mobile work resumes, swap this back to the conditional import:
//   import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
//       if (dart.library.html) '../../core/utils/mlkit_stub.dart';
import '../../core/utils/mlkit_stub.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/session_provider.dart';
import '../../core/di/injection.dart';
import '../../services/platform/pose_service_interface.dart';
import '../../widgets/bpm_indicator.dart';
import '../../widgets/compression_gauge.dart';
import '../../widgets/pose_overlay.dart';

// Web-only build: permission_handler is mobile-only and no longer a
// dependency. permission_stub.dart supplies the Permission type used below.
// If mobile work resumes, swap this back to the conditional import:
//   import 'package:permission_handler/permission_handler.dart'
//       if (dart.library.html) '../../core/utils/permission_stub.dart';
import '../../core/utils/permission_stub.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key, required this.participantId});

  /// The participant this session will be logged under. Required — there is
  /// no anonymous training path. Comes from either a freshly-assigned ID
  /// (ConsentScreen, new registration) or a chosen existing one
  /// (ParticipantGateScreen, returning participant). The same ID can appear
  /// on many sessions; the backend distinguishes sessions by session_id and
  /// groups them by this participant_id (see participant_progress view).
  final String participantId;

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  CameraController? _camera;
  bool _cameraReady = false;
  bool _permissionDenied = false;
  Timer? _webPoseTimer;

  // Tracks whether the MediaPipe JS bridge has confirmed a valid frame.
  // The crash "roi->width > 0 && roi->height > 0" happens if the poll
  // loop starts before the <video> element has non-zero dimensions, so we
  // wait until the JS bridge sets window._novicePoseReady = true (inside
  // its onResults callback) or until a 4-second timeout, then start the loop.
  bool _poseReady = false;
  Timer? _poseReadyPoller;

  late final PoseServiceInterface _poseService;

  @override
  void initState() {
    super.initState();
    _poseService = getIt<PoseServiceInterface>();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() => _permissionDenied = true);
        return;
      }
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _camera = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup:
          kIsWeb ? ImageFormatGroup.jpeg : ImageFormatGroup.bgra8888,
    );

    await _camera!.initialize();
    if (!mounted) return;
    setState(() => _cameraReady = true);

    if (kIsWeb) {
      // Do NOT poll MediaPipe immediately after initialize(). The Flutter
      // camera plugin attaches the stream to a <video> element, but the
      // element has videoWidth=0/videoHeight=0 until the browser paints the
      // first decoded frame, and sending a frame to MediaPipe before that
      // causes a fatal RET_CHECK crash. We poll a JS readiness flag set by
      // the bridge after its own first successful onResults, then start the
      // pose loop. PoseServiceWeb also guards per-frame as a secondary
      // safety net.
      _waitForPoseBridgeReady();
    } else {
      _camera!.startImageStream(_onCameraFrame);
    }
  }

  /// Polls `window._novicePoseReady` (set by the JS bridge) every 100 ms.
  /// Starts the pose loop once ready, or after a 4-second timeout (at which
  /// point PoseServiceWeb's own JS guard handles any remaining bad frames).
  void _waitForPoseBridgeReady() {
    const pollInterval = Duration(milliseconds: 100);
    const maxWait = Duration(seconds: 4);
    final deadline = DateTime.now().add(maxWait);

    _poseReadyPoller = Timer.periodic(pollInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      bool jsReady = false;
      try {
        // _novicePoseReady is set to true by the MediaPipe JS bridge inside
        // its onResults callback once it receives a frame with valid dimensions.
        jsReady = js.context['_novicePoseReady'] == true;
      } catch (_) {
        // js.context access can throw if the bridge hasn't loaded yet — treat
        // as not ready and keep polling.
      }

      final timedOut = DateTime.now().isAfter(deadline);

      if (jsReady || timedOut) {
        timer.cancel();
        if (mounted) {
          setState(() => _poseReady = true);
          _startWebPoseLoop();
        }
      }
    });
  }

  void _startWebPoseLoop() {
    // Polls at AppConstants.poseEstimationTargetFps (25fps, ~40ms) rather
    // than a slower fixed interval — the skeleton overlay and the
    // compression-counting state machine both need enough velocity samples
    // per second to stay responsive; too slow a poll makes the overlay
    // stair-step and delays feedback relative to when the user actually
    // moved.
    final intervalMs = (1000 / AppConstants.poseEstimationTargetFps).round();
    _webPoseTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) {
        final session = ref.read(liveSessionProvider);
        if (!session.isActive) return;
        _poseService.processFrame(null, null).then((frame) {
          if (frame != null && mounted) {
            ref.read(liveSessionProvider.notifier).onFrame(frame);
          }
        });
      },
    );
  }

  void _onCameraFrame(CameraImage image) {
    final session = ref.read(liveSessionProvider);
    if (!session.isActive) return;
    _poseService
        .processFrame(image, InputImageRotation.rotation270deg)
        .then((frame) {
      if (frame != null && mounted) {
        ref.read(liveSessionProvider.notifier).onFrame(frame);
      }
    });
  }

  Future<void> _onStartStop() async {
    final session = ref.read(liveSessionProvider);
    if (session.isActive) {
      final id = await ref.read(liveSessionProvider.notifier).stopSession();
      if (mounted && id != null) {
        context.pushReplacement('/results/$id');
      }
    } else {
      ref.read(liveSessionProvider.notifier).startSession(widget.participantId);
    }
  }

  @override
  void dispose() {
    _poseReadyPoller?.cancel();
    _webPoseTimer?.cancel();
    if (!kIsWeb) _camera?.stopImageStream();
    _camera?.dispose();
    super.dispose();
  }

  /// Reads the <video> element's native pixel dimensions from the same JS
  /// globals flutter_pose_bridge.js sets once the browser has decoded a
  /// real frame (window._novicePoseVideoWidth/Height — see pose_bridge.js
  /// around the videoWidth/videoHeight readiness check). Returns null
  /// before those are available, or off web, so PoseOverlayPainter falls
  /// back to its old direct-mapping behaviour rather than drawing at a
  /// bogus size.
  Size? _nativeVideoSize() {
    if (!kIsWeb) return null;
    final w = js.context['_novicePoseVideoWidth'];
    final h = js.context['_novicePoseVideoHeight'];
    final width = (w is num) ? w.toDouble() : 0.0;
    final height = (h is num) ? h.toDouble() : 0.0;
    if (width <= 0 || height <= 0) return null;
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(liveSessionProvider);
    if (_permissionDenied) return _buildPermissionDenied();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ───────────────────────────────
          if (_cameraReady && _camera != null)
            CameraPreview(_camera!)
          else
            Container(
              color: AppTheme.surfaceDark,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      kIsWeb
                          ? 'Initialising camera…\nAllow camera access when prompted.'
                          : 'Starting camera…',
                      style: TextStyle(
                          color: AppTheme.textSecondaryDark, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // ── Pose bridge warming up (web only) ────────────
          if (kIsWeb && _cameraReady && !_poseReady)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Initialising pose detection…',
                    style:
                        TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12),
                  ),
                ),
              ),
            ),

          // ── Live skeleton overlay ─────────────────────────
          // Draws the actual tracked shoulders/elbows/wrists/hips for this
          // frame — the same landmarks the model is trained on — instead of
          // a fixed placeholder circle, so what's on screen reflects the
          // user's real movement.
          //
          // `frame` is session.smoothedFrame (a one-euro-filtered display
          // copy — see landmark_smoother.dart), not session.lastFrame, so
          // ordinary MediaPipe frame-to-frame jitter doesn't read as a
          // visibly shaky skeleton. Falls back to the raw lastFrame for the
          // handful of frames before the first smoothed frame exists.
          // Inference, compression counting, and hand placement all still
          // read the raw lastFrame elsewhere — only this painter gets the
          // smoothed copy.
          //
          // videoSize is the <video> element's *native* pixel dimensions
          // (e.g. a landscape 1280×720 stream), read from the same JS
          // globals flutter_pose_bridge.js already exposes. MediaPipe's
          // landmarks are normalized against that native frame, not
          // against this portrait screen, so the overlay painter needs it
          // to replicate the video's cover-fit crop — without it, the
          // skeleton drifts toward one corner instead of tracking the
          // person on screen.
          if ((session.smoothedFrame ?? session.lastFrame) != null)
            CustomPaint(
              painter: PoseOverlayPainter(
                frame: session.smoothedFrame ?? session.lastFrame,
                inference: session.lastInference,
                handPlacement: session.handPlacement,
                videoSize: _nativeVideoSize(),
              ),
            ),

          // ── Scan frame corners ───────────────────────────
          if (session.isActive) const _ScanFrame(),

          // ── Top HUD ──────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _HudButton(
                  icon: Icons.arrow_back_ios_rounded,
                  // Was context.pop(), which just returns to whatever's
                  // below Training on the stack (the participant gate) —
                  // not a real exit. Camera/pose teardown still happens
                  // normally via dispose() below regardless of how the
                  // widget is removed, so this is safe mid-session.
                  onTap: () => context.go(AppRoutes.home),
                ),
                const Spacer(),
                BpmIndicator(bpm: session.bpm),
                const SizedBox(width: 12),
                _HudChip(
                  label: session.elapsedFormatted,
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(width: 12),
                _HudButton(
                  label: session.language.toUpperCase(),
                  onTap: () {
                    final next = session.language == 'en' ? 'rw' : 'en';
                    ref.read(liveSessionProvider.notifier).setLanguage(next);
                  },
                ),
              ],
            ),
          ),

          // ── Right side depth gauge ───────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 16,
            child: CompressionGauge(depthCm: session.depthCm),
          ),

          // ── Left side compression count ──────────────────
          if (session.isActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              child: Column(
                children: [
                  _HudChip(
                    label: '${session.compressions}',
                    sublabel: 'compressions',
                    icon: Icons.compress_rounded,
                  ),
                  const SizedBox(height: 12),
                  _TaskIndicators(
                    taskAccuracies: session.taskAccuracies,
                  ),
                ],
              ),
            ),

          // ── Feedback banner ──────────────────────────────
          if (session.currentPrompt != null)
            Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: FeedbackBanner(prompt: session.currentPrompt!),
            ),

          // ── Start / Stop ─────────────────────────────────
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _onStartStop,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    session.isActive ? AppTheme.accentWarn : AppTheme.accent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                session.isActive ? 'Stop Session' : 'Start Session',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_outlined,
                  color: AppTheme.textSecondary, size: 48),
              const SizedBox(height: 16),
              Text('Camera access required',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Novice uses the camera for real-time pose estimation. '
                'Enable camera access in Settings.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const ElevatedButton(
                onPressed: openAppSettings,
                child: Text('Open Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable HUD widgets ──────────────────────────────────

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: CustomPaint(painter: _ScanFramePainter()),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const len = 28.0;
    canvas.drawPath(
        Path()
          ..moveTo(0, len)
          ..lineTo(0, 0)
          ..lineTo(len, 0),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(size.width - len, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, len),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height - len)
          ..lineTo(0, size.height)
          ..lineTo(len, size.height),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(size.width - len, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width, size.height - len),
        paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _HudButton extends StatelessWidget {
  const _HudButton({this.icon, this.label, required this.onTap});
  final IconData? icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 18)
              : Text(label ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({required this.label, this.sublabel, this.icon});
  final String label;
  final String? sublabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.accent, size: 14),
            const SizedBox(width: 5),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              if (sublabel != null)
                Text(sublabel!,
                    style: const TextStyle(
                        color: AppTheme.textSecondaryDark,
                        fontSize: 9,
                        letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Task accuracy indicators (live during session) ──────────────────────────

class _TaskIndicators extends StatelessWidget {
  const _TaskIndicators({required this.taskAccuracies});
  final Map<String, double> taskAccuracies;

  Color _getTaskColor(String task) {
    final acc = taskAccuracies[task] ?? 0.0;
    if (acc >= 0.80) return AppTheme.accent;
    if (acc >= 0.60) return AppTheme.accentAmber;
    return AppTheme.accentWarn;
  }

  @override
  Widget build(BuildContext context) {
    // Show mini indicators for each task
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TaskMiniIndicator(
          task: 'Rate',
          accuracy: taskAccuracies['rate'] ?? 0.0,
          color: _getTaskColor('rate'),
        ),
        const SizedBox(height: 8),
        _TaskMiniIndicator(
          task: 'Depth',
          accuracy: taskAccuracies['depth'] ?? 0.0,
          color: _getTaskColor('depth'),
        ),
        const SizedBox(height: 8),
        _TaskMiniIndicator(
          task: 'Recoil',
          accuracy: taskAccuracies['recoil'] ?? 0.0,
          color: _getTaskColor('recoil'),
        ),
      ],
    );
  }
}

class _TaskMiniIndicator extends StatelessWidget {
  const _TaskMiniIndicator({
    required this.task,
    required this.accuracy,
    required this.color,
  });
  final String task;
  final double accuracy;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (accuracy * 100).clamp(0, 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '${pct.round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}