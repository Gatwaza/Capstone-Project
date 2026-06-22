#!/usr/bin/env python3
"""
migrate_schema_version.py

Tags existing research-session CSV rows with a `schema_version` column so
old (pre-3-head-refactor) sessions are never silently treated as equivalent
to new (3-head model) sessions in analysis.

Background
----------
Before the 3-head refactor, error_rates used an 8-class scheme
(bent_elbows, hand_too_high, hand_too_low, body_lean, ...) and the
precision/recall/F1/AUC columns were never populated (always 0).

After the refactor, error_rates uses the 5-label 3-head scheme
(rate_too_fast, rate_too_slow, too_deep, too_shallow, incomplete_decomp,
correct_compression) and rate/depth/recoil precision, recall, f1, and auc
are populated with real values.

Heuristic
---------
A row is tagged schema_version=1 (pre-3-head-refactor) if ALL of its
precision/recall/f1/auc columns are exactly 0 AND model_was_available is
true (i.e. it produced frame data but never went through the 3-head
metrics path). Rows with model_was_available=false (no inference ran at
all that session — empty error_rates) are tagged schema_version=0, since
they carry no classifier output of either generation and shouldn't be
analyzed as either.

A row is tagged schema_version=2 (current) if any precision/recall/f1/auc
column is non-zero, since only the 3-head pipeline ever populates those.

Usage
-----
    python3 migrate_schema_version.py sessions.csv sessions_tagged.csv
"""
import csv
import sys

METRIC_COLUMNS = [
    "rate_precision", "depth_precision", "recoil_precision",
    "rate_recall", "depth_recall", "recoil_recall",
    "rate_f1", "depth_f1", "recoil_f1",
    "rate_auc", "depth_auc", "recoil_auc",
]


def classify_row(row: dict) -> int:
    model_available = str(row.get("model_was_available", "")).strip().lower() == "true"
    if not model_available:
        # No inference ran this session at all (e.g. session ended before
        # any compression was detected). Neither schema applies.
        return 0

    has_any_metric = False
    for col in METRIC_COLUMNS:
        raw = row.get(col, "0")
        try:
            value = float(raw)
        except (TypeError, ValueError):
            value = 0.0
        if value != 0.0:
            has_any_metric = True
            break

    return 2 if has_any_metric else 1


SCHEMA_LABELS = {
    0: "no-inference",
    1: "pre-3-head-refactor",
    2: "3-head-current",
}


def migrate(in_path: str, out_path: str) -> None:
    with open(in_path, newline="", encoding="utf-8") as f_in:
        reader = csv.DictReader(f_in)
        fieldnames = list(reader.fieldnames or [])
        if "schema_version" not in fieldnames:
            fieldnames = fieldnames + ["schema_version", "schema_label"]
        else:
            fieldnames = fieldnames + ["schema_label"]

        rows = list(reader)

    counts = {0: 0, 1: 0, 2: 0}
    for row in rows:
        version = classify_row(row)
        row["schema_version"] = version
        row["schema_label"] = SCHEMA_LABELS[version]
        counts[version] += 1

    with open(out_path, "w", newline="", encoding="utf-8") as f_out:
        writer = csv.DictWriter(f_out, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    total = sum(counts.values())
    print(f"Tagged {total} rows:")
    for version, label in SCHEMA_LABELS.items():
        print(f"  schema_version={version} ({label}): {counts[version]}")
    print(f"\nWrote: {out_path}")
    print(
        "\nNote: rows tagged schema_version=1 (pre-3-head-refactor) used the "
        "old 8-class error_rates scheme and have no rate/depth/recoil "
        "precision/recall/F1/AUC. Exclude them from any analysis that "
        "compares against the notebook's 3-head F1/AUC targets — they are "
        "not measuring the same model."
    )


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: python3 {sys.argv[0]} <input.csv> <output.csv>")
        sys.exit(1)
    migrate(sys.argv[1], sys.argv[2])
