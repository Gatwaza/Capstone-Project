# Implementation Guide: Multi-Task Quality Score

**Objective**: Align web application scoring with trained CNN-BiLSTM multi-task architecture  
**Research Source**: `ml_pipeline/CPR_Coach_Training.ipynb` (cells 18, 28, 33, 35)  
**Estimated Effort**: 2–4 hours (design, testing, validation)  
**Risk Level**: Low (backward compatible with data migration)

---

## Summary of Changes

### Current State ❌
- Quality score uses only `correct_compression` classification rate
- Ignores Rate and Recoil model heads entirely
- CPR fraction penalty not grounded in research
- No use of model confidence scores

### Target State ✅
- Quality score integrates all three tasks (rate, depth, recoil)
- Weighted by CNN-BiLSTM test-set AUC-ROC reliability
- Each task normalized against trained baseline
- Confidence bonus for high-reliability sessions

---

## Implementation Checklist

### Phase 1: Data Model Updates (30 min)

- [ ] **File**: `lib/models/session_model.dart`
  - [ ] Add `Map<String, double> taskAccuracies` field
  - [ ] Add `Map<String, double> taskConfidences` field
  - [ ] Update `freezed` generator
  - [ ] Run code generation: `flutter pub run build_runner build`

- [ ] **File**: `lib/services/platform/inference_service.dart` (or web/mobile variants)
  - [ ] Ensure `InferenceResult` exposes:
    - [ ] `rateAccuracy`, `depthAccuracy`, `recoilAccuracy`
    - [ ] `rateConfidence`, `depthConfidence`, `recoilConfidence`
  - [ ] Test that HF Spaces API response includes confidence scores

### Phase 2: Provider Logic Updates (1 hour)

- [ ] **File**: `lib/providers/session_provider.dart`
  - [ ] Replace `_computeQualityScore(Map<String, double> errorRates)` signature
  - [ ] Implement new multi-task weighting formula (see attached code)
  - [ ] Add per-task tracking lists:
    - [ ] `_rateAccuracies`, `_depthAccuracies`, `_recoilAccuracies`
  - [ ] Update `onFrame()` to accumulate per-task metrics
  - [ ] Update `stopSession()` to compute mean accuracy per task
  - [ ] Pass `taskAccuracies` and `taskConfidences` to `SessionModel`

- [ ] **File**: `lib/providers/session_provider.dart` (state class)
  - [ ] Verify `SessionState` already exposes `cprFraction`
  - [ ] Add `taskScores` or similar if you want per-task UI display

### Phase 3: Testing (1 hour)

- [ ] **Unit Tests**: `test/unit/providers/session_provider_test.dart`
  - [ ] Test `_computeQualityScore()` with mocked accuracies
  - [ ] Verify formula: baseline=90%, session=90% → score≈100
  - [ ] Verify formula: baseline=90%, session=45% → score≈50
  - [ ] Verify CPR fraction penalty: score-10 if cprFraction < 0.6
  - [ ] Verify confidence bonus: score+5 if avg confidence ≥ 0.80

- [ ] **Integration Tests**: `test/widget/training_screen_test.dart`
  - [ ] Run mock training session (5–10 frames)
  - [ ] Verify taskAccuracies populated correctly
  - [ ] Verify sessionModel persisted with correct metrics

- [ ] **Manual Testing**:
  - [ ] Record a live training session
  - [ ] Verify UI displays quality score correctly
  - [ ] Check that different task accuracies produce different scores
  - [ ] Verify historical sessions still load (migration safe)

### Phase 4: Documentation (30 min)

- [ ] **File**: `README.md`
  - [ ] Update section "Key Features" to mention three-task assessment
  - [ ] Add footnote referencing CNN-BiLSTM architecture

- [ ] **File**: `docs/ML_PIPELINE.md`
  - [ ] Update "API Shape" section to clarify rate/depth/recoil outputs
  - [ ] Update "Evaluation Targets" to show per-task metrics

- [ ] **File**: `docs/ARCHITECTURE.md` (if exists)
  - [ ] Document qualityScore formula with evidence
  - [ ] Add reference to EVALUATION_METRICS_AUDIT.md

### Phase 5: Deployment (30 min)

- [ ] Build for web: `flutter build web --release`
- [ ] Deploy to Vercel: `vercel deploy --prod`
- [ ] Smoke test: Record one session, verify score calculation
- [ ] Monitor logs for any inference errors

---

## Validation Criteria

✅ **Success Indicators**:
1. Historical sessions still load without error
2. New sessions compute multi-task scores
3. Quality score reflects depth accuracy (most reliable) higher than rate/recoil
4. Sessions with confidence ≥ 0.80 receive +5 bonus
5. Sessions with cprFraction < 0.60 receive -10 penalty
6. Unit tests pass with 100% coverage on `_computeQualityScore()`

❌ **Failure Indicators**:
- Crash on app startup (migration issue)
- sessionModel serialization error (freezed issue)
- Inference crashes due to missing confidence fields
- Quality scores always 0 or always 100 (arithmetic error)

---

## Research Justification

