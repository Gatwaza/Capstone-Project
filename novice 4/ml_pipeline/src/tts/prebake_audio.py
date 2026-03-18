#!/usr/bin/env python3
"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

prebake_audio.py
────────────────
Pre-generates WAV files for all 13 Kinyarwanda coaching prompts using
DigitalUmuganda/Kinyarwanda_YourTTS and saves them to:
  ../assets/audio/rw/<key>.wav

These files are loaded by Flutter as bundled assets, so voice coaching
works 100% offline on mobile with zero HTTP calls.

This is the recommended approach for Phase 1 pilot study:
  • No network dependency during sessions
  • Consistent latency (file read vs HTTP synthesis)
  • Audio can be reviewed for quality before deployment

Usage:
  cd ml_pipeline
  source .venv/bin/activate
  python src/tts/prebake_audio.py

  # Then add to Flutter pubspec.yaml assets section (already listed):
  #   - assets/audio/rw/

  # And update lib/services/tts_service.dart to use flutter_tts.playFile()
  # or audioplayers to play the bundled .wav (see TODO in tts_service.dart)
"""

import argparse
import logging
import sys
import time
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("prebake")

# All 13 Kinyarwanda coaching prompts
# Keys match AppConstants.promptsRw in lib/core/constants/app_constants.dart
PROMPTS_RW = {
    "start":             "Shyira intoki zo hagati y'isaya.",
    "good":              "Imirimo myiza — komeza.",
    "bent_elbows":       "Gorora amaboko. Shira ingufu.",
    "hand_too_high":     "Manura intoki. Hagati y'isaya.",
    "hand_too_low":      "Fungura intoki hejuru gato.",
    "too_shallow":       "Kanda cyane. Gera kuri santimetero eshanu.",
    "too_deep":          "Fata neza. Kuri santimetero eshanu kugeza cyenda.",
    "rate_too_slow":     "Yihutirire. Komeza intera.",
    "rate_too_fast":     "Yigende buhoro gato.",
    "body_lean":         "Sonera imbere. Shira umubiri wawe hejuru.",
    "incomplete_decomp": "Rekura intoki neza hagati.",
    "not_compressing":   "Shyira intoki ku isaya hanyuma ufate kanda.",
    "pause_detected":    "Komeza. Ntugahagarike.",
}


def load_model():
    try:
        from transformers import AutoModel
    except ImportError:
        log.error("Run: pip install -r src/tts/tts_requirements.txt")
        sys.exit(1)

    log.info("Loading DigitalUmuganda/Kinyarwanda_YourTTS ...")
    model = AutoModel.from_pretrained("DigitalUmuganda/Kinyarwanda_YourTTS", dtype="auto")
    model.eval()

    try:
        import torch
        if torch.backends.mps.is_available():
            model = model.to("mps")
            log.info("Model on Apple MPS")
        elif torch.cuda.is_available():
            model = model.to("cuda")
            log.info("Model on CUDA")
        else:
            log.info("Model on CPU")
    except Exception:
        pass

    try:
        from transformers import AutoProcessor
        processor = AutoProcessor.from_pretrained("DigitalUmuganda/Kinyarwanda_YourTTS")
    except Exception:
        processor = None

    return model, processor


def synthesize_to_wav(text: str, model, processor, out_path: Path) -> bool:
    """Synthesize text and write WAV file. Returns True on success."""
    import io
    import numpy as np
    import soundfile as sf
    import torch

    try:
        if processor is not None:
            inputs = processor(text=text, return_tensors="pt")
            device = next(model.parameters()).device
            inputs = {k: v.to(device) for k, v in inputs.items()}

            with torch.no_grad():
                try:
                    spk = model.get_speaker_embeddings()
                    audio = model.generate_speech(inputs["input_ids"], spk)
                except AttributeError:
                    audio = model.generate(**inputs)
        else:
            with torch.no_grad():
                audio = model(text)

        audio_np = audio.squeeze().cpu().numpy().astype(np.float32)

        # Normalise
        peak = np.abs(audio_np).max()
        if peak > 0:
            audio_np = audio_np / peak * 0.90

        # TODO: confirm correct sample rate from inspect_model.py output
        sample_rate = 22050
        sf.write(str(out_path), audio_np, sample_rate, format="WAV", subtype="PCM_16")
        return True

    except Exception as e:
        log.error(f"  Synthesis failed: {e}")
        log.info("  Run inspect_model.py and update synthesize() call above")
        return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output",
        default="../assets/audio/rw",
        help="Output directory (default: ../assets/audio/rw)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing .wav files",
    )
    args = parser.parse_args()

    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)

    log.info(f"Output directory: {out_dir.resolve()}")

    model, processor = load_model()

    ok = 0
    failed = 0

    for key, text in PROMPTS_RW.items():
        wav_path = out_dir / f"{key}.wav"

        if wav_path.exists() and not args.force:
            log.info(f"  SKIP {key}.wav (already exists — use --force to regenerate)")
            ok += 1
            continue

        log.info(f"  Synthesizing: [{key}] {text}")
        t0 = time.time()
        success = synthesize_to_wav(text, model, processor, wav_path)
        elapsed = time.time() - t0

        if success:
            size_kb = wav_path.stat().st_size / 1024
            log.info(f"  ✓ {wav_path.name}  ({size_kb:.1f} KB, {elapsed:.1f}s)")
            ok += 1
        else:
            failed += 1

    log.info("")
    log.info(f"Done: {ok} generated, {failed} failed")

    if ok > 0:
        log.info("")
        log.info("Next step — wire Flutter to play these files.")
        log.info("In lib/services/tts_service.dart, replace the flutter_tts call with:")
        log.info("  audioplayers.AudioPlayer().play(AssetSource('audio/rw/{key}.wav'))")
        log.info("Add audioplayers to pubspec.yaml: audioplayers: ^5.2.1")

    if failed > 0:
        log.warning("")
        log.warning(f"{failed} prompt(s) failed synthesis.")
        log.warning("Run inspect_model.py to debug the model API, then fix synthesize().")


if __name__ == "__main__":
    main()
