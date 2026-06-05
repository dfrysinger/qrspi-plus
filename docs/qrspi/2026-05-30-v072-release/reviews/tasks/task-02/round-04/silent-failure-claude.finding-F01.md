---
finding_id: R4-F01
reviewer_tag: silent-failure-claude
round: 4
task: 2
severity: low
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
---

# F01 — `extract_frontmatter_field || true` still swallows awk runtime failures (partial close)

## Location

`scripts/verifier-fan-in.sh` lines 217 and 257

```bash
ct=$(extract_frontmatter_field "$finding" change_type || true)   # L217
raw_score=$(extract_frontmatter_field "$sidecar" score || true)  # L257
```

## Verification of R3 fixes against the four reviewer questions

| Question | Result |
|---|---|
| Test 21 (overflow stderr-assertion) fails if `echo "verifier-fan-in: halt: $FIRST_HALT_CAUSE" >&2` removed? | ✅ Yes — genuine test |
| Test 25 (awk-absent) fails if `command -v awk` guard removed? | ✅ Yes — genuine test (zero findings + empty loop → guard is the only mechanism that can produce non-zero exit) |
| `|| true` swallowing genuinely closed? | ⚠️ Partial — see below |
| New vacuous-test patterns introduced? | ✅ None detected |

## Residual gap

The defense chain now covers the two operationally common awk failure modes:

| Failure mode | Mitigation | Coverage |
|---|---|---|
| awk not in PATH | Startup `command -v awk` guard → exit 2 | ✅ Closed |
| File permission-denied (finding) | `[[ ! -r "$finding" ]]` pre-check → `finding_unreadable` halt | ✅ Closed |
| File permission-denied (sidecar) | `[[ ! -r "$sidecar" ]]` pre-check → `sidecar_unreadable` halt | ✅ Closed |
| awk crashes mid-execution (OOM, internal error) | **`\|\| true` swallows** → `ct`/`raw_score` empty → misattributed to `missing_change_type`/`score_unparseable` | ⚠️ Open |
| TOCTOU: file readable at `[[ -r ]]`, unreadable at awk's `open(2)` | **`\|\| true` swallows** | ⚠️ Open |
| NFS/I/O error during awk's `read(2)` | **`\|\| true` swallows** | ⚠️ Open |

`[[ ! -r "$finding" ]]` tests kernel access bits at the moment of the test; it does not prevent (1) the file being revoked/deleted between `[[ -r ]]` and awk's `open(2)` (TOCTOU window — short but real on CI with parallel cleanup), (2) awk OOM during execution, or (3) the filesystem returning EIO during `read(2)`.

## Why this matters

When the residual paths fire, the script records `missing_change_type` or `score_unparseable` rather than an I/O diagnostic. A developer investigating a CI failure chases a non-existent frontmatter problem instead of the actual infrastructure failure.

## Disposition

KEPT — accepted-with-issues (T02 budget exhausted, no R5 fix). The common-case paths are genuinely closed; the residual gap is real but low-probability. A complete fix would remove `|| true` and explicitly test awk's exit status inside `extract_frontmatter_field` (or use an ERR trap), with separate halt causes for I/O failures vs. genuinely missing/unparseable fields.
