#!/usr/bin/env python3
"""
Novice — CPR-AI Coach
GNU General Public License v3.0
Copyright (C) 2024 Jean Robert Gatwaza — African Leadership University

inspect_model.py
────────────────
Run this FIRST after downloading DigitalUmuganda/Kinyarwanda_YourTTS.
It prints the model's class, available methods, and sample output,
so you can confirm which generate/forward call to use in the TTS server.

Usage:
  cd ml_pipeline
  source .venv/bin/activate
  python src/tts/inspect_model.py

Expected output:
  Model class: <class '...YourTTS'>
  Methods: [generate, generate_speech, encode_text, ...]
  Config: { "model_type": "yourtts", "sampling_rate": 22050, ... }
  Audio shape: (22050,)   ← 1 second at 22050 Hz

If the output differs, update kinyarwanda_tts_server.py synthesize() accordingly.
"""

import sys
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(message)s")
log = logging.getLogger("inspect")

def main():
    try:
        from transformers import AutoModel, AutoProcessor
    except ImportError:
        print("Install: pip install -r src/tts/tts_requirements.txt")
        sys.exit(1)

    MODEL_ID = "DigitalUmuganda/Kinyarwanda_YourTTS"

    log.info(f"Loading {MODEL_ID} ...")
    model = AutoModel.from_pretrained(MODEL_ID, dtype="auto")
    model.eval()

    log.info(f"\n{'='*60}")
    log.info(f"Model class : {type(model)}")
    log.info(f"Config type : {type(model.config)}")

    # Print full config
    log.info("\n--- Model config ---")
    if hasattr(model, "config"):
        cfg = model.config.to_dict()
        for k, v in list(cfg.items())[:20]:
            log.info(f"  {k}: {v}")

    # List public methods that look like generation/synthesis entry points
    methods = [
        m for m in dir(model)
        if not m.startswith("_")
        and callable(getattr(model, m))
        and any(kw in m.lower() for kw in ["generate", "synth", "speak", "forward", "infer", "tts"])
    ]
    log.info(f"\n--- Synthesis-related methods ---")
    for m in methods:
        log.info(f"  model.{m}")

    # Try processor
    log.info("\n--- Attempting AutoProcessor ---")
    try:
        processor = AutoProcessor.from_pretrained(MODEL_ID)
        log.info(f"Processor class: {type(processor)}")
        log.info(f"Processor attrs: {[a for a in dir(processor) if not a.startswith('_')][:10]}")
    except Exception as e:
        log.info(f"No processor: {e}")
        processor = None

    # Attempt a test synthesis
    test_text = "Muraho."
    log.info(f"\n--- Test synthesis: '{test_text}' ---")

    import torch
    import numpy as np

    try:
        if processor is not None:
            inputs = processor(text=test_text, return_tensors="pt")
            log.info(f"Processor output keys: {list(inputs.keys())}")

            # Try common generation methods
            for method_name in ["generate_speech", "generate", "forward"]:
                if hasattr(model, method_name):
                    log.info(f"Trying model.{method_name}() ...")
                    try:
                        with torch.no_grad():
                            if method_name == "forward":
                                out = model(**inputs)
                            elif method_name == "generate_speech":
                                # YourTTS-specific: may need speaker embedding
                                try:
                                    spk = model.get_speaker_embeddings()
                                    out = model.generate_speech(inputs["input_ids"], spk)
                                except Exception:
                                    out = model.generate_speech(inputs["input_ids"])
                            else:
                                out = getattr(model, method_name)(**inputs)

                        log.info(f"  Output type : {type(out)}")
                        if hasattr(out, "shape"):
                            log.info(f"  Output shape: {out.shape}")
                        elif hasattr(out, "audio"):
                            log.info(f"  out.audio shape: {out.audio.shape}")
                            log.info(f"  ✓ Use: output = model.generate_speech(...)  → output.audio")
                        elif isinstance(out, (list, tuple)):
                            log.info(f"  Tuple len: {len(out)}, first shape: {out[0].shape}")
                        break
                    except Exception as e:
                        log.warning(f"  {method_name} failed: {e}")

        else:
            log.info("No processor — trying model(text) directly ...")
            with torch.no_grad():
                out = model(test_text)
            log.info(f"Output: {type(out)}")

    except Exception as e:
        log.error(f"Test synthesis failed: {e}")
        log.info("Check model documentation at: https://huggingface.co/DigitalUmuganda/Kinyarwanda_YourTTS")

    log.info("\n--- Sampling rate ---")
    for attr in ["config.sampling_rate", "config.audio_encoder.sampling_rate",
                 "generation_config.sampling_rate"]:
        try:
            val = model
            for part in attr.split("."):
                val = getattr(val, part)
            log.info(f"  {attr} = {val}")
        except Exception:
            pass

    log.info("\n✓ Inspection complete. Update synthesize() in kinyarwanda_tts_server.py accordingly.")


if __name__ == "__main__":
    main()
