#!/usr/bin/env python3
"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

extract_landmarks.py
────────────────────
Extracts the 12-dimensional feature vector from every frame of every
CPR-Coach video using MediaPipe BlazePose.

Output: data/landmarks/<split>/<class_label>/<video_id>.npy
  Each .npy file: float32 array of shape (T, 12) where T = frame count.

Usage:
  python src/data/extract_landmarks.py --config config.yaml
  python src/data/extract_landmarks.py --config config.yaml --video_dir data/raw/Sample_Dataset

References:
  Wang et al. (2023) CPR-Coach dataset — github.com/Shunli-Wang/CPR-Coach
  MediaPipe BlazePose — Bazarevsky et al. (2020) arxiv.org/abs/2006.10204
"""

import argparse
import json
import logging
import os
import sys
from pathlib import Path
from typing import Optional

import cv2
import mediapipe as mp
import numpy as np
import yaml
from tqdm import tqdm

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("extract_landmarks")

# ── MediaPipe landmark indices ────────────────────────────────────────────────
# https://developers.google.com/mediapipe/solutions/vision/pose_landmarker
MP_LEFT_SHOULDER  = 11
MP_RIGHT_SHOULDER = 12
MP_LEFT_ELBOW     = 13
MP_RIGHT_ELBOW    = 14
MP_LEFT_WRIST     = 15
MP_RIGHT_WRIST    = 16
MP_LEFT_HIP       = 23
MP_RIGHT_HIP      = 24


# ── Geometry helpers (vectorized, matches lib/core/utils/landmark_math.dart) ──

def joint_angle_deg(
    ax: float, ay: float,
    bx: float, by: float,
    cx: float, cy: float,
) -> float:
    """Angle at joint B in degrees [0, 180].  Mirrors LandmarkMath.jointAngleDeg."""
    v1 = np.array([ax - bx, ay - by], dtype=np.float64)
    v2 = np.array([cx - bx, cy - by], dtype=np.float64)
    m = np.linalg.norm(v1) * np.linalg.norm(v2)
    if m < 1e-9:
        return 0.0
    cos_a = np.clip(np.dot(v1, v2) / m, -1.0, 1.0)
    return float(np.degrees(np.arccos(cos_a)))


def spine_verticality_deg(
    shoulder_mid: np.ndarray,  # (x, y)
    hip_mid: np.ndarray,        # (x, y)
) -> float:
    """Angle between torso midline and vertical (0° = perfectly vertical).
    Mirrors LandmarkMath.spineVerticalityDeg."""
    torso = shoulder_mid - hip_mid          # upward vector
    vertical = np.array([0.0, -1.0])        # up in image space (Y increases down)
    m = np.linalg.norm(torso)
    if m < 1e-9:
        return 0.0
    cos_a = np.clip(np.dot(torso, vertical) / m, -1.0, 1.0)
    return float(np.degrees(np.arccos(cos_a)))


def normalized_wrist_displacement(
    wrist_y: float,
    shoulder_y: float,
    hip_y: float,
) -> float:
    """Normalised wrist displacement relative to torso height.
    Mirrors LandmarkMath.normalizedWristDisplacement."""
    torso_h = abs(hip_y - shoulder_y)
    if torso_h < 1e-6:
        return 0.0
    return float(np.clip((wrist_y - shoulder_y) / torso_h, 0.0, 1.0))


def build_feature_vector(
    lm: list,                    # list of NormalizedLandmark from MediaPipe
    prev_wrist_y: Optional[float],
    prev_vel_y:   Optional[float],
) -> np.ndarray:
    """
    Build the 12-dimensional feature vector for one frame.
    Output order MUST match:
      - app_constants.dart buildFeatureVector()
      - config.yaml features.feature_dims = 12

    Returns float32 array of shape (12,).
    """
    def lm_xy(idx):
        return lm[idx].x, lm[idx].y

    def visibility(idx):
        return getattr(lm[idx], "visibility", 1.0) or 0.0

    ls_x, ls_y = lm_xy(MP_LEFT_SHOULDER)
    rs_x, rs_y = lm_xy(MP_RIGHT_SHOULDER)
    le_x, le_y = lm_xy(MP_LEFT_ELBOW)
    re_x, re_y = lm_xy(MP_RIGHT_ELBOW)
    lw_x, lw_y = lm_xy(MP_LEFT_WRIST)
    rw_x, rw_y = lm_xy(MP_RIGHT_WRIST)
    lh_x, lh_y = lm_xy(MP_LEFT_HIP)
    rh_x, rh_y = lm_xy(MP_RIGHT_HIP)

    left_elbow_angle  = joint_angle_deg(ls_x, ls_y, le_x, le_y, lw_x, lw_y)
    right_elbow_angle = joint_angle_deg(rs_x, rs_y, re_x, re_y, rw_x, rw_y)

    shoulder_mid = np.array([(ls_x + rs_x) / 2, (ls_y + rs_y) / 2])
    hip_mid      = np.array([(lh_x + rh_x) / 2, (lh_y + rh_y) / 2])
    spine_angle  = spine_verticality_deg(shoulder_mid, hip_mid)

    wrist_mid_y = (lw_y + rw_y) / 2.0
    shoulder_y  = shoulder_mid[1]
    hip_y       = hip_mid[1]

    vel_y = (wrist_mid_y - prev_wrist_y) if prev_wrist_y is not None else 0.0
    acc_y = (vel_y - prev_vel_y)          if prev_vel_y   is not None else 0.0

    norm_depth    = normalized_wrist_displacement(wrist_mid_y, shoulder_y, hip_y)
    shoulder_width = abs(rs_x - ls_x)

    vis_vals = [visibility(i) for i in [
        MP_LEFT_SHOULDER, MP_RIGHT_SHOULDER,
        MP_LEFT_ELBOW, MP_RIGHT_ELBOW,
        MP_LEFT_WRIST, MP_RIGHT_WRIST,
    ]]
    mean_conf = float(np.mean(vis_vals))

    left_elbow_vis  = float(visibility(MP_LEFT_ELBOW)  > 0.5)
    right_elbow_vis = float(visibility(MP_RIGHT_ELBOW) > 0.5)

    return np.array([
        left_elbow_angle,                              # 0
        right_elbow_angle,                             # 1
        (left_elbow_angle + right_elbow_angle) / 2.0, # 2
        spine_angle,                                   # 3
        wrist_mid_y,                                   # 4
        vel_y,                                         # 5
        acc_y,                                         # 6
        norm_depth,                                    # 7
        shoulder_width,                                # 8
        mean_conf,                                     # 9
        left_elbow_vis,                                # 10
        right_elbow_vis,                               # 11
    ], dtype=np.float32)


# ── Video processor ───────────────────────────────────────────────────────────

def extract_from_video(
    video_path: Path,
    pose_detector,
    min_visibility: float,
    target_fps: int,
) -> Optional[np.ndarray]:
    """
    Extract landmark features from a single video.

    Returns float32 array of shape (T, 12), or None if no valid frames found.
    """
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        log.warning(f"Cannot open video: {video_path}")
        return None

    native_fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
    # Frame skip ratio to downsample to target_fps
    skip = max(1, round(native_fps / target_fps))

    features = []
    prev_wrist_y: Optional[float] = None
    prev_vel_y:   Optional[float] = None
    frame_idx = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame_idx += 1
        if (frame_idx - 1) % skip != 0:
            continue

        # BGR → RGB for MediaPipe
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = pose_detector.process(rgb)

        if result.pose_landmarks is None:
            continue

        lm = result.pose_landmarks.landmark

        # Skip low-confidence frames
        vis_vals = [
            getattr(lm[i], "visibility", 0.0) or 0.0
            for i in [MP_LEFT_SHOULDER, MP_RIGHT_SHOULDER,
                      MP_LEFT_ELBOW,   MP_RIGHT_ELBOW,
                      MP_LEFT_WRIST,   MP_RIGHT_WRIST]
        ]
        if np.mean(vis_vals) < min_visibility:
            continue

        feat = build_feature_vector(lm, prev_wrist_y, prev_vel_y)

        wrist_mid_y  = (lm[MP_LEFT_WRIST].y + lm[MP_RIGHT_WRIST].y) / 2.0
        prev_vel_y   = (wrist_mid_y - prev_wrist_y) if prev_wrist_y is not None else 0.0
        prev_wrist_y = wrist_mid_y

        features.append(feat)

    cap.release()

    if len(features) < 10:
        log.warning(f"Too few valid frames ({len(features)}) in {video_path.name}")
        return None

    return np.stack(features, axis=0)   # (T, 12)


# ── Main ──────────────────────────────────────────────────────────────────────

def main(cfg: dict, video_dir: Optional[str] = None):
    raw_dir       = Path(video_dir or cfg["dataset"]["raw_dir"])
    landmarks_dir = Path(cfg["dataset"]["landmarks_dir"])
    min_vis       = cfg["features"]["min_visibility"]
    target_fps    = cfg["features"]["target_fps"]
    feature_dims  = cfg["features"]["feature_dims"]

    # TODO: Connect Google Drive dataset here if not already downloaded.
    # See scripts/download_dataset.sh for GDrive download automation.
    if not raw_dir.exists():
        log.error(
            f"Dataset directory not found: {raw_dir}\n"
            "  1. Connect Google Drive in Claude (connector panel above)\n"
            "  2. Run: python src/data/download_dataset.py --config config.yaml\n"
            "  3. Or mount your Sample_Dataset manually at data/raw/"
        )
        sys.exit(1)

    landmarks_dir.mkdir(parents=True, exist_ok=True)

    # Discover all video files
    video_extensions = {".mp4", ".avi", ".mov", ".mkv"}
    all_videos = sorted([
        p for p in raw_dir.rglob("*")
        if p.suffix.lower() in video_extensions
    ])

    if not all_videos:
        log.error(f"No video files found under {raw_dir}")
        sys.exit(1)

    log.info(f"Found {len(all_videos)} videos under {raw_dir}")

    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(
        static_image_mode=False,
        model_complexity=2,           # most accurate BlazePose model
        smooth_landmarks=True,
        enable_segmentation=False,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    )

    ok = 0
    skipped = 0

    for video_path in tqdm(all_videos, desc="Extracting landmarks", unit="video"):
        # Infer label from parent directory name
        # Expected: data/raw/<split>/<class_label>/<video_id>.mp4
        # Fallback: use parent dir name
        class_label = video_path.parent.name
        split_dir   = video_path.parent.parent.name

        out_dir = landmarks_dir / split_dir / class_label
        out_dir.mkdir(parents=True, exist_ok=True)

        out_path = out_dir / (video_path.stem + ".npy")
        if out_path.exists():
            ok += 1
            continue   # already processed — skip

        feats = extract_from_video(video_path, pose, min_vis, target_fps)
        if feats is None:
            skipped += 1
            continue

        assert feats.shape[1] == feature_dims, (
            f"Feature dim mismatch: got {feats.shape[1]}, expected {feature_dims}. "
            "Check build_feature_vector() and config.yaml features.feature_dims."
        )

        np.save(str(out_path), feats)
        ok += 1

    pose.close()
    log.info(f"Done. Saved: {ok}  Skipped: {skipped}  Total: {len(all_videos)}")
    log.info(f"Landmarks written to: {landmarks_dir}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract MediaPipe landmarks from CPR videos")
    parser.add_argument("--config",    default="config.yaml", help="Path to config.yaml")
    parser.add_argument("--video_dir", default=None,          help="Override raw video dir")
    args = parser.parse_args()

    with open(args.config) as f:
        cfg = yaml.safe_load(f)

    main(cfg, args.video_dir)
