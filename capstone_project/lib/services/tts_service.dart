import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class _QueueItem {
  final String key;
  final int priority;
  final DateTime ts;
  _QueueItem(this.key, this.priority) : ts = DateTime.now();
}

class TtsService {
  final FlutterTts _tts = FlutterTts();
  String _lang = 'en';
  bool _speaking = false;
  final List<_QueueItem> _queue = [];
  final Map<String, DateTime> _lastSpoken = {};
  DateTime _globalLast = DateTime(2000);

  // Umuganda TTS base URL — from .env
  // [PLACEHOLDER: set UMUGANDA_HOST and UMUGANDA_PORT in .env]
  final String _umugandaUrl = 'http://127.0.0.1:5002/api/tts';

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.85);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      _speaking = false;
      _processQueue();
    });
    _tts.setErrorHandler((msg) {
      _speaking = false;
      _processQueue();
    });
  }

  void setLanguage(String lang) {
    _lang = lang;
    stop();
  }

  void enqueue(String promptKey, int priority) {
    final last = _lastSpoken[promptKey];
    if (last != null &&
        DateTime.now().difference(last).inMilliseconds <
            AppConstants.feedbackCooldownMs) return;

    // Critical prompts displace lower-priority items
    if (priority == AppConstants.priorityCritical) {
      _queue.removeWhere((i) => i.priority > AppConstants.priorityCritical);
    }

    _queue.add(_QueueItem(promptKey, priority));
    _queue.sort((a, b) =>
        a.priority != b.priority ? a.priority - b.priority : a.ts.compareTo(b.ts));

    if (!_speaking) _processQueue();
  }

  void stop() {
    _tts.stop();
    _queue.clear();
    _speaking = false;
  }

  void _processQueue() {
    if (_speaking || _queue.isEmpty) return;
    final elapsed = DateTime.now().difference(_globalLast).inMilliseconds;
    if (elapsed < AppConstants.feedbackMinIntervalMs) {
      Future.delayed(
        Duration(milliseconds: AppConstants.feedbackMinIntervalMs - elapsed),
        _processQueue,
      );
      return;
    }
    final next = _queue.removeAt(0);
    _speak(next.key);
  }

  Future<void> _speak(String key) async {
    final text = _resolveText(key);
    if (text == null) { _processQueue(); return; }
    _speaking = true;
    _lastSpoken[key] = DateTime.now();
    _globalLast = DateTime.now();

    // Try Umuganda for Kinyarwanda
    if (_lang == 'rw') {
      final ok = await _speakUmuganda(text);
      if (ok) return;
    }

    // Fallback to flutter_tts
    await _tts.setLanguage(_lang == 'rw' ? 'rw-RW' : 'en-US');
    await _tts.speak(text);
  }

  Future<bool> _speakUmuganda(String text) async {
    try {
      final resp = await http.post(
        Uri.parse(_umugandaUrl),
        headers: {'Content-Type': 'application/json'},
        body: '{"text":"$text","speaker_id":0}',
      ).timeout(const Duration(seconds: 3));
      if (resp.statusCode != 200) return false;
      // [PLACEHOLDER: play resp.bodyBytes via audioplayer]
      // For now falls through to flutter_tts
      return false;
    } catch (_) {
      return false; // Server not running — use flutter_tts
    }
  }

  String? _resolveText(String key) {
    final map = _lang == 'rw' ? AppConstants.promptsRw : AppConstants.promptsEn;
    return map[key] ?? AppConstants.promptsEn[key];
  }
}
