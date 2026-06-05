---
finding_id: R2-F02
reviewer_tag: security-claude
round: 2
task: 12
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-await-round.bats
  - scripts/await-round.sh
---

## F02 — Prompt-body test does not cover `await_cmd`-written files outside `.dispatch/`; `sum_file` unbounded at bash layer

**Gap 1 — non-`.dispatch/` cleanup paths untested.** The R1-added prompt-body leakage test stubs `await_cmd` as `exit 0`, which writes nothing. Real `await_cmd` implementations (third-party CLIs) may write raw response bodies to `$TMPDIR/<tag>.raw` or `$ROUND_DIR/<tag>.raw`. The cleanup `rm -rf "$ROUND_DIR/.dispatch"` only removes `.dispatch/`; files elsewhere persist with their content never asserted against.

**Gap 2 — `sum_file` lacks size cap at the bash layer.** `err_file` is bounded twice (Python 1 KiB + `head -c 1024`). `sum_file` is read and printed unconditionally:

```bash
SUM_LINE="$(cat "$SUM_FILE" 2>/dev/null || true)"
printf '%s' "$SUM_LINE"
```

If a bug grows `sum_file`, the output-bound guarantee breaks silently.

**Fix — test side:** Add a fixture where `await_cmd` writes a sentinel OUTSIDE `.dispatch/`; assert it doesn't appear in combined output.
**Fix — script side:** Apply `head -c 1024` to `$SUM_LINE` before the `printf`.
