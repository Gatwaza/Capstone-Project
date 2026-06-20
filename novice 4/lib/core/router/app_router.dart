// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/training/training_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/demo/demo_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/research/consent_screen.dart';
import '../../features/research/participant_gate_screen.dart';
import '../../features/research/survey_screen.dart';
import '../../features/research/researcher_dashboard.dart';

/// Route paths — use these constants everywhere to avoid typos.
class AppRoutes {
  AppRoutes._();
  static const splash      = '/';
  static const home        = '/home';
  static const participantGate = '/participant';
  static const training    = '/training/:participantId';
  static const results     = '/results/:sessionId';
  static const history     = '/history';
  static const demo        = '/demo';
  static const settings    = '/settings';
  // Research / pilot study routes
  static const consent     = '/research/consent';
  static const surveyPre   = '/research/survey/pre/:sessionId';
  static const surveyPost  = '/research/survey/post/:sessionId';
  static const researcher  = '/research/dashboard';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.participantGate,
        builder: (_, __) => const ParticipantGateScreen(),
      ),
      GoRoute(
        path: AppRoutes.training,
        builder: (_, state) => TrainingScreen(
          participantId: state.pathParameters['participantId']!,
        ),
      ),
      GoRoute(
        path: '/results/:sessionId',
        builder: (_, state) => ResultsScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.demo,
        builder: (_, __) => const DemoScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      // ── Research / pilot study ─────────────────────────────
      GoRoute(
        path: AppRoutes.consent,
        builder: (_, __) => const ConsentScreen(),
      ),
      GoRoute(
        path: '/research/survey/pre/:sessionId',
        builder: (_, state) => SurveyScreen(
          sessionId: state.pathParameters['sessionId']!,
          type: SurveyType.preSession,
        ),
      ),
      GoRoute(
        path: '/research/survey/post/:sessionId',
        builder: (_, state) => SurveyScreen(
          sessionId: state.pathParameters['sessionId']!,
          type: SurveyType.postSession,
        ),
      ),
      GoRoute(
        path: AppRoutes.researcher,
        builder: (_, __) => const ResearcherDashboard(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
  );
});