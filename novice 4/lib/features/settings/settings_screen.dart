// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/router/app_router.dart';
import '../../providers/session_provider.dart';
import '../../services/platform/storage_service.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(liveSessionProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Language ──────────────────────────────────────
          const _SectionHeader('Language'),
          _SettingTile(
            title: 'Coaching language',
            subtitle: session.language == 'en' ? 'English' : 'Kinyarwanda (Ikinyarwanda)',
            trailing: DropdownButton<String>(
              value: session.language,
              dropdownColor: AppTheme.card,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'rw', child: Text('Kinyarwanda')),
              ],
              onChanged: (lang) {
                if (lang != null) {
                  ref.read(liveSessionProvider.notifier).setLanguage(lang);
                }
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Research ──────────────────────────────────────────
          const _SectionHeader('Pilot Study'),
          _SettingTile(
            title: 'Participant Enrolment',
            subtitle: 'Enrol a new study participant + capture consent',
            trailing: IconButton(
              icon: const Icon(Icons.person_add_rounded, color: AppTheme.accent),
              onPressed: () => context.push(AppRoutes.consent),
            ),
          ),
          _SettingTile(
            title: 'Researcher Dashboard',
            subtitle: 'View Group A/B metrics and export study data',
            trailing: IconButton(
              icon: const Icon(Icons.analytics_rounded, color: AppTheme.accent),
              onPressed: () => context.push(AppRoutes.researcher),
            ),
          ),

          const SizedBox(height: 8),

          // ── Research export ───────────────────────────────
          const _SectionHeader('Research & Data'),
          _SettingTile(
            title: 'Export session data',
            subtitle: 'JSON export for pilot study analysis',
            trailing: IconButton(
              icon: const Icon(Icons.upload_file_rounded,
                  color: AppTheme.accent),
              onPressed: () => _exportData(context),
            ),
          ),

          const SizedBox(height: 8),

          // ── About ─────────────────────────────────────────
          const _SectionHeader('About'),
          const _SettingTile(
            title: 'App version',
            subtitle: AppConstants.appVersion,
          ),
          const _SettingTile(
            title: 'License',
            subtitle: 'GNU General Public License v3.0',
          ),
          const _SettingTile(
            title: 'Developer',
            subtitle: 'Jean Robert Gatwaza — African Leadership University',
          ),
          const _SettingTile(
            title: 'Clinical reference',
            subtitle: 'ERC Guidelines 2021 (Perkins et al.)',
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              'Novice is free software distributed under the GNU GPL v3. '
              'Source code available at github.com/Gatwaza/Capstone-Project.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final storage = getIt<StorageService>();
      final json = await storage.exportJson(); // resolves via exportSummaryJson()
      await Share.share(json, subject: 'Novice CPR Session Data');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}