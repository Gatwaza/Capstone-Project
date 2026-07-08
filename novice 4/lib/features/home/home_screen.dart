// Novice — CPR-AI Coach · Integrated Design
// GNU General Public License v3.0

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_mode_provider.dart';

// Hands control back to web/index.html's landing overlay without resetting
// GoRouter — Flutter stays parked on whatever route it's on, paused behind
// the overlay, same as on first boot. This deliberately sidesteps
// SplashScreen's auto-redirect-to-/procedures, since Flutter's router state
// is never sent back to '/'. This is the single, explicit "leave the app"
// affordance (see the tappable Novice logo below); the old floating
// '#back-to-landing' DOM button has been removed as it overlapped app
// content and didn't reset any state on its own.
void _returnToLanding() {
  if (!kIsWeb) return;
  try {
    js.context.callMethod('showLanding', []);
  } catch (_) {}
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(sessionHistoryProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),

              // ── Header ──────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _returnToLanding,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Center(
                              child: Icon(Icons.monitor_heart_rounded,
                                  color: AppTheme.accent, size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Novice',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(fontSize: 28, letterSpacing: -1)),
                                Text('First Aid CPR Training',
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                    icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                    color: AppTheme.textSecondary,
                    tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                  ),
                  IconButton(
                    onPressed: () => context.push(AppRoutes.settings),
                    icon: const Icon(Icons.tune_rounded),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Eyebrow ─────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI-POWERED FIRST AID TRAINING',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.accent, letterSpacing: 2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                'Tap a card below to begin. Tap the Novice logo above anytime to exit to the landing page.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12.5),
              ),

              const SizedBox(height: 20),

              // ── Stat chips ──────────────────────────────────
              Row(
                children: [
                  _StatChip(label: '6', sub: 'Procedures'),
                  const SizedBox(width: 10),
                  _StatChip(label: 'TCN', sub: 'AI model', accent: true),
                  const SizedBox(width: 10),
                  _StatChip(label: 'Live', sub: 'CPR feedback', accent: true),
                ],
              ),

              const SizedBox(height: 28),

              // ── Primary action — Start Training ─────────────
              _PrimaryActionCard(
                icon: Icons.smart_toy_rounded,
                iconColor: AppTheme.accent,
                title: 'Start CPR Training',
                subtitle: 'Live AI feedback on rate, depth & recoil — camera required',
                accentColor: AppTheme.accent,
                onTap: () => context.push(AppRoutes.participantGate),
              ),

              const SizedBox(height: 8),

              // ── Secondary action — Browse Procedures ─────────
              _PrimaryActionCard(
                icon: Icons.play_lesson_rounded,
                iconColor: AppTheme.chokingAmber,
                title: 'Browse Procedures',
                subtitle: 'Animated step-by-step guides: choking, stroke, recovery & more',
                accentColor: AppTheme.chokingAmber,
                onTap: () => context.push(AppRoutes.demo),
              ),

              const SizedBox(height: 20),

              // ── Secondary actions ────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.history_rounded,
                      iconColor: AppTheme.textSecondary,
                      title: 'History',
                      subtitle: history.when(
                        data: (s) => '${s.length} sessions',
                        loading: () => '...',
                        error: (_, __) => 'unavailable',
                      ),
                      onTap: () => context.push(AppRoutes.history),
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.science_rounded,
                      iconColor: AppTheme.strokePurple,
                      title: 'Research',
                      subtitle: 'Researcher dashboard & data export',
                      onTap: () => context.push(AppRoutes.researcher),
                      compact: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Footer ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline_rounded,
                          color: AppTheme.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CPR is graded live by AI. Other procedures are animated guides — no camera needed.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'GNU GPL v3 · Gatwaza · ALU 2024',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.sub, this.accent = false});
  final String label;
  final String sub;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: accent ? AppTheme.accent.withOpacity(.08) : AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          border: Border.all(
            color: accent ? AppTheme.accent.withOpacity(.3) : AppTheme.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: accent ? AppTheme.accent : AppTheme.textPrimary,
                fontSize: 20, fontWeight: FontWeight.w800,
              ),
            ),
            Text(sub,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.r),
          border: Border.all(color: accentColor.withOpacity(.25)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(.08),
              blurRadius: 20, spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.black, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.compact = false,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}