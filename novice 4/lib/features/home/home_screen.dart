// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/session_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(sessionHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // ── Header ─────────────────────────────────────
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Novice',
                          style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 4),
                      Text(
                        'CPR Coach · Sub-Saharan Africa',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push(AppRoutes.settings),
                    icon: const Icon(Icons.tune_rounded),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // ── Phase badge ────────────────────────────────
              // ── Phase badge ────────────────────────────────
const SizedBox(height: 32),

              const SizedBox(height: 32),

              // ── Primary action ─────────────────────────────
              _ActionCard(
                icon: Icons.monitor_heart_rounded,
                iconColor: AppTheme.accent,
                title: 'Start Training',
                subtitle: 'Real-time CPR coaching with pose feedback',
                onTap: () => context.push(AppRoutes.training),
              ),

              const SizedBox(height: 12),

              // ── Secondary actions ──────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.play_circle_outline_rounded,
                      iconColor: AppTheme.accentAmber,
                      title: 'Demo',
                      subtitle: 'Watch correct technique',
                      onTap: () => context.push(AppRoutes.demo),
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                ],
              ),

              const Spacer(),

              // ── Footer ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Text(
                      'Buri mugenzi yagutabara',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.accent.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"Anyone can help" — CPR saves lives',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'GNU GPL v3 · ALU Capstone · Jean Robert Gatwaza',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(height: 12),
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: AppTheme.textSecondary, size: 16),
                ],
              ),
      ),
    );
  }
}
