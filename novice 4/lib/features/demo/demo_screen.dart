// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

/// Animated CPR technique demonstration screen.
///
/// Phase 1: Pure Flutter animation (no .rive asset required).
/// Phase 2: Replace _CprAnimationPainter with a Rive animation once
///          the .riv file is produced (see assets/animations/cpr_instructor.riv).
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _compression;

  // Simulate 110 bpm — one cycle = ~545ms
  static const int _cycleDurationMs = 545;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _cycleDurationMs),
    )..repeat(reverse: true);

    _compression = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Correct Technique'),
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Animation viewport ──────────────────────────
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: AnimatedBuilder(
                animation: _compression,
                builder: (_, __) => CustomPaint(
                  painter: _CprAnimationPainter(
                    compressionFraction: _compression.value,
                  ),
                  child: Container(),
                ),
              ),
            ),
            // TODO: Replace above CustomPaint with RiveAnimation when .riv available:
            // RiveAnimation.asset('assets/animations/cpr_instructor.riv')

            const SizedBox(height: 24),

            // ── Key technique points ────────────────────────
            Text('Key Points',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            ..._keyPoints.map((p) => _TechniquePoint(
                  icon: p.$1,
                  title: p.$2,
                  detail: p.$3,
                  highlight: p.$4,
                )),

            const SizedBox(height: 24),

            // ── ERC source ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'Technique based on: Perkins et al. (2021) European Resuscitation '
                'Council Guidelines 2021 — Adult Basic Life Support. '
                'Resuscitation 161, 98–114.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 11, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _keyPoints = [
    (
      Icons.back_hand_outlined,
      'Hand placement',
      'Centre of the chest — lower half of the sternum. Heel of one hand, other on top, fingers interlocked.',
      false,
    ),
    (
      Icons.straighten_rounded,
      'Arms straight',
      'Lock your elbows — arms must be fully extended (≥160°). This maximises force transfer.',
      true,
    ),
    (
      Icons.compress_rounded,
      'Depth: 5–6 cm',
      'Press at least 5 cm but no more than 6 cm. Allow full chest recoil between compressions.',
      true,
    ),
    (
      Icons.speed_rounded,
      'Rate: 100–120 bpm',
      'The "Stayin\' Alive" beat (104 bpm) is a useful rhythm guide. Do not exceed 120 bpm.',
      true,
    ),
    (
      Icons.accessibility_new_rounded,
      'Body position',
      'Kneel beside the patient, directly above their chest. Keep your body vertical over your hands.',
      false,
    ),
  ];
}

class _TechniquePoint extends StatelessWidget {
  const _TechniquePoint({
    required this.icon,
    required this.title,
    required this.detail,
    required this.highlight,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlight
                ? AppTheme.accent.withOpacity(0.3)
                : AppTheme.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: highlight ? AppTheme.accent : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(detail,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pure Flutter CPR animation — stick figure doing compressions.
/// Replace with Rive in Phase 2.
class _CprAnimationPainter extends CustomPainter {
  const _CprAnimationPainter({required this.compressionFraction});
  final double compressionFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Manikin — simple torso rectangle
    final manikinPaint = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy + 40), width: 100, height: 140),
        const Radius.circular(12),
      ),
      manikinPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy + 40), width: 100, height: 140),
        const Radius.circular(12),
      ),
      Paint()
        ..color = AppTheme.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Sternum marker
    canvas.drawCircle(
      Offset(cx, cy + 20),
      8,
      Paint()..color = AppTheme.accent.withOpacity(0.3),
    );
    canvas.drawCircle(
      Offset(cx, cy + 20),
      4,
      Paint()..color = AppTheme.accent,
    );

    // Hands — move down with compression
    final handY = cy - 30 + compressionFraction * 18;
    final handPaint = Paint()
      ..color = AppTheme.textPrimary.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, handY), width: 44, height: 14),
        const Radius.circular(4),
      ),
      handPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, handY - 12), width: 38, height: 12),
        const Radius.circular(4),
      ),
      handPaint,
    );

    // Arms
    final armPaint = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Left arm: shoulder → elbow → wrist
    final shoulderLx = cx - 60;
    final shoulderY  = cy - 90;
    canvas.drawLine(
        Offset(shoulderLx, shoulderY), Offset(cx - 20, handY - 50), armPaint);
    canvas.drawLine(
        Offset(cx - 20, handY - 50), Offset(cx - 10, handY - 8), armPaint);

    // Right arm
    final shoulderRx = cx + 60;
    canvas.drawLine(
        Offset(shoulderRx, shoulderY), Offset(cx + 20, handY - 50), armPaint);
    canvas.drawLine(
        Offset(cx + 20, handY - 50), Offset(cx + 10, handY - 8), armPaint);

    // Head
    canvas.drawCircle(
      Offset(cx, cy - 115),
      22,
      Paint()
        ..color = AppTheme.surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy - 115),
      22,
      Paint()
        ..color = AppTheme.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Torso (rescuer)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, shoulderY + 20), width: 80, height: 50),
        const Radius.circular(8),
      ),
      Paint()
        ..color = AppTheme.accent.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );

    // Depth label
    final depthCm = (compressionFraction * 6).clamp(0.0, 6.0);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${depthCm.toStringAsFixed(1)} cm',
        style: TextStyle(
          color: AppTheme.accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(cx + 60, handY - 8));
  }

  @override
  bool shouldRepaint(_CprAnimationPainter old) =>
      old.compressionFraction != compressionFraction;
}
