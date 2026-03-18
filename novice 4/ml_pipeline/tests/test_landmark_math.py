"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

test_landmark_math.py
─────────────────────
Unit tests for the geometry functions in extract_landmarks.py.
These mirror the Dart tests in test/unit/landmark_math_test.dart
to ensure both platforms produce identical feature vectors.

Run: python -m pytest tests/test_landmark_math.py -v
"""

import sys
from pathlib import Path
import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))
from data.extract_landmarks import (
    joint_angle_deg,
    spine_verticality_deg,
    normalized_wrist_displacement,
    build_feature_vector,
)


# ── joint_angle_deg ───────────────────────────────────────

class TestJointAngleDeg:
    def test_straight_line_is_180(self):
        # A(0,0) → B(1,0) → C(2,0)
        assert joint_angle_deg(0, 0, 1, 0, 2, 0) == pytest.approx(180.0, abs=0.001)

    def test_right_angle_is_90(self):
        # A(0,1) → B(0,0) → C(1,0)
        assert joint_angle_deg(0, 1, 0, 0, 1, 0) == pytest.approx(90.0, abs=0.001)

    def test_degenerate_zero_length_returns_zero(self):
        # A == B: zero-length vector
        assert joint_angle_deg(0, 0, 0, 0, 1, 0) == pytest.approx(0.0, abs=0.001)

    def test_angle_range_valid(self):
        angle = joint_angle_deg(0.4, 0.3, 0.35, 0.45, 0.47, 0.58)
        assert 0.0 <= angle <= 180.0


# ── spine_verticality_deg ─────────────────────────────────

class TestSpineVerticality:
    def test_vertical_torso_is_zero(self):
        # Shoulder directly above hip, same X
        shoulder = np.array([0.5, 0.3])
        hip      = np.array([0.5, 0.7])
        assert spine_verticality_deg(shoulder, hip) == pytest.approx(0.0, abs=0.001)

    def test_horizontal_torso_is_90(self):
        # Shoulder and hip at same Y
        shoulder = np.array([0.3, 0.5])
        hip      = np.array([0.7, 0.5])
        assert spine_verticality_deg(shoulder, hip) == pytest.approx(90.0, abs=0.5)

    def test_slight_lean_is_positive(self):
        shoulder = np.array([0.5, 0.28])
        hip      = np.array([0.52, 0.75])
        angle = spine_verticality_deg(shoulder, hip)
        assert 0.0 < angle < 30.0


# ── normalized_wrist_displacement ────────────────────────

class TestNormWristDisp:
    def test_wrist_at_shoulder_is_zero(self):
        assert normalized_wrist_displacement(0.3, 0.3, 0.7) == pytest.approx(0.0, abs=0.001)

    def test_wrist_at_hip_is_one(self):
        assert normalized_wrist_displacement(0.7, 0.3, 0.7) == pytest.approx(1.0, abs=0.001)

    def test_wrist_at_midpoint(self):
        assert normalized_wrist_displacement(0.5, 0.3, 0.7) == pytest.approx(0.5, abs=0.01)

    def test_zero_torso_returns_zero(self):
        # No division by zero
        assert normalized_wrist_displacement(0.5, 0.5, 0.5) == pytest.approx(0.0, abs=0.001)

    def test_clipped_to_unit_range(self):
        # Wrist above shoulder — should clip to 0
        val = normalized_wrist_displacement(0.1, 0.4, 0.8)
        assert 0.0 <= val <= 1.0


# ── build_feature_vector ──────────────────────────────────

class _FakeLandmark:
    """Minimal landmark stub for testing."""
    def __init__(self, x, y, vis=1.0):
        self.x, self.y, self.visibility = x, y, vis


def _make_landmarks():
    """Realistic CPR rescuer pose (approximate normalised coords)."""
    lms = [None] * 33
    lms[11] = _FakeLandmark(0.38, 0.28)   # left shoulder
    lms[12] = _FakeLandmark(0.62, 0.28)   # right shoulder
    lms[13] = _FakeLandmark(0.35, 0.44)   # left elbow
    lms[14] = _FakeLandmark(0.65, 0.44)   # right elbow
    lms[15] = _FakeLandmark(0.47, 0.57)   # left wrist
    lms[16] = _FakeLandmark(0.53, 0.57)   # right wrist
    lms[23] = _FakeLandmark(0.40, 0.75)   # left hip
    lms[24] = _FakeLandmark(0.60, 0.75)   # right hip
    return lms


class TestBuildFeatureVector:
    def test_returns_12_features(self):
        lms = _make_landmarks()
        fv  = build_feature_vector(lms, None, None)
        assert fv.shape == (12,)
        assert fv.dtype == np.float32

    def test_mean_elbow_angle_at_index_2(self):
        lms = _make_landmarks()
        fv  = build_feature_vector(lms, None, None)
        left  = fv[0]
        right = fv[1]
        mean  = fv[2]
        assert mean == pytest.approx((left + right) / 2, abs=0.01)

    def test_no_nans_or_infs(self):
        lms = _make_landmarks()
        fv  = build_feature_vector(lms, None, None)
        assert not np.any(np.isnan(fv))
        assert not np.any(np.isinf(fv))

    def test_velocity_zero_on_first_frame(self):
        lms = _make_landmarks()
        fv  = build_feature_vector(lms, None, None)
        # Index 5 = wrist_vel_y, should be 0 when prev_wrist_y is None
        assert fv[5] == pytest.approx(0.0, abs=0.001)

    def test_velocity_computed_on_second_frame(self):
        lms        = _make_landmarks()
        prev_wrist = 0.50   # previous frame wrist Y
        fv         = build_feature_vector(lms, prev_wrist, 0.0)
        expected_vel = (lms[15].y + lms[16].y) / 2 - prev_wrist
        assert fv[5] == pytest.approx(expected_vel, abs=0.001)

    def test_visibility_flags_binary(self):
        lms = _make_landmarks()
        fv  = build_feature_vector(lms, None, None)
        assert fv[10] in (0.0, 1.0)
        assert fv[11] in (0.0, 1.0)

    def test_low_visibility_landmark_flags_as_zero(self):
        lms      = _make_landmarks()
        lms[13].visibility = 0.3   # left elbow below MIN_VISIBILITY
        fv       = build_feature_vector(lms, None, None)
        assert fv[10] == pytest.approx(0.0, abs=0.001)
