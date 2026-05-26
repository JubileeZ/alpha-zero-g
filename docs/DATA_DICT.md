# Data Dictionary Template — Alpha-Zero-G

This document serves as the single source of truth for column definitions, mathematical bounds, and raw data types across files and database tables.

---

## 1. Core Data Mappings (Example Reference)

| Column Name | Raw Data Type | Unit / Range | Nullable? | Validation Rules & Quirks | Description |
|---|---|---|---|---|---|
| `gameweek` | `Integer` | `[1, 38]` | No | Must be positive | The specific Premier League matchweek sequence. |
| `player_id` | `String` | Unique UUID | No | Must match the main master registry | Unique identifier representing a professional player. |
| `projected_points` | `Float` | `[0.0, 30.0]` | Yes | Values >20.0 must trigger outliers log | Expected points output by the statistical model. |
| `timestamp` | `Datetime` | UTC ISO-8601 | No | Parse using explicit timezone offsets | Exact date and time the data record was ingested. |
| `buy_signal` | `Boolean` | `[True, False]`| No | Cannot be true if sell_signal is also true | Automated trading buy trigger indicator. |

---

## 2. Validation Constraints Registry

Use these standards when creating new schemas or asserting constraints inside `/src` data validators:

- **Numerical Boundaries:** Always register columns with explicit min/max values inside this document before implementing them in validation functions.
- **Categorical Sets:** Document the allowed list of categories (e.g. `['GK', 'DEF', 'MID', 'FWD']`) to allow quick schema checks.
- **Data Freshness:** Define update frequencies (e.g. hourly, daily) and ingest protocols for downstream processors.
