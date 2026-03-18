// Novice — CPR-AI Coach
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — CPR coaching requires vertical phone orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Immersive mode for unobstructed camera view during training
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  // Bootstrap dependency injection
  await configureDependencies();

  runApp(
    const ProviderScope(
      child: NoviceApp(),
    ),
  );
}

class NoviceApp extends ConsumerWidget {
  const NoviceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Novice — CPR Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(), // Dark theme: better camera contrast, battery on OLED
      routerConfig: router,
    );
  }
}
