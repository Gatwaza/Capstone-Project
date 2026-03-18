#!/usr/bin/env python3
"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

kinyarwanda_tts_server.py
─────────────────────────
Local HTTP server that wraps DigitalUmuganda/Kinyarwanda_YourTTS and serves
synthesized Kinyarwanda audio to the Flutter app via a single POST endpoint.

The Flutter TtsService already calls this endpoint:
  POST http://localhost:5000/tts
  Body: {"text": "Shyira intoki zo hagati y'isaya.", "lang": "rw"}
  Response: audio/wav bytes

Model: DigitalUmuganda/Kinyarwanda_YourTTS
  • YourTTS architecture fine-tuned on Kinyarwanda speech
  • Hosted on Hugging Face Hub
  • Loaded once at server startup, cached in memory

Usage:
  cd ml_pipeline
  source .venv/bin/activate
  python src/tts/kinyarwanda_tts_server.py           # default port 5000
  python src/tts/kinyarwanda_tts_server.py --port 5001

  Then in .env:
    UMUGANDA_TTS_URL=http://localhost:5000

  Flutter runs with:
    flutter run --dart-define=UMUGANDA_TTS_URL=http://localhost:5000

Dependencies (in tts_requirements.txt):
  transformers, torch, flask, soundfile, numpy
