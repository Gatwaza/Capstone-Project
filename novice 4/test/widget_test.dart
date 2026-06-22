// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Basic smoke test — verifies the app boots and renders without throwing.
// Replaces the unmodified `flutter create` counter-app template test,
// which referenced a nonexistent `MyApp` class and a counter UI this app
// never had.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novice/main.dart';

void main() {
  testWidgets('NoviceApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NoviceApp()),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
