// lib/widgets/compression_gauge.dart
// Animated vertical bar showing compression depth in real time.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

class CompressionGauge extends StatefulWidget {
  /// Normalised depth value 0.0–1.0.
  /// 0 = no compression, 1 = max detected compression.
  final double depth;

  /// Whether elbows are currently locked (changes colour accent).
  final bool elbowsLocked;

  const CompressionGauge({
    super.key,
    required this.depth,
    this.elbowsLocked = true,
  });

  @override
  State<CompressionGauge> createState() => _CompressionGaugeState();
}

class _CompressionGaugeState extends State<CompressionGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _smoothDepth;
  double _prevDepth = 0.0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _smoothDepth = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(CompressionGauge old) {
    super.didUpdateWidget(old);
    if ((widget.depth - _prevDepth).abs() > 0.01) {
      _smoothDepth = Tween<double>(
        begin: _smoothDepth.value,
        end: widget.depth.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
      _animCtrl.forward(from: 0);
      _prevDepth = widget.depth;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // Target zone is 0.3–0.7 of normalised depth (represents 5–6 cm)
  static const double _targetLo = 0.30;
  static const double _targetHi = 0.70;

  Color _barColor(double depth) {
    if (!widget.elbowsLocked) return AppColors.accentAmber;
    if (depth < _targetLo) return AppColors.accentAmber;
    if (depth > _targetHi) return AppColors.accentRed;
    return AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _smoothDepth,
      builder: (_, __) {
        final d = _smoothDepth.value;
        final color = _barColor(d);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Bar ──────────────────────────────────────────────────────
            SizedBox(
              width: 28,
              height: 110,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Track
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Target zone highlight
                  Positioned(
                    bottom: 110 * _targetLo,
                    left: 0, right: 0,
                    height: 110 * (_targetHi - _targetLo),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.12),
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: AppColors.accentGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Fill bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 28,
                    height: (110 * d).clamp(0, 110),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // ── Label ────────────────────────────────────────────────────
            Text(
              'DEPTH',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              d < _targetLo
                  ? '↑ Shallow'
                  : d > _targetHi
                      ? '↓ Deep'
                      : '✓ Good',
              style: TextStyle(color: color, fontSize: 9),
            ),
          ],
        );
      },
    );
  }
}


/// Compact horizontal compression rate progress bar.
/// Shows current BPM relative to the 100–120 target range.
class BpmRangeBar extends StatelessWidget {
  final double? bpm;
  const BpmRangeBar({super.key, this.bpm});

  @override
  Widget build(BuildContext context) {
    const lo = AppConstants.cprBpmMin.toDouble();
    const hi = AppConstants.cprBpmMax.toDouble();
    const full = hi + 40.0; // visual range 60–160

    final clamped = (bpm ?? 60.0).clamp(60.0, 160.0);
    final fraction = (clamped - 60) / (160 - 60);
    final targetLoFrac = (lo - 60) / (160 - 60);
    final targetHiFrac = (hi - 60) / (160 - 60);

    final inRange = bpm != null && bpm! >= lo && bpm! <= hi;
    final color = bpm == null
        ? AppColors.textMuted
        : inRange
            ? AppColors.accentGreen
            : AppColors.accentAmber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rate',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.5)),
            Text(
              bpm != null ? '${bpm!.round()} BPM' : '—',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (_, constraints) {
            final w = constraints.maxWidth;
            return SizedBox(
              height: 8,
              child: Stack(
                children: [
                  // Track
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Target zone
                  Positioned(
                    left: w * targetLoFrac,
                    width: w * (targetHiFrac - targetLoFrac),
                    top: 0, bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Current BPM indicator
                  if (bpm != null)
                    Positioned(
                      left: (w * fraction - 3).clamp(0, w - 6),
                      top: 0, bottom: 0,
                      width: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                                color: color.withOpacity(0.5), blurRadius: 6)
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('60', style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
            Text('${lo.round()}–${hi.round()} target',
                style: TextStyle(color: AppColors.accentGreen, fontSize: 9)),
            Text('160', style: TextStyle(color: AppColors.textMuted, fontSize: 9)),
          ],
        ),
      ],
    );
  }
}
