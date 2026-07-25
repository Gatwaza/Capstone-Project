// Smoke test for the integration_test harness itself.
// Boots the REAL app via main()'s own path (runApp + configureDependencies),
// same as a real user opening the browser. If this test is red, every other
// integration test will be red for the same reason — get this green first.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:novice/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Novice boots and shows the home screen', (tester) async {
    app.main();
    // Splash screen auto-redirects to /home — this can take a beat, so pump
    // a fixed number of frames instead of pumpAndSettle(), which will hang
    // if anything on the screen animates continuously (e.g. a loading spinner).
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Novice'), findsWidgets);
  });
}