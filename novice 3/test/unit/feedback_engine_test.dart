// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter_test/flutter_test.dart';
import 'package:novice/models/session_model.dart';
import 'package:novice/services/feedback_engine.dart';

InferenceResult _makeResult({
  String label = 'correct_compression',
  double bpm = 110,
  double depth = 5.2,
  double confidence = 0.9,
}) {
  return InferenceResult(
    timestamp: DateTime.now(),
    topClassIndex: 0,
    topClassLabel: label,
    topClassConfidence: confidence,
    allClassScores: {label: confidence},
    currentBpm: bpm,
    estimatedDepthCm: depth,
    elbowAngleMean: 170,
    spineVerticalityDeg: 5,
    isSimulated: true,
  );
}

void main() {
  late FeedbackEngine engine;

  setUp(() {
    engine = FeedbackEngine();
  });

  group('FeedbackEngine — key resolution', () {
    test('correct compression → good', () {
      final result = _makeResult(label: 'correct_compression', bpm: 110);
      final prompt = engine.process(result, 'en');
      expect(prompt.key, equals('good'));
      expect(prompt.severity, equals(FeedbackSeverity.good));
    });

    test('rate too slow overrides model label', () {
      final result = _makeResult(label: 'correct_compression', bpm: 80);
      final prompt = engine.process(result, 'en');
      expect(prompt.key, equals('rate_too_slow'));
      expect(prompt.severity, equals(FeedbackSeverity.warning));
    });

    test('rate too fast overrides model label', () {
      final result = _makeResult(label: 'correct_compression', bpm: 135);
      final prompt = engine.process(result, 'en');
      expect(prompt.key, equals('rate_too_fast'));
    });

    test('bent_elbows is preserved when rate is OK', () {
      final result = _makeResult(label: 'bent_elbows', bpm: 112);
      final prompt = engine.process(result, 'en');
      expect(prompt.key, equals('bent_elbows'));
    });

    test('English prompt message is non-empty', () {
      final result = _makeResult();
      final prompt = engine.process(result, 'en');
      expect(prompt.message, isNotEmpty);
    });

    test('Kinyarwanda prompt message is non-empty', () {
      final result = _makeResult();
      final prompt = engine.process(result, 'rw');
      expect(prompt.message, isNotEmpty);
    });
  });

  group('FeedbackEngine — speak gating', () {
    test('first prompt should always speak', () {
      final result = _makeResult();
      final prompt = engine.process(result, 'en');
      expect(engine.shouldSpeak(prompt), isTrue);
    });

    test('same non-critical prompt should not speak again immediately', () {
      final result = _makeResult();
      final prompt = engine.process(result, 'en');
      engine.shouldSpeak(prompt); // first speak — sets timestamp
      expect(engine.shouldSpeak(prompt), isFalse); // too soon
    });

    test('critical prompt bypasses cooldown', () {
      // First speak
      final good = _makeResult();
      final goodPrompt = engine.process(good, 'en');
      engine.shouldSpeak(goodPrompt);

      // Immediately after — critical should still fire
      final critical = _makeResult(label: 'not_compressing', bpm: 0);
      final critPrompt = engine.process(critical, 'en');
      expect(critPrompt.severity, equals(FeedbackSeverity.critical));
      expect(engine.shouldSpeak(critPrompt), isTrue);
    });

    test('reset clears state so next prompt speaks', () {
      final result = _makeResult();
      final prompt = engine.process(result, 'en');
      engine.shouldSpeak(prompt);
      engine.reset();
      expect(engine.shouldSpeak(prompt), isTrue);
    });
  });

  group('FeedbackEngine — severity', () {
    test('good → FeedbackSeverity.good', () {
      expect(
        engine.process(_makeResult(label: 'correct_compression'), 'en').severity,
        FeedbackSeverity.good,
      );
    });

    test('bent_elbows → FeedbackSeverity.warning', () {
      expect(
        engine.process(_makeResult(label: 'bent_elbows', bpm: 110), 'en').severity,
        FeedbackSeverity.warning,
      );
    });
  });
}
