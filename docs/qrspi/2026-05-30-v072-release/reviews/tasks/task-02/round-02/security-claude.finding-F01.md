---
finding_id: R2-F01
reviewer_tag: security-claude
round: 2
task: 02
severity: medium
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
  - tests/unit/test-verifier-fan-in-script.bats
---

## F01 — Integer overflow bypasses score threshold filter

`scripts/verifier-fan-in.sh` lines 240, 244.

The R1 octal-trap fix changed the score regex to `^[0-9]+$` — accepting digit strings of **arbitrary length**. Bash arithmetic uses 64-bit signed integers and **silently wraps modulo 2^64** on overflow. An attacker controlling a verifier sidecar can craft an oversized score that wraps into the kept-window.

### Attack scenario

Attacker wants a `style` finding with intended score 40 (below floor 80) to be kept as if scored 90:

```yaml
score: 18446744073709551706
```

`18446744073709551706 = 2^64 + 90`. Bash:
- `$((10#18446744073709551706))` wraps to `90`.
- `(( 90 > 100 ))` → false → no halt.
- `(( 90 >= 80 ))` → true → **KEPT**.

Downstream `kept-findings.txt` carries the finding and `apply-fix` acts on it.

### Bypass values per window

| Window | Crafted score | Wrapped |
|---|---|---|
| style/clarity [80,100] | `2^64 + 90` | 90 |
| correctness [70,100]   | `2^64 + 75` | 75 |

### Recommended fix

Cap digit-string length at 3 — the max valid score (100) has exactly three digits:

```bash
if [[ -z "${raw_score:-}" ]] || ! [[ "$raw_score" =~ ^[0-9]{1,3}$ ]]; then
```

This eliminates all overflow with no behavior change for valid scores.

### Test

```bash
@test "score with > 3 digits is rejected as score_unparseable" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" "18446744073709551706"   # wraps to 90 without the fix

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  run jq -r '.halts[0].cause' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "score_unparseable" ]]
}
```

All other R1 dispatch vectors verified clean (newline injection, leading-zero crash, YAML injection via jq --arg, path traversal via glob).
