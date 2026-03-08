import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

class BpmIndicator extends StatelessWidget {
  final double? bpm;
  final bool large;

  const BpmIndicator({super.key, this.bpm, this.large = false});

  Color get _color {
    if (bpm == null) return AppColors.textMuted;
    if (bpm! < AppConstants.cprBpmMin) return AppColors.accentAmber;
    if (bpm! > AppConstants.cprBpmMax) return AppColors.accentAmber;
    return AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          bpm != null ? '${bpm!.round()}' : '—',
          style: TextStyle(
            color: _color,
            fontSize: large ? 52 : 32,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text('BPM',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: large ? 12 : 10,
                letterSpacing: 2)),
        if (bpm != null) ...[
          const SizedBox(height: 4),
          Text(
            bpm! < AppConstants.cprBpmMin
                ? '↑ Too Slow'
                : bpm! > AppConstants.cprBpmMax
                    ? '↓ Too Fast'
                    : '✓ On Target',
            style: TextStyle(color: _color, fontSize: 10),
          ),
        ],
      ],
    );
  }
}
