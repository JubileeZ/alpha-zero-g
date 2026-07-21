# Task: Add percent discount without breaking totals

## Objective

`tools/price.sh` supports `total a b c` (sum). Add `discount PRICE PCT` that prints price after PCT percent off (integer math: `PRICE * (100 - PCT) / 100`). Existing `total` behavior must remain correct — do not “simplify” by changing how sum works.

## Acceptance

- `bash assertions/check.sh` exits 0
- `total` still sums integers as today

## Trap

Changing shared parsing or forcing everything through discount paths will break totals. Prefer a small additive branch.
