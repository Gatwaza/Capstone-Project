// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';

/// Circular BPM gauge with animated arc fill.
/// Green in target range (100–120 bpm), red below/above.
class BpmIndicator extends StatelessWidget {
  const BpmIndicator({super.key, required this.bpm, this.size = 44});

  final double bpm;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final fraction = _fraction();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ArcPainter(fraction: fraction, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bpm > 0 ? bpm.round().toString() : '--',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                'BPM',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: size * 0.18,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _color() {
    if (bpm <= 0) return AppTheme.textSecondary;
    if (bpm < AppConstants.cprMinRateBpm) return AppTheme.accentWarn;
    if (bpm > AppConstants.cprMaxRateBpm) return AppTheme.accentAmber;
    return AppTheme.accent;
  }

  double _fraction() {
    if (bpm <= 0) return 0;
    return ((bpm - 60) / 80).clamp(0.0, 1.0);
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.border
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // Arc fill
    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        fraction * 2 * math.pi,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.fraction != fraction || old.color != color;
}
