// Novice — CPR-AI Coach · Integrated Design
// GNU General Public License v3.0

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
import '../theme/app_theme.dart';

class AppRoutes {
  AppRoutes._();
  static const splash          = '/';
  // Home is the single entry point Flutter lands on — both from splash's
  // auto-redirect and from every landing-page CTA in web/index.html's
  // ROUTE_MAP. /procedures (DemoScreen isHub:true) still exists as a
  // route but nothing links to it anymore; kept only in case something
  // deep-links to it directly. Ordinary "browse procedures" navigation
  // goes through /demo (isHub:false), pushed from Home, which has a
  // normal back button.
  static const procedures      = '/procedures';
  static const home            = '/home';
  static const participantGate = '/participant';
  static const training        = '/training/:participantId';
  static const results         = '/results/:sessionId';
  static const history         = '/history';
  static const demo            = '/demo';
  static const settings        = '/settings';
  static const consent         = '/research/consent';
  static const surveyPre       = '/research/survey/pre/:sessionId';
  static const surveyPost      = '/research/survey/post/:sessionId';
  static const researcher      = '/research/dashboard';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: AppRoutes.splash,     builder: (_, __) => const SplashScreen()),
      // Procedures hub — the first screen after splash
      GoRoute(path: AppRoutes.procedures, builder: (_, __) => const DemoScreen(isHub: true)),
      GoRoute(path: AppRoutes.home,       builder: (_, __) => const HomeScreen()),
      GoRoute(path: AppRoutes.participantGate, builder: (_, __) => const ParticipantGateScreen()),
      GoRoute(
        path: AppRoutes.training,
        // Keyed by the full location (participantId + optional ?ts=...)
        // rather than left unkeyed. Without a key, Flutter's element
        // reconciliation sees "same widget type, same tree position" on a
        // revisit to the same participantId and reuses the existing
        // State — timers, buffers, session logs all carry over instead of
        // resetting. The ?ts= cache-buster from "Practice Again" (see
        // results_screen.dart) only forces a genuinely new mount if it's
        // reflected in the key here too.
        builder: (_, state) => TrainingScreen(
          key: ValueKey(state.uri.toString()),
          participantId: state.pathParameters['participantId']!,
        ),
      ),
      GoRoute(
        path: '/results/:sessionId',
        builder: (_, state) => ResultsScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(path: AppRoutes.history,    builder: (_, __) => const HistoryScreen()),
      GoRoute(path: AppRoutes.demo,       builder: (_, __) => const DemoScreen()),
      GoRoute(path: AppRoutes.settings,   builder: (_, __) => const SettingsScreen()),
      GoRoute(path: AppRoutes.consent,    builder: (_, __) => const ConsentScreen()),
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
      GoRoute(path: AppRoutes.researcher, builder: (_, __) => const ResearcherDashboard()),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Text('Page not found: ${state.uri}',
            style: TextStyle(color: AppTheme.textPrimary)),
      ),
    ),
  );
});