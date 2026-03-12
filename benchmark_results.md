# Benchmark Results: Random Forest vs LLM for House Price Prediction

**Date:** 2026-03-12 11:24
**LLM Model:** anthropic/claude-opus-4.6
**RF Estimators:** 100
**Dataset:** 50050 rows (Train: 40040 / Test: 10010)
**Test subset for LLM:** 20 cases

## Experiment 1 — Accuracy (on 20 test cases)

| Metric | Random Forest | LLM (anthropic/claude-opus-4.6) |
|--------|--------------|----------------|
| MAE    | 8.21K | 155.4K |
| RMSE   | 10.8K | 213.5K |

## Experiment 2 — Latency

| Metric | Random Forest | LLM |
|--------|--------------|-----|
| Avg latency | 0.45 ms | 4040.5 ms |
| Speedup | — | ~8985x slower |

## Experiment 3 — Consistency (10 repeated predictions per case)

| Case | RF Variance | LLM Std Dev |
|------|-------------|-------------|
| 342, 6, 6, 22 | 0 (deterministic) | — (see raw output) |
| 280, 5, 5, 12 | 0 (deterministic) | — (see raw output) |
| 267, 5, 2, 32 | 0 (deterministic) | — (see raw output) |

_(Fill in LLM std dev values from the raw output above)_

## Experiment 4 — Hybrid Pipeline (NL → LLM → RF)

| Input | Expected | Extracted | Match | RF Price (extracted) | RF Price (correct) |
|-------|----------|-----------|-------|---------------------|--------------------|
| A spacious 250 square meter house with 5 ... | [250, 5, 3, 10] | [250, 5, 3, 10] | ✅ | 669.0K | 669.0K |
| Small apartment, 60m², 2 rooms, 1 bathroo... | [60, 2, 1, 2] | [60, 2, 1, 2] | ✅ | 175.6K | 175.6K |
| Old colonial mansion with 400 square mete... | [400, 8, 4, 50] | [400, 8, 4, 50] | ✅ | 800.8K | 800.8K |
| Modern 120m² flat, 3 bedrooms, 2 bathroom... | [120, 3, 2, 5] | [120, 3, 2, 5] | ✅ | 324.2K | 324.2K |
| Cozy 80 sqm home, two bedrooms, one bathr... | [80, 2, 1, 15] | [80, 2, 1, 15] | ✅ | 175.7K | 175.7K |

**Extraction accuracy:** 100.0%
