import 'package:flutter_test/flutter_test.dart';
import 'package:capstone_project/models/session_model.dart';

void main() {
  group('CprSession.scoreGrade', () {
    CprSession make(double score) => CprSession(
      id: 'test',
      startedAt: DateTime.now(),
      durationSeconds: 120,
      rateAdherenceScore: score,
      postureScore: score,
      overallScore: score,
      totalCompressions: 120,
      language: 'en',
      events: [],
    );

    test('Excellent at >= 85%',  () => expect(make(0.90).scoreGrade, 'Excellent'));
    test('Good at >= 70%',       () => expect(make(0.75).scoreGrade, 'Good'));
    test('Fair at >= 50%',       () => expect(make(0.55).scoreGrade, 'Fair'));
    test('Needs Practice < 50%', () => expect(make(0.30).scoreGrade, 'Needs Practice'));
  });

  group('CprSession JSON round-trip', () {
    test('serialises and deserialises correctly', () {
      final session = CprSession(
        id: 'abc123',
        startedAt: DateTime(2024, 1, 15, 10, 0),
        endedAt:   DateTime(2024, 1, 15, 10, 2),
        durationSeconds: 120,
        avgBpm: 108.5,
        rateAdherenceScore: 0.9,
        postureScore: 0.8,
        overallScore: 0.86,
        totalCompressions: 200,
        language: 'en',
        events: [
          const FeedbackEvent(
            frameIndex: 50,
            promptKey: 'elbows_bent',
            priority: 2,
            bpmAtEvent: 95.0,
            label: 'bent_elbows',
          ),
        ],
      );
      final json = session.toJson();
      final restored = CprSession.fromJson(json);
      expect(restored.id, session.id);
      expect(restored.avgBpm, session.avgBpm);
      expect(restored.events.length, 1);
      expect(restored.events.first.promptKey, 'elbows_bent');
    });
  });
}
