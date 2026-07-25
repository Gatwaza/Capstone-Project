// Covers HistoryScreen (lib/features/history/history_screen.dart).
//
// HistoryScreen has no camera/pose/inference dependency — it just watches
// sessionHistoryProvider (a FutureProvider backed by
// StorageService.loadAllSessions(), see providers/session_provider.dart)
// and renders a list. Rather than seeding/clearing real StorageService
// state (which would make test ordering matter, since SharedPreferences
// persists across testWidgets() blocks within the same run),
// sessionHistoryProvider is overridden directly per-test via
// ProviderScope.overrides — clean, isolated, no ordering dependency.
//
// HistoryScreen calls context.pop() (AppBar back button) and
// context.push('/results/${s.id}') (row tap) — both go_router extension
// methods, which throw "No GoRouter found in context" without a real
// GoRouter ancestor. So this test wraps HistoryScreen in a minimal test
// router rather than a bare MaterialApp(home: ...), with a catch-all
// errorBuilder so any push to a path this test didn't register (there
// shouldn't be any — HistoryScreen only ever pushes '/results/:id') fails
// loudly with a visible "route-not-found" screen instead of a raw
// exception.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'package:novice/core/di/injection.dart';
import 'package:novice/core/theme/app_theme.dart';
import 'package:novice/features/history/history_screen.dart';
import 'package:novice/models/session_model.dart';
import 'package:novice/providers/session_provider.dart';
import 'package:novice/services/participant_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap({required List<Override> overrides}) {
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: SizedBox())),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(
          path: '/results/:id',
          builder: (context, state) => Scaffold(
            body: Text('results-screen-${state.pathParameters['id']}'),
          ),
        ),
      ],
      errorBuilder: (context, state) =>
          Scaffold(body: Text('route-not-found: ${state.uri}')),
    );
    // Without an explicit dispose, this router (a ChangeNotifier holding
    // redirect/listener state) lingers after its widget tree is torn down
    // at the end of this test, and can throw when something still
    // referencing it resolves during a later test — the likely source of
    // a "Multiple exceptions... at least one was unexpected" Failure
    // Details block appearing after an otherwise fully green run (see
    // results_flow_test.dart, which hit exactly this).
    addTearDown(router.dispose);
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
  }

  SessionModel buildSession({
    required String id,
    required int qualityScore,
    double rateAccuracy = 0.0,
    double depthAccuracy = 0.0,
    double recoilAccuracy = 0.0,
  }) {
    final start = DateTime.now().subtract(const Duration(days: 1));
    return SessionModel(
      id: id,
      participantId: 'P999',
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 2)),
      totalCompressions: 40,
      meanBpm: 105,
      meanDepthCm: 5.2,
      cprFraction: 0.75,
      qualityScore: qualityScore,
      errorRates: const {},
      rateAccuracy: rateAccuracy,
      depthAccuracy: depthAccuracy,
      recoilAccuracy: recoilAccuracy,
      taskConfidences: const {'rate': 0.9, 'depth': 0.9, 'recoil': 0.9},
      language: 'en',
      modelWasAvailable: rateAccuracy > 0,
      rawFrames: const [],
    );
  }

  setUpAll(() async {
    if (!GetIt.instance.isRegistered<ParticipantService>()) {
      await configureDependencies();
    }
  });

  testWidgets('shows empty state when there are no saved sessions',
      (tester) async {
    await tester.pumpWidget(wrap(overrides: [
      sessionHistoryProvider.overrideWith((ref) async => const []),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('No sessions yet'), findsOneWidget);
    expect(
      find.text('Complete a training session to see your results here.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an error state when the history load fails',
      (tester) async {
    await tester.pumpWidget(wrap(overrides: [
      sessionHistoryProvider.overrideWith(
        (ref) async => throw Exception('storage unavailable'),
      ),
    ]));
    await tester.pumpAndSettle();

    expect(find.textContaining('Error loading history'), findsOneWidget);
  });

  testWidgets(
      'lists saved sessions with quality score and per-task mini chips',
      (tester) async {
    final sessions = [
      buildSession(
        id: 'hist-1',
        qualityScore: 88,
        rateAccuracy: 0.9,
        depthAccuracy: 0.95,
        recoilAccuracy: 0.8,
      ),
      buildSession(id: 'hist-2', qualityScore: 40), // no task accuracies
    ];

    await tester.pumpWidget(wrap(overrides: [
      sessionHistoryProvider.overrideWith((ref) async => sessions),
    ]));
    await tester.pumpAndSettle();

    // Quality scores for both rows.
    expect(find.text('88'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);

    // Compression/bpm summary line.
    expect(find.textContaining('40 compressions · 105 bpm'), findsNWidgets(2));

    // Mini task chips only render when at least one accuracy is > 0 — so
    // only the first session (hist-1) should show them.
    expect(find.textContaining('Rate 90%'), findsOneWidget);
    expect(find.textContaining('Depth 95%'), findsOneWidget);
    expect(find.textContaining('Recoil 80%'), findsOneWidget);
  });

  testWidgets('tapping a session row navigates to its Results screen',
      (tester) async {
    final sessions = [buildSession(id: 'hist-nav-target', qualityScore: 70)];

    await tester.pumpWidget(wrap(overrides: [
      sessionHistoryProvider.overrideWith((ref) async => sessions),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('40 compressions · 105 bpm'));
    await tester.pumpAndSettle();

    expect(find.text('results-screen-hist-nav-target'), findsOneWidget);
  });
}