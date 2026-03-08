import 'package:flutter_test/flutter_test.dart';
import 'package:capstone_project/core/utils/landmark_math.dart';

void main() {
  group('LandmarkMath.estimateBpm', () {
    test('returns null for insufficient data', () {
      expect(LandmarkMath.estimateBpm([0.5, 0.4, 0.6]), isNull);
    });

    test('estimates ~100 BPM from synthetic wrist-Y peaks at 25 fps', () {
      // 100 BPM = 1 compression / 0.6s = 15 frames gap at 25fps
      final buffer = <double>[];
      for (var i = 0; i < 200; i++) {
        // Sine wave with period 15 frames simulates 100 BPM
        buffer.add(0.5 + 0.15 * (i % 15 < 7 ? 1.0 : -1.0));
      }
      final bpm = LandmarkMath.estimateBpm(buffer, minDistance: 10, fps: 25);
      expect(bpm, isNotNull);
      expect(bpm!, inInclusiveRange(85.0, 115.0));
    });
  });

  group('LandmarkMath.featureVector', () {
    test('returns null when landmark maps are empty', () {
      final result = LandmarkMath.featureVector(
        {},
        prevWristY: 0.5,
        prevVelY: 0.0,
        baselineWristY: 0.5,
        refShoulderWidth: 0.3,
      );
      expect(result, isNull);
    });
  });
}
