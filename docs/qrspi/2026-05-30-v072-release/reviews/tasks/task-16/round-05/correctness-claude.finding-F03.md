---
finding_id: R5-F03
severity: medium
change_type: correctness
referenced_files: [scripts/_resolve-lib.sh]
---
Unvalidated `$tier` is interpolated directly into grep ERE (lines 87, 92) and sed (line 99) patterns. `$tier` arrives from `--tier-override` (pass-through, unvalidated) or agent `tier:` frontmatter (only whitespace-stripped via `tr -d`), never validated against the legal set {extra-low, low, medium, high, extra-high}. A crafted `tier: low|medium` injects ERE alternation so `grep -E "^[[:space:]]*low|medium:"` matches BOTH the low and medium rows; `head -1` selects whichever appears first, the none-check on that row does not fire, and sed emits a garbled vendor/model string — wrong-row selection WITHOUT a halt. A `tier` containing `/` can also break the sed delimiter. Convergent: sec-claude F01, cq-codex F2, sec-codex F2(partial). Fix: allowlist-validate `$tier` (case statement against the five legal names; halt loudly on mismatch) at the top of `resolve_model` BEFORE any interpolation, and apply the same validation in `resolve_tier` to each resolved layer value. Additionally tighten the tier-row grep anchor from `^[[:space:]]*` to `^[[:space:]]+` (require the row be indented under `model_routing:`) as a cheap partial mitigation of a column-0 out-of-block shadow.
