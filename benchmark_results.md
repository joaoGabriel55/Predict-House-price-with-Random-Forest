# Benchmark Results: Random Forest vs LLM for House Price Prediction

**Date:** 2026-06-09 10:29
**LLM Model:** anthropic/claude-opus-4.6
**RF Estimators:** 100
**Dataset:** Las Vegas Housing (23075 valid residential sales from 25000 total rows)
**Train/Test Split:** 16152 / 6923
**Features:** Year Built, Lot Size (sqft), Lot Size (acres), Assessed Land Value, Assessed Improvement Value, ZIP Code, Sale Year, Sale Month
**Target:** Sale Price (in thousands)
**Test subset for LLM:** 120 cases

## Experiment 1 — Accuracy (on 120 test cases)

| Metric | Random Forest | LLM (anthropic/claude-opus-4.6) |
|--------|--------------|----------------|
| MAE    | 34.88K | 220.66K |
| RMSE   | 55.02K | 252.46K |

**Winner:** Random Forest (lower error is better)

## Experiment 2 — Latency

| Metric | Random Forest | LLM |
|--------|--------------|-----|
| Avg latency | 0.529 ms | 2419.7 ms |
| Speedup | — | ~4576x slower |

**Winner:** Random Forest (4576x faster)

## Experiment 3 — Consistency (120 repeated predictions per case)

| Case | RF Variance | LLM Std Dev |
|------|-------------|-------------|
| 1999, 2419, 29750 | 0 (deterministic) | 5.36K |
| 1996, 1286, 28350 | 0 (deterministic) | 32.83K |
| 2020, 1336, 26250 | 0 (deterministic) | 1.88K |

**Winner:** Random Forest (deterministic, zero variance)
