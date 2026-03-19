// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// TrainingScreen — cross-platform camera + pose + inference screen.
//
// Platform behaviour:
//   iOS/Android : CameraController + google_mlkit_pose_detection
//   Web         : CameraController (getUserMedia) + JS interop pose bridge
//                 Falls back to demo simulation when JS bridge is not ready.

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// google_mlkit_pose_detection is mobile-only — not available on web.
// The stub provides InputImageRotation so the call site compiles on all targets.
// On web, processFrame() receives the rotation but PoseServiceWeb ignores it.
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    if (dart.library.html) '../../core/utils/mlkit_stub.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/session_provider.dart';
import '../../core/di/injection.dart';
import '../../services/platform/pose_service_interface.dart';
import '../../widgets/bpm_indicator.dart';
import '../../widgets/compression_gauge.dart';
import '../../widgets/feedback_banner.dart';
import '../../widgets/pose_overlay.dart';

// Permission handler — mobile only (no-op on web)
import 'package:permission_handler/permission_handler.dart'
    if (dart.library.html) '../../core/utils/permission_stub.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  CameraController? _camera;
  bool _cameraReady = false;
  bool _permissionDenied = false;

  late final PoseServiceInterface _poseService;

  @override
  void initState() {
    super.initState();
    _poseService = getIt<PoseServiceInterface>();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Permission check — mobile only (web uses browser permission dialog)
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() => _permissionDenied = true);
        return;
      }
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Front camera preferred for self-guided CPR coaching
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _camera = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
      // iOS: bgra8888 native | Android: nv21 | Web: yuv420 (camera plugin handles it)
      imageFormatGroup: kIsWeb
          ? ImageFormatGroup.jpeg
          : ImageFormatGroup.bgra8888,
    );

    await _camera!.initialize();
    if (!mounted) return;
    setState(() => _cameraReady = true);

    // Start frame processing loop
    _camera!.startImageStream(_onCameraFrame);
  }

  void _onCameraFrame(CameraImage image) {
    final session = ref.read(liveSessionProvider);
    if (!session.isActive) return;

    // Rotation: portrait front camera
    // iOS iPhone 15 Pro: 270°  |  Android varies  |  Web: 0° (already upright)
    final rotation = kIsWeb
        ? null
        : InputImageRotation.rotation270deg;

    _poseService.processFrame(image, rotation).then((frame) {
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
      ref.read(liveSessionProvider.notifier).startSession();
    }
  }

  @override
  void dispose() {
    _camera?.stopImageStream();
    _camera?.dispose();
    super.dispose();
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
              color: AppTheme.surface,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      kIsWeb
                          ? 'Initialising camera…\nAllow camera access when prompted.'
                          : 'Starting camera…',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // ── Pose skeleton overlay ────────────────────────
          if (session.lastInference != null)
            CustomPaint(
              painter: PoseOverlayPainter(inference: session.lastInference!),
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
                  onTap: () => context.pop(),
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
              child: _HudChip(
                label: '${session.compressions}',
                sublabel: 'compressions',
                icon: Icons.compress_rounded,
              ),
            ),

          // ── Platform badge ───────────────────────────────
          if (kIsWeb)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16 + 48 + 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.accentAmber.withOpacity(0.4)),
                ),
                child: Text(
                  'WEB',
                  style: TextStyle(
                    color: AppTheme.accentAmber,
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                backgroundColor: session.isActive
                    ? AppTheme.accentWarn
                    : AppTheme.accent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                session.isActive ? 'Stop Session' : 'Start Session',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),

          // ── Model status ─────────────────────────────────
          if (!session.modelAvailable)
            Positioned(
              bottom: 104,
              left: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.accentAmber.withOpacity(0.4)),
                ),
                child: Text(
                  'DEMO MODE — TRAIN MODEL TO ACTIVATE AI',
                  style: TextStyle(
                    color: AppTheme.accentAmber,
                    fontSize: 9,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
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
              ElevatedButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings'),
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
        Path()..moveTo(0, len)..lineTo(0, 0)..lineTo(len, 0), paint);
    canvas.drawPath(
        Path()..moveTo(size.width - len, 0)..lineTo(size.width, 0)..lineTo(size.width, len), paint);
    canvas.drawPath(
        Path()..moveTo(0, size.height - len)..lineTo(0, size.height)..lineTo(len, size.height), paint);
    canvas.drawPath(
        Path()..moveTo(size.width - len, size.height)..lineTo(size.width, size.height)..lineTo(size.width, size.height - len), paint);
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
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.white, size: 18)
              : Text(label ?? '',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
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
        border: Border.all(color: AppTheme.border),
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
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              if (sublabel != null)
                Text(sublabel!,
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 9, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}
