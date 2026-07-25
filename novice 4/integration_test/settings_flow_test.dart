// Covers SettingsScreen (lib/features/settings/settings_screen.dart).
//
// No camera/pose/inference dependency, and — unlike History — nothing
// here needs a provider override for its core interactions:
//   - The dark-mode Switch drives themeModeProvider directly; this test
//     only asserts the Switch's own visual state flips on tap (it doesn't
//     assume anything about ThemeModeNotifier's internals, since that
//     file wasn't available to verify against).
//   - The language dropdown drives liveSessionProvider.notifier
//     .setLanguage(), which IS fully known (session_provider.dart) — this
//     test asserts against the real provider state after selecting an
//     item, the same pattern training_flow_test.dart uses.
//
// Deliberately NOT exercised: tapping "Export session data". Its handler
// calls Share.share() (share_plus), which on web typically invokes the
// browser's native share sheet — that requires a real user gesture to
// resolve and can hang a headless/automated tap indefinitely waiting on
// something nothing in this test can dismiss. This test only asserts the
// export control renders.
//
// SettingsScreen calls context.pop() and context.push(AppRoutes.*) — both
// go_router extension methods requiring a real GoRouter ancestor, same as
// HistoryScreen. Wrapped in a minimal test router with a catch-all
// errorBuilder; none of AppRoutes.privacyPolicy/consent/researcher's
// actual path strings need to be known since this test never taps those
// buttons (avoids depending on core/router/app_router.dart, which wasn't
// available to verify against either).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'package:novice/core/di/injection.dart';
import 'package:novice/core/theme/app_theme.dart';
import 'package:novice/features/settings/settings_screen.dart';
import 'package:novice/providers/session_provider.dart';
import 'package:novice/services/participant_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap() {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: SizedBox())),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
      errorBuilder: (context, state) =>
          Scaffold(body: Text('route-not-found: ${state.uri}')),
    );
    // See results_flow_test.dart's note on this — an undisposed ad-hoc
    // GoRouter is the likely source of stray post-test exceptions when
    // multiple tests in one file each build their own router instance.
    addTearDown(router.dispose);
    return ProviderScope(
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
  }

  setUpAll(() async {
    if (!GetIt.instance.isRegistered<ParticipantService>()) {
      await configureDependencies();
    }
  });

  testWidgets('renders all settings sections', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsOneWidget);
    expect(find.text('LEGAL'), findsOneWidget);
    expect(find.text('PILOT STUDY'), findsOneWidget);
    expect(find.text('RESEARCH & DATA'), findsOneWidget);

    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Coaching language'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Participant Enrolment'), findsOneWidget);
    expect(find.text('Researcher Dashboard'), findsOneWidget);
    expect(find.text('Export session data'), findsOneWidget);

    // SettingsScreen's body is a plain ListView(children: [...]) — its
    // Sliver only builds elements near the viewport, so items below the
    // fold (ABOUT section onward) simply don't exist in the widget tree
    // yet. Scroll them into view before asserting on them.
    await tester.scrollUntilVisible(
      find.text('License'),
      300.0,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('License'), findsOneWidget);
    expect(find.text('GNU General Public License v3.0'), findsOneWidget);
  });

  testWidgets('defaults to English coaching language', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // DropdownButton renders an invisible sizing copy of its items in
    // addition to the visible selected one, so 'English' can legitimately
    // appear more than once even while the menu is closed — see
    // results_flow_test.dart's note on the same class of issue with
    // duplicate percentage text.
    expect(find.text('English'), findsAtLeastNWidgets(1));
    expect(find.text('Coaching language'), findsOneWidget);
  });

  testWidgets('toggling the dark mode switch flips its visual state',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    final initialValue = tester.widget<Switch>(switchFinder).value;

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final newValue = tester.widget<Switch>(switchFinder).value;
    expect(newValue, isNot(equals(initialValue)));

    // Subtitle copy should track the new state too.
    expect(
      find.text(newValue
          ? 'Dark surfaces across the app'
          : 'Light surfaces across the app'),
      findsOneWidget,
    );
  });

  testWidgets(
      'selecting Kinyarwanda updates the real liveSessionProvider language',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );
    expect(container.read(liveSessionProvider).language, 'en');

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    // Two 'Kinyarwanda' texts now exist: the closed dropdown's selected
    // item (English, still) plus the open menu's items — select the menu
    // item specifically via the dropdown's overlay entry.
    await tester.tap(find.text('Kinyarwanda').last);
    await tester.pumpAndSettle();

    expect(container.read(liveSessionProvider).language, 'rw');
    expect(find.text('Kinyarwanda (Ikinyarwanda)'), findsOneWidget);
  });

  testWidgets('export control renders but is not tapped (see file header)',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Export session data'), findsOneWidget);
    expect(find.byIcon(Icons.upload_file_rounded), findsOneWidget);
  });
}