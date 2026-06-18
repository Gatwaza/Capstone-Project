// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Dependency injection — registers all services into GetIt.
//
// Platform service matrix:
//   Service           | iOS/Android              | Web
//   ──────────────────────────────────────────────────────────────────────
//   Pose estimation   | PoseServiceMobile        | PoseServiceWeb
//   ML inference      | InferenceService (TFLite)| InferenceServiceWeb (TF.js)
//   Session storage   | SessionLogger (SQLite)   | StorageService (SharedPrefs)
//   Research logging  | ResearchLogger (SQLite)  | ResearchLoggerWeb (SharedPrefs)
//   TTS               | flutter_tts (offline)    | flutter_tts (Web Speech API)
//   Feedback engine   | FeedbackEngine           | FeedbackEngine (same Dart)
//
// FIX (2025-06): ResearchLoggerWeb is now registered on web so that
//   researcher_dashboard.dart can call getIt<ResearchLoggerWeb>() safely.
//   The dashboard previously called getIt<ResearchLogger>() unconditionally,
//   crashing on web with "Object/factory with type ResearchLogger is not
//   registered inside GetIt."

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../services/feedback_engine.dart';
import '../../services/inference_service.dart';
import '../../services/research_logger.dart';
import '../../services/research_logger_web.dart';
import '../../services/session_logger.dart';
import '../../services/platform/inference_service_web.dart'
    show InferenceServiceWeb;
import '../../services/platform/pose_service_interface.dart'
    show PoseServiceInterface;
import '../../services/platform/pose_service_mobile.dart'
    show PoseServiceMobile;
import '../../services/platform/pose_service_web.dart' show PoseServiceWeb;
import '../../services/platform/storage_service.dart';
import '../../services/tts_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ── Logger ─────────────────────────────────────────────────────────────────
  getIt.registerSingleton<Logger>(
    Logger(printer: PrettyPrinter(methodCount: 1, errorMethodCount: 5)),
  );
  final log = getIt<Logger>();

  // ── Session storage ────────────────────────────────────────────────────────
  SessionLogger? sqliteLogger;
  if (!kIsWeb) {
    sqliteLogger = SessionLogger();
    await sqliteLogger.init();
    getIt.registerSingleton<SessionLogger>(sqliteLogger);
  }
  getIt.registerSingleton<StorageService>(
    StorageService(mobileLogger: sqliteLogger),
  );

  // ── TTS ────────────────────────────────────────────────────────────────────
  const umugandaUrl =
      String.fromEnvironment('UMUGANDA_TTS_URL', defaultValue: '');
  final tts = TtsService(
    umugandaTtsUrl: umugandaUrl.isEmpty ? null : umugandaUrl,
  );
  await tts.init();
  getIt.registerSingleton<TtsService>(tts);

  // ── Pose estimation ────────────────────────────────────────────────────────
  final PoseServiceInterface pose =
      kIsWeb ? PoseServiceWeb() : PoseServiceMobile();
  getIt.registerSingleton<PoseServiceInterface>(pose);

  // ── ML Inference ───────────────────────────────────────────────────────────
  bool modelLoaded = false;
  if (kIsWeb) {
    final inferWeb = InferenceServiceWeb();
    await inferWeb.init();
    modelLoaded = inferWeb.isModelLoaded;
    getIt.registerSingleton<InferenceServiceWeb>(inferWeb);
  } else {
    final infer = InferenceService();
    await infer.loadModel();
    modelLoaded = infer.isModelLoaded;
    getIt.registerSingleton<InferenceService>(infer);
  }

  // ── Feedback engine ────────────────────────────────────────────────────────
  getIt.registerSingleton<FeedbackEngine>(FeedbackEngine());

  // ── Research logger ────────────────────────────────────────────────────────
  // Web:    ResearchLoggerWeb (SharedPreferences / localStorage)
  // Mobile: ResearchLogger   (SQLite via sqflite)
  // Both are registered so researcher_dashboard + consent_screen
  // can use the ResearchLoggerAdapter helper below without platform checks.
  if (kIsWeb) {
    // Read optional cloud webhook from compile-time env var:
    //   flutter build web --dart-define=RESEARCH_WEBHOOK_URL=https://...
    const webhookUrl = String.fromEnvironment('RESEARCH_WEBHOOK_URL',
        defaultValue: '');
    final webLogger = ResearchLoggerWeb(
      cloudWebhookUrl: webhookUrl.isEmpty ? null : webhookUrl,
    );
    await webLogger.init();
    getIt.registerSingleton<ResearchLoggerWeb>(webLogger);
  } else {
    final research = ResearchLogger();
    await research.init();
    getIt.registerSingleton<ResearchLogger>(research);
  }

  log.i(
    'DI ready | platform=${kIsWeb ? "web" : "mobile"} | '
    'model=${modelLoaded ? "loaded" : "rule-based fallback"}',
  );
}