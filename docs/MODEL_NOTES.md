# Model Notes & Assumptions Registry — Alpha-Zero-G

Use this file to record the mathematical assumptions, experiments, training splits, and validation outcomes of statistical models developed in this workspace.

---

## 1. Active Model Assumptions

Document active model assumptions here before compiling training pipelines:

- **Assumption ID: MASS-001 — Residual Normality**
  - *Model:* Ridge Regression / FPL score model
  - *Assumption:* Residuals are normally distributed with zero mean and constant variance (homoscedasticity).
  - *Verification:* Check Q-Q plots during post-training output checks (validate-output skill).
  
- **Assumption ID: MASS-002 — Stationarity of Log-Returns**
  - *Model:* GARCH / Crypto volatility signal model
  - *Assumption:* Log-returns of price series are stationary.
  - *Verification:* Run Augmented Dickey-Fuller (ADF) checks on input transformations.

---

## 2. Experiments Log

| Date | Run ID | Model Type | Parameters | Main Metric (Val/Test) | Status |
|---|---|---|---|---|---|
| 2026-05-26 | `RUN-001` | XGBoost Regressor | `depth=6, lr=0.05, estimators=200` | MAE: `3.12` / `3.45` | Baseline established |
| 2026-05-26 | `RUN-002` | Linear Model | Ridge Regression (`alpha=1.0`) | MAE: `3.56` / `3.62` | Simplified alternative |

---

## 3. Validation Reports

### Run ID: `RUN-001` (Example)
- **Null / Inf Check:** Passed (0 missing records found).
- **Physical Boundary Assertions:** Passed (all predictions strictly positive).
- **Outlier Check:** Verified (top 1% predictions do not exceed maximum score cap of 28.0).
- **Baseline Comparison:** Outperformed naive historical-average baseline by `12.5%` on test splits.
