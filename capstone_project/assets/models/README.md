# Model Assets

## cpr_classifier.tflite
**Status:** Not included (must be generated via ML pipeline)

**To generate:**
1. Open `ml_pipeline/CPR_Coach_Training.ipynb` in Google Colab
2. Run all cells (uses dummy data if CPR-Coach sample not available)
3. Download `cpr_classifier.tflite` from `My Drive/capstone_data/exports/`
4. Place it here: `assets/models/cpr_classifier.tflite`

**Without the model:** The app runs in rule-based mode.
All CPR feedback (BPM, elbow detection, posture) still works via
direct landmark geometry — just without ML error classification.
The banner will display: "Rule-based mode — train model to enable AI feedback"

## cpr_classifier_metadata.json
Auto-generated alongside the .tflite file. Documents:
- Input shape: [1, 30, 12]
- Output shape: [1, 8]
- Class labels and normalisation parameters
