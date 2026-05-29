# Statistical Modeling Rules — {{PROJECT_NAME}}

This document details statistical modeling protocols, metric definitions, temporal splits, and validations.

## What You MUST Do
- **ALWAYS define metrics** before running a model. Define first, evaluate second.
- **ALWAYS enforce strict temporal split** on time-series/sequential data to prevent data leakage.
- **ALWAYS perform statistical significance tests** (e.g., p-value, confidence intervals) when comparing models.
- **ALWAYS establish a baseline model** (at minimum a mean/median predictor or last-value baseline) to compare against.
- **ALWAYS document assumptions** explicitly in function docstrings (e.g., stationarity, normal distribution).
- **ALWAYS include prediction/confidence intervals** for model predictions.
- **ALWAYS validate outputs** against domain knowledge / business logic before returning them.

## What You MUST NEVER Do
- **NEVER evaluate model** without predefined, objective success criteria.
- **NEVER leak future data** into training features.
- **NEVER compare models** on raw performance metrics without statistical testing.
- **NEVER deploy** a model without comparing it against a simple, robust baseline.
