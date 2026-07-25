// Covers the happy path of ConsentScreen (lib/features/research/consent_screen.dart)
// that consent_flow_test.dart explicitly could NOT cover: a participant
// actually getting registered and reaching "Participant Enrolled".
//
// Unlocked by the http.Client constructor seam added to ParticipantService
// (see lib/services/participant_service.dart) — this test registers a
// ParticipantService backed by an http.MockClient
// (test_helpers.dart#overrideParticipantServiceForTesting) that returns a
// fake Supabase 201 response, so no real network call happens and no
// SUPABASE_URL/SUPABASE_ANON_KEY --dart-define is required to run this file.
//
// This does NOT exercise participant_service.dart's URL/header construction
// against a real Supabase instance — that's still only verified by the
// "not configured" path in the other flow tests, or by a real staging run.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'package:novice/core/di/injection.dart';
import 'package:novice/core/theme/app_theme.dart';
import 'package:novice/features/research/consent_screen.dart';
import 'package:novice/services/participant_service.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.light(), home: child),
    );
  }

  setUpAll(() async {
    // ConsentScreen reads getIt<ParticipantService>() eagerly in a field
    // initializer, so GetIt must already hold *some* registration before
    // the widget is first pumped. configureDependencies() gives every
    // other service (Logger, StorageService, etc.) its real registration;
    // overrideParticipantServiceForTesting() then swaps just
    // ParticipantService for the mocked one. Guarded so this is safe to
    // call even if a prior test in the same run already configured GetIt.
    if (!GetIt.instance.isRegistered<ParticipantService>()) {
      await configureDependencies();
    }
    overrideParticipantServiceForTesting(assignedParticipantId: 'P999');
  });

  testWidgets(
      'info step -> form step -> submit -> Participant Enrolled with assigned ID',
      (tester) async {
    await tester.pumpWidget(wrap(const ConsentScreen()));
    await tester.pumpAndSettle();

    final infoButton = find.widgetWithText(
      ElevatedButton,
      'I have read and understood this information',
    );
    // The info step is a SingleChildScrollView and this button sits near
    // the bottom — ensureVisible() scrolls it into the viewport first so
    // tap()'s computed offset actually lands on the widget instead of
    // outside the rendered bounds (a harmless-but-fragile warning
    // otherwise; see enrollment_flow_test.dart run notes).
    await tester.ensureVisible(infoButton);
    await tester.pumpAndSettle();
    await tester.tap(infoButton);
    await tester.pumpAndSettle();

    expect(find.text('PARTICIPANT DETAILS'), findsOneWidget);

    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.pumpAndSettle();
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    final submitButton = find.widgetWithText(
      ElevatedButton,
      'Confirm & Enrol Participant',
    );
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    // _saveEnrolment awaits registerParticipant() (now resolved instantly
    // by the MockClient) then setState()s into _buildDoneStep — pump
    // rather than settle in case anything on the done step animates.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Participant Enrolled'), findsOneWidget);
    expect(find.textContaining('ID: P999'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Start Training'),
      findsOneWidget,
    );
  });
}