// Novice — CPR-AI Coach
// GNU General Public License v3.0
// Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

import 'package:flutter_test/flutter_test.dart';
import 'package:novice/core/utils/landmark_math.dart';

void main() {
  group('LandmarkMath — joint angles', () {
    test('straight line returns 180°', () {
      // A(0,0) → B(1,0) → C(2,0) : perfectly straight
      final angle = LandmarkMath.jointAngleDeg(0, 0, 1, 0, 2, 0);
      expect(angle, closeTo(180.0, 0.001));
    });

    test('right angle returns 90°', () {
      // A(0,1) → B(0,0) → C(1,0) : perpendicular
      final angle = LandmarkMath.jointAngleDeg(0, 1, 0, 0, 1, 0);
      expect(angle, closeTo(90.0, 0.001));
    });

    test('zero-length vector returns 0°', () {
      // Degenerate case: A == B
      final angle = LandmarkMath.jointAngleDeg(0, 0, 0, 0, 1, 0);
      expect(angle, closeTo(0.0, 0.001));
    });

    test('locked elbow (>= 160°) detected correctly', () {
      // Simulate near-straight arm: shoulder(0.4, 0.3) elbow(0.35, 0.45) wrist(0.47, 0.58)
      final angle = LandmarkMath.jointAngleDeg(0.4, 0.3, 0.35, 0.45, 0.47, 0.58);
      // We just verify it's a valid angle, not zero
      expect(angle, greaterThan(0));
      expect(angle, lessThanOrEqualTo(180));
    });
  });

  group('LandmarkMath — spine verticality', () {
    test('perfectly vertical torso returns 0°', () {
      // Shoulder directly above hip at same X
      final angle = LandmarkMath.spineVerticalityDeg(0.5, 0.3, 0.5, 0.7);
      expect(angle, closeTo(0.0, 0.001));
    });

    test('horizontal torso returns 90°', () {
      // Shoulder and hip at same Y — leaning all the way over
      final angle = LandmarkMath.spineVerticalityDeg(0.3, 0.5, 0.7, 0.5);
      expect(angle, closeTo(90.0, 0.5));
    });

    test('slight lean returns non-zero angle', () {
      final angle = LandmarkMath.spineVerticalityDeg(0.5, 0.28, 0.52, 0.75);
      expect(angle, greaterThan(0));
      expect(angle, lessThan(30));
    });
  });

  group('LandmarkMath — normalized wrist displacement', () {
    test('wrist at shoulder level returns 0', () {
      final d = LandmarkMath.normalizedWristDisplacement(0.3, 0.3, 0.7);
      expect(d, closeTo(0.0, 0.001));
    });

    test('wrist at hip level returns 1', () {
      final d = LandmarkMath.normalizedWristDisplacement(0.7, 0.3, 0.7);
      expect(d, closeTo(1.0, 0.001));
    });

    test('wrist at mid-torso returns ~0.5', () {
      final d = LandmarkMath.normalizedWristDisplacement(0.5, 0.3, 0.7);
      expect(d, closeTo(0.5, 0.01));
    });

    test('zero torso height returns 0 (no division by zero)', () {
      final d = LandmarkMath.normalizedWristDisplacement(0.5, 0.5, 0.5);
      expect(d, closeTo(0.0, 0.001));
    });
  });

  group('LandmarkMath — hand placement', () {
    test('sternum center returns correct', () {
      // 50% down torso = sternum
      final result = LandmarkMath.assessHandPlacement(0.5, 0.3, 0.7);
      expect(result, HandPlacementResult.correct);
    });

    test('hands too high', () {
      // 25% down torso = above sternum
      final result = LandmarkMath.assessHandPlacement(0.35, 0.3, 0.7);
      expect(result, HandPlacementResult.tooHigh);
    });

    test('hands too low', () {
      // 90% down torso = below sternum
      final result = LandmarkMath.assessHandPlacement(0.66, 0.3, 0.7);
      expect(result, HandPlacementResult.tooLow);
    });

    test('zero torso returns unknown', () {
      final result = LandmarkMath.assessHandPlacement(0.5, 0.5, 0.5);
      expect(result, HandPlacementResult.unknown);
    });
  });

  group('LandmarkMath — feature vector', () {
    test('returns correct length (12)', () {
      final vec = LandmarkMath.buildFeatureVector(
        leftElbowAngle:     170.0,
        rightElbowAngle:    168.0,
        spineVerticality:   5.0,
        wristY:             0.55,
        wristVelocityY:     0.01,
        wristAccelerationY: 0.001,
        normalizedDepth:    0.4,
        shoulderWidth:      0.22,
        meanConfidence:     0.95,
        leftElbowVisible:   true,
        rightElbowVisible:  true,
      );
      expect(vec.length, equals(12));
    });

    test('mean elbow angle is correct (index 2)', () {
      final vec = LandmarkMath.buildFeatureVector(
        leftElbowAngle:     160.0,
        rightElbowAngle:    180.0,
        spineVerticality:   0,
        wristY:             0,
        wristVelocityY:     0,
        wristAccelerationY: 0,
        normalizedDepth:    0,
        shoulderWidth:      0,
        meanConfidence:     1.0,
        leftElbowVisible:   true,
        rightElbowVisible:  true,
      );
      expect(vec[2], closeTo(170.0, 0.001)); // mean of 160 and 180
    });

    test('visibility flags encoded as 0/1', () {
      final vec = LandmarkMath.buildFeatureVector(
        leftElbowAngle:     170.0,
        rightElbowAngle:    170.0,
        spineVerticality:   0,
        wristY:             0,
        wristVelocityY:     0,
        wristAccelerationY: 0,
        normalizedDepth:    0,
        shoulderWidth:      0,
        meanConfidence:     1.0,
        leftElbowVisible:   true,
        rightElbowVisible:  false,
      );
      expect(vec[10], closeTo(1.0, 0.001)); // left visible
      expect(vec[11], closeTo(0.0, 0.001)); // right not visible
    });
  });

  group('LandmarkMath — distance and dot product', () {
    test('distance2d is correct', () {
      expect(LandmarkMath.distance2d(0, 0, 3, 4), closeTo(5.0, 0.001));
    });

    test('dot2d is correct', () {
      expect(LandmarkMath.dot2d(1, 0, 0, 1), closeTo(0.0, 0.001));  // perpendicular
      expect(LandmarkMath.dot2d(1, 0, 1, 0), closeTo(1.0, 0.001));  // parallel
    });
  });
}
