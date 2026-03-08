import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});
  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  int _step = 0;

  static const _steps = [
    _DemoStep(
      icon: Icons.back_hand,
      color: AppColors.accentRed,
      title: 'Hand Placement',
      body:
          'Place the heel of your dominant hand on the CENTER of the chest, between the nipples. '
          'Interlock your fingers and keep them off the chest.',
    ),
    _DemoStep(
      icon: Icons.straighten,
      color: Color(0xFF7B1FA2),
      title: 'Body Position',
      body:
          'Kneel beside the person. Keep your arms STRAIGHT — lock your elbows. '
          'Your shoulders should be directly above your hands.',
    ),
    _DemoStep(
      icon: Icons.compress,
      color: AppColors.accentAmber,
      title: 'Compression Depth',
      body:
          'Press down HARD — at least 5 cm (2 inches). Allow the chest to fully recoil '
          'between compressions. Do not lean on the chest.',
    ),
    _DemoStep(
      icon: Icons.speed,
      color: AppColors.accentGreen,
      title: 'Compression Rate',
      body:
          'Compress at 100–120 per minute. Think of the beat of "Stayin\' Alive" by the Bee Gees. '
          'Count aloud if it helps.',
    ),
    _DemoStep(
      icon: Icons.phone,
      color: Colors.blue,
      title: 'Call for Help',
      body:
          'Always call emergency services (112 in Rwanda) FIRST or send someone to call. '
          'Continue CPR until help arrives or the person recovers.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _steps[_step];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('How To: CPR')),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_step + 1) / _steps.length,
            backgroundColor: AppColors.surface,
            color: s.color,
            minHeight: 3,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated icon
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Transform.scale(
                      scale: 1.0 + _pulseCtrl.value * 0.08,
                      child: child,
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.color.withOpacity(0.15),
                        border: Border.all(color: s.color, width: 2),
                      ),
                      child: Icon(s.icon, color: s.color, size: 56),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Step counter
                  Text(
                    'Step ${_step + 1} of ${_steps.length}',
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Navigation
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _step = (_step - 1).clamp(0, _steps.length - 1)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('← Back'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_step < _steps.length - 1) {
                        setState(() => _step++);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _step < _steps.length - 1 ? 'Next →' : "I'm Ready",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoStep {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _DemoStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}
