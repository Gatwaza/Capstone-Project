// Covers ConsentScreen (lib/features/research/consent_screen.dart).
//
// _saveEnrolment() calls ParticipantService.registerParticipant(), which
// hits Supabase directly over `http` with no injected client (see
// test_helpers.dart's note). Same scope decision as participant_gate_flow_test.dart:
// this test runs with Env unconfigured, so registerParticipant() throws
// StateError synchronously and the screen's own catch block shows an
// "Enrolment failed" SnackBar — a real, user-reachable failure path, not a
// mocked one. It does NOT reach step 2 (_buildDoneStep) because that
// requires a real assigned participant ID from the server.
//
// A true happy-path test (reaching "Participant Enrolled" and asserting the
// Start Training button) needs ParticipantService to accept an injected
// http.Client so a MockClient can return a fake 201 — flag this to Ron
// before claiming step-2 coverage exists.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:novice/core/theme/app_theme.dart';
import 'package:novice/features/research/consent_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );
  }

  testWidgets('info step -> form step -> consent checkbox enables submit',
      (tester) async {
    await tester.pumpWidget(wrap(const ConsentScreen()));
    await tester.pumpAndSettle();

    expect(find.text('PARTICIPANT INFORMATION SHEET'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'I have read and understood this information'),
    );
    await tester.pumpAndSettle();

    expect(find.text('PARTICIPANT DETAILS'), findsOneWidget);

    // Submit is disabled until the consent checkbox is checked.
    var submit = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Confirm & Enrol Participant'),
    );
    expect(submit.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    submit = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Confirm & Enrol Participant'),
    );
    expect(submit.onPressed, isNotNull);
  });

  testWidgets('submitting with an unconfigured backend shows the enrolment-failed snackbar',
      (tester) async {
    await tester.pumpWidget(wrap(const ConsentScreen()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'I have read and understood this information'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Confirm & Enrol Participant'),
    );
    // _saveEnrolment's catch block runs after the failed await — pump
    // rather than settle in case the SnackBar's own entrance animation
    // would otherwise be mistaken for "never settles".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Enrolment failed'), findsOneWidget);
  });
}