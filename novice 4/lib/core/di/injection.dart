// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// Dependency injection — registers all services into GetIt.
//
// WEB-ONLY BUILD (mobile on hold, see PROJECT_STATUS notes):
//   Service           | Web
//   ─────────────────────────────────────────────────────
//   Pose estimation   | PoseServiceWeb
//   ML inference      | InferenceServiceWeb (TF.js / hosted TCN API)
//   Session storage   | StorageService (SharedPrefs)
//   Research logging  | ResearchLoggerWeb (SharedPrefs)
//   TTS               | flutter_tts (Web Speech API)
//   Feedback engine   | FeedbackEngine (same Dart)
//
// Mobile counterparts (PoseServiceMobile, InferenceService, SessionLogger,
// ResearchLogger) were removed from this file when Android/iOS work was
// paused. To resume mobile work: restore those four files from git history,
// re-add their imports below, and reinstate the kIsWeb branches removed
// from this function (see git blame on this file for the prior version).

import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../../services/feedback_engine.dart';
import '../../services/participant_service.dart';
import '../../services/research_logger_web.dart';
import '../../services/platform/inference_service_web.dart'
    show InferenceServiceWeb;
import '../../services/platform/pose_service_interface.dart'
    show PoseServiceInterface;
import '../../services/platform/pose_service_web.dart' show PoseServiceWeb;
import '../../services/platform/storage_service.dart';
import '../../services/platform/telemetry_service.dart';
import '../../services/tts_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ── Logger ─────────────────────────────────────────────────────────────────
  getIt.registerSingleton<Logger>(
    Logger(printer: PrettyPrinter(methodCount: 1, errorMethodCount: 5)),
  );
  final log = getIt<Logger>();

  // ── Session storage ────────────────────────────────────────────────────────
  getIt.registerSingleton<StorageService>(StorageService());
  getIt.registerLazySingleton<TelemetryService>(() => TelemetryService());
  getIt.registerLazySingleton<ParticipantService>(() => ParticipantService());

  // ── TTS ────────────────────────────────────────────────────────────────────
  const umugandaUrl =
      String.fromEnvironment('UMUGANDA_TTS_URL', defaultValue: '');
  final tts = TtsService(
    umugandaTtsUrl: umugandaUrl.isEmpty ? null : umugandaUrl,
  );
  await tts.init();
  getIt.registerSingleton<TtsService>(tts);

  // ── Pose estimation ────────────────────────────────────────────────────────
  final PoseServiceInterface pose = PoseServiceWeb();
  getIt.registerSingleton<PoseServiceInterface>(pose);

  // ── ML Inference ───────────────────────────────────────────────────────────
  final inferWeb = InferenceServiceWeb();
  await inferWeb.init();
  final modelLoaded = inferWeb.isModelLoaded;
  getIt.registerSingleton<InferenceServiceWeb>(inferWeb);

  // ── Feedback engine ────────────────────────────────────────────────────────
  getIt.registerSingleton<FeedbackEngine>(FeedbackEngine());

  // ── Research logger ────────────────────────────────────────────────────────
  // Read optional cloud webhook from compile-time env var:
  //   flutter build web --dart-define=RESEARCH_WEBHOOK_URL=https://...
  const webhookUrl =
      String.fromEnvironment('RESEARCH_WEBHOOK_URL', defaultValue: '');
  final webLogger = ResearchLoggerWeb(
    cloudWebhookUrl: webhookUrl.isEmpty ? null : webhookUrl,
  );
  await webLogger.init();
  getIt.registerSingleton<ResearchLoggerWeb>(webLogger);

  log.i(
    'DI ready | platform=web | '
    'model=${modelLoaded ? "loaded" : "rule-based fallback"}',
  );
}