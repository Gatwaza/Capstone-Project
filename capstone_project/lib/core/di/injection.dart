import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../services/tts_service.dart';
import '../../services/session_logger.dart';
import '../../services/inference_service.dart';
import '../../services/drive_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerSingleton<TtsService>(TtsService());
  getIt.registerSingleton<SessionLogger>(SessionLogger());
  getIt.registerSingleton<InferenceService>(InferenceService());
  getIt.registerSingleton<DriveService>(DriveService());

  await getIt<TtsService>().initialize();
  await getIt<SessionLogger>().initialize();
  await getIt<InferenceService>().initialize();

  debugPrint('[DI] All services initialized ✓');
}
