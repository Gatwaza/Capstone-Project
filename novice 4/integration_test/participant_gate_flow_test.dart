// Covers ParticipantGateScreen (lib/features/research/participant_gate_screen.dart).
//
// Scope note: in this test build, SUPABASE_URL / SUPABASE_ANON_KEY are not
// passed via --dart-define, so Env.isConfigured is false — the same state
// a fresh clone is in before secrets are set. That's not a workaround; it's
// a real, reachable state of the app (see the warning banner's own copy:
// "Backend not configured..."), so this test asserts on it directly instead
// of faking a configured backend.
//
// To also test the CONFIGURED path (dropdown populated with real
// participants, "Register as a new participant" enabled), ParticipantService
// needs an injectable http.Client first — see test_helpers.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:novice/core/theme/app_theme.dart';
import 'package:novice/core/router/app_router.dart';
import 'package:novice/features/research/participant_gate_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: child,
      ),
    );
  }

  testWidgets('shows unconfigured-backend warning and disables new-participant path',
      (tester) async {
    await tester.pumpWidget(wrap(const ParticipantGateScreen()));
    // listParticipants() resolves immediately to [] when unconfigured
    // (see ParticipantService.listParticipants), so a couple of pumps is
    // enough — no pumpAndSettle(), since nothing here animates forever.
    await tester.pump();
    await tester.pump();

    expect(find.text('Who is training?'), findsOneWidget);
    expect(
      find.textContaining('Backend not configured'),
      findsOneWidget,
    );
    expect(find.text('No registered participants found yet.'), findsOneWidget);

    final registerButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Register as a new participant'),
    );
    expect(registerButton.onPressed, isNull,
        reason: 'Register button must be disabled while Env.isConfigured is false');
  });

  testWidgets('continue-to-training stays disabled with no participant selected',
      (tester) async {
    await tester.pumpWidget(wrap(const ParticipantGateScreen()));
    await tester.pump();
    await tester.pump();

    final continueButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Continue to training'),
    );
    expect(continueButton.onPressed, isNull);
  });
}