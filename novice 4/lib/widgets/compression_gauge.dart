// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../models/session_model.dart';

// ── Compression depth gauge ───────────────────────────────

/// Vertical bar gauge showing compression depth with target zone.
class CompressionGauge extends StatelessWidget {
  const CompressionGauge({super.key, required this.depthCm});

  final double depthCm;

  static const double _maxCm    = 8.0;
  static const double _barH     = 100.0;
  static const double _barW     = 10.0;

  @override
  Widget build(BuildContext context) {
    final pct   = (depthCm / _maxCm).clamp(0.0, 1.0);
    final isOk  = depthCm >= AppConstants.cprMinDepthCm &&
                  depthCm <= AppConstants.cprMaxDepthCm;
    final color = depthCm <= 0
        ? AppTheme.textSecondary
        : isOk
            ? AppTheme.accent
            : AppTheme.accentWarn;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            depthCm > 0 ? '${depthCm.toStringAsFixed(1)}cm' : '--',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: _barW,
            height: _barH,
            child: CustomPaint(
              painter: _GaugePainter(pct: pct, color: color),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'DEPTH',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.pct, required this.color});
  final double pct;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rx = Radius.circular(size.width / 2);

    // Track
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        rx,
      ),
      Paint()..color = AppTheme.border,
    );

    // Fill (bottom-up)
    final fillH = size.height * pct;
    if (fillH > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height - fillH, size.width, fillH),
          rx,
        ),
        Paint()..color = color,
      );
    }

    // Target zone lines (5 cm and 6 cm)
    final y5 = size.height * (1 - AppConstants.cprMinDepthCm / 8.0);
    final y6 = size.height * (1 - AppConstants.cprMaxDepthCm / 8.0);

    final markerPaint = Paint()
      ..color = AppTheme.accent.withOpacity(0.5)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(-3, y5), Offset(size.width + 3, y5), markerPaint);
    canvas.drawLine(Offset(-3, y6), Offset(size.width + 3, y6), markerPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.pct != pct || old.color != color;
}

// ── Feedback banner ───────────────────────────────────────

/// Translucent banner showing the current coaching prompt.
/// Severity drives color: good=green, warning=amber, critical=red.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key, required this.prompt});

  final FeedbackPrompt prompt;

  @override
  Widget build(BuildContext context) {
    final (borderColor, iconColor, bgColor, icon) = switch (prompt.severity) {
      FeedbackSeverity.good     => (
          AppTheme.accent.withOpacity(0.4),
          AppTheme.accent,
          Colors.black.withOpacity(0.7),
          '✓',
        ),
      FeedbackSeverity.warning  => (
          AppTheme.accentWarn.withOpacity(0.4),
          AppTheme.accentWarn,
          const Color(0xCC140008),
          '⚠',
        ),
      FeedbackSeverity.critical => (
          AppTheme.accentWarn,
          AppTheme.accentWarn,
          const Color(0xDD200008),
          '!',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(color: iconColor, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prompt.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