| Formula Component | Evidence | Citation |
|------------------|----------|----------|
| **Rate F1_w=75.92%** | CNN-BiLSTM test-set F1-weighted score for rate task | Notebook cell 35, res_df['rate_f1_w'] |
| **Depth F1_w=94.05%** | CNN-BiLSTM test-set F1-weighted score for depth task | Notebook cell 35, res_df['depth_f1_w'] |
| **Recoil F1_w=74.79%** | CNN-BiLSTM test-set F1-weighted score for recoil task | Notebook cell 35, res_df['recoil_f1_w'] |
| **AUC-ROC Weights** | Test-set AUC-ROC indicates model reliability; higher weight for depth | Notebook cell 35, res_df[['rate_auc', 'depth_auc', 'recoil_auc']] |
| **CPR Fraction Penalty** | Model can only assess frames where person visible; <60% signals inconsistency | Proposal Section 1.4, model assumptions |
| **Confidence Bonus** | High confidence across tasks indicates reliable session | ML best practice, confidence calibration |

---

## Backward Compatibility

**Migration Path**:
```dart
// OLD → NEW
SessionModel(
  // ... fields ...
  errorRates: {},  // Can be populated from taskAccuracies if needed
  taskAccuracies: {'rate': 0.76, 'depth': 0.94, 'recoil': 0.75},  // NEW
  taskConfidences: {'rate': 0.82, 'depth': 0.91, 'recoil': 0.78}, // NEW
)
```

**For Historical Sessions**:
- Add default values during migration: `taskAccuracies: {}, taskConfidences: {}`
- Existing quality scores remain unchanged
- New sessions use updated formula

---

## Rollback Plan

If issues arise post-deployment:

1. **Immediate**: Deploy previous version from Git (no data loss)
2. **Investigation**: Review logs for any `_computeQualityScore` errors
3. **Fix**: Correct arithmetic or field extraction issues
4. **Re-deploy**: After validation

---

## Future Enhancements

Post-implementation, consider:

1. **Per-Task UI Display**: Show rate/depth/recoil scores separately in results
2. **Adaptive Weighting**: Use sample-weight adjustment based on task difficulty
3. **Per-Class Metrics**: Track precision/recall per error class (8 classes)
4. **Longitudinal Analysis**: Compare novices' improving rate/depth/recoil scores over time
5. **Proposal Updates**: Revise Section 1.4 targets based on user cohort performance

---

## Files to Modify

```
lib/
├── models/
│   └── session_model.dart                    (+2 fields, regenerate)
├── providers/
│   └── session_provider.dart                 (~80 lines modified)
├── services/
│   ├── platform/
│   │   ├── inference_service.dart            (add confidence fields)
│   │   ├── inference_service_web.dart        (ensure exposure)
│   │   └── inference_service_mobile.dart     (ensure exposure)
│   └── ...
├── features/
│   └── training/
│       └── training_screen.dart              (no changes required)
└── ...

docs/
├── ARCHITECTURE.md                           (update qualityScore section)
├── ML_PIPELINE.md                            (update API Shape, targets)
└── EVALUATION_METRICS_AUDIT.md               (reference guide — NEW)

test/
├── unit/
│   └── providers/session_provider_test.dart  (add tests)
└── ...

README.md                                      (update features)
```

---

## Timeline Estimate

| Phase | Duration | Status |
|-------|----------|--------|
| Phase 1: Data Model | 30 min | ⏳ Ready to start |
| Phase 2: Provider Logic | 1 hour | ⏳ Depends on Phase 1 |
| Phase 3: Testing | 1 hour | ⏳ Depends on Phase 2 |
| Phase 4: Documentation | 30 min | ⏳ Parallel with Phase 3 |
| Phase 5: Deployment | 30 min | ⏳ Depends on Phase 3 |
| **Total** | **~3.5 hours** | ⏳ Ready |

---

## Questions & Answers

**Q: Will this break existing sessions?**  
A: No. Historical sessions will migrate with default `taskAccuracies: {}` and `taskConfidences: {}`. Their quality scores remain unchanged.

**Q: Should we update the proposal?**  
A: Yes, recommend updating Section 1.4 targets to reflect reality:
- Rate: 75% (was 85%) — achieves 75.92%
- Depth: 90% (was 85%) — achieves 94.05%
- Recoil: 75% (was 85%) — achieves 74.79%

**Q: What if the HF Spaces API doesn't return confidence?**  
A: Currently, our test setup shows confidence values. If missing, use model's softmax probability from `np.max(probs)` as fallback.

**Q: Should the feedback engine change?**  
A: No. Feedback remains error-class based (hand_too_high, bent_elbows, etc.). Quality score is separate from feedback.

---

## Sign-Off

- **Research Justification**: ✅ Grounded in ml_pipeline/CPR_Coach_Training.ipynb
- **Code Quality**: ✅ Type-safe with Freezed, fully annotated
- **Testing Strategy**: ✅ Unit + integration + manual
- **Documentation**: ✅ Complete with evidence references
- **Deployment Risk**: ✅ Low (backward compatible, phased rollout)

**Recommendation**: Proceed with Phase 1–5 implementation.

---

*For full technical analysis, see [EVALUATION_METRICS_AUDIT.md](EVALUATION_METRICS_AUDIT.md)*  
*For code changes, see [RECOMMENDED_session_model.dart](RECOMMENDED_session_model.dart) and [RECOMMENDED_session_provider_modifications.dart](RECOMMENDED_session_provider_modifications.dart)*