"""

import argparse
import io
import logging
import os
import sys
import time

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("tts_server")


def load_model():
    """
    Load DigitalUmuganda/Kinyarwanda_YourTTS from Hugging Face Hub.

    First call downloads ~500 MB to ~/.cache/huggingface/hub/ and caches it.
    Subsequent calls load from cache — no internet needed.

    Returns (model, processor) or raises on failure.
    """
    log.info("Loading DigitalUmuganda/Kinyarwanda_YourTTS ...")
    log.info("First run downloads ~500 MB to HuggingFace cache. May take a few minutes.")

    try:
        from transformers import AutoModel, AutoProcessor
    except ImportError:
        log.error(
            "transformers not installed. Run:\n"
            "  pip install -r src/tts/tts_requirements.txt"
        )
        sys.exit(1)

    t0 = time.time()
    model = AutoModel.from_pretrained(
        "DigitalUmuganda/Kinyarwanda_YourTTS",
        dtype="auto",           # uses float16 on GPU, float32 on CPU
    )
    model.eval()

    # Move to GPU if available (M1 Mac: MPS backend)
    try:
        import torch
        if torch.backends.mps.is_available():
            model = model.to("mps")
            log.info("Model loaded on Apple MPS (M1 GPU)")
        elif torch.cuda.is_available():
            model = model.to("cuda")
            log.info("Model loaded on CUDA GPU")
        else:
            log.info("Model loaded on CPU")
    except Exception as e:
        log.warning(f"Could not move model to GPU: {e} — using CPU")

    # Load processor / tokenizer
    try:
        processor = AutoProcessor.from_pretrained(
            "DigitalUmuganda/Kinyarwanda_YourTTS"
        )
    except Exception:
        # Some YourTTS checkpoints don't have a separate processor
        processor = None
        log.info("No AutoProcessor found — will use model.generate() directly")

    elapsed = time.time() - t0
    log.info(f"Model ready in {elapsed:.1f}s")
    return model, processor


def synthesize(text: str, model, processor) -> bytes:
    """
    Synthesize Kinyarwanda speech for the given text.

    Returns WAV bytes ready to send as HTTP response body.
    The calling Flutter TtsService plays these bytes via audioplayers.

    TODO: Validate voice quality against pilot study participants' feedback.
    TODO: Adjust speaking_rate if prompts feel too fast during CPR coaching.
    """
    import numpy as np
    import soundfile as sf

    if not text or not text.strip():
        raise ValueError("Empty text input")

    try:
        import torch

        if processor is not None:
            # Processor-based pipeline (most HF TTS models)
            inputs = processor(text=text, return_tensors="pt")
            # Move inputs to same device as model
            device = next(model.parameters()).device
            inputs = {k: v.to(device) for k, v in inputs.items()}

            with torch.no_grad():
                output = model.generate_speech(
                    inputs["input_ids"],
                    model.get_speaker_embeddings(),  # default speaker
                )
            # output is typically (samples,) float32 tensor
            audio_np = output.squeeze().cpu().numpy().astype(np.float32)

        else:
            # Direct generation without processor
            # TODO: Confirm the exact API for DigitalUmuganda/Kinyarwanda_YourTTS
            # Run: python src/tts/inspect_model.py to print available methods
            with torch.no_grad():
                output = model(text)
            audio_np = output.squeeze().cpu().numpy().astype(np.float32)

    except AttributeError as e:
        log.error(
            f"Model API mismatch: {e}\n"
            "Run python src/tts/inspect_model.py to see available methods."
        )
        raise

    # Normalise to prevent clipping
    peak = np.abs(audio_np).max()
    if peak > 0:
        audio_np = audio_np / peak * 0.95

    # Encode to WAV in memory
    sample_rate = 22050  # YourTTS default — adjust if model differs
    buf = io.BytesIO()
    sf.write(buf, audio_np, sample_rate, format="WAV", subtype="PCM_16")
    buf.seek(0)
    return buf.read()


def create_app(model, processor):
    """Create and return the Flask app with TTS endpoint."""
    try:
        from flask import Flask, request, jsonify, Response
    except ImportError:
        log.error("flask not installed. Run: pip install -r src/tts/tts_requirements.txt")
        sys.exit(1)

    app = Flask("novice_tts")

    # Pre-warm model with a short phrase so first real request is fast
    try:
        log.info("Warming up model ...")
        synthesize("Muraho.", model, processor)
        log.info("Warm-up complete")
    except Exception as e:
        log.warning(f"Warm-up failed (non-fatal): {e}")

    @app.route("/health", methods=["GET"])
    def health():
        """Health check — Flutter app can ping this on startup."""
        return jsonify({"status": "ok", "model": "DigitalUmuganda/Kinyarwanda_YourTTS"})

    @app.route("/tts", methods=["POST"])
    def tts():
        """
        Synthesize speech and return WAV bytes.

        Expected body: {"text": "...", "lang": "rw"}
        Returns: audio/wav

        Called by Flutter TtsService._umugandaHttp() in lib/services/tts_service.dart.
        """
        data = request.get_json(silent=True) or {}
        text = data.get("text", "").strip()
        lang = data.get("lang", "rw")

        if not text:
            return jsonify({"error": "text field required"}), 400

        if lang != "rw":
            # This server is Kinyarwanda-only; Flutter handles English natively
            return jsonify({"error": "lang must be rw"}), 400

        try:
            t0 = time.time()
            wav_bytes = synthesize(text, model, processor)
            elapsed_ms = (time.time() - t0) * 1000
            log.info(f'TTS: "{text[:50]}" → {len(wav_bytes)} bytes in {elapsed_ms:.0f}ms')
            return Response(
                wav_bytes,
                status=200,
                mimetype="audio/wav",
                headers={"X-Synthesis-Ms": str(int(elapsed_ms))},
            )
        except Exception as e:
            log.error(f"Synthesis failed: {e}")
            return jsonify({"error": str(e)}), 500

    @app.route("/prompts", methods=["GET"])
    def list_prompts():
        """
        Returns all Kinyarwanda coaching prompts from app_constants.
        Convenience endpoint for pre-generating all prompt audio files.
        """
        prompts = {
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
        return jsonify(prompts)

    return app


def main():
    parser = argparse.ArgumentParser(
        description="Novice Kinyarwanda TTS server (DigitalUmuganda/Kinyarwanda_YourTTS)"
    )
    parser.add_argument("--port", type=int, default=5000, help="Port to listen on (default 5000)")
    parser.add_argument("--host", type=str, default="127.0.0.1",
                        help="Host to bind to (default 127.0.0.1 — localhost only)")
    parser.add_argument("--no-warmup", action="store_true",
                        help="Skip model warm-up (faster startup, slower first request)")
    args = parser.parse_args()

    log.info("=" * 60)
    log.info("  Novice — Kinyarwanda TTS Server")
    log.info("  Model: DigitalUmuganda/Kinyarwanda_YourTTS")
    log.info(f"  Endpoint: http://{args.host}:{args.port}/tts")
    log.info("=" * 60)

    model, processor = load_model()
    app = create_app(model, processor)

    log.info(f"Listening on http://{args.host}:{args.port}")
    log.info("Flutter app: set UMUGANDA_TTS_URL=http://localhost:5000 in .env")
    log.info("Press Ctrl+C to stop")

    app.run(host=args.host, port=args.port, debug=False, threaded=True)


if __name__ == "__main__":
    main()
