// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University
//
// TTS service — cross-platform voice coaching.
//
// Language tiers:
//   EN: flutter_tts (offline on mobile, Web Speech API on web)
//   RW: 1. Umuganda TTS HTTP (if endpoint configured in .env)
//       2. flutter_tts English fallback
//
// TODO: Record native Kinyarwanda speaker for assets/audio/rw/
// TODO: Set UMUGANDA_TTS_URL in .env before enabling RW HTTP tier

import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../core/constants/app_constants.dart';

class TtsService {
  TtsService({this.umugandaTtsUrl});

  final String? umugandaTtsUrl;
  final _tts = FlutterTts();
  final _log = Logger();

  bool _initialized = false;
  bool _isSpeaking  = false;
  String _lang      = 'en';

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(()    => _isSpeaking = true);
    _tts.setCompletionHandler(()=> _isSpeaking = false);
    _tts.setErrorHandler((msg) {
      _log.w('TtsService: $msg');
      _isSpeaking = false;
    });

    _initialized = true;
    _log.i('TtsService: initialized');
  }

  void setLanguage(String lang) => _lang = lang;

  Future<void> speakKey(String key) async {
    final prompts = _lang == 'rw'
        ? AppConstants.promptsRw
        : AppConstants.promptsEn;
    final message = prompts[key] ?? prompts['good']!;
    await speak(message);
  }

  Future<void> speak(String message) async {
    if (!_initialized) await init();
    if (_isSpeaking) await stop();

    if (_lang == 'rw') {
      await _speakKinyarwanda(message);
    } else {
      await _speakEnglish(message);
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> dispose() async => _tts.stop();

  Future<void> _speakEnglish(String message) async {
    await _tts.setLanguage('en-US');
    await _tts.speak(message);
  }

  Future<void> _speakKinyarwanda(String message) async {
    if (umugandaTtsUrl != null && umugandaTtsUrl!.isNotEmpty) {
      final ok = await _umugandaHttp(message);
      if (ok) return;
    }
    // Fallback to English — logged for pilot study awareness
    _log.w('TtsService: Kinyarwanda TTS unavailable — falling back to English');
    await _speakEnglish(message);
  }

  Future<bool> _umugandaHttp(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$umugandaTtsUrl/tts'),
        headers: {'Content-Type': 'application/json'},
        body: '{"text":"${message.replaceAll('"', '\\"')}","lang":"rw"}',
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        // TODO: Play returned audio bytes via audioplayers package
        // PLACEHOLDER: HTTP call works but audio playback not yet wired.
        // Phase 2: add audioplayers dependency and play response.bodyBytes
        _log.i('TtsService: Umuganda response ${response.statusCode}');
        return false; // return false until playback wired
      }
      return false;
    } catch (e) {
      _log.w('TtsService: Umuganda HTTP failed — $e');
      return false;
    }
  }
}
