#!/usr/bin/env python3
"""
ml_pipeline/extract_landmarks.py
─────────────────────────────────
Offline MediaPipe landmark extractor for CPR video files.
Run this LOCALLY (not in Colab) on raw labelled CPR video clips
to produce the landmarks.csv used by the training notebook.

Usage:
    python extract_landmarks.py --input_dir ./videos --output_csv ./landmarks.csv

Input directory structure:
    videos/
        correct_compression/  ← folder name = class label
            clip_001.mp4
            clip_002.mp4
        wrong_hand_high/
            clip_001.mp4
        ...

Output:
    landmarks.csv  with columns:
        label, x_0..x_32, y_0..y_32, z_0..z_32, vis_0..vis_32
"""

import argparse
import csv
import sys
from pathlib import Path

try:
    import cv2
    import mediapipe as mp
    import numpy as np
except ImportError:
    print("Install dependencies first:\n  pip install mediapipe opencv-python numpy")
    sys.exit(1)

CLASS_LABELS = [
    'correct_compression', 'wrong_hand_high', 'wrong_hand_low',
    'bent_elbows', 'too_shallow', 'rate_too_slow', 'rate_too_fast', 'not_compressing',
]

def extract(input_dir: Path, output_csv: Path, max_frames_per_video: int = 500):
    mp_pose   = mp.solutions.pose
    pose      = mp_pose.Pose(
        static_image_mode=False,
        model_complexity=1,
        min_detection_confidence=0.50,
        min_tracking_confidence=0.50,
    )

    fieldnames = ['label']
    for i in range(33):
        fieldnames += [f'x_{i}', f'y_{i}', f'z_{i}', f'vis_{i}']

    output_csv.parent.mkdir(parents=True, exist_ok=True)
    total_rows = 0

    with open(output_csv, 'w', newline='') as fout:
        writer = csv.DictWriter(fout, fieldnames=fieldnames)
        writer.writeheader()

        for label in CLASS_LABELS:
            label_dir = input_dir / label
            if not label_dir.exists():
                print(f"  [skip] {label} — folder not found")
                continue

            videos = list(label_dir.glob('*.mp4')) + list(label_dir.glob('*.avi'))
            print(f"  {label}: {len(videos)} videos")

            for video_path in videos:
                cap  = cv2.VideoCapture(str(video_path))
                n    = 0
                skip = max(1, int(cap.get(cv2.CAP_PROP_FRAME_COUNT)) // max_frames_per_video)

                frame_idx = 0
                while True:
                    ret, frame = cap.read()
                    if not ret:
                        break
                    frame_idx += 1
                    if frame_idx % skip != 0:
                        continue

                    rgb     = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    results = pose.process(rgb)

                    if not results.pose_landmarks:
                        continue

                    row = {'label': label}
                    for idx, lm in enumerate(results.pose_landmarks.landmark):
                        row[f'x_{idx}']   = round(lm.x,          5)
                        row[f'y_{idx}']   = round(lm.y,          5)
                        row[f'z_{idx}']   = round(lm.z,          5)
                        row[f'vis_{idx}'] = round(lm.visibility, 5)

                    writer.writerow(row)
                    n += 1

                cap.release()
                print(f"    {video_path.name}: {n} frames extracted")
                total_rows += n

    pose.close()
    print(f"\n✓ Done — {total_rows} landmark frames → {output_csv}")


def main():
    parser = argparse.ArgumentParser(description='CPR landmark extractor')
    parser.add_argument('--input_dir',  required=True, help='Root video directory')
    parser.add_argument('--output_csv', default='landmarks.csv', help='Output CSV path')
    parser.add_argument('--max_frames', type=int, default=500,
                        help='Max frames sampled per video (default 500)')
    args = parser.parse_args()

    extract(
        input_dir=Path(args.input_dir),
        output_csv=Path(args.output_csv),
        max_frames_per_video=args.max_frames,
    )


if __name__ == '__main__':
    main()
