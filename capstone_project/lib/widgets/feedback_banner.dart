import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

enum FeedbackType { critical, coaching, positive, idle }

class FeedbackBanner extends StatelessWidget {
  final String? promptKey;
  final String lang;
  final FeedbackType type;

  const FeedbackBanner({
    super.key,
    this.promptKey,
    required this.lang,
    this.type = FeedbackType.idle,
  });

  Color get _bg {
    switch (type) {
      case FeedbackType.critical: return AppColors.accentRed.withOpacity(0.25);
      case FeedbackType.coaching: return AppColors.accentAmber.withOpacity(0.18);
      case FeedbackType.positive: return AppColors.accentGreen.withOpacity(0.22);
      case FeedbackType.idle:     return AppColors.card;
    }
  }

  IconData get _icon {
    switch (type) {
      case FeedbackType.critical: return Icons.warning_rounded;
      case FeedbackType.coaching: return Icons.tips_and_updates;
      case FeedbackType.positive: return Icons.check_circle;
      case FeedbackType.idle:     return Icons.info_outline;
    }
  }

  String get _text {
    if (promptKey == null) return 'Initializing...';
    final map = lang == 'rw' ? AppConstants.promptsRw : AppConstants.promptsEn;
    return map[promptKey!] ?? promptKey!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: type == FeedbackType.idle
              ? Colors.transparent
              : _bg.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _text,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color get _iconColor {
    switch (type) {
      case FeedbackType.critical: return AppColors.accentRed;
      case FeedbackType.coaching: return AppColors.accentAmber;
      case FeedbackType.positive: return AppColors.accentGreen;
      case FeedbackType.idle:     return AppColors.textMuted;
    }
  }
}
