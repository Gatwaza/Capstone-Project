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

  group('FeedbackEngine — adaptive severity bands (post-defense revision)', () {
    test('mildly slow rate → warning, not critical', () {
      final prompt = engine.process(_makeResult(bpm: 90), 'en');
      expect(prompt.key, equals('rate_too_slow'));
      expect(prompt.severity, equals(FeedbackSeverity.warning));
    });

    test('severely slow rate → critical, distinct key', () {
      final prompt = engine.process(_makeResult(bpm: 60), 'en');
      expect(prompt.key, equals('rate_too_slow_severe'));
      expect(prompt.severity, equals(FeedbackSeverity.critical));
    });

    test('severely fast rate → critical, distinct key', () {
      final prompt = engine.process(_makeResult(bpm: 150), 'en');
      expect(prompt.key, equals('rate_too_fast_severe'));
      expect(prompt.severity, equals(FeedbackSeverity.critical));
    });

    test('mildly shallow depth → message includes the measured value', () {
      final prompt = engine.process(_makeResult(depth: 4.2), 'en');
      expect(prompt.key, equals('too_shallow'));
      expect(prompt.message, contains('4.2'));
    });

    test('severely shallow depth → distinct key and message', () {
      final prompt = engine.process(_makeResult(depth: 2.0), 'en');
      expect(prompt.key, equals('too_shallow_severe'));
      expect(prompt.message, contains('2.0'));
    });

    test('rate message includes the actual bpm value', () {
      final prompt = engine.process(_makeResult(bpm: 135), 'en');
      expect(prompt.message, contains('135'));
    });

    test('numeric rate check overrides a stale "correct" label even at '
        'low confidence', () {
      final prompt = engine.process(
        _makeResult(label: 'correct_compression', bpm: 145, confidence: 0.4),
        'en',
      );
      expect(prompt.key, equals('rate_too_fast_severe'));
    });

    test('not_compressing label → critical regardless of bpm', () {
      final prompt = engine.process(_makeResult(label: 'not_compressing', bpm: 0), 'en');
      expect(prompt.key, equals('not_compressing'));
      expect(prompt.severity, equals(FeedbackSeverity.critical));
    });
  });

  group('FeedbackEngine — first prompt always speaks', () {
    test('very first prompt of a session speaks even if it is "good"', () {
      final result = _makeResult();
      final prompt = engine.process(result, 'en');
      expect(prompt.severity, equals(FeedbackSeverity.good));
      expect(engine.shouldSpeak(prompt), isTrue);
    });

    test('very first prompt speaks even if it is a critical error', () {
      final result = _makeResult(label: 'not_compressing', bpm: 0);
      final prompt = engine.process(result, 'en');
      expect(engine.shouldSpeak(prompt), isTrue);
    });
  });
}