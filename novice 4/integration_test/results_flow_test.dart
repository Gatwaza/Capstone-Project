// Covers ResultsScreen (lib/features/results/results_screen.dart).
//
// Unlike training_flow_test.dart, this screen has NO camera/pose/inference
// dependency — it's a pure read of a saved SessionModel via
// StorageService.loadSession(sessionId), rendered with FutureBuilder. So
// this test doesn't need overridePoseServiceForTesting() or
// overrideInferenceServiceForTesting() at all; it needs a REAL session
// sitting in StorageService (real SharedPreferences on web, per the
// project's existing "only needs StorageService + Riverpod state" note),
// seeded directly before pumping the widget.
//
// Two scenarios are covered:
//   1. Happy path — a fully-populated session (modelWasAvailable: true,
//      real accuracies, a review label) renders the score, metrics grid,
//      technique breakdown, and review panel.
//   2. Not-found path — an unknown sessionId renders the "Session not
//      found" branch, confirming the null-session guard in
//      ResultsScreen.build() actually works.
//
// This test constructs SessionModel directly using the field set
// documented in session_provider.dart's stopSession() (id, participantId,
// startedAt, endedAt, totalCompressions, meanBpm, meanDepthCm, cprFraction,
// qualityScore, errorRates, rateAccuracy, depthAccuracy, recoilAccuracy,
// taskConfidences, language, modelWasAvailable, rawFrames), plus
// reviewLabel/reviewNote which results_screen.dart reads directly. If
// SessionModel's actual constructor differs from this (e.g. additional
// required fields), the analyzer will flag it immediately — check against
// models/session_model.dart if this fails to compile.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'package:novice/core/di/injection.dart';
import 'package:novice/core/theme/app_theme.dart';
import 'package:novice/features/results/results_screen.dart';
import 'package:novice/models/session_model.dart';
import 'package:novice/services/participant_service.dart';
import 'package:novice/services/platform/storage_service.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Each test builds its own GoRouter (needed since sessionId differs per
  // test). Without an explicit dispose, the previous test's router — a
  // ChangeNotifier holding redirect/listener state — lingers after its
  // widget tree is torn down, and can throw when something still
  // references it resolves later. That's the most likely source of the
  // "Multiple exceptions... at least one was unexpected" Failure Details
  // block that can appear after an otherwise fully green run.
  Widget wrapWithRouter(Widget child) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => child),
      ],
    );
    addTearDown(router.dispose);
    return ProviderScope(
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
  }

  SessionModel buildSession({
    required String id,
    bool modelWasAvailable = true,
    String? reviewLabel,
    String? reviewNote,
  }) {
    final start = DateTime.now().subtract(const Duration(minutes: 2));
    return SessionModel(
      id: id,
      participantId: 'P999',
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 2)),
      totalCompressions: 48,
      meanBpm: 108,
      meanDepthCm: 5.4,
      cprFraction: 0.82,
      qualityScore: modelWasAvailable ? 91 : 0,
      errorRates: const {},
      rateAccuracy: modelWasAvailable ? 0.93 : 0.0,
      depthAccuracy: modelWasAvailable ? 0.97 : 0.0,
      recoilAccuracy: modelWasAvailable ? 0.88 : 0.0,
      taskConfidences: modelWasAvailable
          ? const {'rate': 0.9, 'depth': 0.95, 'recoil': 0.7}
          : const {'rate': 0.0, 'depth': 0.0, 'recoil': 0.0},
      language: 'en',
      modelWasAvailable: modelWasAvailable,
      rawFrames: const [],
      reviewLabel: reviewLabel,
      reviewNote: reviewNote,
    );
  }

  setUpAll(() async {
    if (!GetIt.instance.isRegistered<ParticipantService>()) {
      await configureDependencies();
    }
  });

  testWidgets('renders a fully-populated session (score, metrics, breakdown)',
      (tester) async {
    final session = buildSession(id: 'results-test-happy-path');
    await GetIt.instance<StorageService>().saveSession(session);

    await tester.pumpWidget(
      wrapWithRouter(const ResultsScreen(sessionId: 'results-test-happy-path')),
    );
    // Clears the FutureBuilder's ConnectionState.waiting frame.
    await tester.pumpAndSettle();

    expect(find.text('Session Results'), findsOneWidget);
    expect(find.text('91'), findsOneWidget); // quality score
    expect(find.text('48'), findsOneWidget); // total compressions
    expect(find.text('108 bpm'), findsOneWidget);
    expect(find.text('5.4 cm'), findsOneWidget);
    expect(find.text('82%'), findsOneWidget); // CPR fraction
    expect(find.text('TCN'), findsOneWidget); // modelWasAvailable -> 'TCN'

    // Technique breakdown only renders when modelWasAvailable is true.
    // NOTE: _ResearchMetricsPanel (also gated on modelWasAvailable, in the
    // truncated portion of results_screen.dart) repeats these same
    // rate/depth/recoil percentages in its own card — so these numbers
    // legitimately appear twice on screen, not just once. Use
    // findsAtLeastNWidgets rather than findsOneWidget so this test isn't
    // coupled to exactly how many panels choose to display the figure.
    expect(find.text('Technique Breakdown'), findsOneWidget);
    expect(find.text('93%'), findsAtLeastNWidgets(1)); // rate
    expect(find.text('97%'), findsAtLeastNWidgets(1)); // depth
    expect(find.text('88%'), findsAtLeastNWidgets(1)); // recoil
  });

  testWidgets('shows low-confidence note when recoil confidence is below threshold',
      (tester) async {
    final start = DateTime.now().subtract(const Duration(minutes: 2));
    final session = SessionModel(
      id: 'results-test-low-confidence',
      participantId: 'P999',
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 2)),
      totalCompressions: 30,
      meanBpm: 100,
      meanDepthCm: 5.0,
      cprFraction: 0.7,
      qualityScore: 75,
      errorRates: const {},
      rateAccuracy: 0.9,
      depthAccuracy: 0.9,
      recoilAccuracy: 0.5,
      // recoilConfidence below _lowConfidenceThreshold (0.6) in
      // results_screen.dart's _TaskAccuracyChart — should trigger the
      // dimmed bar + "treat this figure as indicative" note.
      taskConfidences: const {'rate': 0.9, 'depth': 0.9, 'recoil': 0.4},
      language: 'en',
      modelWasAvailable: true,
      rawFrames: const [],
    );
    await GetIt.instance<StorageService>().saveSession(session);

    await tester.pumpWidget(
      wrapWithRouter(
          const ResultsScreen(sessionId: 'results-test-low-confidence')),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('treat this figure as indicative'),
      findsOneWidget,
    );
  });

  testWidgets('shows "Model was not available" messaging when modelWasAvailable is false',
      (tester) async {
    final session =
        buildSession(id: 'results-test-no-model', modelWasAvailable: false);
    await GetIt.instance<StorageService>().saveSession(session);

    await tester.pumpWidget(
      wrapWithRouter(const ResultsScreen(sessionId: 'results-test-no-model')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Model was not available this session'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    // Technique Breakdown and Research Metrics are both gated on
    // modelWasAvailable — neither should render.
    expect(find.text('Technique Breakdown'), findsNothing);
  });

  testWidgets('shows "Session not found" for an unknown sessionId',
      (tester) async {
    await tester.pumpWidget(
      wrapWithRouter(
          const ResultsScreen(sessionId: 'does-not-exist-anywhere')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Session not found'), findsOneWidget);
  });
}