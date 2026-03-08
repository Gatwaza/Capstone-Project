import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/di/injection.dart';
import '../core/theme/app_theme.dart';
import '../services/session_logger.dart';
import 'training_screen.dart';
import 'results_screen.dart';
import 'demo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _lang = 'en';
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await getIt<SessionLogger>().getStats();
    if (mounted) setState(() => _stats = stats);
  }

  void _toggleLang() => setState(() => _lang = _lang == 'en' ? 'rw' : 'en');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildHeroCard(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 28),
              _buildActionButtons(),
              const SizedBox(height: 20),
              _buildRecentSessions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CPR AI COACH',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 3)),
            const Text('Capstone Project',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _toggleLang,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(_lang == 'en' ? '🇬🇧' : '🇷🇼', fontSize: 16),
                    const SizedBox(width: 4),
                    Text(_lang.toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFF880E4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite, color: Colors.white, size: 36),
          const SizedBox(height: 16),
          const Text('Ready to\nSave a Life?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2)),
          const SizedBox(height: 8),
          Text(
            'Real-time AI guidance for CPR. No training needed.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statChip('100–120', 'BPM Target'),
              const SizedBox(width: 12),
              _statChip('5–6 cm', 'Depth'),
              const SizedBox(width: 12),
              _statChip('2 min', 'Session'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final total = _stats['total'] ?? 0;
    final best = _stats['bestScore'] != null
        ? '${(_stats['bestScore'] * 100).round()}%'
        : '—';
    return Row(
      children: [
        _metricCard('$total', 'Sessions', Icons.history),
        const SizedBox(width: 10),
        _metricCard(best, 'Best Score', Icons.emoji_events),
        const SizedBox(width: 10),
        _metricCard(
          _lang == 'en' ? 'EN' : 'RW',
          'Language',
          Icons.language,
        ),
      ],
    );
  }

  Widget _metricCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accentRed, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => TrainingScreen(lang: _lang))),
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: Text(_lang == 'en' ? 'Start CPR Training' : 'Tangira Amahugurwa'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: AppColors.accentRed,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DemoScreen())),
                icon: const Icon(Icons.ondemand_video, size: 18),
                label: const Text('Watch Demo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ResultsScreen())),
                icon: const Icon(Icons.bar_chart, size: 18),
                label: const Text('History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSessions() {
    final total = _stats['total'] ?? 0;
    if (total == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Stats',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$total session${total == 1 ? '' : 's'} completed',
                  style: const TextStyle(color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ResultsScreen())),
                child: const Text('View All →',
                    style: TextStyle(color: AppColors.accentRed)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
