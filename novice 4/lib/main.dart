// Novice — CPR-AI Coach
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
// GNU General Public License v3.0

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/env.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter web defaults to HASH url strategy (e.g. /#/participant).
  // index.html's JS bridge (launchFlutter / history.pushState) writes
  // plain paths like "/participant" with NO hash, assuming PATH strategy.
  // Without this call, GoRouter listens to window.onhashchange while the
  // JS bridge writes via pushState — two systems disagreeing about where
  // the route lives, which is what produced "Page not found: modules"
  // (a stray #modules scroll-anchor hash from the landing page being
  // misread by GoRouter as a route). This must be called before runApp
  // and matches the assumption already baked into web/index.html and
  // vercel.json's SPA rewrite rule.
  if (kIsWeb) usePathUrlStrategy();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  // Surface config problems in the console at startup, rather than only
  // discovering "[ParticipantService] Not configured" when a participant
  // hits "Confirm & Enrol" deep into the consent flow.
  Env.warmup();

  await configureDependencies();

  runApp(const ProviderScope(child: NoviceApp()));
}

class NoviceApp extends ConsumerStatefulWidget {
  const NoviceApp({super.key});

  @override
  ConsumerState<NoviceApp> createState() => _NoviceAppState();
}

class _NoviceAppState extends ConsumerState<NoviceApp> {
  final _routerWrapper = _GoRouterWrapper();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _registerJsBridge();
  }

  // ── JS ↔ Flutter bridge ──────────────────────────────────────────────────
  // Registers window._noviceFlutterNavigate so the landing page can call
  // router.go(route) once Flutter has mounted.
  void _registerJsBridge() {
    js.context['_noviceFlutterNavigate'] = js.allowInterop((String route) {
      _routerWrapper.navigateTo(route);
      _showBackButton();
    });

    js.context['_noviceShowBackButton'] =
        js.allowInterop(() => _showBackButton());
  }

  void _showBackButton() {
    try {
      // ignore: undefined_prefixed_name
      final btn = js.context['document']
          .callMethod('getElementById', ['back-to-landing']);
      if (btn != null) btn['style']['display'] = 'block';
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    _routerWrapper.setRouter(router);

    return MaterialApp.router(
      title: 'Novice — CPR Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}

// ── GoRouter wrapper ─────────────────────────────────────────────────────────
// Accepts the router lazily so the JS bridge can call go() after Flutter
// mounts without needing it at construction time.
class _GoRouterWrapper {
  GoRouter? _router;

  void setRouter(GoRouter r) => _router = r;

  void navigateTo(String route) => _router?.go(route);
}