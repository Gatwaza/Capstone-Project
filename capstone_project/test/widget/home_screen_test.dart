import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:capstone_project/screens/home_screen.dart';
import 'package:capstone_project/services/session_logger.dart';

// Minimal smoke test — checks the home screen mounts without crashing
void main() {
  setUp(() async {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<SessionLogger>()) {
      getIt.registerSingleton<SessionLogger>(SessionLogger());
    }
  });

  testWidgets('HomeScreen renders Start button', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Start CPR Training'), findsOneWidget);
    expect(find.text('Watch Demo'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}
