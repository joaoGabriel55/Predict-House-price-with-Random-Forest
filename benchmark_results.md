# Benchmark Results: Random Forest vs LLM for House Price Prediction

**Date:** 2026-06-02 13:55
**LLM Model:** anthropic/claude-opus-4.6
**RF Estimators:** 100
**Dataset:** Las Vegas Housing (23075 valid residential sales from 25000 total rows)
**Train/Test Split:** 18460 / 4615
**Features:** Year Built, Lot Size (sqft), Lot Size (acres), Assessed Land Value, Assessed Improvement Value, ZIP Code, Sale Year, Sale Month
**Target:** Sale Price (in thousands)
**Test subset for LLM:** 20 cases

## Experiment 1 — Accuracy (on 20 test cases)

| Metric | Random Forest | LLM (anthropic/claude-opus-4.6) |
|--------|--------------|----------------|
| MAE    | 46.16K | 233.65K |
| RMSE   | 71.37K | 292.03K |

**Winner:** Random Forest (lower error is better)

## Experiment 2 — Latency

| Metric | Random Forest | LLM |
|--------|--------------|-----|
| Avg latency | 0.828 ms | 2169.4 ms |
| Speedup | — | ~2621x slower |

**Winner:** Random Forest (2621x faster)

## Experiment 3 — Consistency (10 repeated predictions per case)

| Case | RF Variance | LLM Std Dev |
|------|-------------|-------------|
| 2003, 1855, 30100 | 0 (deterministic) | — (see raw output) |
| 2009, 1916, 39550 | 0 (deterministic) | — (see raw output) |
| 2023, 2010, 54600 | 0 (deterministic) | — (see raw output) |

_(Fill in LLM std dev values from the raw output above)_

**Winner:** Random Forest (deterministic, zero variance)
