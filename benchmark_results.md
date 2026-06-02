# Benchmark Results: Random Forest vs LLM for House Price Prediction

**Date:** 2026-06-02 10:16
**LLM Model:** anthropic/claude-opus-4.6
**RF Estimators:** 100
**Dataset:** Las Vegas Housing (1730 valid rows from 4583 total)
**Train/Test Split:** 1384 / 346
**Features:** Bedrooms, Full Bathrooms, Half Bathrooms, Square Footage, Lot Size
**Test subset for LLM:** 20 cases

## Experiment 1 — Accuracy (on 20 test cases)

| Metric | Random Forest | LLM (anthropic/claude-opus-4.6) |
|--------|--------------|----------------|
| MAE    | 125.85K | 248.01K |
| RMSE   | 255.79K | 425.44K |

## Experiment 2 — Latency

| Metric | Random Forest | LLM |
|--------|--------------|-----|
| Avg latency | 0.468 ms | 2094.5 ms |
| Speedup | — | ~4476x slower |

## Experiment 3 — Consistency (10 repeated predictions per case)

| Case | RF Variance | LLM Std Dev |
|------|-------------|-------------|
| 2, 2, 1, 1091, 871 | 0 (deterministic) | — (see raw output) |
| 4, 3, 1, 2660, 9103 | 0 (deterministic) | — (see raw output) |
| 4, 3, 1, 2948, 15681 | 0 (deterministic) | — (see raw output) |

_(Fill in LLM std dev values from the raw output above)_

## Experiment 4 — Hybrid Pipeline (NL → LLM → RF)

| Input | Expected | Extracted | Match | RF Price (extracted) | RF Price (correct) |
|-------|----------|-----------|-------|---------------------|--------------------|
| Spacious single family home with 4 bedroo... | [4, 3, 1, 2500, 7000] | [4, 3, 1, 2500, 7000] | ✅ | 349.4K | 349.4K |
| Cozy 3 bed 2 bath house, 1800 sqft, sits ... | [3, 2, 0, 1800, 5500] | [3, 2, 0, 1800, 5500] | ✅ | 196.1K | 196.1K |
| Luxury property, 5 bedrooms, 4.5 baths (4... | [5, 4, 1, 4200, 10000] | [5, 4, 1, 4200, 10000] | ✅ | 512.9K | 512.9K |
| Small starter home, 2 bedrooms, 2 bathroo... | [2, 2, 0, 1200, 3000] | [2, 2, 0, 1200, 3000] | ✅ | 134.4K | 134.4K |
| Modern home with three bedrooms, two and ... | [3, 2, 1, 2000, 6500] | [3, 2, 1, 2000, 6500] | ✅ | 210.1K | 210.1K |

**Extraction accuracy:** 100.0%
